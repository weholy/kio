import Foundation
import UIKit

/// The flame artwork. Drawn as vectors so a single shape covers every level and
/// every size — the level only swaps the gradient stops.
///
/// If a raster asset named `Megram/Flame0`, `Megram/Flame1` or `Megram/Flame2`
/// is present in the main bundle it is used instead, so hand-drawn artwork can
/// be dropped in later without touching this file.
public final class MegramFlameView: UIView {
    private let glowLayer = CAGradientLayer()
    private let outerLayer = CAGradientLayer()
    private let outerMask = CAShapeLayer()
    private let coreLayer = CAGradientLayer()
    private let coreMask = CAShapeLayer()
    private let imageView = UIImageView()

    private var animating = false

    public private(set) var level: MegramFireLevel

    /// Dimmed rendering for a fire that has not been lit yet.
    public var isDimmed: Bool = false {
        didSet {
            if self.isDimmed != oldValue {
                self.applyLevel()
            }
        }
    }

    public init(level: MegramFireLevel) {
        self.level = level

        super.init(frame: CGRect())

        self.isUserInteractionEnabled = false

        self.glowLayer.type = .radial
        self.glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        self.glowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)

        self.outerLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        self.outerLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.outerLayer.mask = self.outerMask

        self.coreLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        self.coreLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.coreLayer.mask = self.coreMask

        self.imageView.contentMode = .scaleAspectFit
        self.imageView.isHidden = true

        self.layer.addSublayer(self.glowLayer)
        self.layer.addSublayer(self.outerLayer)
        self.layer.addSublayer(self.coreLayer)
        self.addSubview(self.imageView)

        self.applyLevel()
    }

    required public init?(coder: NSCoder) {
        return nil
    }

    public func update(level: MegramFireLevel) {
        guard self.level != level else {
            return
        }
        self.level = level
        self.applyLevel()
    }

    private func applyLevel() {
        let palette = self.level.palette
        let opacity: Float = self.isDimmed ? 0.28 : 1.0

        if let image = UIImage(named: "Megram/Flame\(self.level.rawValue)") {
            self.imageView.image = image
            self.imageView.isHidden = false
            self.imageView.layer.opacity = opacity
            self.outerLayer.isHidden = true
            self.coreLayer.isHidden = true
        } else {
            self.imageView.isHidden = true
            self.outerLayer.isHidden = false
            self.coreLayer.isHidden = false
            self.outerLayer.colors = palette.flameOuter.map { $0.cgColor }
            self.coreLayer.colors = palette.flameCore.map { $0.cgColor }
            self.outerLayer.opacity = opacity
            self.coreLayer.opacity = opacity
        }

        self.glowLayer.colors = [
            palette.glow.withAlphaComponent(self.isDimmed ? 0.12 : 0.55).cgColor,
            palette.glow.withAlphaComponent(self.isDimmed ? 0.04 : 0.18).cgColor,
            palette.glow.withAlphaComponent(0.0).cgColor
        ]
        self.glowLayer.locations = [0.0, 0.45, 1.0]
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        let bounds = self.bounds
        guard bounds.width > 0.0, bounds.height > 0.0 else {
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let glowSide = max(bounds.width, bounds.height) * 2.1
        self.glowLayer.frame = CGRect(
            x: bounds.midX - glowSide / 2.0,
            y: bounds.midY - glowSide / 2.0 + bounds.height * 0.05,
            width: glowSide,
            height: glowSide
        )

        self.outerLayer.frame = bounds
        self.coreLayer.frame = bounds
        self.imageView.frame = bounds

        self.outerMask.frame = bounds
        self.outerMask.path = MegramFlameView.outerPath(in: bounds).cgPath
        self.coreMask.frame = bounds
        self.coreMask.path = MegramFlameView.corePath(in: bounds).cgPath

        CATransaction.commit()
    }

    // MARK: Animation

    public func startAnimating() {
        guard !self.animating else {
            return
        }
        self.animating = true

        let breathe = CABasicAnimation(keyPath: "transform.scale")
        breathe.fromValue = 0.985 as NSNumber
        breathe.toValue = 1.035 as NSNumber
        breathe.duration = 1.7
        breathe.autoreverses = true
        breathe.repeatCount = .infinity
        breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        self.outerLayer.add(breathe, forKey: "megramBreathe")
        self.imageView.layer.add(breathe, forKey: "megramBreathe")

        let flicker = CABasicAnimation(keyPath: "transform.scale")
        flicker.fromValue = 0.94 as NSNumber
        flicker.toValue = 1.06 as NSNumber
        flicker.duration = 0.85
        flicker.autoreverses = true
        flicker.repeatCount = .infinity
        flicker.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        self.coreLayer.add(flicker, forKey: "megramFlicker")

        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.94 as NSNumber
        pulse.toValue = 1.1 as NSNumber
        pulse.duration = 2.4
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        self.glowLayer.add(pulse, forKey: "megramPulse")
    }

    public func stopAnimating() {
        self.animating = false
        self.outerLayer.removeAllAnimations()
        self.coreLayer.removeAllAnimations()
        self.glowLayer.removeAllAnimations()
        self.imageView.layer.removeAllAnimations()
    }

    /// One-shot bump, used when a day is added to the streak.
    public func playIgnition() {
        let bump = CAKeyframeAnimation(keyPath: "transform.scale")
        bump.values = [1.0 as NSNumber, 1.22 as NSNumber, 0.94 as NSNumber, 1.0 as NSNumber]
        bump.keyTimes = [0.0 as NSNumber, 0.35 as NSNumber, 0.7 as NSNumber, 1.0 as NSNumber]
        bump.duration = 0.55
        bump.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        self.outerLayer.add(bump, forKey: "megramIgnition")
        self.coreLayer.add(bump, forKey: "megramIgnition")
        self.imageView.layer.add(bump, forKey: "megramIgnition")
    }

    // MARK: Geometry

    /// Design box the paths below are authored in.
    private static let designSize = CGSize(width: 100.0, height: 124.0)

    private static func scaled(_ points: [CGPoint], in rect: CGRect) -> [CGPoint] {
        let side = min(rect.width / self.designSize.width, rect.height / self.designSize.height)
        let width = self.designSize.width * side
        let height = self.designSize.height * side
        let originX = rect.midX - width / 2.0
        let originY = rect.midY - height / 2.0
        return points.map { CGPoint(x: originX + $0.x * side, y: originY + $0.y * side) }
    }

    /// Outer silhouette: tall hooked tip, two side tongues, round base.
    private static func outerPath(in rect: CGRect) -> UIBezierPath {
        let p = self.scaled([
            CGPoint(x: 55.0, y: 3.0),    // 0 tip
            CGPoint(x: 70.0, y: 20.0), CGPoint(x: 77.0, y: 33.0), CGPoint(x: 74.0, y: 47.0),
            CGPoint(x: 78.0, y: 42.0), CGPoint(x: 84.0, y: 37.0), CGPoint(x: 88.0, y: 32.0),
            CGPoint(x: 91.0, y: 45.0), CGPoint(x: 85.0, y: 55.0), CGPoint(x: 79.0, y: 64.0),
            CGPoint(x: 89.0, y: 70.0), CGPoint(x: 95.0, y: 75.0), CGPoint(x: 95.0, y: 86.0),
            CGPoint(x: 95.0, y: 106.0), CGPoint(x: 76.0, y: 122.0), CGPoint(x: 50.0, y: 122.0),
            CGPoint(x: 24.0, y: 122.0), CGPoint(x: 5.0, y: 106.0), CGPoint(x: 5.0, y: 86.0),
            CGPoint(x: 5.0, y: 75.0), CGPoint(x: 12.0, y: 70.0), CGPoint(x: 21.0, y: 64.0),
            CGPoint(x: 15.0, y: 55.0), CGPoint(x: 9.0, y: 45.0), CGPoint(x: 12.0, y: 32.0),
            CGPoint(x: 16.0, y: 37.0), CGPoint(x: 22.0, y: 42.0), CGPoint(x: 26.0, y: 47.0),
            CGPoint(x: 22.0, y: 22.0), CGPoint(x: 33.0, y: 2.0)
        ], in: rect)

        let path = UIBezierPath()
        path.move(to: p[0])
        path.addCurve(to: p[3], controlPoint1: p[1], controlPoint2: p[2])
        path.addCurve(to: p[6], controlPoint1: p[4], controlPoint2: p[5])
        path.addCurve(to: p[9], controlPoint1: p[7], controlPoint2: p[8])
        path.addCurve(to: p[12], controlPoint1: p[10], controlPoint2: p[11])
        path.addCurve(to: p[15], controlPoint1: p[13], controlPoint2: p[14])
        path.addCurve(to: p[18], controlPoint1: p[16], controlPoint2: p[17])
        path.addCurve(to: p[21], controlPoint1: p[19], controlPoint2: p[20])
        path.addCurve(to: p[24], controlPoint1: p[22], controlPoint2: p[23])
        path.addCurve(to: p[27], controlPoint1: p[25], controlPoint2: p[26])
        path.addCurve(to: p[0], controlPoint1: p[28], controlPoint2: p[29])
        path.close()
        return path
    }

    /// Inner core: a teardrop sitting in the lower half of the silhouette.
    private static func corePath(in rect: CGRect) -> UIBezierPath {
        let p = self.scaled([
            CGPoint(x: 53.0, y: 37.0),   // 0 tip
            CGPoint(x: 63.0, y: 52.0), CGPoint(x: 69.0, y: 65.0), CGPoint(x: 68.0, y: 79.0),
            CGPoint(x: 68.0, y: 97.0), CGPoint(x: 62.0, y: 110.0), CGPoint(x: 50.0, y: 110.0),
            CGPoint(x: 38.0, y: 110.0), CGPoint(x: 32.0, y: 97.0), CGPoint(x: 32.0, y: 79.0),
            CGPoint(x: 32.0, y: 71.0), CGPoint(x: 37.0, y: 65.0), CGPoint(x: 40.0, y: 58.0),
            CGPoint(x: 43.0, y: 51.0), CGPoint(x: 47.0, y: 44.0)
        ], in: rect)

        let path = UIBezierPath()
        path.move(to: p[0])
        path.addCurve(to: p[3], controlPoint1: p[1], controlPoint2: p[2])
        path.addCurve(to: p[6], controlPoint1: p[4], controlPoint2: p[5])
        path.addCurve(to: p[9], controlPoint1: p[7], controlPoint2: p[8])
        path.addCurve(to: p[12], controlPoint1: p[10], controlPoint2: p[11])
        path.addCurve(to: p[0], controlPoint1: p[13], controlPoint2: p[14])
        path.close()
        return path
    }
}

// MARK: - Badge

/// Compact "🔥 N" pill used in the chat navigation bar.
public final class MegramFireBadgeView: UIView {
    private let flameView: MegramFlameView
    private let label = UILabel()
    private let backgroundView = UIView()
    private let button = UIButton(type: .custom)

    public private(set) var days: Int = 0

    /// Set to make the badge open the fire screen. While nil the badge stays
    /// decorative and lets touches through to whatever is underneath.
    public var pressed: (() -> Void)? {
        didSet {
            self.isUserInteractionEnabled = self.pressed != nil
        }
    }

    public init() {
        self.flameView = MegramFlameView(level: .ember)

        super.init(frame: CGRect())

        self.isUserInteractionEnabled = false

        self.backgroundView.layer.cornerRadius = 9.0
        self.backgroundView.layer.borderWidth = 1.0

        self.label.font = UIFont.systemFont(ofSize: 11.0, weight: .bold)
        self.label.textAlignment = .center
        self.label.textColor = .white

        self.addSubview(self.backgroundView)
        self.addSubview(self.flameView)
        self.addSubview(self.label)
        self.addSubview(self.button)

        self.button.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
    }

    @objc private func buttonPressed() {
        self.pressed?()
    }

    required public init?(coder: NSCoder) {
        return nil
    }

    public func update(days: Int) {
        self.days = days
        let level = MegramFireLevel.level(forDays: days)
        self.flameView.update(level: level)
        self.label.text = "\(days)"
        let palette = level.palette
        self.backgroundView.backgroundColor = palette.glow.withAlphaComponent(0.22)
        self.backgroundView.layer.borderColor = palette.accent.withAlphaComponent(0.5).cgColor
        self.setNeedsLayout()
    }

    /// Intrinsic width for a given day count, so callers can lay the badge out
    /// without instantiating it.
    public static func width(days: Int) -> CGFloat {
        let digits = CGFloat("\(max(days, 0))".count)
        return 16.0 + digits * 7.0 + 8.0
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        let bounds = self.bounds
        self.backgroundView.frame = bounds
        self.flameView.frame = CGRect(x: 2.0, y: (bounds.height - 14.0) / 2.0, width: 12.0, height: 14.0)
        self.label.frame = CGRect(x: 14.0, y: 0.0, width: max(0.0, bounds.width - 16.0), height: bounds.height)
        // Padded outwards: the pill is small, and an 18pt tap target is hard to
        // hit in a navigation bar.
        self.button.frame = bounds.insetBy(dx: -6.0, dy: -6.0)
    }
}
