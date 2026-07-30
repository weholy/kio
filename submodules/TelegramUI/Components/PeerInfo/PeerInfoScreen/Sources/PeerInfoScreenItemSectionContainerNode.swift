import Foundation
import UIKit
import Display
import AsyncDisplayKit
import AccountContext
import TelegramPresentationData
import SGLiquidGlassCore
import SGLiquidGlass

final class PeerInfoScreenItemSectionContainerNode: ASDisplayNode {
    private let backgroundNode: ASDisplayNode
    private let topSeparatorNode: ASDisplayNode
    private let bottomSeparatorNode: ASDisplayNode
    private let itemContainerNode: ASDisplayNode
    
    private var currentItems: [PeerInfoScreenItem] = []
    var itemNodes: [AnyHashable: PeerInfoScreenItemNode] = [:]
    
    override init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = false
        
        self.topSeparatorNode = ASDisplayNode()
        self.topSeparatorNode.isLayerBacked = true
        
        self.bottomSeparatorNode = ASDisplayNode()
        self.bottomSeparatorNode.isLayerBacked = true
        
        self.itemContainerNode = ASDisplayNode()
        self.itemContainerNode.clipsToBounds = true
        
        super.init()
        
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.itemContainerNode)
        self.addSubnode(self.topSeparatorNode)
        self.addSubnode(self.bottomSeparatorNode)
    }
    
    func update(context: AccountContext, width: CGFloat, safeInsets: UIEdgeInsets, hasCorners: Bool, presentationData: PresentationData, items: [PeerInfoScreenItem], transition: ContainedViewLayoutTransition) -> CGFloat {
        let glassOn = SGLiquidGlassZone.settings.isEnabled || SGLiquidGlassZone.profile.isEnabled
        let isDark = presentationData.theme.overallDarkAppearance
        // Always round glass "clouds" for Wallet / Saved / Calls / Folders sections
        let useCorners = glassOn ? true : hasCorners
        let r = NamelessItemListGlass.sectionCornerRadius

        if glassOn {
            // Clear solid fill so real UIGlassEffect can show; kill thick gray section stripes.
            self.backgroundNode.backgroundColor = .clear
            self.topSeparatorNode.isHidden = true
            self.bottomSeparatorNode.isHidden = true
            self.itemContainerNode.clipsToBounds = true
            self.itemContainerNode.cornerRadius = r
            self.backgroundNode.cornerRadius = r
            if let glass = self.backgroundNode.sgGlassOverlay {
                // No solid accent tint — pure panel glass
                glass.tint = .clear
                glass.updateLayout(
                    size: CGSize(width: width, height: max(self.backgroundNode.bounds.height, 1)),
                    topLeft: r, topRight: r,
                    bottomLeft: r, bottomRight: r,
                    isDark: isDark
                )
            }
        } else {
            self.backgroundNode.backgroundColor = presentationData.theme.list.itemBlocksBackgroundColor
            self.topSeparatorNode.backgroundColor = presentationData.theme.list.itemBlocksSeparatorColor
            self.bottomSeparatorNode.backgroundColor = presentationData.theme.list.itemBlocksSeparatorColor
            self.topSeparatorNode.isHidden = hasCorners
            self.bottomSeparatorNode.isHidden = hasCorners
            self.itemContainerNode.cornerRadius = 0
            self.backgroundNode.cornerRadius = 0
        }
        
        var contentHeight: CGFloat = 0.0
        var contentWithBackgroundHeight: CGFloat = 0.0
        var contentWithBackgroundOffset: CGFloat = 0.0
        
        for i in 0 ..< items.count {
            let item = items[i]
            
            let itemNode: PeerInfoScreenItemNode
            var wasAdded = false
            if let current = self.itemNodes[item.id] {
                itemNode = current
            } else {
                wasAdded = true
                itemNode = item.node()
                self.itemNodes[item.id] = itemNode
                self.itemContainerNode.addSubnode(itemNode)
                itemNode.bringToFrontForHighlight = { [weak self, weak itemNode] in
                    guard let strongSelf = self, let itemNode = itemNode else {
                        return
                    }
                    strongSelf.view.bringSubviewToFront(itemNode.view)
                }
            }
            
            let itemTransition: ContainedViewLayoutTransition = wasAdded ? .immediate : transition
            
            let topItem: PeerInfoScreenItem?
            if i == 0 {
                topItem = nil
            } else if items[i - 1] is PeerInfoScreenHeaderItem {
                topItem = nil
            } else {
                topItem = items[i - 1]
            }
            
            let bottomItem: PeerInfoScreenItem?
            if i == items.count - 1 {
                bottomItem = nil
            } else if items[i + 1] is PeerInfoScreenCommentItem {
                bottomItem = nil
            } else {
                bottomItem = items[i + 1]
            }
            
            let itemHeight = itemNode.update(context: context, width: width, safeInsets: safeInsets, presentationData: presentationData, item: item, topItem: topItem, bottomItem: bottomItem, hasCorners: hasCorners, transition: itemTransition)
            let itemFrame = CGRect(origin: CGPoint(x: 0.0, y: contentHeight), size: CGSize(width: width, height: itemHeight))
            itemTransition.updateFrame(node: itemNode, frame: itemFrame)
            if wasAdded {
                itemNode.alpha = 0.0
                let alphaTransition: ContainedViewLayoutTransition = transition.isAnimated ? .animated(duration: 0.35, curve: .linear) : .immediate
                alphaTransition.updateAlpha(node: itemNode, alpha: 1.0)
            }
            
            if item is PeerInfoScreenCommentItem {
            } else {
                contentWithBackgroundHeight += itemHeight
            }
            contentHeight += itemHeight
            
            if item is PeerInfoScreenHeaderItem {
                contentWithBackgroundOffset = contentHeight
            }
        }
        
        var removeIds: [AnyHashable] = []
        for (id, _) in self.itemNodes {
            if !items.contains(where: { $0.id == id }) {
                removeIds.append(id)
            }
        }
        for id in removeIds {
            if let itemNode = self.itemNodes.removeValue(forKey: id) {
                itemNode.view.superview?.sendSubviewToBack(itemNode.view)
                transition.updateAlpha(node: itemNode, alpha: 0.0, completion: { [weak itemNode] _ in
                    itemNode?.removeFromSupernode()
                })
            }
        }
        
        let bgHeight = max(0.0, contentWithBackgroundHeight - contentWithBackgroundOffset)
        let bgFrame = CGRect(origin: CGPoint(x: 0.0, y: contentWithBackgroundOffset), size: CGSize(width: width, height: bgHeight))
        transition.updateFrame(node: self.itemContainerNode, frame: CGRect(origin: CGPoint(), size: CGSize(width: width, height: contentHeight)))
        transition.updateFrame(node: self.backgroundNode, frame: bgFrame)
        transition.updateFrame(node: self.topSeparatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: contentWithBackgroundOffset - UIScreenPixel), size: CGSize(width: width, height: UIScreenPixel)))
        transition.updateFrame(node: self.bottomSeparatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: contentWithBackgroundHeight), size: CGSize(width: width, height: UIScreenPixel)))

        if glassOn, bgHeight > 0.5, let glass = self.backgroundNode.sgGlassOverlay {
            let corner = useCorners ? r : 0.0
            glass.updateLayout(
                size: bgFrame.size,
                topLeft: corner, topRight: corner,
                bottomLeft: corner, bottomRight: corner,
                isDark: isDark
            )
        }
        
        if contentHeight.isZero || glassOn {
            transition.updateAlpha(node: self.topSeparatorNode, alpha: 0.0)
            transition.updateAlpha(node: self.bottomSeparatorNode, alpha: 0.0)
        } else {
            transition.updateAlpha(node: self.topSeparatorNode, alpha: 1.0)
            transition.updateAlpha(node: self.bottomSeparatorNode, alpha: 1.0)
        }
        
        return contentHeight
    }
    
    func animateErrorIfNeeded() {
        for (_, itemNode) in self.itemNodes {
            if let itemNode = itemNode as? PeerInfoScreenMultilineInputItemNode {
                itemNode.animateErrorIfNeeded()
            }
        }
    }
}
