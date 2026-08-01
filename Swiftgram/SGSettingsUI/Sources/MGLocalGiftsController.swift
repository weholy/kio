import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import SGSimpleSettings
import MGLocalGifts

// MARK: - Local gift shop
//
// Buying a gift here spends local stars and writes a row into the local ledger. Nothing is sent
// to Telegram — the gift exists in this installation only, which is stated on the screen rather
// than left for the user to discover.

private enum MGLocalGiftsEntry: ItemListNodeEntry {
    case balanceHeader(id: Int, text: String)
    case balance(id: Int, text: String, detail: String)
    case ownedHeader(id: Int, text: String)
    case owned(id: Int, title: String, detail: String, giftId: String)
    case clearOwned(id: Int)
    case catalogHeader(id: Int, text: String)
    case catalogItem(id: Int, title: String, detail: String, kindId: String, enabled: Bool)
    case info(id: Int, text: String)

    var section: ItemListSectionId {
        switch self {
        case .balanceHeader, .balance:
            return 0
        case .ownedHeader, .owned, .clearOwned:
            return 1
        case .catalogHeader, .catalogItem:
            return 2
        case .info:
            return 3
        }
    }

    var stableId: Int {
        switch self {
        case let .balanceHeader(id, _), let .balance(id, _, _), let .ownedHeader(id, _),
             let .owned(id, _, _, _), let .clearOwned(id), let .catalogHeader(id, _),
             let .catalogItem(id, _, _, _, _), let .info(id, _):
            return id
        }
    }

    static func < (lhs: MGLocalGiftsEntry, rhs: MGLocalGiftsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    static func == (lhs: MGLocalGiftsEntry, rhs: MGLocalGiftsEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.balanceHeader(a, t1), .balanceHeader(b, t2)),
             let (.ownedHeader(a, t1), .ownedHeader(b, t2)),
             let (.catalogHeader(a, t1), .catalogHeader(b, t2)),
             let (.info(a, t1), .info(b, t2)):
            return a == b && t1 == t2
        case let (.balance(a, t1, d1), .balance(b, t2, d2)):
            return a == b && t1 == t2 && d1 == d2
        case let (.owned(a, t1, d1, g1), .owned(b, t2, d2, g2)):
            return a == b && t1 == t2 && d1 == d2 && g1 == g2
        case let (.clearOwned(a), .clearOwned(b)):
            return a == b
        case let (.catalogItem(a, t1, d1, k1, e1), .catalogItem(b, t2, d2, k2, e2)):
            return a == b && t1 == t2 && d1 == d2 && k1 == k2 && e1 == e2
        default:
            return false
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! MGLocalGiftsArguments
        switch self {
        case let .balanceHeader(_, text), let .ownedHeader(_, text), let .catalogHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .info(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .balance(_, text, detail):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: text,
                label: detail,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: nil
            )
        case let .owned(_, title, detail, giftId):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                label: detail,
                labelStyle: .detailText,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: {
                    arguments.removeGift(giftId)
                }
            )
        case .clearOwned:
            return ItemListActionItem(
                presentationData: presentationData,
                title: "Удалить все подарки",
                kind: .destructive,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.removeAll()
                }
            )
        case let .catalogItem(_, title, detail, kindId, enabled):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                enabled: enabled,
                label: detail,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.buy(kindId)
                }
            )
        }
    }
}

private final class MGLocalGiftsArguments {
    let buy: (String) -> Void
    let removeGift: (String) -> Void
    let removeAll: () -> Void

    init(buy: @escaping (String) -> Void, removeGift: @escaping (String) -> Void, removeAll: @escaping () -> Void) {
        self.buy = buy
        self.removeGift = removeGift
        self.removeAll = removeAll
    }
}

private func giftDateText(_ timestamp: Double) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM, HH:mm"
    return formatter.string(from: Date(timeIntervalSince1970: timestamp))
}

private func mgLocalGiftsEntries() -> [MGLocalGiftsEntry] {
    let settings = SGSimpleSettings.shared
    let owned = MGLocalGiftStore.shared.allGifts()
    var entries: [MGLocalGiftsEntry] = []
    var id = 0

    entries.append(.balanceHeader(id: id, text: "БАЛАНС")); id += 1
    entries.append(.balance(
        id: id,
        text: settings.localStarsEnabled ? "Локальные звёзды" : "Локальные звёзды выключены",
        detail: settings.localStarsEnabled ? "\(settings.localStarsBalance) ⭐" : "—"
    ))
    id += 1

    if !owned.isEmpty {
        entries.append(.ownedHeader(id: id, text: "МОИ ПОДАРКИ")); id += 1
        for gift in owned {
            guard let kind = MGLocalGiftCatalog.kind(id: gift.kindId) else {
                continue
            }
            var detail = giftDateText(gift.date)
            if let serial = gift.serial, let supply = kind.supply {
                detail = "\(serial) из \(supply) · \(detail)"
            }
            if !gift.message.isEmpty {
                detail += "\n\(gift.message)"
            }
            entries.append(.owned(id: id, title: "\(kind.emoji)  \(kind.title)", detail: detail, giftId: gift.id))
            id += 1
        }
        entries.append(.clearOwned(id: id)); id += 1
    }

    entries.append(.catalogHeader(id: id, text: "КАТАЛОГ")); id += 1
    for kind in MGLocalGiftCatalog.all {
        var detail = "\(kind.price) ⭐"
        if let supply = kind.supply {
            detail += " · 1 из \(supply)"
        }
        entries.append(.catalogItem(
            id: id,
            title: "\(kind.emoji)  \(kind.title)",
            detail: detail,
            kindId: kind.id,
            enabled: settings.localStarsEnabled && settings.localStarsBalance >= kind.price
        ))
        id += 1
    }

    entries.append(.info(id: id, text: "Подарки существуют только на этом устройстве. На серверы Telegram ничего не отправляется, и собеседник их не увидит — даже если пользуется этим же клиентом."))
    return entries
}

public func mgLocalGiftsController(context: AccountContext) -> ViewController {
    let reloadPromise = ValuePromise(true, ignoreRepeated: false)
    var presentControllerImpl: ((ViewController, Any?) -> Void)?

    let alert: (String, String) -> Void = { title, text in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        presentControllerImpl?(
            textAlertController(
                context: context,
                title: title,
                text: text,
                actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]
            ),
            nil
        )
    }

    let arguments = MGLocalGiftsArguments(
        buy: { kindId in
            guard let kind = MGLocalGiftCatalog.kind(id: kindId) else {
                return
            }
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            // A purchase spends the balance, so it asks first — the same courtesy a real one owes.
            presentControllerImpl?(
                textAlertController(
                    context: context,
                    title: "\(kind.emoji) \(kind.title)",
                    text: "Купить за \(kind.price) ⭐?",
                    actions: [
                        TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {}),
                        TextAlertAction(type: .defaultAction, title: "Купить", action: {
                            do {
                                let selfId = "\(context.account.peerId.id._internalGetInt64Value())"
                                _ = try MGLocalGiftStore.shared.purchase(
                                    kindId: kindId,
                                    recipientPeerId: selfId,
                                    recipientName: "",
                                    message: ""
                                )
                                reloadPromise.set(true)
                            } catch {
                                let message = (error as? MGLocalGiftPurchaseError)?.errorDescription ?? error.localizedDescription
                                alert("Не удалось купить", message)
                            }
                        })
                    ]
                ),
                nil
            )
        },
        removeGift: { giftId in
            MGLocalGiftStore.shared.remove(giftId: giftId)
            reloadPromise.set(true)
        },
        removeAll: {
            MGLocalGiftStore.shared.removeAll()
            reloadPromise.set(true)
        }
    )

    let signal = combineLatest(reloadPromise.get(), context.sharedContext.presentationData)
    |> map { _, presentationData -> (ItemListControllerState, (ItemListNodeState, MGLocalGiftsArguments)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Локальные подарки"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: mgLocalGiftsEntries(),
            style: .blocks,
            ensureVisibleItemTag: nil,
            initialScrollToItem: nil
        )
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a as? ViewControllerPresentationArguments)
    }
    return controller
}
