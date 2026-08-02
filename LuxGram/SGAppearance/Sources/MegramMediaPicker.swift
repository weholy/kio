import Foundation
import UIKit
import AVFoundation
import PhotosUI

/// Picks a photo or video from the library and prepares it for use as an
/// appearance background.
///
/// Video is re-encoded rather than copied: a phone shoots 4K at tens of
/// megabytes a second, and decoding that continuously behind the UI drains the
/// battery and the memory budget for nothing — the result is dimmed and
/// scaled down anyway.
public final class MegramMediaPicker: NSObject {
    public enum PickError: Error {
        case cancelled
        case unreadable
        case exportFailed
    }

    private let slot: MegramAppearanceStore.Slot
    private let completion: (Result<Void, PickError>) -> Void
    private let progress: (Float) -> Void
    private weak var presenter: UIViewController?
    /// Held until the flow finishes: PHPicker does not retain its delegate.
    private var strongSelf: MegramMediaPicker?

    private var exportSession: AVAssetExportSession?
    private var progressTimer: Foundation.Timer?

    public init(
        slot: MegramAppearanceStore.Slot,
        progress: @escaping (Float) -> Void = { _ in },
        completion: @escaping (Result<Void, PickError>) -> Void
    ) {
        self.slot = slot
        self.progress = progress
        self.completion = completion
        super.init()
    }

    public func present(in viewController: UIViewController) {
        self.presenter = viewController
        self.strongSelf = self

        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = self.slot.isVideo ? .videos : .images
        // The original is needed for video: a transcoded delivery copy would be
        // re-encoded a second time by the export below.
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        viewController.present(picker, animated: true)
    }

    private func finish(_ result: Result<Void, PickError>) {
        self.progressTimer?.invalidate()
        self.progressTimer = nil
        self.exportSession = nil
        let completion = self.completion
        Queue.main.async {
            completion(result)
        }
        self.strongSelf = nil
    }

    // MARK: Photo

    private func handlePhoto(_ image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                return
            }
            // Cap the long side: a 48-megapixel still costs nearly 200 MB
            // decoded, and nothing on screen can show that detail.
            let maxSide: CGFloat = 2048.0
            let scale = min(1.0, maxSide / max(image.size.width, image.size.height))
            let targetSize = CGSize(width: floor(image.size.width * scale), height: floor(image.size.height * scale))

            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = true
            let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
            let resized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }

            guard let data = resized.jpegData(compressionQuality: 0.85) else {
                self.finish(.failure(.exportFailed))
                return
            }
            let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
            do {
                try data.write(to: temporary)
                try MegramAppearanceStore.install(temporary, for: self.slot)
                self.finish(.success(()))
            } catch {
                self.finish(.failure(.exportFailed))
            }
        }
    }

    // MARK: Video

    private func handleVideo(at url: URL) {
        let asset = AVURLAsset(url: url)

        // The audio track is dropped outright rather than muted at playback:
        // the background loops forever and the sound is never wanted.
        let composition = AVMutableComposition()
        guard
            let videoTrack = asset.tracks(withMediaType: .video).first,
            let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            self.finish(.failure(.unreadable))
            return
        }
        do {
            try compositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
            compositionTrack.preferredTransform = videoTrack.preferredTransform
        } catch {
            self.finish(.failure(.unreadable))
            return
        }

        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPreset1280x720) else {
            self.finish(.failure(.exportFailed))
            return
        }
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        export.outputURL = temporary
        export.outputFileType = .mp4
        export.shouldOptimizeForNetworkUse = true
        self.exportSession = export

        // AVAssetExportSession reports progress by polling, not by callback.
        let timer = Foundation.Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, let export = self.exportSession else {
                return
            }
            let value = export.progress
            Queue.main.async {
                self.progress(value)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.progressTimer = timer

        export.exportAsynchronously { [weak self] in
            guard let self else {
                return
            }
            guard export.status == .completed else {
                try? FileManager.default.removeItem(at: temporary)
                self.finish(.failure(.exportFailed))
                return
            }
            do {
                try MegramAppearanceStore.install(temporary, for: self.slot)
                self.finish(.success(()))
            } catch {
                self.finish(.failure(.exportFailed))
            }
        }
    }
}

extension MegramMediaPicker: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider else {
            self.finish(.failure(.cancelled))
            return
        }

        if self.slot.isVideo {
            // Ask for a file URL rather than data: a video loaded into memory
            // as Data would defeat the point of compressing it.
            provider.loadFileRepresentation(forTypeIdentifier: "public.movie") { [weak self] url, _ in
                guard let self else {
                    return
                }
                guard let url else {
                    self.finish(.failure(.unreadable))
                    return
                }
                // The provided URL is deleted as soon as this closure returns,
                // so it has to be copied before the export reads it.
                let copy = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                do {
                    try FileManager.default.copyItem(at: url, to: copy)
                } catch {
                    self.finish(.failure(.unreadable))
                    return
                }
                self.handleVideo(at: copy)
            }
        } else {
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let self else {
                    return
                }
                guard let image = object as? UIImage else {
                    self.finish(.failure(.unreadable))
                    return
                }
                self.handlePhoto(image)
            }
        }
    }
}

/// Minimal main-queue helper so this module needs no dependency on SwiftSignalKit.
private enum Queue {
    static func mainAsync(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

    enum main {
        static func async(_ block: @escaping () -> Void) {
            Queue.mainAsync(block)
        }
    }
}
