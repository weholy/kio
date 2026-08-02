import Foundation
import UIKit
import AVFoundation

/// Draws one appearance slot: a still image or a silent looping video.
///
/// Playback follows the app's lifecycle. A video left running while the app is
/// backgrounded keeps the decoder alive, drains the battery and eventually gets
/// the app killed, so it pauses on the way out and resumes on the way in.
public final class MegramBackgroundView: UIView {
    private let imageView = UIImageView()
    private let playerLayer = AVPlayerLayer()
    private let dimView = UIView()

    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var appliedPath: String?

    private var slot: MegramAppearanceStore.Slot?
    private var observers: [NSObjectProtocol] = []

    public init(slot: MegramAppearanceStore.Slot? = nil) {
        self.slot = slot

        super.init(frame: CGRect())

        self.isUserInteractionEnabled = false
        self.clipsToBounds = true

        self.imageView.contentMode = .scaleAspectFill
        self.playerLayer.videoGravity = .resizeAspectFill

        self.addSubview(self.imageView)
        self.layer.addSublayer(self.playerLayer)
        self.addSubview(self.dimView)

        let center = NotificationCenter.default
        self.observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.player?.pause()
        })
        self.observers.append(center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.player?.play()
        })
        self.observers.append(center.addObserver(forName: MegramAppearanceStore.didChange, object: nil, queue: .main) { [weak self] _ in
            self?.reload()
        })

        self.reload()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    deinit {
        for observer in self.observers {
            NotificationCenter.default.removeObserver(observer)
        }
        self.player?.pause()
    }

    public func setSlot(_ slot: MegramAppearanceStore.Slot?) {
        guard self.slot != slot else {
            return
        }
        self.slot = slot
        self.appliedPath = nil
        self.reload()
    }

    /// Picks whichever global slot is active. Video wins when both are on —
    /// two backgrounds cannot share the same space, and video is the more
    /// deliberate choice.
    public func useActiveGlobalSlot() {
        if MegramAppearanceStore.isEnabled(.globalVideo) {
            self.setSlot(.globalVideo)
        } else if MegramAppearanceStore.isEnabled(.globalPhoto) {
            self.setSlot(.globalPhoto)
        } else {
            self.setSlot(nil)
        }
    }

    private func reload() {
        guard let slot, MegramAppearanceStore.isEnabled(slot) else {
            self.teardown()
            return
        }
        let url = MegramAppearanceStore.fileURL(for: slot)
        guard FileManager.default.fileExists(atPath: url.path) else {
            self.teardown()
            return
        }

        self.isHidden = false
        self.dimView.backgroundColor = UIColor(white: 0.0, alpha: 1.0 - MegramAppearanceStore.backgroundOpacity)

        if slot.isVideo {
            self.imageView.image = nil
            self.imageView.isHidden = true
            self.playerLayer.isHidden = false
            if self.appliedPath != url.path {
                self.appliedPath = url.path
                let item = AVPlayerItem(url: url)
                let player = AVQueuePlayer(playerItem: item)
                player.isMuted = true
                // Never interrupt music the user is already playing.
                player.actionAtItemEnd = .advance
                self.looper = AVPlayerLooper(player: player, templateItem: item)
                self.playerLayer.player = player
                self.player = player
                player.play()
            }
        } else {
            self.player?.pause()
            self.player = nil
            self.looper = nil
            self.playerLayer.player = nil
            self.playerLayer.isHidden = true
            self.imageView.isHidden = false
            if self.appliedPath != url.path {
                self.appliedPath = url.path
                // Decoded off the main thread: a 2048px JPEG blocks it for a
                // noticeable moment otherwise.
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    let image = UIImage(contentsOfFile: url.path)
                    DispatchQueue.main.async {
                        self?.imageView.image = image
                    }
                }
            }
        }
    }

    private func teardown() {
        self.appliedPath = nil
        self.player?.pause()
        self.player = nil
        self.looper = nil
        self.playerLayer.player = nil
        self.imageView.image = nil
        self.isHidden = true
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
        self.dimView.frame = self.bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.playerLayer.frame = self.bounds
        CATransaction.commit()
    }
}
