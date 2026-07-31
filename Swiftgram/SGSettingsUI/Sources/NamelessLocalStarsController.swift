import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import SGSimpleSettings

// MARK: - Local (fake) stars wallet editor
//
// Edits the top-up amount backing `SGSimpleSettings.localStarsBalance`. The balance itself
// is top-up minus whatever has been spent locally, so this screen also surfaces the spent
// counter and offers a reset ("top up again").

private enum NamelessLocalStarsEntry: ItemListNodeEntry {
    case amountHeader(id: Int, text: String)
    case amount(id: Int, text: String, placeholder: String)
    case balanceInfo(id: Int, text: String)
    case reset(id: Int, text: String, enabled: Bool)

    var section: ItemListSectionId { 0 }

    var stableId: Int {
        switch self {
        case let .amountHeader(id, _), let .amount(id, _, _), let .balanceInfo(id, _), let .reset(id, _, _):
            return id
        }
    }

    static func < (lhs: NamelessLocalStarsEntry, rhs: NamelessLocalStarsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    static func == (lhs: NamelessLocalStarsEntry, rhs: NamelessLocalStarsEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.amountHeader(a, t1), .amountHeader(b, t2)):
            return a == b && t1 == t2
        case let (.amount(a, t1, p1), .amount(b, t2, p2)):
            return a == b && t1 == t2 && p1 == p2
        case let (.balanceInfo(a, t1), .balanceInfo(b, t2)):
            return a == b && t1 == t2
        case let (.reset(a, t1, e1), .reset(b, t2, e2)):
            return a == b && t1 == t2 && e1 == e2
        default:
            return false
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! NamelessLocalStarsArguments
        switch self {
        case let .amountHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .amount(_, text, placeholder):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: NSAttributedString(string: "⭐", textColor: presentationData.theme.list.itemPrimaryTextColor),
                text: text,
                placeholder: placeholder,
                type: .number,
                clearType: .always,
                sectionId: self.section,
                textUpdated: { arguments.updateAmount($0) },
                action: {}
            )
        case let .balanceInfo(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .reset(_, text, enabled):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: enabled ? .generic : .disabled,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: { arguments.resetSpending() }
            )
        }
    }
}

private final class NamelessLocalStarsArguments {
    let updateAmount: (String) -> Void
    let resetSpending: () -> Void

    init(updateAmount: @escaping (String) -> Void, resetSpending: @escaping () -> Void) {
        self.updateAmount = updateAmount
        self.resetSpending = resetSpending
    }
}

private func namelessLocalStarsEntries() -> [NamelessLocalStarsEntry] {
    let s = SGSimpleSettings.shared
    var entries: [NamelessLocalStarsEntry] = []
    var id = 0

    entries.append(.amountHeader(id: id, text: "СУММА ПОПОЛНЕНИЯ"))
    id += 1
    entries.append(.amount(id: id, text: s.feelRichStarsAmount, placeholder: "1000"))
    id += 1
    entries.append(.balanceInfo(id: id, text: "Текущий баланс: \(s.localStarsBalance) ⭐\nПотрачено: \(s.localStarsSpent) ⭐\n\nБаланс отображается только у вас и не связан с сервером Telegram."))
    id += 1
    entries.append(.reset(id: id, text: "Сбросить траты", enabled: s.localStarsSpent > 0))

    return entries
}

/// Editor for the local stars wallet.
public func namelessLocalStarsController(context: AccountContext, onSave: @escaping () -> Void) -> ViewController {
    let reloadPromise = ValuePromise(true, ignoreRepeated: false)

    let arguments = NamelessLocalStarsArguments(
        updateAmount: { value in
            SGSimpleSettings.shared.feelRichStarsAmount = value
            NotificationCenter.default.post(name: .namelessLocalStarsDidChange, object: nil)
            onSave()
            reloadPromise.set(true)
        },
        resetSpending: {
            SGSimpleSettings.shared.resetLocalStarsSpending()
            onSave()
            reloadPromise.set(true)
        }
    )

    let signal = combineLatest(reloadPromise.get(), context.sharedContext.presentationData)
    |> map { _, presentationData -> (ItemListControllerState, (ItemListNodeState, NamelessLocalStarsArguments)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Локальные звёзды"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: namelessLocalStarsEntries(),
            style: .blocks,
            ensureVisibleItemTag: nil,
            initialScrollToItem: nil
        )
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
