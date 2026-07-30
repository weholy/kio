import Foundation
import UIKit
import AsyncDisplayKit
import SGLiquidGlassCore
import SGSimpleSettings

private var sharedIsReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled

public final class NavigationBackgroundNode: ASDisplayNode, SGLiquidGlassContainer {
    private var _color: UIColor

    public var color: UIColor {
        return self._color
    }

    private var enableBlur: Bool
    private var enableSaturation: Bool
    private var customBlurRadius: CGFloat?

    public var effectView: UIVisualEffectView?
    private let backgroundNode: ASDisplayNode

    // nameless: optional Liquid Glass overlay for navigation bars
    // We keep both an `any SGLiquidGlassViewProtocol` (for the glass API) and
    // the same instance as `UIView` (for frame / superview ops) — split
    // because some Swift versions refuse `any P & UIView` existentials.
    private var glassViewProtocol: (any SGLiquidGlassViewProtocol)?
    private var glassView: UIView?
    private var glassRegistered: Bool = false
    /// Set to true to enable the Liquid Glass overlay (defaults to false; the
    /// tab bar / nav bar / chat input panel opt-in explicitly).
    public var enableLiquidGlass: Bool = false {
        didSet {
            self.updateGlass()
        }
    }
    /// Optional tint color for the glass. When nil, the glass uses the
    /// navigation background color.
    public var glassTintColor: UIColor?
    
    public var backgroundView: UIView {
        return self.backgroundNode.view
    }

    private var validLayout: (CGSize, CGFloat)?
    
    public var backgroundCornerRadius: CGFloat {
        if let (_, cornerRadius) = self.validLayout {
            return cornerRadius
        } else {
            return 0.0
        }
    }

    public init(color: UIColor, enableBlur: Bool = true, enableSaturation: Bool = true, customBlurRadius: CGFloat? = nil) {
        self._color = .clear
        self.enableBlur = enableBlur
        self.enableSaturation = enableSaturation
        self.customBlurRadius = customBlurRadius

        self.backgroundNode = ASDisplayNode()

        super.init()

        self.addSubnode(self.backgroundNode)

        self.updateColor(color: color, transition: .immediate)
    }

    deinit {
        if let v = self.glassViewProtocol, self.glassRegistered {
            SGLiquidGlassCoordinator.shared.unregister(node: v)
        }
    }

    // MARK: nameless Liquid Glass

    private func updateGlass() {
        let shouldHave = self.enableLiquidGlass && SGLiquidGlassZone.navigationBar.isEnabled
        if shouldHave {
            // Official Apple liquid glass only — kill solid fill + legacy gaussian blur
            self.backgroundNode.backgroundColor = .clear
            if let effectView = self.effectView {
                effectView.isHidden = true
            }
            if self.glassView == nil {
                guard let proto = SGLiquidGlassFactory.shared.create?() else {
                    return
                }
                guard let v = proto as? UIView else {
                    return
                }
                // Official path: no solid tint wash — GlassBackgroundView handles UIGlassEffect
                proto.tintColorGlass = self.glassTintColor ?? .clear
                proto.cornerRadii = GlassRadii(radius: self.validLayout?.1 ?? 0)
                self.view.addSubview(v)
                self.glassView = v
                self.glassViewProtocol = proto
                if let (size, cornerRadius) = self.validLayout {
                    v.frame = CGRect(origin: .zero, size: size)
                    proto.cornerRadii = GlassRadii(radius: cornerRadius)
                }
                if !self.glassRegistered {
                    self.glassRegistered = true
                    SGLiquidGlassCoordinator.shared.register(node: proto, zone: .navigationBar)
                }
                proto.refreshGlass(zone: .navigationBar)
            } else {
                self.glassViewProtocol?.tintColorGlass = self.glassTintColor ?? .clear
                self.glassViewProtocol?.refreshGlass(zone: .navigationBar)
            }
        } else if let v = self.glassView {
            v.removeFromSuperview()
            if let proto = self.glassViewProtocol, self.glassRegistered {
                SGLiquidGlassCoordinator.shared.unregister(node: proto)
                self.glassRegistered = false
            }
            self.glassView = nil
            self.glassViewProtocol = nil
            self.effectView?.isHidden = false
        }
    }

    public func refreshGlass(zone: SGLiquidGlassZone) {
        self.updateGlass()
    }

    
    public override func didLoad() {
        super.didLoad()
        
        if self.scheduledUpdate {
            self.scheduledUpdate = false
            self.updateBackgroundBlur(forceKeepBlur: false)
        }
    }
    
    private var scheduledUpdate = false
    
    private func updateBackgroundBlur(forceKeepBlur: Bool) {
        guard self.isNodeLoaded else {
            self.scheduledUpdate = true
            return
        }
        // When official liquid glass is active — never stack custom gaussian blur
        let glassActive = self.enableLiquidGlass && SGLiquidGlassZone.navigationBar.isEnabled
        if glassActive {
            if let effectView = self.effectView {
                self.effectView = nil
                effectView.removeFromSuperview()
            }
            return
        }
        if self.enableBlur && !sharedIsReduceTransparencyEnabled && ((self._color.alpha > .ulpOfOne && self._color.alpha < 0.95) || forceKeepBlur) {
            if self.effectView == nil {
                // Prefer official UIGlassEffect over stripped UIBlurEffect/gaussian
                let effectView = makeOfficialLiquidGlassEffectView(isDark: true, interactive: false)

                if let (size, cornerRadius) = self.validLayout {
                    effectView.frame = CGRect(origin: CGPoint(), size: size)
                    ContainedViewLayoutTransition.immediate.updateCornerRadius(layer: effectView.layer, cornerRadius: cornerRadius)
                    effectView.clipsToBounds = !cornerRadius.isZero
                }
                self.effectView = effectView
                self.view.insertSubview(effectView, at: 0)
            }
        } else if let effectView = self.effectView {
            self.effectView = nil
            effectView.removeFromSuperview()
        }
    }

    public func updateColor(color: UIColor, enableBlur: Bool? = nil, enableSaturation: Bool? = nil, forceKeepBlur: Bool = false, transition: ContainedViewLayoutTransition) {
        let effectiveEnableBlur = enableBlur ?? self.enableBlur
        let effectiveEnableSaturation = enableSaturation ?? self.enableSaturation

        if self._color.isEqual(color) && self.enableBlur == effectiveEnableBlur && self.enableSaturation == effectiveEnableSaturation {
            return
        }
        self._color = color
        self.enableBlur = effectiveEnableBlur
        self.enableSaturation = effectiveEnableSaturation

        // When liquid glass is on, never paint solid gray — glass is the only surface
        let glassActive = self.enableLiquidGlass && SGLiquidGlassZone.navigationBar.isEnabled
        if glassActive {
            transition.updateBackgroundColor(node: self.backgroundNode, color: .clear)
        } else if sharedIsReduceTransparencyEnabled {
            transition.updateBackgroundColor(node: self.backgroundNode, color: self._color.withAlphaComponent(1.0))
        } else {
            transition.updateBackgroundColor(node: self.backgroundNode, color: self._color)
        }

        self.updateBackgroundBlur(forceKeepBlur: forceKeepBlur)
        // nameless: clear glass tint (no gray wash from theme background color)
        if let v = self.glassViewProtocol {
            v.tintColorGlass = self.glassTintColor ?? .clear
        }
        self.updateGlass()
    }

    public func update(size: CGSize, cornerRadius: CGFloat = 0.0, transition: ContainedViewLayoutTransition, beginWithCurrentState: Bool = true) {
        self.validLayout = (size, cornerRadius)

        let contentFrame = CGRect(origin: CGPoint(), size: size)
        transition.updateFrame(node: self.backgroundNode, frame: contentFrame, beginWithCurrentState: true)
        if let effectView = self.effectView, effectView.frame != contentFrame {
            transition.updateFrame(layer: effectView.layer, frame: contentFrame, beginWithCurrentState: true)
            if let sublayers = effectView.layer.sublayers {
                for sublayer in sublayers {
                    transition.updateFrame(layer: sublayer, frame: contentFrame, beginWithCurrentState: true)
                }
            }
        }
        // nameless: sync Liquid Glass frame
        if let v = self.glassView, let proto = self.glassViewProtocol {
            transition.updateFrame(view: v, frame: contentFrame)
            proto.cornerRadii = GlassRadii(radius: cornerRadius)
        }

        transition.updateCornerRadius(node: self.backgroundNode, cornerRadius: cornerRadius)
        if let effectView = self.effectView {
            transition.updateCornerRadius(layer: effectView.layer, cornerRadius: cornerRadius)
            effectView.clipsToBounds = !cornerRadius.isZero
        }
    }

    public func update(size: CGSize, cornerRadius: CGFloat = 0.0, animator: ControlledTransitionAnimator) {
        self.validLayout = (size, cornerRadius)

        let contentFrame = CGRect(origin: CGPoint(), size: size)
        animator.updateFrame(layer: self.backgroundNode.layer, frame: contentFrame, completion: nil)
        if let effectView = self.effectView, effectView.frame != contentFrame {
            animator.updateFrame(layer: effectView.layer, frame: contentFrame, completion: nil)
            if let sublayers = effectView.layer.sublayers {
                for sublayer in sublayers {
                    animator.updateFrame(layer: sublayer, frame: contentFrame, completion: nil)
                }
            }
        }
        // nameless: sync Liquid Glass frame
        if let v = self.glassView, let proto = self.glassViewProtocol {
            animator.updateFrame(layer: v.layer, frame: contentFrame, completion: nil)
            proto.cornerRadii = GlassRadii(radius: cornerRadius)
        }

        animator.updateCornerRadius(layer: self.backgroundNode.layer, cornerRadius: cornerRadius, completion: nil)
        if let effectView = self.effectView {
            animator.updateCornerRadius(layer: effectView.layer, cornerRadius: cornerRadius, completion: nil)
            effectView.clipsToBounds = !cornerRadius.isZero
        }
    }
}

open class BlurredBackgroundView: UIView {
    private var _color: UIColor?

    private var enableBlur: Bool
    private var customBlurRadius: CGFloat?

    public private(set) var effectView: UIVisualEffectView?
    private let backgroundView: UIView

    private var validLayout: (CGSize, CGFloat)?
    
    public var backgroundCornerRadius: CGFloat {
        if let (_, cornerRadius) = self.validLayout {
            return cornerRadius
        } else {
            return 0.0
        }
    }

    public init(color: UIColor?, enableBlur: Bool = true, customBlurRadius: CGFloat? = nil) {
        self._color = nil
        self.enableBlur = enableBlur
        self.customBlurRadius = customBlurRadius

        self.backgroundView = UIView()

        super.init(frame: CGRect())

        self.addSubview(self.backgroundView)

        if let color = color {
            self.updateColor(color: color, transition: .immediate)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateBackgroundBlur(forceKeepBlur: Bool) {
        if let color = self._color, self.enableBlur && !sharedIsReduceTransparencyEnabled && ((color.alpha > .ulpOfOne && color.alpha < 0.95) || forceKeepBlur) {
            if self.effectView == nil {
                // Official Apple liquid glass — never stripped gaussianBlur UIBlurEffect
                let effectView = makeOfficialLiquidGlassEffectView(isDark: true, interactive: false)

                if let (size, cornerRadius) = self.validLayout {
                    effectView.frame = CGRect(origin: CGPoint(), size: size)
                    ContainedViewLayoutTransition.immediate.updateCornerRadius(layer: effectView.layer, cornerRadius: cornerRadius)
                    effectView.clipsToBounds = !cornerRadius.isZero
                }
                self.effectView = effectView
                self.insertSubview(effectView, at: 0)
            }
        } else if let effectView = self.effectView {
            self.effectView = nil
            effectView.removeFromSuperview()
        }
    }

    public func updateColor(color: UIColor, enableBlur: Bool? = nil, forceKeepBlur: Bool = false, transition: ContainedViewLayoutTransition) {
        let effectiveEnableBlur = enableBlur ?? self.enableBlur

        if self._color == color && self.enableBlur == effectiveEnableBlur {
            return
        }
        self._color = color
        self.enableBlur = effectiveEnableBlur

        if sharedIsReduceTransparencyEnabled {
            transition.updateBackgroundColor(layer: self.backgroundView.layer, color: color.withAlphaComponent(1.0))
        } else {
            transition.updateBackgroundColor(layer: self.backgroundView.layer, color: color)
        }

        self.updateBackgroundBlur(forceKeepBlur: forceKeepBlur)
    }

    public func update(size: CGSize, cornerRadius: CGFloat = 0.0, maskedCorners: CACornerMask = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner], transition: ContainedViewLayoutTransition) {
        self.validLayout = (size, cornerRadius)

        let contentFrame = CGRect(origin: CGPoint(), size: size)
        transition.updateFrame(view: self.backgroundView, frame: contentFrame, beginWithCurrentState: true)
        if let effectView = self.effectView, effectView.frame != contentFrame {
            transition.updateFrame(layer: effectView.layer, frame: contentFrame, beginWithCurrentState: true)
            if let sublayers = effectView.layer.sublayers {
                for sublayer in sublayers {
                    transition.updateFrame(layer: sublayer, frame: contentFrame, beginWithCurrentState: true)
                }
            }
        }
        
        if #available(iOS 11.0, *) {
            self.backgroundView.layer.maskedCorners = maskedCorners
        }

        transition.updateCornerRadius(layer: self.backgroundView.layer, cornerRadius: cornerRadius)
        if let effectView = self.effectView {
            transition.updateCornerRadius(layer: effectView.layer, cornerRadius: cornerRadius)
            effectView.clipsToBounds = !cornerRadius.isZero
            
            if #available(iOS 11.0, *) {
                effectView.layer.maskedCorners = maskedCorners
            }
        }
    }
    
    public func update(size: CGSize, cornerRadius: CGFloat = 0.0, animator: ControlledTransitionAnimator) {
        self.validLayout = (size, cornerRadius)

        let contentFrame = CGRect(origin: CGPoint(), size: size)
        animator.updateFrame(layer: self.backgroundView.layer, frame: contentFrame, completion: nil)
        if let effectView = self.effectView, effectView.frame != contentFrame {
            animator.updateFrame(layer: effectView.layer, frame: contentFrame, completion: nil)
            if let sublayers = effectView.layer.sublayers {
                for sublayer in sublayers {
                    animator.updateFrame(layer: sublayer, frame: contentFrame, completion: nil)
                }
            }
        }

        animator.updateCornerRadius(layer: self.backgroundView.layer, cornerRadius: cornerRadius, completion: nil)
        if let effectView = self.effectView {
            animator.updateCornerRadius(layer: effectView.layer, cornerRadius: cornerRadius, completion: nil)
            effectView.clipsToBounds = !cornerRadius.isZero
        }
    }
}
