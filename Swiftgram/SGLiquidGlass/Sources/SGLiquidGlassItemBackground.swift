import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SGLiquidGlassCore
import SGSimpleSettings
import GlassBackgroundComponent
import ComponentFlow

// MARK: - Per-item Liquid Glass
// ONLY official GlassBackgroundView → UIGlassEffect (Telegram-iOS / Apple path).

public final class SGLiquidGlassItemBackground {
    private weak var host: ASDisplayNode?
    private let glassView: GlassBackgroundView
    private var registered: Bool = false
    private var _tint: UIColor = .clear
    private var currentSize: CGSize = .zero
    private var currentRadii: GlassBackgroundView.CornerRadii = .init(radius: 0)
    private var currentIsDark: Bool = true

    public init() {
        // Force native Apple glass (never legacy custom blur)
        GlassBackgroundView.useCustomGlassImpl = false
        self.glassView = GlassBackgroundView()
        self.glassView.isUserInteractionEnabled = false
        self.glassView.isHidden = true
    }

    public func attach(to node: ASDisplayNode) {
        self.host = node
        if self.glassView.superview !== node.view {
            node.view.insertSubview(self.glassView, at: 0)
        }
        if !self.registered {
            self.registered = true
            SGLiquidGlassCoordinator.shared.register(node: self, zone: .settings)
        }
        self.refresh()
    }

    public func detach() {
        if self.registered {
            SGLiquidGlassCoordinator.shared.unregister(node: self)
            self.registered = false
        }
        self.glassView.removeFromSuperview()
        self.host = nil
    }

    public var tint: UIColor {
        get { self._tint }
        set { self._tint = newValue; self.pushGlass() }
    }

    public func updateLayout(size: CGSize, cornerRadius: CGFloat = 0) {
        self.updateLayout(
            size: size,
            topLeft: cornerRadius, topRight: cornerRadius,
            bottomLeft: cornerRadius, bottomRight: cornerRadius,
            isDark: true
        )
    }

    public func updateLayout(
        size: CGSize,
        topLeft: CGFloat, topRight: CGFloat,
        bottomLeft: CGFloat, bottomRight: CGFloat,
        isDark: Bool
    ) {
        self.currentSize = size
        self.currentRadii = .init(
            topLeft: topLeft, topRight: topRight,
            bottomLeft: bottomLeft, bottomRight: bottomRight
        )
        self.currentIsDark = isDark
        self.glassView.frame = CGRect(origin: .zero, size: size)
        self.pushGlass()
    }

    public func refresh() {
        self.pushGlass()
    }

    private func pushGlass() {
        let enabled = SGLiquidGlassZone.settings.isEnabled
        if let host = self.host, enabled {
            // Host must be transparent or Apple glass is covered
            host.backgroundColor = .clear
        }
        self.glassView.isHidden = !enabled
        guard enabled, self.currentSize.width > 0.5, self.currentSize.height > 0.5 else { return }

        GlassBackgroundView.useCustomGlassImpl = false

        // Official Apple liquid glass, with the intensity slider selecting how thin the
        // material is (see SGOfficialGlassTint.tint).
        let tint = SGOfficialGlassTint.tint(
            intensity: CGFloat(SGSimpleSettings.shared.namelessLiquidGlassIntensity),
            isDark: self.currentIsDark,
            accent: self._tint == .clear ? nil : self._tint
        )

        self.glassView.update(
            size: self.currentSize,
            cornerRadii: self.currentRadii,
            isDark: self.currentIsDark,
            tintColor: tint,
            isInteractive: true,
            isVisible: true,
            transition: .immediate
        )
        self.glassView.alpha = 1.0
    }
}

extension SGLiquidGlassItemBackground: SGLiquidGlassContainer {
    public func refreshGlass(zone: SGLiquidGlassZone) {
        self.refresh()
    }
}

// MARK: - ASDisplayNode convenience

private var sgGlassOverlayKey: UInt8 = 0

public extension ASDisplayNode {
    var sgGlassOverlay: SGLiquidGlassItemBackground? {
        if SGLiquidGlassZone.settings.isEnabled {
            if let existing = objc_getAssociatedObject(self, &sgGlassOverlayKey) as? SGLiquidGlassItemBackground {
                return existing
            }
            let overlay = SGLiquidGlassItemBackground()
            overlay.attach(to: self)
            objc_setAssociatedObject(self, &sgGlassOverlayKey, overlay, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return overlay
        } else {
            if let existing = objc_getAssociatedObject(self, &sgGlassOverlayKey) as? SGLiquidGlassItemBackground {
                existing.detach()
                objc_setAssociatedObject(self, &sgGlassOverlayKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return nil
        }
    }

    func sgRefreshGlass() {
        if let overlay = objc_getAssociatedObject(self, &sgGlassOverlayKey) as? SGLiquidGlassItemBackground {
            overlay.refresh()
        }
    }
}

// MARK: - Shared ItemList glass applicator

public enum NamelessItemListGlass {
    /// Official liquid glass section corner radius (Whitegram-style large pills)
    public static let sectionCornerRadius: CGFloat = 26.0

    public static func softSeparatorColor(isDark: Bool) -> UIColor {
        if isDark {
            return UIColor(white: 1.0, alpha: 0.12)
        } else {
            return UIColor(white: 0.0, alpha: 0.08)
        }
    }

    /// Apply official Apple liquid glass to a settings row background.
    public static func apply(
        backgroundNode: ASDisplayNode,
        topStripeNode: ASDisplayNode,
        bottomStripeNode: ASDisplayNode,
        size: CGSize,
        hasTopCorners: Bool,
        hasBottomCorners: Bool,
        isMiddleOfSection: Bool,
        isDark: Bool,
        accentTint: UIColor
    ) {
        guard SGLiquidGlassZone.settings.isEnabled else { return }

        backgroundNode.backgroundColor = .clear

        let r = sectionCornerRadius
        let top: CGFloat = hasTopCorners ? r : 0
        let bottom: CGFloat = hasBottomCorners ? r : 0

        if let glass = backgroundNode.sgGlassOverlay {
            glass.tint = .clear
            glass.updateLayout(
                size: size,
                topLeft: top, topRight: top,
                bottomLeft: bottom, bottomRight: bottom,
                isDark: isDark
            )
        }

        // Soft hairlines only between middle rows (official list look)
        topStripeNode.isHidden = true
        if isMiddleOfSection {
            bottomStripeNode.backgroundColor = softSeparatorColor(isDark: isDark)
            bottomStripeNode.isHidden = false
            bottomStripeNode.alpha = 1.0
        } else {
            bottomStripeNode.isHidden = true
        }
    }
}
