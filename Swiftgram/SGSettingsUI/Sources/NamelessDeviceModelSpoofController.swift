import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import SGSimpleSettings

// MARK: - Device model spoof editor
//
// Sets `SGSimpleSettings.deviceModelSpoof`, which MTApiEnvironment reads directly from
// NSUserDefaults on connection setup. Applies only after the app reconnects, hence the
// restart prompt when this screen is dismissed with a non-empty value.

private enum NamelessDeviceModelEntry: ItemListNodeEntry {
    case header(id: Int, text: String)
    case input(id: Int, text: String, placeholder: String)
    case clear(id: Int, text: String, enabled: Bool)
    case info(id: Int, text: String)

    var section: ItemListSectionId { 0 }
    var stableId: Int {
        switch self {
        case let .header(id, _), let .input(id, _, _), let .clear(id, _, _), let .info(id, _):
            return id
        }
    }

    static func < (lhs: NamelessDeviceModelEntry, rhs: NamelessDeviceModelEntry) -> Bool { lhs.stableId < rhs.stableId }

    static func == (lhs: NamelessDeviceModelEntry, rhs: NamelessDeviceModelEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.header(a, t1), .header(b, t2)): return a == b && t1 == t2
        case let (.input(a, t1, p1), .input(b, t2, p2)): return a == b && t1 == t2 && p1 == p2
        case let (.clear(a, t1, e1), .clear(b, t2, e2)): return a == b && t1 == t2 && e1 == e2
        case let (.info(a, t1), .info(b, t2)): return a == b && t1 == t2
        default: return false
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! NamelessDeviceModelArguments
        switch self {
        case let .header(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .input(_, text, placeholder):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: NSAttributedString(string: "📱", textColor: presentationData.theme.list.itemPrimaryTextColor),
                text: text,
                placeholder: placeholder,
                type: .regular(capitalization: true, autocorrection: false),
                clearType: .always,
                sectionId: self.section,
                textUpdated: { arguments.updateModel($0) },
                action: {}
            )
        case let .clear(_, text, enabled):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: enabled ? .destructive : .disabled,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: { arguments.reset() }
            )
        case let .info(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private final class NamelessDeviceModelArguments {
    let updateModel: (String) -> Void
    let reset: () -> Void

    init(updateModel: @escaping (String) -> Void, reset: @escaping () -> Void) {
        self.updateModel = updateModel
        self.reset = reset
    }
}

private func entries() -> [NamelessDeviceModelEntry] {
    let value = SGSimpleSettings.shared.deviceModelSpoof
    var out: [NamelessDeviceModelEntry] = []
    var id = 0
    out.append(.header(id: id, text: "НАЗВАНИЕ УСТРОЙСТВА")); id += 1
    out.append(.input(id: id, text: value, placeholder: "iPhone 15 Pro / Samsung Galaxy S24 / …")); id += 1
    out.append(.clear(id: id, text: "Сбросить (использовать реальное)", enabled: !value.isEmpty)); id += 1
    out.append(.info(id: id, text: "Оставьте пустым, чтобы Telegram видел настоящее устройство. Изменения применяются при следующем подключении к серверу."))
    return out
}

public func namelessDeviceModelSpoofController(context: AccountContext, onSave: @escaping () -> Void) -> ViewController {
    let reloadPromise = ValuePromise(true, ignoreRepeated: false)
    let arguments = NamelessDeviceModelArguments(
        updateModel: { value in
            SGSimpleSettings.shared.deviceModelSpoof = value
            onSave()
            reloadPromise.set(true)
        },
        reset: {
            SGSimpleSettings.shared.deviceModelSpoof = ""
            onSave()
            reloadPromise.set(true)
        }
    )

    let signal = combineLatest(reloadPromise.get(), context.sharedContext.presentationData)
    |> map { _, presentationData -> (ItemListControllerState, (ItemListNodeState, NamelessDeviceModelArguments)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Название устройства"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries(),
            style: .blocks,
            ensureVisibleItemTag: nil,
            initialScrollToItem: nil
        )
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
