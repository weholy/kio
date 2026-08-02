import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData
import WallpaperBackgroundNode
import SGLiquidGlassCore
import SGSimpleSettings
import GlassBackgroundComponent
import ComponentFlow

public enum ChatMessageBackgroundMergeType: Equatable {
    case None, Side, Top(side: Bool), Bottom, Both, Extracted
    
    public init(top: Bool, bottom: Bool, side: Bool) {
        if top && bottom {
            self = .Both
        } else if top {
            self = .Top(side: side)
        } else if bottom {
            if side {
                self = .Side
            } else {
                self = .Bottom
            }
        } else {
            if side {
                self = .Side
            } else {
                self = .None
            }
        }
    }
}

public enum ChatMessageBackgroundType: Equatable {
    case none
    case incoming(ChatMessageBackgroundMergeType)
    case outgoing(ChatMessageBackgroundMergeType)

    public static func ==(lhs: ChatMessageBackgroundType, rhs: ChatMessageBackgroundType) -> Bool {
        switch lhs {
            case .none:
                if case .none = rhs {
                    return true
                } else {
                    return false
                }
            case let .incoming(mergeType):
                if case .incoming(mergeType) = rhs {
                    return true
                } else {
                    return false
                }
            case let .outgoing(mergeType):
                if case .outgoing(mergeType) = rhs {
                    return true
                } else {
                    return false
                }
        }
    }
}

public class ChatMessageBackground: ASDisplayNode {
    public weak var backdropNode: ChatMessageBubbleBackdrop?
        
    public private(set) var type: ChatMessageBackgroundType?
    private var currentHighlighted: Bool?
    private var hasWallpaper: Bool?
    private var graphics: PrincipalThemeEssentialGraphics?
    private var maskMode: Bool?
    private let outlineImageNode: ASImageNode
    private weak var backgroundNode: WallpaperBackgroundNode?
    
    private var imageFrame: CGRect?
    private var imageView: UIImageView?
    private var imageViewImage: UIImage?
    
    public var customHighlightColor: UIColor? {
        didSet {
            self.imageView?.tintColor = self.customHighlightColor
        }
    }
    
    public var backgroundFrame: CGRect = .zero
    
    public var hasImage: Bool {
        self.imageViewImage != nil
    }
    
    public override init() {
        self.outlineImageNode = ASImageNode()
        self.outlineImageNode.displaysAsynchronously = false
        self.outlineImageNode.displayWithoutProcessing = true
        
        super.init()
                
        self.isUserInteractionEnabled = false
        self.addSubnode(self.outlineImageNode)
    }
    
    override public func didLoad() {
        super.didLoad()
        
        let imageView = UIImageView()
        self.imageView = imageView
        self.view.addSubview(imageView)
        
        imageView.image = self.imageViewImage
        imageView.tintColor = self.customHighlightColor
        
        if let imageFrame = self.imageFrame {
            imageView.frame = imageFrame
        }
    }
    
    public func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        let imageFrame = CGRect(origin: CGPoint(), size: size).insetBy(dx: -1.0, dy: -1.0)
        self.imageFrame = imageFrame
        if let imageView = self.imageView {
            transition.updateFrame(view: imageView, frame: imageFrame)
        }
        transition.updateFrame(node: self.outlineImageNode, frame: CGRect(origin: CGPoint(), size: size).insetBy(dx: -1.0, dy: -1.0))
    }
    
    public func updateLayout(size: CGSize, transition: ListViewItemUpdateAnimation) {
        let imageFrame = CGRect(origin: CGPoint(), size: size).insetBy(dx: -1.0, dy: -1.0)
        self.imageFrame = imageFrame
        if let imageView = self.imageView {
            transition.animator.updateFrame(layer: imageView.layer, frame: imageFrame, completion: nil)
        }
        
        transition.animator.updateFrame(layer: self.outlineImageNode.layer, frame: CGRect(origin: CGPoint(), size: size).insetBy(dx: -1.0, dy: -1.0), completion: nil)
    }
    
    public func setMaskMode(_ maskMode: Bool) {
        if let type = self.type, let hasWallpaper = self.hasWallpaper, let highlighted = self.currentHighlighted, let graphics = self.graphics, let backgroundNode = self.backgroundNode {
            self.setType(type: type, highlighted: highlighted, graphics: graphics, maskMode: maskMode, hasWallpaper: hasWallpaper, transition: .immediate, backgroundNode: backgroundNode)
        }
    }
    
    public func currentCorners(bubbleCorners: PresentationChatBubbleCorners) -> (topLeftRadius: CGFloat, topRightRadius: CGFloat, bottomLeftRadius: CGFloat, bottomRightRadius: CGFloat, drawTail: Bool)? {
        guard let type = self.type else {
            return nil
        }
        
        let maxRadius = bubbleCorners.mainRadius
        let minRadius = bubbleCorners.auxiliaryRadius
        
        switch type {
        case .none:
            return nil
        case let .incoming(mergeType):
            switch mergeType {
            case .None:
                return messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: true, neighbors: .none)
            case let .Top(side):
                return messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: true, neighbors: .top(side: side))
            case .Bottom:
                return messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: true, neighbors: .bottom)
            case .Both:
                return messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: true, neighbors: .both)
            case .Side:
                return messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: true, neighbors: .side)
            case .Extracted:
                return messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: true, neighbors: .extracted)
            }
        case let .outgoing(mergeType):
            switch mergeType {
            case .None:
                return messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: false, neighbors: .none)
            case let .Top(side):
                return messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: false, neighbors: .top(side: side))
            case .Bottom:
                return messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: false, neighbors: .bottom)
            case .Both:
                return messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: false, neighbors: .both)
            case .Side:
                return messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: false, neighbors: .side)
            case .Extracted:
                return messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: false, neighbors: .extracted)
            }
        }
    }
    
    public func setType(type: ChatMessageBackgroundType, highlighted: Bool, graphics: PrincipalThemeEssentialGraphics, maskMode: Bool, hasWallpaper: Bool, transition: ContainedViewLayoutTransition, backgroundNode: WallpaperBackgroundNode?) {
        let previousType = self.type
        if let currentType = previousType, currentType == type, self.currentHighlighted == highlighted, self.graphics === graphics, backgroundNode === self.backgroundNode, self.maskMode == maskMode, self.hasWallpaper == hasWallpaper {
            return
        }
        self.type = type
        self.currentHighlighted = highlighted
        self.graphics = graphics
        self.backgroundNode = backgroundNode
        self.hasWallpaper = hasWallpaper
        
        var image: UIImage?

        // Official liquid glass bubbles: no solid fill image — glass backdrop is the surface
        let glassMessagesOn: Bool = {
            switch type {
            case .outgoing: return SGLiquidGlassZone.outgoingMessages.isEnabled
            case .incoming: return SGLiquidGlassZone.messages.isEnabled
            case .none: return false
            }
        }()
        
        switch type {
        case .none:
            image = nil
        case let .incoming(mergeType):
            if glassMessagesOn || (maskMode && backgroundNode?.hasBubbleBackground(for: .incoming) == true && !highlighted) {
                image = nil
            } else {
                switch mergeType {
                case .None:
                    image = highlighted ? graphics.chatMessageBackgroundIncomingHighlightedImage : graphics.chatMessageBackgroundIncomingImage
                case let .Top(side):
                    if side {
                        image = highlighted ? graphics.chatMessageBackgroundIncomingMergedTopSideHighlightedImage : graphics.chatMessageBackgroundIncomingMergedTopSideImage
                    } else {
                        image = highlighted ? graphics.chatMessageBackgroundIncomingMergedTopHighlightedImage : graphics.chatMessageBackgroundIncomingMergedTopImage
                    }
                case .Bottom:
                    image = highlighted ? graphics.chatMessageBackgroundIncomingMergedBottomHighlightedImage : graphics.chatMessageBackgroundIncomingMergedBottomImage
                case .Both:
                    image = highlighted ? graphics.chatMessageBackgroundIncomingMergedBothHighlightedImage : graphics.chatMessageBackgroundIncomingMergedBothImage
                case .Side:
                    image = highlighted ? graphics.chatMessageBackgroundIncomingMergedSideHighlightedImage : graphics.chatMessageBackgroundIncomingMergedSideImage
                case .Extracted:
                    image = graphics.chatMessageBackgroundIncomingExtractedImage
                }
            }
        case let .outgoing(mergeType):
            if glassMessagesOn || (maskMode && backgroundNode?.hasBubbleBackground(for: .outgoing) == true && !highlighted) {
                image = nil
            } else {
                switch mergeType {
                case .None:
                    image = highlighted ? graphics.chatMessageBackgroundOutgoingHighlightedImage : graphics.chatMessageBackgroundOutgoingImage
                case let .Top(side):
                    if side {
                        image = highlighted ? graphics.chatMessageBackgroundOutgoingMergedTopSideHighlightedImage : graphics.chatMessageBackgroundOutgoingMergedTopSideImage
                    } else {
                        image = highlighted ? graphics.chatMessageBackgroundOutgoingMergedTopHighlightedImage : graphics.chatMessageBackgroundOutgoingMergedTopImage
                    }
                case .Bottom:
                    image = highlighted ? graphics.chatMessageBackgroundOutgoingMergedBottomHighlightedImage : graphics.chatMessageBackgroundOutgoingMergedBottomImage
                case .Both:
                    image = highlighted ? graphics.chatMessageBackgroundOutgoingMergedBothHighlightedImage : graphics.chatMessageBackgroundOutgoingMergedBothImage
                case .Side:
                    image = highlighted ? graphics.chatMessageBackgroundOutgoingMergedSideHighlightedImage : graphics.chatMessageBackgroundOutgoingMergedSideImage
                case .Extracted:
                    image = graphics.chatMessageBackgroundOutgoingExtractedImage
                }
            }
        }
        
        // No solid outline when official liquid glass is the bubble surface
        let outlineImage: UIImage?
        if glassMessagesOn {
            outlineImage = nil
        } else if hasWallpaper {
            switch type {
            case .none:
                outlineImage = nil
            case let .incoming(mergeType):
                switch mergeType {
                case .None:
                    outlineImage = graphics.chatMessageBackgroundIncomingOutlineImage
                case let .Top(side):
                    if side {
                        outlineImage = graphics.chatMessageBackgroundIncomingMergedTopSideOutlineImage
                    } else {
                        outlineImage = graphics.chatMessageBackgroundIncomingMergedTopOutlineImage
                    }
                case .Bottom:
                    outlineImage = graphics.chatMessageBackgroundIncomingMergedBottomOutlineImage
                case .Both:
                    outlineImage = graphics.chatMessageBackgroundIncomingMergedBothOutlineImage
                case .Side:
                    outlineImage = graphics.chatMessageBackgroundIncomingMergedSideOutlineImage
                case .Extracted:
                    outlineImage = graphics.chatMessageBackgroundIncomingExtractedOutlineImage
                }
            case let .outgoing(mergeType):
                switch mergeType {
                case .None:
                    outlineImage = graphics.chatMessageBackgroundOutgoingOutlineImage
                case let .Top(side):
                    if side {
                        outlineImage = graphics.chatMessageBackgroundOutgoingMergedTopSideOutlineImage
                    } else {
                        outlineImage = graphics.chatMessageBackgroundOutgoingMergedTopOutlineImage
                    }
                case .Bottom:
                    outlineImage = graphics.chatMessageBackgroundOutgoingMergedBottomOutlineImage
                case .Both:
                    outlineImage = graphics.chatMessageBackgroundOutgoingMergedBothOutlineImage
                case .Side:
                    outlineImage = graphics.chatMessageBackgroundOutgoingMergedSideOutlineImage
                case .Extracted:
                    outlineImage = graphics.chatMessageBackgroundOutgoingExtractedOutlineImage
                }
            }
        } else {
            outlineImage = nil
        }
        
        if let previousType = previousType, previousType != .none, type == .none {
            if transition.isAnimated, let imageView = self.imageView {
                let tempLayer = CALayer()
                tempLayer.contents = imageView.layer.contents
                tempLayer.contentsScale = imageView.layer.contentsScale
                tempLayer.rasterizationScale = imageView.layer.rasterizationScale
                tempLayer.contentsGravity = imageView.layer.contentsGravity
                tempLayer.contentsCenter = imageView.layer.contentsCenter
                
                tempLayer.frame = imageView.frame
                self.layer.insertSublayer(tempLayer, above: imageView.layer)
                transition.updateAlpha(layer: tempLayer, alpha: 0.0, completion: { [weak tempLayer] _ in
                    tempLayer?.removeFromSuperlayer()
                })
            }
        } else if transition.isAnimated, let imageView = self.imageView {
            if let previousContents = imageView.layer.contents {
                if let image = image {
                    if (previousContents as AnyObject) !== image.cgImage {
                        imageView.layer.animate(from: previousContents as AnyObject, to: image.cgImage! as AnyObject, keyPath: "contents", timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, duration: 0.42)
                    }
                } else {
                    let tempLayer = CALayer()
                    tempLayer.contents = imageView.layer.contents
                    tempLayer.contentsScale = imageView.layer.contentsScale
                    tempLayer.rasterizationScale = imageView.layer.rasterizationScale
                    tempLayer.contentsGravity = imageView.layer.contentsGravity
                    tempLayer.contentsCenter = imageView.layer.contentsCenter
                    tempLayer.compositingFilter = imageView.layer.compositingFilter
                    
                    tempLayer.frame = imageView.frame
                    
                    imageView.superview?.layer.insertSublayer(tempLayer, above: imageView.layer)
                    transition.updateAlpha(layer: tempLayer, alpha: 0.0, completion: { [weak tempLayer] _ in
                        tempLayer?.removeFromSuperlayer()
                    })
                }
            }
        }
        
        self.imageViewImage = image
        if let imageView = self.imageView {
            imageView.image = image
        }
        
        self.outlineImageNode.image = outlineImage
    }

    public func animateFrom(sourceView: UIView, transition: CombinedTransition) {
        if transition.isAnimated {
            self.imageView?.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.1)
            self.outlineImageNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.1)
            
            let sourceViewFrame = sourceView.frame

            self.view.addSubview(sourceView)

            sourceView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false, completion: { [weak sourceView] _ in
                sourceView?.removeFromSuperview()
            })

            if let imageView = self.imageView {
                transition.animateFrame(layer: imageView.layer, from: sourceView.frame)
                transition.updateFrame(layer: sourceView.layer, frame: CGRect(origin: imageView.frame.origin, size: CGSize(width: imageView.frame.width - 7.0, height: imageView.frame.height)))
            }
            transition.animateFrame(layer: self.outlineImageNode.layer, from: sourceViewFrame)
        }
    }
}

public final class ChatMessageShadowNode: ASDisplayNode {
    private let contentNode: ASImageNode
    private var graphics: PrincipalThemeEssentialGraphics?
    
    public override init() {
        self.contentNode = ASImageNode()
        self.contentNode.isLayerBacked = true
        self.contentNode.displaysAsynchronously = false
        self.contentNode.displayWithoutProcessing = true
        
        super.init()
        
        self.transform = CATransform3DMakeRotation(CGFloat.pi, 0.0, 0.0, 1.0)
        
        self.isLayerBacked = true
        
        self.addSubnode(self.contentNode)
    }
    
    public func setType(type: ChatMessageBackgroundType, hasWallpaper: Bool, graphics: PrincipalThemeEssentialGraphics) {
        let shadowImage: UIImage?
        
        if hasWallpaper {
            switch type {
            case .none:
                shadowImage = nil
            case let .incoming(mergeType):
                switch mergeType {
                case .None:
                    shadowImage = graphics.chatMessageBackgroundIncomingShadowImage
                case let .Top(side):
                    if side {
                        shadowImage = graphics.chatMessageBackgroundIncomingMergedTopSideShadowImage
                    } else {
                        shadowImage = graphics.chatMessageBackgroundIncomingMergedTopShadowImage
                    }
                case .Bottom:
                    shadowImage = graphics.chatMessageBackgroundIncomingMergedBottomShadowImage
                case .Both:
                    shadowImage = graphics.chatMessageBackgroundIncomingMergedBothShadowImage
                case .Side:
                    shadowImage = graphics.chatMessageBackgroundIncomingMergedSideShadowImage
                case .Extracted:
                    shadowImage = nil
                }
            case let .outgoing(mergeType):
                switch mergeType {
                case .None:
                    shadowImage = graphics.chatMessageBackgroundOutgoingShadowImage
                case let .Top(side):
                    if side {
                        shadowImage = graphics.chatMessageBackgroundOutgoingMergedTopSideShadowImage
                    } else {
                        shadowImage = graphics.chatMessageBackgroundOutgoingMergedTopShadowImage
                    }
                case .Bottom:
                    shadowImage = graphics.chatMessageBackgroundOutgoingMergedBottomShadowImage
                case .Both:
                    shadowImage = graphics.chatMessageBackgroundOutgoingMergedBothShadowImage
                case .Side:
                    shadowImage = graphics.chatMessageBackgroundOutgoingMergedSideShadowImage
                case .Extracted:
                    shadowImage = nil
                }
            }
        } else {
            shadowImage = nil
        }
        
        self.contentNode.image = shadowImage
    }
    
    public func updateLayout(backgroundFrame: CGRect, animator: ControlledTransitionAnimator) {
        animator.updateFrame(layer: self.contentNode.layer, frame: CGRect(origin: CGPoint(x: backgroundFrame.minX - 10.0, y: backgroundFrame.minY - 10.0), size: CGSize(width: backgroundFrame.width + 20.0, height: backgroundFrame.height + 20.0)), completion: nil)
    }
    
    public func updateLayout(backgroundFrame: CGRect, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(layer: self.contentNode.layer, frame: CGRect(origin: CGPoint(x: backgroundFrame.minX - 10.0, y: backgroundFrame.minY - 10.0), size: CGSize(width: backgroundFrame.width + 20.0, height: backgroundFrame.height + 20.0)), completion: nil)
    }
}


private let maskInset: CGFloat = 1.0

public func bubbleMaskForType(_ type: ChatMessageBackgroundType, graphics: PrincipalThemeEssentialGraphics) -> UIImage? {
    let image: UIImage?
    switch type {
    case .none:
        image = nil
    case let .incoming(mergeType):
        switch mergeType {
        case .None:
            image = graphics.chatMessageBackgroundIncomingMaskImage
        case let .Top(side):
            if side {
                image = graphics.chatMessageBackgroundIncomingMergedTopSideMaskImage
            } else {
                image = graphics.chatMessageBackgroundIncomingMergedTopMaskImage
            }
        case .Bottom:
            image = graphics.chatMessageBackgroundIncomingMergedBottomMaskImage
        case .Both:
            image = graphics.chatMessageBackgroundIncomingMergedBothMaskImage
        case .Side:
            image = graphics.chatMessageBackgroundIncomingMergedSideMaskImage
        case .Extracted:
            image = graphics.chatMessageBackgroundIncomingExtractedMaskImage
        }
    case let .outgoing(mergeType):
        switch mergeType {
        case .None:
            image = graphics.chatMessageBackgroundOutgoingMaskImage
        case let .Top(side):
            if side {
                image = graphics.chatMessageBackgroundOutgoingMergedTopSideMaskImage
            } else {
                image = graphics.chatMessageBackgroundOutgoingMergedTopMaskImage
            }
        case .Bottom:
            image = graphics.chatMessageBackgroundOutgoingMergedBottomMaskImage
        case .Both:
            image = graphics.chatMessageBackgroundOutgoingMergedBothMaskImage
        case .Side:
            image = graphics.chatMessageBackgroundOutgoingMergedSideMaskImage
        case .Extracted:
            image = graphics.chatMessageBackgroundOutgoingExtractedMaskImage
        }
    }
    return image
}

public final class ChatMessageBubbleBackdrop: ASDisplayNode, SGLiquidGlassContainer {
    public private(set) var backgroundContent: WallpaperBubbleBackgroundNode?

    private var currentType: ChatMessageBackgroundType?
    private var currentMaskMode: Bool?
    private var theme: ChatPresentationThemeData?
    private var essentialGraphics: PrincipalThemeEssentialGraphics?
    private weak var backgroundNode: WallpaperBackgroundNode?

    public var maskView: UIImageView?
    private var fixedMaskMode: Bool?

    private var absolutePosition: (CGRect, CGSize)?

    // MARK: nameless Liquid Glass
    /// Liquid glass surface layered above the wallpaper background but below
    /// the bubble mask image. When `nameless.liquidGlass.messages` is enabled
    /// this gives every chat bubble the iOS 26 Liquid Glass look.
    private var glassView: GlassBackgroundView?
    /// What was last pushed into `glassView`. Every apply pass of every visible bubble calls
    /// `setType`, and during a scroll that is dozens of calls per frame — rebuilding an identical
    /// glass surface each time is the difference between a smooth flick and a stuttering one.
    private var appliedGlassState: (size: CGSize, radii: GlassBackgroundView.CornerRadii, isDark: Bool, tint: GlassBackgroundView.TintColor)?
    private var currentBubbleColor: UIColor = .clear
    private var currentGlassRadii: GlassBackgroundView.CornerRadii = .init(radius: 0)
    /// Lazily-created frost layer for the "Размытие сообщений" option. Kept separate from
    /// `glassView` because that one is the Liquid Glass surface and is mutually exclusive
    /// with the classic (non-glass) bubble rendering path.
    private var namelessBlurView: UIVisualEffectView?
    
    public var overrideMask: Bool = false {
        didSet {
            self.maskView?.image = nil
        }
    }
    
    public var hasImage: Bool {
        return self.backgroundContent != nil
    }
    
    public override var frame: CGRect {
        didSet {
            if let maskView = self.maskView {
                let maskFrame = self.bounds.insetBy(dx: -maskInset, dy: -maskInset)
                if maskView.frame != maskFrame {
                    maskView.frame = maskFrame
                }
            }
            // nameless: keep glass in sync
            if let glassView = self.glassView, glassView.frame != self.bounds {
                glassView.frame = self.bounds
            }
            if let namelessBlurView = self.namelessBlurView, namelessBlurView.frame != self.bounds {
                namelessBlurView.frame = self.bounds
            }
            if let backgroundContent = self.backgroundContent {
                backgroundContent.frame = self.bounds
                if let (rect, containerSize) = self.absolutePosition {
                    var backgroundFrame = backgroundContent.frame
                    backgroundFrame.origin.x += rect.minX
                    backgroundFrame.origin.y += rect.minY
                    backgroundContent.update(rect: backgroundFrame, within: containerSize, transition: .immediate)
                }
            }
        }
    }
    
    public override init() {
        super.init()

        self.clipsToBounds = true
    }

    /// Creates the glass surface the first time a bubble actually shows one.
    ///
    /// A `GlassBackgroundView` is a `UIVisualEffectView` plus its mask stack — far too expensive
    /// to allocate for every bubble the history recycles, most of which are off-screen or drawn
    /// with a flat fill. Building it on demand keeps that cost proportional to the bubbles that
    /// really are glass.
    private func ensureGlassView() -> GlassBackgroundView {
        if let glassView = self.glassView {
            return glassView
        }
        let glassView = GlassBackgroundView()
        glassView.isUserInteractionEnabled = false
        glassView.frame = self.bounds
        self.glassView = glassView
        self.view.insertSubview(glassView, at: 0)
        return glassView
    }

    /// MARK: Nameless — installs/removes the frost layer behind the bubble content.
    /// The node already clips to its bubble shape, so the blur inherits the correct outline
    /// without needing its own mask.
    private func updateNamelessBlurEffect(isEnabled: Bool) {
        if isEnabled {
            let blurView: UIVisualEffectView
            if let current = self.namelessBlurView {
                blurView = current
            } else {
                blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
                blurView.isUserInteractionEnabled = false
                self.namelessBlurView = blurView
                // Above the wallpaper-sampled fill, below the bubble's own content. Glass and
                // blur are mutually exclusive, so when glass was never built the blur simply goes
                // to the bottom.
                if let glassView = self.glassView {
                    self.view.insertSubview(blurView, aboveSubview: glassView)
                } else {
                    self.view.insertSubview(blurView, at: 0)
                }
            }
            blurView.frame = self.bounds
            blurView.isHidden = false
        } else if let blurView = self.namelessBlurView {
            self.namelessBlurView = nil
            blurView.removeFromSuperview()
        }
    }

    private func updateGlass(size: CGSize, isDark: Bool, zone: SGLiquidGlassZone, transition: ComponentTransition = .immediate) {
        let enabled = zone.isEnabled && size.width > 0.5 && size.height > 0.5
        // Official Apple liquid glass ONLY:
        // message bubbles use clear-style glass, not panel glass. This keeps the iOS 26
        // refraction/specular material while avoiding a grey/colored solid fill over chats.
        GlassBackgroundView.useCustomGlassImpl = false
        // The bubble tint is not decoration. Once the solid fill is gone it is the only thing
        // that still distinguishes an outgoing message from an incoming one, so it is applied
        // regardless of the global "tint glass surfaces" preference — that flag only decides
        // how far it is pushed. A plain untinted `.clear` bubble made both sides of the
        // conversation render as the same colourless lens over the wallpaper.
        // Pure glass: no tint at all, so the bubble is the material and nothing else. The cost is
        // that incoming and outgoing look identical apart from which side they sit on — which is
        // exactly what the switch is for.
        let tint: GlassBackgroundView.TintColor
        if SGSimpleSettings.shared.megramPureClearBubbles {
            tint = .init(kind: .clear)
        } else if self.currentBubbleColor != .clear {
            // MARK: Megram — halved from 0.18/0.15/0.12/0.10. The tint was
            // dense enough to read as a coloured fill rather than glass, and
            // the chat wallpaper barely came through it.
            let alpha: CGFloat = zone.isTinted ? (isDark ? 0.09 : 0.08) : (isDark ? 0.06 : 0.05)
            tint = .init(kind: .custom(style: .clear, color: self.currentBubbleColor.withAlphaComponent(alpha)))
        } else {
            // No bubble colour to lean on (custom wallpaper themes): the faintest neutral wash,
            // just enough to give the glass an edge to read against.
            tint = .init(kind: .custom(style: .clear, color: UIColor(white: 1.0, alpha: isDark ? 0.04 : 0.06)))
        }
        if enabled {
            let state = (size: size, radii: self.currentGlassRadii, isDark: isDark, tint: tint)
            let glassView = self.ensureGlassView()
            if glassView.superview !== self.view {
                self.view.insertSubview(glassView, at: 0)
            }
            glassView.frame = CGRect(origin: .zero, size: size)
            // Rebuilding the effect is what costs; pushing an identical state is pure waste, and
            // `setType` runs for every visible bubble on every apply pass.
            if let applied = self.appliedGlassState,
               applied.size == state.size,
               applied.radii == state.radii,
               applied.isDark == state.isDark,
               applied.tint == state.tint {
            } else {
                self.appliedGlassState = state
                glassView.update(size: size, cornerRadii: self.currentGlassRadii, isDark: isDark, tintColor: tint, isInteractive: false, isVisible: true, transition: transition)
            }
            glassView.isHidden = false
            glassView.alpha = 1.0
            // Kill solid wallpaper-sampled fill — glass is the bubble surface
            self.backgroundContent?.isHidden = true
            self.backgroundContent?.alpha = 0.0
            // Liquid Glass already frosts the backdrop; a second blur would just muddy it.
            self.updateNamelessBlurEffect(isEnabled: false)
        } else {
            self.appliedGlassState = nil
            self.glassView?.isHidden = true
            self.backgroundContent?.isHidden = false
            var alpha: CGFloat = 1.0
            if SGSimpleSettings.shared.messageTransparent {
                alpha = 0.35
            } else if SGSimpleSettings.shared.messageSemiTransparent {
                alpha = 0.65
            }
            self.backgroundContent?.alpha = alpha
            // MARK: Nameless — "Размытие сообщений": frost the bubble so the wallpaper behind
            // it is blurred rather than merely shown through. Only meaningful when the bubble
            // is not fully opaque, which is why it composes with the transparency options above.
            self.updateNamelessBlurEffect(isEnabled: SGSimpleSettings.shared.messageBlurEffect)
            if SGSimpleSettings.shared.messageOutline {
                self.view.layer.borderWidth = UIScreen.main.scale > 0 ? (1.0 / UIScreen.main.scale) * 2.0 : 1.0
                self.view.layer.borderColor = (isDark ? UIColor.white : UIColor.black).withAlphaComponent(0.22).cgColor
            } else {
                self.view.layer.borderWidth = 0.0
                self.view.layer.borderColor = nil
            }
        }
    }

    private func glassCorners() -> (topLeftRadius: CGFloat, topRightRadius: CGFloat, bottomLeftRadius: CGFloat, bottomRightRadius: CGFloat)? {
        guard let type = self.currentType else {
            return nil
        }
        let maxRadius = CGFloat(18.0)
        let minRadius = CGFloat(6.0)
        let incoming: Bool
        let mergeType: ChatMessageBackgroundMergeType
        switch type {
        case .none:
            return nil
        case let .incoming(value):
            incoming = true
            mergeType = value
        case let .outgoing(value):
            incoming = false
            mergeType = value
        }
        let arguments: (topLeftRadius: CGFloat, topRightRadius: CGFloat, bottomLeftRadius: CGFloat, bottomRightRadius: CGFloat, drawTail: Bool)
        switch mergeType {
        case .None:
            arguments = messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: incoming, neighbors: .none)
        case let .Top(side):
            arguments = messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: incoming, neighbors: .top(side: side))
        case .Bottom:
            arguments = messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: incoming, neighbors: .bottom)
        case .Both:
            arguments = messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: incoming, neighbors: .both)
        case .Side:
            arguments = messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: incoming, neighbors: .side)
        case .Extracted:
            arguments = messageBubbleArguments(maxCornerRadius: maxRadius, minCornerRadius: minRadius, incoming: incoming, neighbors: .extracted)
        }
        return (arguments.topLeftRadius, arguments.topRightRadius, arguments.bottomLeftRadius, arguments.bottomRightRadius)
    }

    private func updateGlassRadii(_ corners: (topLeftRadius: CGFloat, topRightRadius: CGFloat, bottomLeftRadius: CGFloat, bottomRightRadius: CGFloat)?) {
        if let corners {
            self.currentGlassRadii = .init(topLeft: corners.topLeftRadius, topRight: corners.topRightRadius, bottomLeft: corners.bottomLeftRadius, bottomRight: corners.bottomRightRadius)
        } else {
            self.currentGlassRadii = .init(radius: 0)
        }
    }

    public func refreshGlass(zone: SGLiquidGlassZone) {
        // A settings change is exactly the case the memo must not swallow.
        self.appliedGlassState = nil
        self.updateGlass(size: self.bounds.size, isDark: self.theme?.theme.overallDarkAppearance ?? false, zone: zone)
    }
    
    public func setMaskMode(_ maskMode: Bool) {
        if let currentType = self.currentType, let theme = self.theme, let essentialGraphics = self.essentialGraphics, let backgroundNode = self.backgroundNode {
            self.setType(type: currentType, theme: theme, essentialGraphics: essentialGraphics, maskMode: maskMode, backgroundNode: backgroundNode)
        }
    }
        
    public func setType(type: ChatMessageBackgroundType, theme: ChatPresentationThemeData, essentialGraphics: PrincipalThemeEssentialGraphics, maskMode inputMaskMode: Bool, backgroundNode: WallpaperBackgroundNode?) {
        let maskMode = self.fixedMaskMode ?? inputMaskMode

        let glassZone: SGLiquidGlassZone
        switch type {
        case .outgoing: glassZone = .outgoingMessages
        default:        glassZone = .messages
        }

        // nameless: pick a bubble color for tinting
        let bubbleColor: UIColor
        switch type {
        case .none:
            bubbleColor = .clear
        case .incoming:
            bubbleColor = theme.theme.chat.message.incoming.bubble.withWallpaper.fill.first ?? .clear
        case .outgoing:
            bubbleColor = theme.theme.chat.message.outgoing.bubble.withWallpaper.fill.first ?? .clear
        }
        self.currentBubbleColor = bubbleColor
        let typeUpdated = self.currentType != type || self.theme != theme || self.currentMaskMode != maskMode || self.backgroundNode !== backgroundNode
        self.currentType = type
        self.theme = theme
        self.essentialGraphics = essentialGraphics
        self.backgroundNode = backgroundNode
        self.updateGlassRadii(self.glassCorners())
        self.updateGlass(size: self.bounds.size, isDark: theme.theme.overallDarkAppearance, zone: glassZone)

        if typeUpdated || self.essentialGraphics !== essentialGraphics {
            let typeUpdated = self.currentType != type || self.theme != theme || self.currentMaskMode != maskMode || self.backgroundNode !== backgroundNode

            if maskMode != self.currentMaskMode {
                self.currentMaskMode = maskMode
                
                if maskMode {
                    let maskView: UIImageView
                    if let current = self.maskView {
                        maskView = current
                    } else {
                        maskView = UIImageView()
                        maskView.frame = self.bounds.insetBy(dx: -maskInset, dy: -maskInset)
                        self.maskView = maskView
                        self.view.mask = maskView
                    }
                } else {
                    if let _ = self.maskView {
                        self.view.mask = nil
                        self.maskView = nil
                    }
                }
            }

            if let backgroundContent = self.backgroundContent {
                backgroundContent.frame = self.bounds
                if let (rect, containerSize) = self.absolutePosition {
                    var backgroundFrame = backgroundContent.frame
                    backgroundFrame.origin.x += rect.minX
                    backgroundFrame.origin.y += rect.minY
                    backgroundContent.update(rect: backgroundFrame, within: containerSize, transition: .immediate)
                }
            }

            if typeUpdated {
                if let backgroundContent = self.backgroundContent {
                    self.backgroundContent = nil
                    backgroundContent.removeFromSupernode()
                }

                switch type {
                case .none:
                    break
                case .incoming:
                    if let backgroundContent = backgroundNode?.makeBubbleBackground(for: .incoming) {
                        backgroundContent.frame = self.bounds
                        if let (rect, containerSize) = self.absolutePosition {
                            var backgroundFrame = backgroundContent.frame
                            backgroundFrame.origin.x += rect.minX
                            backgroundFrame.origin.y += rect.minY
                            backgroundContent.update(rect: backgroundFrame, within: containerSize, transition: .immediate)
                        }
                        self.backgroundContent = backgroundContent
                        self.insertSubnode(backgroundContent, at: 0)
                        // nameless: solid fill only when liquid glass is off
                        let glassOn = glassZone.isEnabled
                        backgroundContent.isHidden = glassOn
                        backgroundContent.alpha = glassOn ? 0.0 : 1.0
                    }
                case .outgoing:
                    if let backgroundContent = backgroundNode?.makeBubbleBackground(for: .outgoing) {
                        backgroundContent.frame = self.bounds
                        if let (rect, containerSize) = self.absolutePosition {
                            var backgroundFrame = backgroundContent.frame
                            backgroundFrame.origin.x += rect.minX
                            backgroundFrame.origin.y += rect.minY
                            backgroundContent.update(rect: backgroundFrame, within: containerSize, transition: .immediate)
                        }
                        self.backgroundContent = backgroundContent
                        self.insertSubnode(backgroundContent, at: 0)
                        let glassOn = glassZone.isEnabled
                        backgroundContent.isHidden = glassOn
                        backgroundContent.alpha = glassOn ? 0.0 : 1.0
                    }
                }
            }

            // Ensure glass is re-applied after solid fill changes
            self.updateGlass(size: self.bounds.size, isDark: theme.theme.overallDarkAppearance, zone: glassZone)
            
            if let maskView = self.maskView {
                maskView.image = self.overrideMask ? nil : bubbleMaskForType(type, graphics: essentialGraphics)
            }
        }
    }
        
    public func update(rect: CGRect, within containerSize: CGSize, transition: ContainedViewLayoutTransition = .immediate) {
        self.absolutePosition = (rect, containerSize)
        if let backgroundContent = self.backgroundContent {
            var backgroundFrame = backgroundContent.frame
            backgroundFrame.origin.x += rect.minX
            backgroundFrame.origin.y += rect.minY
            backgroundContent.update(rect: backgroundFrame, within: containerSize, transition: transition)
        }
    }
    
    public func offset(value: CGPoint, animationCurve: ContainedViewLayoutTransitionCurve, duration: Double) {
        self.backgroundContent?.offset(value: value, animationCurve: animationCurve, duration: duration)
    }
    
    public func offsetSpring(value: CGFloat, duration: Double, damping: CGFloat) {
        self.backgroundContent?.offsetSpring(value: value, duration: duration, damping: damping)
    }
    
    public func updateFrame(_ value: CGRect, animator: ControlledTransitionAnimator, completion: @escaping () -> Void = {}) {
        if let maskView = self.maskView {
            animator.updateFrame(layer: maskView.layer, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: value.size.width, height: value.size.height)).insetBy(dx: -maskInset, dy: -maskInset), completion: nil)
        }
        if let backgroundContent = self.backgroundContent {
            animator.updateFrame(layer: backgroundContent.layer, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: value.size.width, height: value.size.height)), completion: nil)
            if let (rect, containerSize) = self.absolutePosition {
                var backgroundFrame = backgroundContent.frame
                backgroundFrame.origin.x += rect.minX
                backgroundFrame.origin.y += rect.minY
                backgroundContent.update(rect: backgroundFrame, within: containerSize, animator: animator)
            }
        }
        animator.updateFrame(layer: self.layer, frame: value, completion: { _ in
            completion()
        })
    }
    
    public func updateFrame(_ value: CGRect, transition: ContainedViewLayoutTransition, completion: @escaping () -> Void = {}) {
        if let maskView = self.maskView {
            transition.updateFrame(view: maskView, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: value.size.width, height: value.size.height)).insetBy(dx: -maskInset, dy: -maskInset))
        }
        if let backgroundContent = self.backgroundContent {
            transition.updateFrame(layer: backgroundContent.layer, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: value.size.width, height: value.size.height)))
            if let (rect, containerSize) = self.absolutePosition {
                var backgroundFrame = backgroundContent.frame
                backgroundFrame.origin.x += rect.minX
                backgroundFrame.origin.y += rect.minY
                backgroundContent.update(rect: backgroundFrame, within: containerSize, transition: transition)
            }
        }
        transition.updateFrame(node: self, frame: value, completion: { _ in
            completion()
        })
    }

    public func updateFrame(_ value: CGRect, transition: CombinedTransition, completion: @escaping () -> Void = {}) {
        if let maskView = self.maskView {
            transition.updateFrame(layer: maskView.layer, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: value.size.width, height: value.size.height)).insetBy(dx: -maskInset, dy: -maskInset))
        }
        if let backgroundContent = self.backgroundContent {
            transition.updateFrame(layer: backgroundContent.layer, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: value.size.width, height: value.size.height)))
            if let (rect, containerSize) = self.absolutePosition {
                var backgroundFrame = backgroundContent.frame
                backgroundFrame.origin.x += rect.minX
                backgroundFrame.origin.y += rect.minY
                backgroundContent.update(rect: backgroundFrame, within: containerSize, transition: transition)
            }
        }
        transition.updateFrame(layer: self.layer, frame: value, completion: { _ in
            completion()
        })
    }

    public func animateFrom(sourceView: UIView, transition: CombinedTransition) {
        if transition.isAnimated {
            let previousFrame = self.frame
            self.updateFrame(CGRect(origin: CGPoint(x: previousFrame.minX, y: sourceView.frame.minY), size: sourceView.frame.size), transition: .immediate)
            self.updateFrame(previousFrame, transition: transition)

            self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.1)
        }
    }
}
