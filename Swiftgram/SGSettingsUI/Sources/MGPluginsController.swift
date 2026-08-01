import Foundation
import UIKit
import UniformTypeIdentifiers
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import MGPluginKit

// MARK: - Plugins screen
//
// Lists what the user installed and nothing else: built-in plugins are part of the client and
// never appear here. "+" opens the system file browser; a plugin can also arrive by tapping a
// `.plugin` file in a chat, which routes to the same installer.

private enum MGPluginsEntry: ItemListNodeEntry {
    case empty(id: Int, text: String)
    case pluginSwitch(id: Int, section: Int, name: String, detail: String?, isEnabled: Bool, pluginId: String)
    case pluginRemove(id: Int, section: Int, pluginId: String)
    case rowsHeader(id: Int, text: String)
    case pluginRow(id: Int, title: String, subtitle: String, row: MGPluginSettingsRow)

    var section: ItemListSectionId {
        switch self {
        case .empty:
            return 0
        case let .pluginSwitch(_, section, _, _, _, _), let .pluginRemove(_, section, _):
            return ItemListSectionId(section)
        case .rowsHeader, .pluginRow:
            // Contributed rows always sit in their own trailing section, whatever the plugin
            // count, so adding a plugin never renumbers them.
            return 1000
        }
    }

    var stableId: Int {
        switch self {
        case let .empty(id, _),
             let .pluginSwitch(id, _, _, _, _, _),
             let .pluginRemove(id, _, _),
             let .rowsHeader(id, _),
             let .pluginRow(id, _, _, _):
            return id
        }
    }

    static func < (lhs: MGPluginsEntry, rhs: MGPluginsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    static func == (lhs: MGPluginsEntry, rhs: MGPluginsEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.empty(a, t1), .empty(b, t2)):
            return a == b && t1 == t2
        case let (.pluginSwitch(a, s1, n1, d1, e1, p1), .pluginSwitch(b, s2, n2, d2, e2, p2)):
            return a == b && s1 == s2 && n1 == n2 && d1 == d2 && e1 == e2 && p1 == p2
        case let (.pluginRemove(a, s1, p1), .pluginRemove(b, s2, p2)):
            return a == b && s1 == s2 && p1 == p2
        case let (.rowsHeader(a, t1), .rowsHeader(b, t2)):
            return a == b && t1 == t2
        case let (.pluginRow(a, t1, s1, r1), .pluginRow(b, t2, s2, r2)):
            return a == b && t1 == t2 && s1 == s2 && r1 == r2
        default:
            return false
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! MGPluginsArguments
        switch self {
        case let .empty(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .pluginSwitch(_, _, name, detail, isEnabled, pluginId):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: name,
                text: detail,
                value: isEnabled,
                maximumNumberOfLines: 2,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.setEnabled(pluginId, value)
                }
            )
        case let .pluginRemove(_, _, pluginId):
            return ItemListActionItem(
                presentationData: presentationData,
                title: "Удалить плагин",
                kind: .destructive,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.remove(pluginId)
                }
            )
        case let .rowsHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .pluginRow(_, title, subtitle, row):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                label: subtitle,
                labelStyle: .detailText,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: {
                    arguments.performRow(row)
                }
            )
        }
    }
}

private final class MGPluginsArguments {
    let setEnabled: (String, Bool) -> Void
    let remove: (String) -> Void
    let performRow: (MGPluginSettingsRow) -> Void

    init(
        setEnabled: @escaping (String, Bool) -> Void,
        remove: @escaping (String) -> Void,
        performRow: @escaping (MGPluginSettingsRow) -> Void
    ) {
        self.setEnabled = setEnabled
        self.remove = remove
        self.performRow = performRow
    }
}

private func mgPluginsEntries(plugins: [MGInstalledPlugin], rows: [MGPluginSettingsRow]) -> [MGPluginsEntry] {
    var entries: [MGPluginsEntry] = []
    var id = 0

    guard !plugins.isEmpty else {
        entries.append(.empty(id: id, text: "Плагинов пока нет.\n\nНажмите «+», чтобы установить плагин из Файлов, или откройте присланный в чате файл .plugin, .mgplugin, .js или .mjs."))
        return entries
    }

    for (index, plugin) in plugins.enumerated() {
        let section = index + 1

        var detailParts: [String] = []
        if !plugin.manifest.version.isEmpty {
            detailParts.append("v\(plugin.manifest.version)")
        }
        if !plugin.manifest.author.isEmpty {
            detailParts.append(plugin.manifest.author)
        }
        var detail = detailParts.joined(separator: " · ")
        if !plugin.manifest.summary.isEmpty {
            detail = detail.isEmpty ? plugin.manifest.summary : "\(detail)\n\(plugin.manifest.summary)"
        }

        entries.append(.pluginSwitch(
            id: id,
            section: section,
            name: plugin.manifest.name,
            detail: detail.isEmpty ? nil : detail,
            isEnabled: plugin.isEnabled,
            pluginId: plugin.id
        ))
        id += 1
        entries.append(.pluginRemove(id: id, section: section, pluginId: plugin.id))
        id += 1
    }

    // Rows the plugins themselves contributed via `mg.addSettingsRow`.
    if !rows.isEmpty {
        entries.append(.rowsHeader(id: id, text: "НАСТРОЙКИ ПЛАГИНОВ"))
        id += 1
        for row in rows {
            entries.append(.pluginRow(id: id, title: row.title, subtitle: row.subtitle, row: row))
            id += 1
        }
    }

    return entries
}

/// `UIDocumentPickerViewController` holds its delegate weakly, so the delegate keeps itself alive
/// from presentation until one of the two terminal callbacks fires. Both paths release, so this is
/// bounded — the picker always either returns a file or is cancelled.
private final class MGPluginDocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    private let onPick: (URL) -> Void
    private var selfRetain: MGPluginDocumentPickerDelegate?

    init(onPick: @escaping (URL) -> Void) {
        self.onPick = onPick
        super.init()
        self.selfRetain = self
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.selfRetain = nil
        guard let url = urls.first else {
            return
        }
        self.onPick(url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.selfRetain = nil
    }
}

public func mgPluginsController(context: AccountContext) -> ViewController {
    let reloadPromise = ValuePromise(true, ignoreRepeated: false)
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    var presentPickerImpl: ((UIViewController) -> Void)?

    let arguments = MGPluginsArguments(
        setEnabled: { pluginId, value in
            MGPluginManager.shared.setEnabled(value, pluginId: pluginId)
            reloadPromise.set(true)
        },
        remove: { pluginId in
            MGPluginManager.shared.remove(pluginId: pluginId)
            reloadPromise.set(true)
        },
        performRow: { row in
            // The plugin usually rewrites its own rows in response, which posts
            // `.megramPluginsDidChange` and refreshes this list.
            MGPluginManager.shared.performSettingsRow(row)
            reloadPromise.set(true)
        }
    )

    let presentInstallResult: (String, String) -> Void = { title, text in
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

    let install: (URL) -> Void = { url in
        do {
            let plugin = try MGPluginManager.shared.install(from: url)
            reloadPromise.set(true)
            presentInstallResult("Плагин установлен", plugin.manifest.name)
        } catch {
            let message = (error as? MGPluginInstallError)?.errorDescription ?? error.localizedDescription
            presentInstallResult("Не удалось установить", message)
        }
    }

    let addPlugin: () -> Void = {
        guard #available(iOS 14.0, *) else {
            presentInstallResult("Недоступно", "Установка плагинов из Файлов требует iOS 14 или новее.")
            return
        }
        // Everything is selectable rather than filtered to our extensions: `.plugin` and
        // `.mgplugin` have no registered UTI, so a filtered picker would grey out exactly the
        // files the user came for. The installer validates and explains instead.
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = MGPluginDocumentPickerDelegate(onPick: install)
        picker.allowsMultipleSelection = false
        presentPickerImpl?(picker)
    }

    // The list also changes from outside this screen — a `.plugin` file tapped in a chat installs
    // through the same manager. Modelling that as a signal ties the observer's lifetime to the
    // state subscription, so it is torn down exactly when the screen goes away.
    let externalChanges = Signal<Bool, NoError> { subscriber in
        subscriber.putNext(true)
        let observer = NotificationCenter.default.addObserver(
            forName: .megramPluginsDidChange,
            object: nil,
            queue: .main
        ) { _ in
            subscriber.putNext(true)
        }
        return ActionDisposable {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    let pluginsSignal = combineLatest(reloadPromise.get(), externalChanges)
    |> map { _, _ -> ([MGInstalledPlugin], [MGPluginSettingsRow]) in
        return (MGPluginManager.shared.visiblePlugins(), MGPluginManager.shared.settingsRows())
    }

    let signal = combineLatest(pluginsSignal, context.sharedContext.presentationData)
    |> map { pluginsAndRows, presentationData -> (ItemListControllerState, (ItemListNodeState, MGPluginsArguments)) in
        let (plugins, rows) = pluginsAndRows
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Плагины"),
            leftNavigationButton: nil,
            rightNavigationButton: ItemListNavigationButton(
                content: .icon(.add),
                style: .regular,
                enabled: true,
                action: {
                    addPlugin()
                }
            ),
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: mgPluginsEntries(plugins: plugins, rows: rows),
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
    presentPickerImpl = { [weak controller] viewController in
        guard let window = controller?.view.window else {
            return
        }
        // `UIDocumentPickerViewController` is a plain UIKit controller, so it goes through the
        // window's root rather than Telegram's `ViewController.present`, which takes its own type.
        viewController.popoverPresentationController?.sourceView = window
        viewController.popoverPresentationController?.sourceRect = CGRect(
            origin: CGPoint(x: window.bounds.width * 0.5, y: window.bounds.height - 1.0),
            size: CGSize(width: 1.0, height: 1.0)
        )
        window.rootViewController?.present(viewController, animated: true)
    }

    return controller
}
