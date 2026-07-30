import Foundation
import UIKit
import Display
import SwiftSignalKit
import AccountContext
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import SGSimpleSettings

private enum OHSection: Int32 {
    case list = 0
    case actions = 1
}

private enum OHEntry: ItemListNodeEntry {
    case header(id: Int, text: String)
    case row(id: Int, title: String, subtitle: String)
    case empty(id: Int, text: String)
    case clear(id: Int, text: String)

    var section: ItemListSectionId {
        switch self {
        case .clear: return OHSection.actions.rawValue
        default: return OHSection.list.rawValue
        }
    }

    var stableId: Int {
        switch self {
        case .header(let i, _), .row(let i, _, _), .empty(let i, _), .clear(let i, _):
            return i
        }
    }

    static func < (lhs: OHEntry, rhs: OHEntry) -> Bool { lhs.stableId < rhs.stableId }

    static func == (lhs: OHEntry, rhs: OHEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.header(a, t1), .header(b, t2)): return a == b && t1 == t2
        case let (.row(a, t1, s1), .row(b, t2, s2)): return a == b && t1 == t2 && s1 == s2
        case let (.empty(a, t1), .empty(b, t2)): return a == b && t1 == t2
        case let (.clear(a, t1), .clear(b, t2)): return a == b && t1 == t2
        default: return false
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! OHArguments
        switch self {
        case .header(_, let text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
        case let .row(_, title, subtitle):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: subtitle,
                sectionId: section,
                style: .blocks,
                disclosureStyle: .none,
                action: nil
            )
        case .empty(_, let text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: section)
        case .clear(_, let text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .destructive, alignment: .natural, sectionId: section, style: .blocks, action: {
                args.clear()
            })
        }
    }
}

private final class OHArguments {
    let clear: () -> Void
    init(clear: @escaping () -> Void) { self.clear = clear }
}

private func ohEntries(presentationData: PresentationData) -> [OHEntry] {
    var entries: [OHEntry] = []
    var id = 0
    let df = DateFormatter()
    df.dateFormat = "d MMM HH:mm:ss"
    let list = NamelessOnlineHistory.all()
    entries.append(.header(id: id, text: "ИСТОРИЯ ОНЛАЙНА"))
    id += 1
    if list.isEmpty {
        entries.append(.empty(id: id, text: "Пока пусто. Включите «История онлайна» и откройте чаты с контактами."))
        id += 1
    } else {
        for e in list.prefix(100) {
            let status = e.isOnline ? "Онлайн" : "Оффлайн"
            entries.append(.row(id: id, title: e.name, subtitle: "\(status) · \(df.string(from: e.date))"))
            id += 1
        }
    }
    entries.append(.clear(id: id, text: "Очистить историю"))
    return entries
}

/// Экран «История онлайна контактов» (как Whitegram, бренд nameless).
public func namelessOnlineHistoryController(context: AccountContext) -> ViewController {
    let reload = ValuePromise(true, ignoreRepeated: false)
    let arguments = OHArguments(clear: {
        NamelessOnlineHistory.clear()
        reload.set(true)
    })
    let signal = combineLatest(reload.get(), context.sharedContext.presentationData)
    |> map { _, presentationData -> (ItemListControllerState, (ItemListNodeState, OHArguments)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("История онлайна"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let entries = ohEntries(presentationData: presentationData)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks)
        return (controllerState, (listState, arguments))
    }
    return ItemListController(context: context, state: signal)
}
