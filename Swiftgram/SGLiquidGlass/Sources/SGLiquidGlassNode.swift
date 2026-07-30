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

    public static func forZone(_ zone: SGLiquidGlassZone) -> GlassBackgroundView.TintColor {
        // Everywhere: official Apple liquid glass = UIGlassEffect(.regular) via .panel
        // (matches chat bubbles / settings pills / tab bar in Whitegram reference)
        let _ = zone
        return .init(kind: .panel)
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
    let intensity = CGFloat(SGSimpleSettings.shared.namelessLiquidGlassIntensity)
    // Full opacity — never dim glass into a gray fog
    view.alpha = (intensity <= 0.01) ? 1.0 : max(0.85, min(1.0, intensity))
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
        if _tintColor != .clear {
            let style: GlassBackgroundView.TintColor.CustomStyle = (_kind == .clear) ? .clear : .default
            return .init(kind: .custom(style: style, color: _tintColor.withAlphaComponent(0.35)))
        }
        return .init(kind: _kind)
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
        _kind = SGOfficialGlassTint.forZone(zone).kind
        glassView.isHidden = !enabled || !_glassVisible
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
        if _tintColor != .clear {
            let style: GlassBackgroundView.TintColor.CustomStyle = (_kind == .clear) ? .clear : .default
            return .init(kind: .custom(style: style, color: _tintColor.withAlphaComponent(0.35)))
        }
        return .init(kind: _kind)
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
        _kind = SGOfficialGlassTint.forZone(zone).kind
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
