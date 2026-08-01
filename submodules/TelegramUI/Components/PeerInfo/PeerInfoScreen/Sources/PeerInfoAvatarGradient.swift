import Foundation
import UIKit
import Display

// MARK: - Backdrop derived from the avatar
//
// The profile's info blocks sit on a soft gradient built from the avatar's own colours, so every
// person's profile is tinted like their photo. Two decisions worth stating:
//
// * Colours come from a **downscaled** copy of the avatar. Averaging a full-size image on the main
//   thread during a push transition is exactly the kind of work that turns a screen open into a
//   stutter; 16×16 carries all the hue information a two-stop gradient can express.
// * Results are cached by a caller-supplied key (the peer id). A profile relayouts constantly
//   while scrolling, and recomputing the same two colours on every pass would be pure waste.

public struct PeerInfoAvatarPalette: Equatable {
    public let top: UIColor
    public let bottom: UIColor

    public init(top: UIColor, bottom: UIColor) {
        self.top = top
        self.bottom = bottom
    }

    /// Used when there is no avatar yet, or the image cannot be read. Neutral rather than
    /// colourful: a wrong guess is more noticeable than no colour at all.
    public static func placeholder(isDark: Bool) -> PeerInfoAvatarPalette {
        if isDark {
            return PeerInfoAvatarPalette(
                top: UIColor(white: 1.0, alpha: 0.06),
                bottom: UIColor(white: 1.0, alpha: 0.02)
            )
        } else {
            return PeerInfoAvatarPalette(
                top: UIColor(white: 0.0, alpha: 0.05),
                bottom: UIColor(white: 0.0, alpha: 0.02)
            )
        }
    }
}

public final class PeerInfoAvatarGradient {
    public static let shared = PeerInfoAvatarGradient()

    private var cache: [String: PeerInfoAvatarPalette] = [:]
    private let lock = NSLock()

    private init() {}

    public func cachedPalette(key: String) -> PeerInfoAvatarPalette? {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.cache[key]
    }

    /// Returns the palette for `image`, computing it once per `key`.
    ///
    /// `isDark` only affects the alpha the colours are carried at — the hues themselves come from
    /// the photo either way, so a profile does not change character between themes.
    public func palette(for image: UIImage?, key: String, isDark: Bool) -> PeerInfoAvatarPalette {
        if let cached = self.cachedPalette(key: key) {
            return cached
        }
        guard let image, let colors = PeerInfoAvatarGradient.dominantColors(of: image) else {
            return PeerInfoAvatarPalette.placeholder(isDark: isDark)
        }

        // The backdrop sits behind text, so the photo's colours are carried at low alpha rather
        // than at full strength — enough to tint the surface, never enough to fight a label.
        let topAlpha: CGFloat = isDark ? 0.22 : 0.16
        let bottomAlpha: CGFloat = isDark ? 0.08 : 0.05
        let palette = PeerInfoAvatarPalette(
            top: colors.top.withAlphaComponent(topAlpha),
            bottom: colors.bottom.withAlphaComponent(bottomAlpha)
        )

        self.lock.lock()
        self.cache[key] = palette
        self.lock.unlock()
        return palette
    }

    public func invalidate(key: String) {
        self.lock.lock()
        self.cache.removeValue(forKey: key)
        self.lock.unlock()
    }

    /// Average colour of the image's top and bottom halves, read from a 16×16 downscale.
    ///
    /// Deliberately not a clustering algorithm: a two-stop gradient cannot express more than two
    /// colours, and the average of each half tracks a portrait's "sky above, subject below"
    /// structure closely enough while costing a single 256-pixel pass.
    private static func dominantColors(of image: UIImage) -> (top: UIColor, bottom: UIColor)? {
        let side = 16
        let bytesPerRow = side * 4
        var pixels = [UInt8](repeating: 0, count: side * side * 4)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }
        guard let context = CGContext(
            data: &pixels,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        guard let cgImage = image.cgImage else {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))

        func average(rows: Range<Int>) -> UIColor {
            var r = 0
            var g = 0
            var b = 0
            var count = 0
            for y in rows {
                for x in 0 ..< side {
                    let offset = y * bytesPerRow + x * 4
                    // Skip near-transparent pixels: they carry no colour, and averaging them in
                    // drags every palette toward black.
                    guard pixels[offset + 3] > 32 else {
                        continue
                    }
                    r += Int(pixels[offset])
                    g += Int(pixels[offset + 1])
                    b += Int(pixels[offset + 2])
                    count += 1
                }
            }
            guard count > 0 else {
                return UIColor(white: 0.5, alpha: 1.0)
            }
            return UIColor(
                red: CGFloat(r / count) / 255.0,
                green: CGFloat(g / count) / 255.0,
                blue: CGFloat(b / count) / 255.0,
                alpha: 1.0
            )
        }

        return (top: average(rows: 0 ..< side / 2), bottom: average(rows: side / 2 ..< side))
    }
}

/// A gradient backdrop that keeps itself in sync with a palette. Non-interactive by construction —
/// it is decoration and must never intercept a touch meant for the content above it.
public final class PeerInfoAvatarGradientView: UIView {
    override public static var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    private var currentPalette: PeerInfoAvatarPalette?

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.isUserInteractionEnabled = false
        if let layer = self.layer as? CAGradientLayer {
            layer.startPoint = CGPoint(x: 0.5, y: 0.0)
            layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(palette: PeerInfoAvatarPalette) {
        guard self.currentPalette != palette else {
            return
        }
        self.currentPalette = palette
        if let layer = self.layer as? CAGradientLayer {
            layer.colors = [palette.top.cgColor, palette.bottom.cgColor]
        }
    }
}
