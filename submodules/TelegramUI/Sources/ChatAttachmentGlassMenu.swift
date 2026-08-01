import Foundation
import UIKit
import Display
import TelegramPresentationData
import AccountContext
import ContextUI
import AttachmentUI
import SGSimpleSettings

// MARK: - Megram — glass attachment menu
//
// Tapping "+" used to drop straight into the gallery with a horizontal tab bar of sources
// pinned under the sheet. iOS 26 presents this kind of choice as a floating clear-glass list
// anchored to the control that opened it, with the chat still readable behind it.
//
// This file builds that list. It deliberately reuses `ContextController` rather than growing a
// second menu implementation: the material, corner radius, highlight pill, dismissal gestures
// and open/close animation are then literally the same code that renders the message context
// menu, so the two can never drift apart visually.
//
// Picking a row re-enters `presentAttachmentMenu`, which opens exactly the screen the old tab
// bar would have opened — no attachment source changes behaviour, only how it is chosen.

/// Accent colour of a source's icon chip. These are the platform's semantic colours (the same
/// ones Apple uses for the equivalent concepts in Files/Maps/Contacts) rather than theme
/// colours, because the chips have to stay recognisable on every wallpaper and in both
/// appearances — a theme-derived tint would wash out against a matching wallpaper.
private func attachmentSourceColor(for type: AttachmentButtonType) -> UIColor {
    switch type {
    case .gallery:
        return UIColor(rgb: 0xF0508E)
    case .file:
        return UIColor(rgb: 0x0A84FF)
    case .location:
        return UIColor(rgb: 0x34C759)
    case .contact:
        return UIColor(rgb: 0xFF6B3D)
    case .todo:
        return UIColor(rgb: 0xFFCC00)
    case .poll:
        return UIColor(rgb: 0x5AC8FA)
    case .audio:
        return UIColor(rgb: 0xAF52DE)
    case .gift:
        return UIColor(rgb: 0xFF3B30)
    case .sticker, .emoji:
        return UIColor(rgb: 0x5E5CE6)
    case .link:
        return UIColor(rgb: 0x30B0C7)
    case .quickReply:
        return UIColor(rgb: 0x64D2FF)
    case .app, .standalone:
        return UIColor(rgb: 0x8E8E93)
    }
}

/// SF Symbol drawn inside the chip.
private func attachmentSourceSymbolName(for type: AttachmentButtonType) -> String {
    switch type {
    case .gallery:
        return "photo.on.rectangle"
    case .file:
        return "folder.fill"
    case .location:
        return "location.fill"
    case .todo:
        return "checklist"
    case .contact:
        return "person.crop.circle.fill"
    case .poll:
        return "chart.bar.fill"
    case .audio:
        return "music.note"
    case .gift:
        return "gift.fill"
    case .sticker:
        return "face.smiling.inverse"
    case .emoji:
        return "smiley.fill"
    case .link:
        return "link"
    case .quickReply:
        return "arrowshape.turn.up.left.fill"
    case .app, .standalone:
        return "square.grid.2x2.fill"
    }
}

private func attachmentSourceTitle(for type: AttachmentButtonType, strings: PresentationStrings) -> String {
    switch type {
    case .gallery:
        return strings.Attachment_Gallery
    case .file:
        return strings.Attachment_File
    case .location:
        return strings.Attachment_Location
    case .todo:
        return strings.Attachment_Todo
    case .contact:
        return strings.Attachment_Contact
    case .poll:
        return strings.Attachment_Poll
    case .gift:
        return strings.Attachment_Gift
    case .sticker:
        return strings.Attachment_Sticker
    case .emoji:
        return "Emoji"
    case .audio:
        return strings.Attachment_Audio
    case .link:
        return strings.Attachment_Link
    case .quickReply:
        return strings.Attachment_Reply
    case let .app(bot):
        return bot.shortName
    case .standalone:
        return ""
    }
}

/// A rounded-square colour chip with a white glyph, sized to the menu's icon slot.
private func generateAttachmentSourceIcon(type: AttachmentButtonType) -> UIImage? {
    let size = CGSize(width: 32.0, height: 32.0)
    let color = attachmentSourceColor(for: type)

    var glyph: UIImage?
    if #available(iOS 13.0, *) {
        let configuration = UIImage.SymbolConfiguration(pointSize: 15.0, weight: .semibold)
        glyph = UIImage(systemName: attachmentSourceSymbolName(for: type), withConfiguration: configuration)
    }

    return UIGraphicsImageRenderer(size: size).image { context in
        let cgContext = context.cgContext
        cgContext.addPath(UIBezierPath(roundedRect: CGRect(origin: CGPoint(), size: size), cornerRadius: 10.0).cgPath)
        cgContext.setFillColor(color.cgColor)
        cgContext.fillPath()

        guard let glyph, glyph.size.width > 0.0, glyph.size.height > 0.0 else {
            return
        }
        let maxGlyphSide: CGFloat = 18.0
        let scale = min(maxGlyphSide / glyph.size.width, maxGlyphSide / glyph.size.height)
        let glyphSize = CGSize(width: floor(glyph.size.width * scale), height: floor(glyph.size.height * scale))
        let glyphFrame = CGRect(
            origin: CGPoint(
                x: floor((size.width - glyphSize.width) * 0.5),
                y: floor((size.height - glyphSize.height) * 0.5)
            ),
            size: glyphSize
        )
        if #available(iOS 13.0, *) {
            glyph.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: glyphFrame)
        } else {
            glyph.draw(in: glyphFrame)
        }
    }.withRenderingMode(.alwaysOriginal)
}

extension ChatControllerImpl {
    /// True when "+" should open the glass list instead of dropping straight into a source.
    private var isAttachmentGlassMenuEnabled: Bool {
        let settings = SGSimpleSettings.shared
        guard settings.liquidGlassEnabled, !settings.blurInsteadGlass else {
            return false
        }
        return settings.namelessCompactAttachmentSheet
    }

    /// Presents the source picker. Returns `false` when the menu cannot or should not be shown
    /// (feature off, hand-off already in progress, nothing to pick from, no anchor view), in
    /// which case the caller proceeds with the classic flow untouched.
    func presentAttachmentGlassMenu(buttons: [AttachmentButtonType], subject: AttachMenuSubject) -> Bool {
        guard self.isAttachmentGlassMenuEnabled else {
            return false
        }
        // Only the plain "+" entry point is a free choice between sources. Every other subject
        // names the source it wants (a bot, a gift, editing an existing media message), so a
        // picker would be an extra tap in front of a decision the user already made.
        guard case .default = subject else {
            return false
        }
        let sources = buttons.filter { button in
            if case .standalone = button {
                return false
            }
            return true
        }
        guard sources.count > 1 else {
            return false
        }
        guard let sourceView = self.chatDisplayNode.getAttachmentButton() else {
            return false
        }

        let presentationData = self.presentationData
        var items: [ContextMenuItem] = []
        for source in sources {
            let icon = generateAttachmentSourceIcon(type: source)
            items.append(.action(ContextMenuActionItem(
                text: attachmentSourceTitle(for: source, strings: presentationData.strings),
                textLayout: .singleLine,
                icon: { _ in return icon },
                action: { [weak self] _, dismiss in
                    dismiss(.default)
                    guard let self else {
                        return
                    }
                    self.attachmentMenuPendingButton = source
                    self.presentAttachmentMenu(subject: .default)
                }
            )))
        }

        let contextController = makeContextController(
            context: self.context,
            presentationData: presentationData,
            source: .reference(ChatControllerContextReferenceContentSource(
                controller: self,
                sourceView: sourceView,
                insets: .zero,
                actionsOnTop: true
            )),
            items: .single(ContextController.Items(content: .list(items))),
            gesture: nil
        )
        self.presentInGlobalOverlay(contextController)
        return true
    }
}
