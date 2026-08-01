import Foundation
import UIKit
import SGLogging

public extension Notification.Name {
    /// Posted when the set of installed plugins, their enabled state, or their contributed
    /// settings rows changed. Screens showing either list observe this.
    static let megramPluginsDidChange = Notification.Name("megram.plugins.didChange")
}

/// Loads plugins, keeps their runtimes alive, and fans app events out to them.
///
/// Single-threaded by design: everything happens on the main queue because every runtime is a
/// `JSContext` and every host call ends in UIKit. The manager is the only object the app talks to.
public final class MGPluginManager {
    public static let shared = MGPluginManager()

    private var runtimes: [String: MGPluginRuntime] = [:]
    private var isStarted = false
    private weak var host: MGPluginHostDelegate?

    private init() {}

    // MARK: - Lifecycle

    /// Installs the host bridge and loads every enabled plugin. Safe to call more than once; the
    /// second call only refreshes the host.
    public func start(host: MGPluginHostDelegate) {
        assert(Thread.isMainThread)
        self.host = host
        guard !self.isStarted else {
            return
        }
        self.isStarted = true
        self.reload()
        self.dispatch(hook: MGPluginHook.appStart, arguments: [])
    }

    /// Tears every runtime down and loads the current on-disk set again. Called after an install,
    /// a removal, or an enable/disable.
    public func reload() {
        assert(Thread.isMainThread)
        for (_, runtime) in self.runtimes {
            runtime.dispose()
        }
        self.runtimes.removeAll()

        for descriptor in MGBuiltinPlugins.all {
            self.load(plugin: descriptor.installedPlugin, source: descriptor.source)
        }
        for plugin in MGPluginStore.shared.installedPlugins() where plugin.isEnabled {
            guard let source = MGPluginStore.shared.source(of: plugin) else {
                continue
            }
            self.load(plugin: plugin, source: source)
        }

        NotificationCenter.default.post(name: .megramPluginsDidChange, object: nil)
    }

    private func load(plugin: MGInstalledPlugin, source: String) {
        let runtime = MGPluginRuntime(
            plugin: plugin,
            source: source,
            host: self.host,
            onSettingsChanged: {
                NotificationCenter.default.post(name: .megramPluginsDidChange, object: nil)
            },
            onLog: { pluginId, message in
                SGLogger.shared.log("MGPlugin", "[\(pluginId)] \(message)")
            }
        )
        guard let runtime else {
            SGLogger.shared.log("MGPlugin", "[\(plugin.id)] failed to create JavaScript context")
            return
        }
        self.runtimes[plugin.id] = runtime
    }

    // MARK: - Events

    public func dispatch(hook: String, arguments: [Any] = []) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.dispatch(hook: hook, arguments: arguments)
            }
            return
        }
        for (_, runtime) in self.runtimes {
            runtime.dispatch(hook: hook, arguments: arguments)
        }
    }

    public func dispatchMessageReceived(_ message: MGPluginMessage) {
        self.dispatch(hook: MGPluginHook.messageReceive, arguments: [message.jsRepresentation])
    }

    public func dispatchMessageSent(_ message: MGPluginMessage) {
        self.dispatch(hook: MGPluginHook.messageSend, arguments: [message.jsRepresentation])
    }

    public func dispatchChatOpened(peerId: String) {
        self.dispatch(hook: MGPluginHook.chatOpen, arguments: [peerId])
    }

    public func dispatchChatClosed(peerId: String) {
        self.dispatch(hook: MGPluginHook.chatClose, arguments: [peerId])
    }

    public func dispatchAppForeground() {
        self.dispatch(hook: MGPluginHook.appForeground, arguments: [])
    }

    public func dispatchAppBackground() {
        self.dispatch(hook: MGPluginHook.appBackground, arguments: [])
    }

    /// Called when the user taps a notification a plugin scheduled. `userInfo` is the notification's
    /// own, so the plugin that scheduled it is the only one told about the tap.
    public func dispatchNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let pluginId = userInfo["megram_plugin_id"] as? String else {
            return
        }
        let identifier = userInfo["megram_notification_id"] as? String ?? ""
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.dispatchNotificationTap(userInfo: userInfo)
            }
            return
        }
        self.runtimes[pluginId]?.dispatch(
            hook: MGPluginHook.notificationTap,
            arguments: [["id": identifier]]
        )
    }

    // MARK: - Settings rows contributed by plugins

    public func settingsRows() -> [MGPluginSettingsRow] {
        assert(Thread.isMainThread)
        // Stable order: by plugin id, then by the order the plugin added its rows.
        return self.runtimes
            .sorted { $0.key < $1.key }
            .flatMap { $0.value.settingsRows }
    }

    public func performSettingsRow(_ row: MGPluginSettingsRow) {
        assert(Thread.isMainThread)
        guard !row.hookName.isEmpty else {
            return
        }
        self.runtimes[row.pluginId]?.dispatch(hook: row.hookName, arguments: [])
    }

    // MARK: - Install / enable / remove

    /// Installs and immediately loads. Throws `MGPluginInstallError` so the caller can show the
    /// reason verbatim.
    @discardableResult
    public func install(from url: URL) throws -> MGInstalledPlugin {
        let plugin = try MGPluginStore.shared.install(from: url)
        self.reload()
        return plugin
    }

    @discardableResult
    public func install(source: String, fileName: String) throws -> MGInstalledPlugin {
        let plugin = try MGPluginStore.shared.install(source: source, fileName: fileName)
        self.reload()
        return plugin
    }

    public func setEnabled(_ enabled: Bool, pluginId: String) {
        MGPluginStore.shared.setEnabled(enabled, pluginId: pluginId)
        self.reload()
    }

    public func remove(pluginId: String) {
        MGPluginStore.shared.remove(pluginId: pluginId)
        self.reload()
    }

    /// User-visible plugins. Built-ins are deliberately absent — they are part of the client, not
    /// something the user installed or can turn off.
    public func visiblePlugins() -> [MGInstalledPlugin] {
        return MGPluginStore.shared.installedPlugins()
    }
}
