import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData
import AccountContext

/// A row of small rounded chips — Megram's form for the id, dc and mutual-contact
/// facts that used to occupy three full list rows each.
///
/// A tap copies the chip's value and flashes it, so the values stay reachable
/// without a long press or a context menu.
final class MegramChipsItem: PeerInfoScreenItem {
    struct Chip: Equatable {
        let title: String
        /// What lands on the pasteboard. Nil makes the chip a label only.
        let copyValue: String?

        init(title: String, copyValue: String?) {
            self.title = title
            self.copyValue = copyValue
        }
    }

    let id: AnyHashable
    let chips: [Chip]
    let copied: (String) -> Void

    init(id: AnyHashable, chips: [Chip], copied: @escaping (String) -> Void) {
        self.id = id
        self.chips = chips
        self.copied = copied
    }

    func node() -> PeerInfoScreenItemNode {
        return MegramChipsItemNode()
    }
}

private final class MegramChipView: UIView {
    private let backgroundView = UIView()
    private let label = UILabel()
    private let button = HighlightTrackingButton()

    private(set) var copyValue: String?
    var pressed: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundView.layer.cornerRadius = 13.0
        self.label.font = Font.regular(13.0)
        self.label.textAlignment = .center

        self.addSubview(self.backgroundView)
        self.addSubview(self.label)
        self.addSubview(self.button)

        self.button.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
        self.button.highligthedChanged = { [weak self] highlighted in
            self?.alpha = highlighted ? 0.6 : 1.0
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    @objc private func buttonPressed() {
        guard let copyValue = self.copyValue else {
            return
        }
        self.pressed?(copyValue)
        // A brief flash is the only feedback a copy gets here.
        self.backgroundView.layer.animateAlpha(from: 0.35, to: 1.0, duration: 0.35)
    }

    func update(chip: MegramChipsItem.Chip, presentationData: PresentationData) {
        self.copyValue = chip.copyValue
        self.label.text = chip.title
        self.label.textColor = presentationData.theme.list.itemSecondaryTextColor
        // Barely-there fill: present enough to read as a control, quiet enough
        // not to compete with the rest of the profile.
        self.backgroundView.backgroundColor = presentationData.theme.list.itemSecondaryTextColor.withAlphaComponent(0.10)
        self.button.isUserInteractionEnabled = chip.copyValue != nil
    }

    func measure() -> CGSize {
        let textSize = self.label.sizeThatFits(CGSize(width: 1000.0, height: 26.0))
        return CGSize(width: ceil(textSize.width) + 24.0, height: 26.0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundView.frame = self.bounds
        self.label.frame = self.bounds
        self.button.frame = self.bounds
    }
}

private final class MegramChipsItemNode: PeerInfoScreenItemNode {
    private let selectionNode: PeerInfoScreenSelectableBackgroundNode
    private let bottomSeparatorNode: ASDisplayNode
    private var chipViews: [MegramChipView] = []

    private var item: MegramChipsItem?

    override init() {
        var bringToFrontForHighlightImpl: (() -> Void)?
        self.selectionNode = PeerInfoScreenSelectableBackgroundNode(bringToFrontForHighlight: { bringToFrontForHighlightImpl?() })
        self.bottomSeparatorNode = ASDisplayNode()
        self.bottomSeparatorNode.isLayerBacked = true

        super.init()

        bringToFrontForHighlightImpl = { [weak self] in
            self?.bringToFrontForHighlight?()
        }

        self.addSubnode(self.selectionNode)
        self.addSubnode(self.bottomSeparatorNode)
    }

    override func update(context: AccountContext, width: CGFloat, safeInsets: UIEdgeInsets, presentationData: PresentationData, item: PeerInfoScreenItem, topItem: PeerInfoScreenItem?, bottomItem: PeerInfoScreenItem?, hasCorners: Bool, transition: ContainedViewLayoutTransition) -> CGFloat {
        guard let item = item as? MegramChipsItem else {
            return 10.0
        }
        self.item = item

        let sideInset: CGFloat = 16.0 + safeInsets.left
        let verticalInset: CGFloat = 10.0
        let spacing: CGFloat = 8.0

        // Rebuilding is cheap here — a profile carries three chips at most.
        for view in self.chipViews {
            view.removeFromSuperview()
        }
        self.chipViews.removeAll()

        var x = sideInset
        var y = verticalInset
        var rowHeight: CGFloat = 0.0
        let maxX = width - sideInset

        for chip in item.chips {
            let view = MegramChipView(frame: CGRect())
            view.update(chip: chip, presentationData: presentationData)
            view.pressed = { [weak self] value in
                self?.item?.copied(value)
            }
            let size = view.measure()

            // Wrap rather than clip: a long id plus a country name will not fit
            // one line on a narrow screen.
            if x > sideInset && x + size.width > maxX {
                x = sideInset
                y += size.height + spacing
            }
            view.frame = CGRect(origin: CGPoint(x: x, y: y), size: size)
            self.view.addSubview(view)
            self.chipViews.append(view)

            x += size.width + spacing
            rowHeight = size.height
        }

        let height = y + rowHeight + verticalInset

        self.bottomSeparatorNode.backgroundColor = presentationData.theme.list.itemBlocksSeparatorColor
        transition.updateFrame(node: self.bottomSeparatorNode, frame: CGRect(origin: CGPoint(x: sideInset, y: height - UIScreenPixel), size: CGSize(width: width - sideInset, height: UIScreenPixel)))
        self.bottomSeparatorNode.isHidden = bottomItem == nil

        transition.updateFrame(node: self.selectionNode, frame: CGRect(origin: CGPoint(), size: CGSize(width: width, height: height)))
        self.selectionNode.update(size: CGSize(width: width, height: height), theme: presentationData.theme, transition: transition)

        return height
    }
}
