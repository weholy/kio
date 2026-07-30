import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SGLiquidGlassCore

// MARK: - Popup Glass Container

/// Adds Liquid Glass to any popup/sheet UIView or ASDisplayNode.
/// Apply to the root background view of a popup before it appears.
///
/// Usage (UIView):
///   SGLiquidGlassPopupHelper.apply(to: popupView, zone: .popup, cornerRadius: 20)
///
/// Usage (ASDisplayNode):
///   SGLiquidGlassPopupHelper.apply(to: backgroundNode, zone: .popup, cornerRadius: 20)
public enum SGLiquidGlassPopupHelper {

    // MARK: UIView

    @discardableResult
    public static func apply(
        to view: UIView,
        zone: SGLiquidGlassZone = .popup,
        cornerRadius: CGFloat = 20
    ) -> SGLiquidGlassView? {
        guard zone.isEnabled else { return nil }
        let glass = SGLiquidGlassView()
        glass.cornerRadii = GlassRadii(radius: cornerRadius)
        glass.frame = view.bounds
        glass.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Insert below all content so it doesn't occlude anything
        view.insertSubview(glass, at: 0)
        // Make view itself semi-transparent so glass shines through
        view.backgroundColor = view.backgroundColor?.withAlphaComponent(0.0) ?? .clear
        SGLiquidGlassCoordinator.shared.register(node: glass, zone: zone)
        return glass
    }

    // MARK: ASDisplayNode

    @discardableResult
    public static func apply(
        to node: ASDisplayNode,
        zone: SGLiquidGlassZone = .popup,
        cornerRadius: CGFloat = 20
    ) -> SGLiquidGlassNode? {
        guard zone.isEnabled else { return nil }
        let glass = SGLiquidGlassNode()
        glass.glassCornerRadii = GlassRadii(radius: cornerRadius)
        node.insertSubnode(glass, at: 0)
        glass.frame = node.bounds
        node.backgroundColor = .clear
        SGLiquidGlassCoordinator.shared.register(node: glass, zone: zone)
        return glass
    }
}

// MARK: - Context Menu Glass Background

/// UIView subclass that serves as a glass background for context menus.
/// Instantiate and add as the bottom-most subview of the context menu container.
public final class SGLiquidGlassContextMenuBackground: UIView, SGLiquidGlassViewContainer {
    private let glassView: SGLiquidGlassView

    public init(cornerRadius: CGFloat = 14) {
        self.glassView = SGLiquidGlassView()
        self.glassView.cornerRadii = GlassRadii(radius: cornerRadius)
        self.glassView.glassKind = .panel
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.addSubview(self.glassView)
        SGLiquidGlassCoordinator.shared.register(node: self, zone: .contextMenu)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        SGLiquidGlassCoordinator.shared.unregister(node: self)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.glassView.frame = self.bounds
    }

    public func refreshGlass(zone: SGLiquidGlassZone) {
        self.glassView.refreshGlass(zone: zone)
        self.isHidden = !zone.isEnabled
    }
}

// MARK: - Search Bar Glass Background

/// Adds Liquid Glass to a search bar container view.
/// Wrap the search bar in a container and use this helper.
public final class SGLiquidGlassSearchBackground: UIView, SGLiquidGlassViewContainer {
    private let glassView: SGLiquidGlassView

    public init(cornerRadius: CGFloat = 10) {
        self.glassView = SGLiquidGlassView()
        self.glassView.cornerRadii = GlassRadii(radius: cornerRadius)
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.addSubview(self.glassView)
        SGLiquidGlassCoordinator.shared.register(node: self, zone: .search)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        SGLiquidGlassCoordinator.shared.unregister(node: self)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.glassView.frame = self.bounds
    }

    public func refreshGlass(zone: SGLiquidGlassZone) {
        self.glassView.refreshGlass(zone: zone)
        self.isHidden = !zone.isEnabled
    }
}
