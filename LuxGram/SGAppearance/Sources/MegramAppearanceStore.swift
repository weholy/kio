import Foundation
import UIKit

/// Where Megram keeps the media backing the custom appearance, and which of it
/// is switched on.
///
/// Files live in Application Support rather than the settings store: they are
/// megabytes, and UserDefaults is not a file system. Only paths are persisted.
public enum MegramAppearanceStore {
    public enum Slot: String, CaseIterable {
        /// Behind every screen in the app.
        case globalVideo = "global.video"
        case globalPhoto = "global.photo"
        /// Behind the profile screen only.
        case profileWallpaper = "profile.wallpaper"
        /// The strip above the avatar, down to the track card.
        case profileBannerPhoto = "profile.banner.photo"
        case profileBannerVideo = "profile.banner.video"

        public var isVideo: Bool {
            switch self {
            case .globalVideo, .profileBannerVideo:
                return true
            case .globalPhoto, .profileWallpaper, .profileBannerPhoto:
                return false
            }
        }

        var enabledKey: String {
            return "nameless.appearance.\(self.rawValue).enabled"
        }

        var fileName: String {
            return "megram-\(self.rawValue.replacingOccurrences(of: ".", with: "-"))"
        }
    }

    private static var defaults: UserDefaults {
        return .standard
    }

    /// Directory for appearance media, created on first use.
    public static var mediaDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = base.appendingPathComponent("MegramAppearance", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    public static func fileURL(for slot: Slot) -> URL {
        return self.mediaDirectory.appendingPathComponent(slot.fileName + (slot.isVideo ? ".mp4" : ".jpg"))
    }

    public static func hasMedia(for slot: Slot) -> Bool {
        return FileManager.default.fileExists(atPath: self.fileURL(for: slot).path)
    }

    public static func isEnabled(_ slot: Slot) -> Bool {
        // A slot with no file behind it is off regardless of the switch: the
        // switch is turned on before the picker runs, and an interrupted pick
        // would otherwise leave it claiming to be active.
        return self.defaults.bool(forKey: slot.enabledKey) && self.hasMedia(for: slot)
    }

    public static func setEnabled(_ slot: Slot, _ value: Bool) {
        self.defaults.set(value, forKey: slot.enabledKey)
        NotificationCenter.default.post(name: MegramAppearanceStore.didChange, object: nil)
    }

    public static func clear(_ slot: Slot) {
        try? FileManager.default.removeItem(at: self.fileURL(for: slot))
        self.defaults.set(false, forKey: slot.enabledKey)
        NotificationCenter.default.post(name: MegramAppearanceStore.didChange, object: nil)
    }

    /// Moves a processed file into place, replacing whatever was there.
    public static func install(_ url: URL, for slot: Slot) throws {
        let destination = self.fileURL(for: slot)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: url, to: destination)
        self.defaults.set(true, forKey: slot.enabledKey)
        NotificationCenter.default.post(name: MegramAppearanceStore.didChange, object: nil)
    }

    /// Posted whenever a slot's file or switch changes, so views can reload.
    public static let didChange = Notification.Name("megram.appearance.didChange")

    /// True when anything is drawn behind the whole app — the signal the theme
    /// uses to decide whether list backgrounds must become translucent.
    public static var hasGlobalBackground: Bool {
        return self.isEnabled(.globalVideo) || self.isEnabled(.globalPhoto)
    }

    /// How much of the background shows through the UI, 0...1.
    public static var backgroundOpacity: CGFloat {
        let stored = self.defaults.object(forKey: "nameless.appearance.opacity") as? Double
        return CGFloat(stored ?? 0.75)
    }

    public static func setBackgroundOpacity(_ value: CGFloat) {
        self.defaults.set(Double(max(0.0, min(1.0, value))), forKey: "nameless.appearance.opacity")
        NotificationCenter.default.post(name: MegramAppearanceStore.didChange, object: nil)
    }
}
