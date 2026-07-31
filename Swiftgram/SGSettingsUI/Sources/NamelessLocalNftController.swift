import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import SGSimpleSettings

private enum NamelessLocalNftSection: Int32 {
    case giftEditor = 0
    case usernameEditor
    case current
}

private enum NamelessLocalNftEntry: ItemListNodeEntry {
    case header(id: Int, section: NamelessLocalNftSection, text: String)
    case input(id: Int, section: NamelessLocalNftSection, icon: String, text: String, placeholder: String, kind: InputKind)
    case action(id: Int, section: NamelessLocalNftSection, text: String, kind: ItemListActionKind, action: Action)
    case info(id: Int, section: NamelessLocalNftSection, text: String)

    enum InputKind {
        case peerId
        case giftTitle
        case giftSubtitle
        case giftEmoji
        case giftRarity
        case giftSerial
        case username
        case usernameNumber
        case usernameColor
    }

    enum Action {
        case addGift
        case addUsername
        case removeGift(String)
        case removeUsername(String)
    }

    var section: ItemListSectionId {
        switch self {
        case let .header(_, section, _), let .input(_, section, _, _, _, _), let .action(_, section, _, _, _), let .info(_, section, _):
            return section.rawValue
        }
    }

    var stableId: Int {
        switch self {
        case let .header(id, _, _), let .input(id, _, _, _, _, _), let .action(id, _, _, _, _), let .info(id, _, _):
            return id
        }
    }

    static func < (lhs: NamelessLocalNftEntry, rhs: NamelessLocalNftEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    static func == (lhs: NamelessLocalNftEntry, rhs: NamelessLocalNftEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.header(a, s1, t1), .header(b, s2, t2)):
            return a == b && s1 == s2 && t1 == t2
        case let (.input(a, s1, i1, t1, p1, k1), .input(b, s2, i2, t2, p2, k2)):
            return a == b && s1 == s2 && i1 == i2 && t1 == t2 && p1 == p2 && k1 == k2
        case let (.action(a, s1, t1, _, _), .action(b, s2, t2, _, _)):
            return a == b && s1 == s2 && t1 == t2
        case let (.info(a, s1, t1), .info(b, s2, t2)):
            return a == b && s1 == s2 && t1 == t2
        default:
            return false
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! NamelessLocalNftArguments
        switch self {
        case let .header(_, _, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .input(_, _, icon, text, placeholder, kind):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: NSAttributedString(string: icon, textColor: presentationData.theme.list.itemPrimaryTextColor),
                text: text,
                placeholder: placeholder,
                type: .regular(capitalization: false, autocorrection: false),
                clearType: .always,
                sectionId: self.section,
                textUpdated: { arguments.update(kind, $0) },
                action: {}
            )
        case let .action(_, _, text, kind, action):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: kind,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: { arguments.perform(action) }
            )
        case let .info(_, _, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private final class NamelessLocalNftState {
    var peerId: String
    var giftTitle: String = "Crystal Heart"
    var giftSubtitle: String = "Megram local collectible"
    var giftEmoji: String = "💎"
    var giftRarity: String = "Legendary"
    var giftSerial: String = "#1"
    var username: String = "megram"
    var usernameNumber: String = "#1"
    var usernameColor: String = "#66D7FF"

    init() {
        self.peerId = SGSimpleSettings.shared.currentAccountPeerId
    }
}

private final class NamelessLocalNftArguments {
    let update: (NamelessLocalNftEntry.InputKind, String) -> Void
    let perform: (NamelessLocalNftEntry.Action) -> Void

    init(update: @escaping (NamelessLocalNftEntry.InputKind, String) -> Void, perform: @escaping (NamelessLocalNftEntry.Action) -> Void) {
        self.update = update
        self.perform = perform
    }
}

private func trimmed(_ value: String) -> String {
    return value.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func namelessLocalNftEntries(state: NamelessLocalNftState) -> [NamelessLocalNftEntry] {
    let settings = SGSimpleSettings.shared
    var entries: [NamelessLocalNftEntry] = []
    var id = 0

    entries.append(.header(id: id, section: .giftEditor, text: "NFT-ПОДАРОК"))
    id += 1
    entries.append(.input(id: id, section: .giftEditor, icon: "ID", text: state.peerId, placeholder: "Telegram ID или пусто для себя", kind: .peerId))
    id += 1
    entries.append(.input(id: id, section: .giftEditor, icon: "🎁", text: state.giftTitle, placeholder: "Название подарка", kind: .giftTitle))
    id += 1
    entries.append(.input(id: id, section: .giftEditor, icon: "✦", text: state.giftSubtitle, placeholder: "Описание", kind: .giftSubtitle))
    id += 1
    entries.append(.input(id: id, section: .giftEditor, icon: "💠", text: state.giftEmoji, placeholder: "Emoji", kind: .giftEmoji))
    id += 1
    entries.append(.input(id: id, section: .giftEditor, icon: "R", text: state.giftRarity, placeholder: "Редкость", kind: .giftRarity))
    id += 1
    entries.append(.input(id: id, section: .giftEditor, icon: "#", text: state.giftSerial, placeholder: "#1", kind: .giftSerial))
    id += 1
    entries.append(.action(id: id, section: .giftEditor, text: "Добавить NFT-подарок", kind: .generic, action: .addGift))
    id += 1

    entries.append(.header(id: id, section: .usernameEditor, text: "NFT-USERNAME"))
    id += 1
    entries.append(.input(id: id, section: .usernameEditor, icon: "@", text: state.username, placeholder: "username без @", kind: .username))
    id += 1
    entries.append(.input(id: id, section: .usernameEditor, icon: "#", text: state.usernameNumber, placeholder: "#1", kind: .usernameNumber))
    id += 1
    entries.append(.input(id: id, section: .usernameEditor, icon: "HEX", text: state.usernameColor, placeholder: "#66D7FF", kind: .usernameColor))
    id += 1
    entries.append(.action(id: id, section: .usernameEditor, text: "Добавить NFT-username", kind: .generic, action: .addUsername))
    id += 1

    entries.append(.header(id: id, section: .current, text: "ДОБАВЛЕНО ЛОКАЛЬНО"))
    id += 1
    if settings.localNftGifts.isEmpty && settings.localNftUsernames.isEmpty {
        entries.append(.info(id: id, section: .current, text: "Пока нет локальных NFT. Добавленные элементы будут отображаться только в Megram/Nameless и не меняют данные на сервере Telegram."))
        id += 1
    } else {
        for gift in settings.localNftGifts {
            let owner = gift.peerId.isEmpty ? "self" : gift.peerId
            entries.append(.action(id: id, section: .current, text: "\(gift.emoji) \(gift.title) \(gift.serial) · \(gift.rarity) · \(owner)", kind: .destructive, action: .removeGift(gift.id)))
            id += 1
        }
        for username in settings.localNftUsernames {
            let owner = username.peerId.isEmpty ? "self" : username.peerId
            entries.append(.action(id: id, section: .current, text: "@\(username.username) \(username.number) · \(owner)", kind: .destructive, action: .removeUsername(username.id)))
            id += 1
        }
    }

    return entries
}

public func namelessLocalNftController(context: AccountContext, onSave: @escaping () -> Void) -> ViewController {
    let reloadPromise = ValuePromise(true, ignoreRepeated: false)
    let state = NamelessLocalNftState()

    let arguments = NamelessLocalNftArguments(
        update: { kind, value in
            switch kind {
            case .peerId:
                state.peerId = value
            case .giftTitle:
                state.giftTitle = value
            case .giftSubtitle:
                state.giftSubtitle = value
            case .giftEmoji:
                state.giftEmoji = value
            case .giftRarity:
                state.giftRarity = value
            case .giftSerial:
                state.giftSerial = value
            case .username:
                state.username = value
            case .usernameNumber:
                state.usernameNumber = value
            case .usernameColor:
                state.usernameColor = value
            }
        },
        perform: { action in
            let settings = SGSimpleSettings.shared
            let peerId = trimmed(state.peerId).isEmpty ? settings.currentAccountPeerId : trimmed(state.peerId)
            switch action {
            case .addGift:
                settings.addLocalNftGift(NamelessLocalNftGift(peerId: peerId, title: trimmed(state.giftTitle), subtitle: trimmed(state.giftSubtitle), emoji: trimmed(state.giftEmoji).isEmpty ? "🎁" : trimmed(state.giftEmoji), rarity: trimmed(state.giftRarity), serial: trimmed(state.giftSerial)))
            case .addUsername:
                let username = trimmed(state.username).replacingOccurrences(of: "@", with: "")
                if !username.isEmpty {
                    settings.addLocalNftUsername(NamelessLocalNftUsername(peerId: peerId, username: username, number: trimmed(state.usernameNumber), colorHex: trimmed(state.usernameColor)))
                }
            case let .removeGift(id):
                settings.removeLocalNftGift(id: id)
            case let .removeUsername(id):
                settings.removeLocalNftUsername(id: id)
            }
            onSave()
            reloadPromise.set(true)
        }
    )

    let signal = combineLatest(reloadPromise.get(), context.sharedContext.presentationData)
    |> map { _, presentationData -> (ItemListControllerState, (ItemListNodeState, NamelessLocalNftArguments)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Megram NFT"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: namelessLocalNftEntries(state: state),
            style: .blocks,
            ensureVisibleItemTag: nil,
            initialScrollToItem: nil
        )
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
