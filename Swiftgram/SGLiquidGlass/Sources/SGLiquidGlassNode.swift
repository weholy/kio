import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SGLiquidGlassCore
import SGSimpleSettings
import GlassBackgroundComponent
import ComponentFlow

// MARK: - Official Apple Liquid Glass only
//
// NO custom blur, NO specular layers, NO hand-rolled UIVisualEffectView.
// Everything goes through Telegram's GlassBackgroundView → UIGlassEffect
// (same path as official Telegram-iOS on iOS 26).

/// Maps zone → official GlassBackgroundView.TintColor (Apple UIGlassEffect).
public enum SGOfficialGlassTint {
    /// Interactive chrome (buttons, input, menu, nav pills) → `.panel` → UIGlassEffect(.regular)
    public static var panel: GlassBackgroundView.TintColor {
        .init(kind: .panel)
    }

    /// Large transparent surfaces (settings sheets over wallpaper) → `.clear` → UIGlassEffect(.clear)
    public static var clear: GlassBackgroundView.TintColor {
        .init(kind: .clear)
    }

    /// Resolves the tint that actually reaches `UIGlassEffect`.
    ///
    /// The material is *always* `UIGlassEffect(style: .clear)` — the see-through iOS 26 glass
    /// that refracts whatever is behind it. `.regular` was what made every surface read as
    /// milky fog: it composites an opaque-ish white/grey wash over the backdrop, so wallpaper
    /// and bubbles behind the panel disappear. Translucency is therefore never expressed via
    /// the host view's `alpha` (that cross-dissolves the effect view toward a flat rectangle
    /// and kills the refraction) — only via the tint alpha layered on top of clear glass.
    ///
    /// `intensity` no longer picks the *style*; it only scales the readability dim, so text on
    /// a menu stays legible over a bright wallpaper. 0.0 → no dim at all, 1.0 → the strongest
    /// dim we allow (still far more transparent than `.regular` ever was).
    public static func resolve(kind: GlassBackgroundView.TintColor.Kind, isDark: Bool, accent: UIColor?) -> GlassBackgroundView.TintColor {
        // An explicit custom colour from a call site wins — it is a deliberate art direction
        // choice (bubble fill, accent button), we only force its style to `.clear`.
        if case let .custom(_, color) = kind {
            return .init(kind: .custom(style: .clear, color: color))
        }

        let intensity = max(0.0, min(1.0, CGFloat(SGSimpleSettings.shared.namelessLiquidGlassIntensity)))
        // Accent tinting only applies when the user turned it on; otherwise the dim is neutral
        // (black on dark so panels sink into the backdrop, a whisper of white on light so text
        // keeps contrast without the surface turning into fog).
        let useAccent = SGSimpleSettings.shared.namelessLiquidGlassTinting && accent != nil
        let maxAlpha: CGFloat = isDark ? 0.26 : 0.10
        let alpha = maxAlpha * intensity
        if alpha <= 0.001 && !useAccent {
            return .init(kind: .clear)
        }
        let base = useAccent ? accent! : (isDark ? UIColor.black : UIColor.white)
        return .init(kind: .custom(style: .clear, color: base.withAlphaComponent(alpha)))
    }

    public static func forZone(_ zone: SGLiquidGlassZone, isDark: Bool = true, accent: UIColor? = nil) -> GlassBackgroundView.TintColor {
        return resolve(kind: .clear, isDark: isDark, accent: accent)
    }
}

// MARK: - Shared push helper

private func pushOfficialGlass(
    view: GlassBackgroundView,
    size: CGSize,
    radii: GlassBackgroundView.CornerRadii,
    isDark: Bool,
    tint: GlassBackgroundView.TintColor,
    isInteractive: Bool,
    isVisible: Bool
) {
    guard size.width > 0.5, size.height > 0.5 else { return }
    // Force native Apple path (never legacy custom blur impl)
    GlassBackgroundView.useCustomGlassImpl = false
    view.update(
        size: size,
        cornerRadii: radii,
        isDark: isDark,
        tintColor: tint,
        isInteractive: isInteractive,
        isVisible: isVisible,
        transition: .immediate
    )
    // Always fully opaque: see the note on `SGOfficialGlassTint.tint(intensity:isDark:accent:)`
    // — translucency comes from the glass style, not from dimming the view.
    view.alpha = 1.0
}

// MARK: - Glass Node (ASDisplayKit wrapper around official GlassBackgroundView)

public final class SGLiquidGlassNode: ASDisplayNode, SGLiquidGlassContainer {

    private let glassView = GlassBackgroundView()
    private var _tintColor: UIColor = .clear
    private var _cornerRadii: GlassRadii = .init(radius: 0)
    private var _glassVisible: Bool = true
    private var _interactive: Bool = true
    private var _isDark: Bool = true
    private var _kind: GlassBackgroundView.TintColor.Kind = .panel

    public var glassTintColor: UIColor {
        get { _tintColor }
        set { if _tintColor != newValue { _tintColor = newValue; push() } }
    }

    public var glassCornerRadii: GlassRadii {
        get { _cornerRadii }
        set { _cornerRadii = newValue; push() }
    }

    public var glassVisible: Bool {
        get { _glassVisible }
        set { _glassVisible = newValue; glassView.isHidden = !newValue; push() }
    }

    public var interactive: Bool {
        get { _interactive }
        set { _interactive = newValue; push() }
    }

    /// Kept for API compatibility; official glass has its own specular — no custom layer.
    public var specularEnabled: Bool {
        get { true }
        set { /* no-op: no custom specular */ }
    }

    public var isDark: Bool {
        get { _isDark }
        set { _isDark = newValue; push() }
    }

    /// Use `.panel` (regular) or `.clear` — official Apple styles only.
    public var glassKind: GlassBackgroundView.TintColor.Kind {
        get { _kind }
        set { _kind = newValue; push() }
    }

    public override init() {
        super.init()
        isLayerBacked = false
        backgroundColor = .clear
        clipsToBounds = false
        glassView.isUserInteractionEnabled = false
    }

    public override func didLoad() {
        super.didLoad()
        if glassView.superview !== view {
            view.insertSubview(glassView, at: 0)
        }
        push()
    }

    private func officialTint() -> GlassBackgroundView.TintColor {
        // The requested `glassKind` is respected — see SGOfficialGlassTint.resolve.
        return SGOfficialGlassTint.resolve(
            kind: _kind,
            isDark: _isDark,
            accent: _tintColor == .clear ? nil : _tintColor
        )
    }

    private func push() {
        guard isNodeLoaded else { return }
        if glassView.superview !== view {
            view.insertSubview(glassView, at: 0)
        }
        glassView.frame = bounds
        glassView.isHidden = !_glassVisible
        let r = GlassBackgroundView.CornerRadii(
            topLeft: _cornerRadii.topLeft, topRight: _cornerRadii.topRight,
            bottomLeft: _cornerRadii.bottomLeft, bottomRight: _cornerRadii.bottomRight
        )
        pushOfficialGlass(
            view: glassView,
            size: bounds.size,
            radii: r,
            isDark: _isDark,
            tint: officialTint(),
            isInteractive: _interactive,
            isVisible: _glassVisible
        )
    }

    public override func layout() {
        super.layout()
        glassView.frame = bounds
        push()
    }

    public func updateGlassFrame(_ frame: CGRect, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self, frame: frame)
        glassView.frame = bounds
        push()
    }

    public func refreshGlass(zone: SGLiquidGlassZone) {
        guard isNodeLoaded else { return }
        let enabled = zone.isEnabled
        let shouldHide = !enabled || !_glassVisible
        // MARK: Nameless — "Анимация фейда при включении": cross-fade the surface when glass
        // is switched on/off instead of popping. Only animates on an actual visibility change.
        if zone.fadeAnimationEnabled, glassView.isHidden != shouldHide {
            if shouldHide {
                glassView.alpha = 1.0
                UIView.animate(withDuration: 0.25, animations: {
                    self.glassView.alpha = 0.0
                }, completion: { _ in
                    self.glassView.isHidden = true
                    self.glassView.alpha = 1.0
                })
            } else {
                glassView.isHidden = false
                // push() rebuilds the effect and resets alpha to 1, so fade from 0 afterwards.
                push()
                glassView.alpha = 0.0
                UIView.animate(withDuration: 0.25) {
                    self.glassView.alpha = 1.0
                }
            }
            return
        }
        glassView.isHidden = shouldHide
        if enabled {
            push()
        }
    }
}

// MARK: - Glass View (UIView wrapper around official GlassBackgroundView)

public final class SGLiquidGlassView: UIView, SGLiquidGlassViewProtocol, SGLiquidGlassViewContainer {
    private let glassView = GlassBackgroundView()
    private var _tintColor: UIColor = .clear
    private var _cornerRadii: GlassRadii = .init(radius: 0)
    private var _interactive: Bool = true
    private var _visible: Bool = true
    private var _isDark: Bool = true
    private var _kind: GlassBackgroundView.TintColor.Kind = .panel

    public var tintColorGlass: UIColor {
        get { _tintColor }
        set { _tintColor = newValue; push() }
    }

    public var cornerRadii: GlassRadii {
        get { _cornerRadii }
        set { _cornerRadii = newValue; push() }
    }

    public var isInteractive: Bool {
        get { _interactive }
        set { _interactive = newValue; push() }
    }

    public var isVisible: Bool {
        get { _visible }
        set { _visible = newValue; glassView.isHidden = !newValue; push() }
    }

    public var isDark: Bool {
        get { _isDark }
        set { _isDark = newValue; push() }
    }

    public var glassKind: GlassBackgroundView.TintColor.Kind {
        get { _kind }
        set { _kind = newValue; push() }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = false
        isUserInteractionEnabled = false
        glassView.isUserInteractionEnabled = false
        addSubview(glassView)
    }

    required init?(coder: NSCoder) { fatalError() }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil { push() }
    }

    private func officialTint() -> GlassBackgroundView.TintColor {
        return SGOfficialGlassTint.resolve(
            kind: _kind,
            isDark: _isDark,
            accent: _tintColor == .clear ? nil : _tintColor
        )
    }

    private func push() {
        glassView.frame = bounds
        glassView.isHidden = !_visible
        let r = GlassBackgroundView.CornerRadii(
            topLeft: _cornerRadii.topLeft, topRight: _cornerRadii.topRight,
            bottomLeft: _cornerRadii.bottomLeft, bottomRight: _cornerRadii.bottomRight
        )
        pushOfficialGlass(
            view: glassView,
            size: bounds.size,
            radii: r,
            isDark: _isDark,
            tint: officialTint(),
            isInteractive: _interactive,
            isVisible: _visible
        )
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        glassView.frame = bounds
        push()
    }

    public func refreshGlass(zone: SGLiquidGlassZone) {
        let enabled = zone.isEnabled
        glassView.isHidden = !enabled || !_visible
        if enabled {
            push()
        }
    }
}

// MARK: - Factory

public extension SGLiquidGlassFactory {
    @discardableResult
    func registerConcreteGlassView() -> Bool {
        if create == nil {
            create = {
                let v = SGLiquidGlassView()
                v.glassKind = .panel
                return v
            }
        }
        return true
    }
}

public enum SGLiquidGlass {
    @discardableResult
    public static func registerFactory() -> Bool {
        // Always native Apple UIGlassEffect path
        GlassBackgroundView.useCustomGlassImpl = false
        return SGLiquidGlassFactory.shared.registerConcreteGlassView()
    }
}
