import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramCore
import AccountContext
import ChatPresentationInterfaceState
import ChatControllerInteraction
import SGLiquidGlassCore
import SGLiquidGlass

public protocol ChatInputPanelViewForOverlayContent: UIView {
    func maybeDismissContent(point: CGPoint)
}

open class ChatInputPanelNode: ASDisplayNode, SGLiquidGlassContainer {
    open var context: AccountContext?
    open var chatControllerInteraction: ChatControllerInteraction?
    open var interfaceInteraction: ChatPanelInterfaceInteraction?
    open var prevInputPanelNode: ChatInputPanelNode?

    open var viewForOverlayContent: ChatInputPanelViewForOverlayContent?

    // nameless: Liquid Glass overlay for the chat input panel
    private var _glassNode: SGLiquidGlassNode?
    private var glassRegistered: Bool = false
    private var glassSetupDone: Bool = false

    open func updateAbsoluteRect(_ rect: CGRect, within containerSize: CGSize, transition: ContainedViewLayoutTransition) {
    }

    public final func compactBottomSideInset(bottomInset: CGFloat, deviceMetrics: DeviceMetrics) -> CGFloat {
        if bottomInset <= 32.0 && deviceMetrics.screenCornerRadius > 0.0 {
            return 18.0
        } else {
            return 0.0
        }
    }

    open func updateLayout(width: CGFloat, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat, additionalSideInsets: UIEdgeInsets, maxHeight: CGFloat, maxOverlayHeight: CGFloat, isSecondary: Bool, transition: ContainedViewLayoutTransition, interfaceState: ChatPresentationInterfaceState, metrics: LayoutMetrics, deviceMetrics: DeviceMetrics, isMediaInputExpanded: Bool) -> CGFloat {
        return 0.0
    }

    open func minimalHeight(interfaceState: ChatPresentationInterfaceState, metrics: LayoutMetrics) -> CGFloat {
        return 0.0
    }

    open func defaultHeight(metrics: LayoutMetrics) -> CGFloat {
        if case .regular = metrics.widthClass, case .regular = metrics.heightClass {
            return 40.0
        } else {
            return 40.0
        }
    }

    open func canHandleTransition(from prevInputPanelNode: ChatInputPanelNode?) -> Bool {
        return false
    }

    // nameless: lazy Liquid Glass setup. Done in `didLoad` so we don't have to
    // override `init()` (which could conflict with subclass designated
    // initializers).
    private func ensureGlassSetup() {
        guard !self.glassSetupDone else { return }
        self.glassSetupDone = true
        let g = SGLiquidGlassNode()
        g.glassTintColor = .clear
        g.glassCornerRadii = GlassRadii(radius: 22.0)
        g.interactive = true
        g.glassVisible = SGLiquidGlassZone.inputPanel.isEnabled
        // Glass sits behind text/buttons so controls stay tappable
        self.insertSubnode(g, at: 0)
        self._glassNode = g
        if !self.glassRegistered {
            self.glassRegistered = true
            SGLiquidGlassCoordinator.shared.register(node: g, zone: .inputPanel)
        }
    }

    open override func didLoad() {
        super.didLoad()
        self.ensureGlassSetup()
    }

    deinit {
        if let g = self._glassNode, self.glassRegistered {
            SGLiquidGlassCoordinator.shared.unregister(node: g)
        }
    }

    open override func layout() {
        super.layout()
        self.ensureGlassSetup()
        if let g = self._glassNode {
            g.frame = self.bounds
            g.glassCornerRadii = GlassRadii(radius: min(22.0, self.bounds.height * 0.5))
            g.glassVisible = SGLiquidGlassZone.inputPanel.isEnabled
            g.refreshGlass(zone: .inputPanel)
        }
    }

    public func updateGlassFrame(_ frame: CGRect, transition: ContainedViewLayoutTransition) {
        self.frame = frame
        if let g = self._glassNode {
            transition.updateFrame(node: g, frame: self.bounds)
            g.glassCornerRadii = GlassRadii(radius: min(22.0, self.bounds.height * 0.5))
            g.glassVisible = SGLiquidGlassZone.inputPanel.isEnabled
            g.refreshGlass(zone: .inputPanel)
        }
    }

    // MARK: SGLiquidGlassContainer

    public func refreshGlass(zone: SGLiquidGlassZone) {
        guard let g = self._glassNode else { return }
        g.glassVisible = SGLiquidGlassZone.inputPanel.isEnabled
        g.refreshGlass(zone: .inputPanel)
    }
}
