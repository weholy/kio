import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData
import ContextUI

// MARK: - Compact action row at the top of the message menu
//
// iOS 26 leads a message menu with a row of the two or three actions you reach for constantly,
// drawn as icon-over-label buttons, and keeps the long-form list underneath for everything else.
//
// The row does not invent actions: it is handed the very `ContextMenuActionItem`s that would
// otherwise have been rows, and reuses their icons, titles and closures. Whatever the menu
// builder decided about availability, colour or behaviour therefore still holds — the row only
// changes how those items are drawn.

private let actionRowTitleFont = Font.regular(12.0)

private final class ChatMessageActionsRowButtonNode: HighlightTrackingButtonNode {
    let item: ContextMenuActionItem

    private let iconNode: ASImageNode
    private let titleNode: ImmediateTextNode

    private let performAction: (ContextMenuActionItem) -> Void

    init(item: ContextMenuActionItem, presentationData: PresentationData, performAction: @escaping (ContextMenuActionItem) -> Void) {
        self.item = item
        self.performAction = performAction

        self.iconNode = ASImageNode()
        self.iconNode.displaysAsynchronously = false
        self.iconNode.displayWithoutProcessing = true
        self.iconNode.isUserInteractionEnabled = false
        self.iconNode.contentMode = .scaleAspectFit

        self.titleNode = ImmediateTextNode()
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.isUserInteractionEnabled = false
        self.titleNode.displaysAsynchronously = false
        self.titleNode.textAlignment = .center

        super.init()

        self.addSubnode(self.iconNode)
        self.addSubnode(self.titleNode)

        self.updateTheme(presentationData: presentationData)

        self.highligthedChanged = { [weak self] highlighted in
            guard let self else {
                return
            }
            let alpha: CGFloat = highlighted ? 0.4 : 1.0
            self.iconNode.alpha = alpha
            self.titleNode.alpha = alpha
        }
        self.addTarget(self, action: #selector(self.pressed), forControlEvents: .touchUpInside)
    }

    @objc private func pressed() {
        self.performAction(self.item)
    }

    func updateTheme(presentationData: PresentationData) {
        let color: UIColor
        switch self.item.textColor {
        case .destructive:
            color = presentationData.theme.contextMenu.destructiveColor
        case .disabled:
            color = presentationData.theme.contextMenu.primaryColor.withMultipliedAlpha(0.4)
        default:
            color = presentationData.theme.contextMenu.primaryColor
        }

        self.titleNode.attributedText = NSAttributedString(string: self.item.text, font: actionRowTitleFont, textColor: color)
        // Menu icons ship as templates tinted at draw time, so the row tints them the same way
        // the list rows do — including the red for a destructive action.
        self.iconNode.image = self.item.icon(presentationData.theme).flatMap { image in
            return generateTintedImage(image: image, color: color)
        }
        self.isUserInteractionEnabled = self.item.action != nil
    }

    func updateLayout(size: CGSize) {
        let iconSize = CGSize(width: 24.0, height: 24.0)
        let spacing: CGFloat = 6.0
        let titleSize = self.titleNode.updateLayout(CGSize(width: size.width - 4.0, height: 100.0))

        let contentHeight = iconSize.height + spacing + titleSize.height
        let contentTop = floorToScreenPixels((size.height - contentHeight) / 2.0)

        self.iconNode.frame = CGRect(
            origin: CGPoint(x: floorToScreenPixels((size.width - iconSize.width) / 2.0), y: contentTop),
            size: iconSize
        )
        self.titleNode.frame = CGRect(
            origin: CGPoint(x: floorToScreenPixels((size.width - titleSize.width) / 2.0), y: contentTop + iconSize.height + spacing),
            size: titleSize
        )
    }

    /// Widest this button wants to be — used to size the row so no label is clipped.
    func intrinsicWidth() -> CGFloat {
        let titleSize = self.titleNode.updateLayout(CGSize(width: 200.0, height: 100.0))
        return max(64.0, titleSize.width + 16.0)
    }
}

private final class ChatMessageActionsRowNode: ASDisplayNode, ContextMenuCustomNode {
    private let items: [ContextMenuActionItem]
    private var buttonNodes: [ChatMessageActionsRowButtonNode] = []
    private var separatorNodes: [ASDisplayNode] = []

    private let getController: () -> ContextControllerProtocol?
    private let actionSelected: (ContextMenuActionResult) -> Void

    /// The row is its own group; the stack draws the divider below it.
    var needsSeparator: Bool {
        return true
    }

    var needsPadding: Bool {
        return false
    }

    init(
        items: [ContextMenuActionItem],
        presentationData: PresentationData,
        getController: @escaping () -> ContextControllerProtocol?,
        actionSelected: @escaping (ContextMenuActionResult) -> Void
    ) {
        self.items = items
        self.getController = getController
        self.actionSelected = actionSelected

        super.init()

        for item in items {
            let buttonNode = ChatMessageActionsRowButtonNode(item: item, presentationData: presentationData, performAction: { [weak self] item in
                self?.perform(item: item)
            })
            self.addSubnode(buttonNode)
            self.buttonNodes.append(buttonNode)
        }
        for _ in 0 ..< max(0, items.count - 1) {
            let separatorNode = ASDisplayNode()
            separatorNode.isLayerBacked = true
            separatorNode.backgroundColor = presentationData.theme.contextMenu.itemSeparatorColor.withMultipliedAlpha(0.5)
            self.addSubnode(separatorNode)
            self.separatorNodes.append(separatorNode)
        }
    }

    private func perform(item: ContextMenuActionItem) {
        guard let action = item.action else {
            return
        }
        let controller = self.getController()
        action(ContextMenuActionItem.Action(
            controller: controller,
            dismissWithResult: { [weak self] result in
                self?.actionSelected(result)
            },
            updateAction: { _, _ in
                // The row is rebuilt from scratch whenever the menu is, so an in-place update of
                // one of its items has nothing to apply to.
            }
        ))
    }

    func updateLayout(constrainedWidth: CGFloat, constrainedHeight: CGFloat) -> (CGSize, (CGSize, ContainedViewLayoutTransition) -> Void) {
        let height: CGFloat = 60.0
        let intrinsicWidth = self.buttonNodes.reduce(CGFloat(0.0)) { $0 + $1.intrinsicWidth() }
        let width = max(180.0, min(constrainedWidth, intrinsicWidth))

        return (CGSize(width: width, height: height), { [weak self] size, transition in
            guard let self, !self.buttonNodes.isEmpty else {
                return
            }
            let buttonWidth = size.width / CGFloat(self.buttonNodes.count)
            for (index, buttonNode) in self.buttonNodes.enumerated() {
                let frame = CGRect(
                    origin: CGPoint(x: buttonWidth * CGFloat(index), y: 0.0),
                    size: CGSize(width: buttonWidth, height: size.height)
                )
                transition.updateFrame(node: buttonNode, frame: frame)
                buttonNode.updateLayout(size: frame.size)
            }
            let separatorInset: CGFloat = 12.0
            for (index, separatorNode) in self.separatorNodes.enumerated() {
                transition.updateFrame(node: separatorNode, frame: CGRect(
                    origin: CGPoint(x: buttonWidth * CGFloat(index + 1) - UIScreenPixel * 0.5, y: separatorInset),
                    size: CGSize(width: UIScreenPixel, height: size.height - separatorInset * 2.0)
                ))
            }
        })
    }

    func updateTheme(presentationData: PresentationData) {
        for buttonNode in self.buttonNodes {
            buttonNode.updateTheme(presentationData: presentationData)
        }
        for separatorNode in self.separatorNodes {
            separatorNode.backgroundColor = presentationData.theme.contextMenu.itemSeparatorColor.withMultipliedAlpha(0.5)
        }
    }

    // The row handles its own taps per button, so the stack's whole-item highlight and
    // pan-to-select must not treat it as one target.
    func canBeHighlighted() -> Bool {
        return false
    }

    func updateIsHighlighted(isHighlighted: Bool) {
    }

    func performAction() {
    }
}

final class ChatMessageActionsRowItem: ContextMenuCustomItem {
    private let items: [ContextMenuActionItem]

    init(items: [ContextMenuActionItem]) {
        self.items = items
    }

    func node(
        presentationData: PresentationData,
        getController: @escaping () -> ContextControllerProtocol?,
        actionSelected: @escaping (ContextMenuActionResult) -> Void
    ) -> ContextMenuCustomNode {
        return ChatMessageActionsRowNode(
            items: self.items,
            presentationData: presentationData,
            getController: getController,
            actionSelected: actionSelected
        )
    }
}

extension Array where Element == ContextMenuItem {
    /// Lifts Select / Copy / Delete out of the list and into a compact row at the top.
    ///
    /// Matching is by title against the same string table the items were built from, because the
    /// menu builder does not tag them — comparing localized text to the exact strings that
    /// produced it is reliable in a way that substring matching would not be.
    ///
    /// If none of the three are present (a service message, a channel post the user cannot act
    /// on), the list is returned untouched rather than growing an empty row.
    func withLeadingActionsRow(strings: PresentationStrings) -> [ContextMenuItem] {
        let rowTitles: [String] = [
            strings.Conversation_ContextMenuSelect,
            strings.Conversation_ContextMenuCopy,
            strings.Conversation_ContextMenuDelete
        ]

        var rowItems: [ContextMenuActionItem] = []
        for title in rowTitles {
            for item in self {
                if case let .action(action) = item, action.text == title {
                    rowItems.append(action)
                    break
                }
            }
        }
        guard rowItems.count >= 2 else {
            return self
        }

        let promotedTitles = Set(rowItems.map { $0.text })
        var remaining: [ContextMenuItem] = []
        for item in self {
            if case let .action(action) = item, promotedTitles.contains(action.text) {
                continue
            }
            remaining.append(item)
        }
        // A separator that ended up leading the list once its neighbours moved up would draw a
        // stray gap under the row.
        while case .separator? = remaining.first {
            remaining.removeFirst()
        }

        return [.custom(ChatMessageActionsRowItem(items: rowItems), false)] + remaining
    }
}
