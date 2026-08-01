import Foundation
import UIKit
import JavaScriptCore
import UserNotifications

// MARK: - One plugin, one JavaScript context
//
// Each plugin gets its own `JSVirtualMachine`, so a plugin that throws, leaks or spins cannot
// reach another plugin's objects or stall it. Everything runs on the main thread: JSContext is
// not thread-safe, and every host call below ends in UIKit anyway. Work that must not block the
// UI (network) is dispatched natively and hops back before touching the context.

final class MGPluginRuntime {
    let plugin: MGInstalledPlugin

    private let virtualMachine: JSVirtualMachine
    private let context: JSContext
    private weak var host: MGPluginHostDelegate?

    /// hook name → callbacks. A plugin may register several callbacks for one hook.
    private var hooks: [String: [JSValue]] = [:]
    private(set) var settingsRows: [MGPluginSettingsRow] = []

    private var timers: [Int: DispatchWorkItem] = [:]
    private var repeatingTimers: Set<Int> = []
    private var nextTimerId = 1
    private var isDisposed = false

    private let onSettingsChanged: () -> Void
    private let onLog: (String, String) -> Void

    init?(
        plugin: MGInstalledPlugin,
        source: String,
        host: MGPluginHostDelegate?,
        onSettingsChanged: @escaping () -> Void,
        onLog: @escaping (String, String) -> Void
    ) {
        guard let virtualMachine = JSVirtualMachine(), let context = JSContext(virtualMachine: virtualMachine) else {
            return nil
        }
        self.plugin = plugin
        self.virtualMachine = virtualMachine
        self.context = context
        self.host = host
        self.onSettingsChanged = onSettingsChanged
        self.onLog = onLog

        context.name = "megram.plugin.\(plugin.id)"
        context.exceptionHandler = { [weak self] _, exception in
            guard let self else {
                return
            }
            let description = exception?.toString() ?? "unknown error"
            let line = exception?.objectForKeyedSubscript("line")?.toString() ?? "?"
            self.onLog(self.plugin.id, "JS exception at line \(line): \(description)")
        }

        self.installAPI()

        // `evaluateScript(withSourceURL:)` makes stack traces name the plugin file.
        context.evaluateScript(source, withSourceURL: plugin.fileURL)
    }

    deinit {
        self.dispose()
    }

    /// Cancels timers and drops callbacks. After this the context is inert even if JS still holds
    /// references to its own closures.
    func dispose() {
        guard !self.isDisposed else {
            return
        }
        self.isDisposed = true
        for (_, item) in self.timers {
            item.cancel()
        }
        self.timers.removeAll()
        self.repeatingTimers.removeAll()
        self.hooks.removeAll()
        self.settingsRows.removeAll()
        self.context.exceptionHandler = nil
    }

    // MARK: - Hook dispatch

    func dispatch(hook: String, arguments: [Any]) {
        guard !self.isDisposed, let callbacks = self.hooks[hook], !callbacks.isEmpty else {
            return
        }
        for callback in callbacks {
            callback.call(withArguments: arguments)
        }
    }

    func hasHook(_ hook: String) -> Bool {
        return !(self.hooks[hook] ?? []).isEmpty
    }

    // MARK: - API installation

    private func installAPI() {
        let mg = JSValue(newObjectIn: self.context)
        guard let mg else {
            return
        }
        let pluginId = self.plugin.id
        let store = MGPluginStore.shared

        // --- Logging & simple UI -------------------------------------------------------------

        let log: @convention(block) (JSValue?) -> Void = { [weak self] value in
            guard let self else {
                return
            }
            self.onLog(pluginId, value?.toString() ?? "")
        }
        mg.setObject(log, forKeyedSubscript: "log" as NSString)

        let toast: @convention(block) (JSValue?) -> Void = { [weak self] value in
            guard let self, let text = value?.toString() else {
                return
            }
            self.host?.pluginHostPresentToast(text)
        }
        mg.setObject(toast, forKeyedSubscript: "toast" as NSString)

        // `alert(message)` and `alert(title, message[, callback])` are both accepted: the
        // Whitegram dialect uses the single-argument form and porting a plugin should not require
        // touching every call site.
        let alert: @convention(block) (JSValue?, JSValue?, JSValue?) -> Void = { [weak self] first, second, third in
            guard let self else {
                return
            }
            let title: String?
            let message: String
            var completion: JSValue?
            if let second, !second.isUndefined, !second.isNull, !second.isObject {
                title = first?.toString()
                message = second.toString() ?? ""
                completion = third
            } else {
                title = nil
                message = first?.toString() ?? ""
                completion = (second?.isObject ?? false) ? second : third
            }
            let callback = completion
            self.host?.pluginHostPresentAlert(title: title, message: message, completion: {
                callback?.call(withArguments: [])
            })
        }
        mg.setObject(alert, forKeyedSubscript: "alert" as NSString)

        let haptic: @convention(block) (JSValue?) -> Void = { value in
            let style = value?.toString() ?? "light"
            switch style {
            case "success", "warning", "error":
                let generator = UINotificationFeedbackGenerator()
                let type: UINotificationFeedbackGenerator.FeedbackType
                switch style {
                case "success": type = .success
                case "warning": type = .warning
                default: type = .error
                }
                generator.notificationOccurred(type)
            case "heavy":
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            case "medium":
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            default:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        mg.setObject(haptic, forKeyedSubscript: "haptic" as NSString)
        mg.setObject(haptic, forKeyedSubscript: "vibrate" as NSString)

        let copy: @convention(block) (JSValue?) -> Void = { value in
            UIPasteboard.general.string = value?.toString() ?? ""
        }
        mg.setObject(copy, forKeyedSubscript: "copy" as NSString)

        let clipboard: @convention(block) () -> String = {
            return UIPasteboard.general.string ?? ""
        }
        mg.setObject(clipboard, forKeyedSubscript: "getClipboard" as NSString)

        let isDarkMode: @convention(block) () -> Bool = {
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
        mg.setObject(isDarkMode, forKeyedSubscript: "isDarkMode" as NSString)

        let screenSize: @convention(block) () -> [String: Double] = {
            let bounds = UIScreen.main.bounds
            return ["width": Double(bounds.width), "height": Double(bounds.height)]
        }
        mg.setObject(screenSize, forKeyedSubscript: "screenSize" as NSString)

        let openURL: @convention(block) (JSValue?) -> Void = { [weak self] value in
            guard let self, let url = value?.toString() else {
                return
            }
            self.host?.pluginHostOpenURL(url)
        }
        mg.setObject(openURL, forKeyedSubscript: "openURL" as NSString)

        // --- Storage -------------------------------------------------------------------------

        let getStorage: @convention(block) (JSValue?) -> Any? = { key in
            guard let key = key?.toString() else {
                return nil
            }
            return store.setting(pluginId: pluginId, key: key)
        }
        mg.setObject(getStorage, forKeyedSubscript: "getStorage" as NSString)

        let setStorage: @convention(block) (JSValue?, JSValue?) -> Void = { key, value in
            guard let key = key?.toString() else {
                return
            }
            store.setSetting(pluginId: pluginId, key: key, value: value?.toString())
        }
        mg.setObject(setStorage, forKeyedSubscript: "setStorage" as NSString)

        let removeStorage: @convention(block) (JSValue?) -> Void = { key in
            guard let key = key?.toString() else {
                return
            }
            store.setSetting(pluginId: pluginId, key: key, value: nil)
        }
        mg.setObject(removeStorage, forKeyedSubscript: "removeStorage" as NSString)

        let clearStorage: @convention(block) () -> Void = {
            store.clearSettings(pluginId: pluginId)
        }
        mg.setObject(clearStorage, forKeyedSubscript: "clearStorage" as NSString)

        let dataDir: @convention(block) () -> String = {
            return store.ensuredDataDirectoryPath(pluginId: pluginId)
        }
        mg.setObject(dataDir, forKeyedSubscript: "dataDirectory" as NSString)

        // --- Network -------------------------------------------------------------------------

        let request: @convention(block) (JSValue?, JSValue?, JSValue?, JSValue?) -> Void = { urlValue, methodValue, bodyValue, callback in
            guard let urlString = urlValue?.toString(), let url = URL(string: urlString) else {
                callback?.call(withArguments: ["invalid_url", ""])
                return
            }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = (methodValue?.toString() ?? "GET").uppercased()
            if let body = bodyValue?.toString(), !body.isEmpty, urlRequest.httpMethod != "GET" {
                urlRequest.httpBody = body.data(using: .utf8)
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            URLSession.shared.dataTask(with: urlRequest) { data, _, error in
                let errorText = error?.localizedDescription
                let text = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                // Back to the main thread: the callback re-enters the context.
                DispatchQueue.main.async {
                    callback?.call(withArguments: [errorText as Any? ?? NSNull(), text])
                }
            }.resume()
        }
        mg.setObject(request, forKeyedSubscript: "request" as NSString)

        // --- Hooks ---------------------------------------------------------------------------

        let on: @convention(block) (JSValue?, JSValue?) -> Void = { [weak self] hookValue, callback in
            guard let self, let hook = hookValue?.toString(), let callback, !callback.isUndefined else {
                return
            }
            self.hooks[hook, default: []].append(callback)
        }
        mg.setObject(on, forKeyedSubscript: "on" as NSString)

        let off: @convention(block) (JSValue?) -> Void = { [weak self] hookValue in
            guard let self, let hook = hookValue?.toString() else {
                return
            }
            self.hooks.removeValue(forKey: hook)
        }
        mg.setObject(off, forKeyedSubscript: "off" as NSString)

        let emit: @convention(block) (JSValue?, JSValue?) -> Void = { [weak self] hookValue, payload in
            guard let self, let hook = hookValue?.toString() else {
                return
            }
            let arguments: [Any] = (payload == nil || payload!.isUndefined) ? [] : [payload!]
            self.dispatch(hook: hook, arguments: arguments)
        }
        mg.setObject(emit, forKeyedSubscript: "emit" as NSString)

        // --- Telegram ------------------------------------------------------------------------

        let currentChat: @convention(block) () -> String = { [weak self] in
            return self?.host?.pluginHostCurrentChatPeerId() ?? ""
        }
        mg.setObject(currentChat, forKeyedSubscript: "getCurrentChat" as NSString)

        let accountId: @convention(block) () -> String = { [weak self] in
            return self?.host?.pluginHostAccountId() ?? ""
        }
        mg.setObject(accountId, forKeyedSubscript: "getAccountId" as NSString)

        let openChat: @convention(block) (JSValue?) -> Void = { [weak self] value in
            guard let self, let peerId = value?.toString(), !peerId.isEmpty else {
                return
            }
            self.host?.pluginHostOpenChat(peerId: peerId)
        }
        mg.setObject(openChat, forKeyedSubscript: "openChat" as NSString)

        let getInputText: @convention(block) () -> String = { [weak self] in
            return self?.host?.pluginHostInputText() ?? ""
        }
        mg.setObject(getInputText, forKeyedSubscript: "getInputText" as NSString)

        let setInputText: @convention(block) (JSValue?) -> Void = { [weak self] value in
            guard let self else {
                return
            }
            self.host?.pluginHostSetInputText(value?.toString() ?? "")
        }
        mg.setObject(setInputText, forKeyedSubscript: "setInputText" as NSString)

        let sendMessage: @convention(block) () -> Void = { [weak self] in
            self?.host?.pluginHostSendCurrentInput()
        }
        mg.setObject(sendMessage, forKeyedSubscript: "sendMessage" as NSString)

        // --- Screens -------------------------------------------------------------------------

        let pushWebView: @convention(block) (JSValue?, JSValue?) -> Void = { [weak self] titleValue, htmlValue in
            guard let self else {
                return
            }
            self.host?.pluginHostPushWebView(
                title: titleValue?.toString() ?? "",
                html: htmlValue?.toString() ?? ""
            )
        }
        mg.setObject(pushWebView, forKeyedSubscript: "pushWebView" as NSString)

        let pushURL: @convention(block) (JSValue?, JSValue?) -> Void = { [weak self] titleValue, urlValue in
            guard let self, let url = urlValue?.toString() else {
                return
            }
            self.host?.pluginHostPushURL(title: titleValue?.toString() ?? "", url: url)
        }
        mg.setObject(pushURL, forKeyedSubscript: "pushWebViewURL" as NSString)

        // --- Settings rows ---------------------------------------------------------------------

        let addSettingsRow: @convention(block) (JSValue?) -> Void = { [weak self] descriptor in
            guard let self, let descriptor, descriptor.isObject else {
                return
            }
            let id = descriptor.objectForKeyedSubscript("id")?.toString() ?? ""
            guard !id.isEmpty else {
                return
            }
            let row = MGPluginSettingsRow(
                pluginId: pluginId,
                id: id,
                title: descriptor.objectForKeyedSubscript("title")?.toString() ?? "",
                subtitle: descriptor.objectForKeyedSubscript("subtitle")?.toString() ?? "",
                hookName: descriptor.objectForKeyedSubscript("hookName")?.toString() ?? ""
            )
            // Re-adding an existing id updates it in place: plugins rebuild their whole row list
            // on every state change and expect the order to stay put.
            if let index = self.settingsRows.firstIndex(where: { $0.id == id }) {
                self.settingsRows[index] = row
            } else {
                self.settingsRows.append(row)
            }
            self.onSettingsChanged()
        }
        mg.setObject(addSettingsRow, forKeyedSubscript: "addSettingsRow" as NSString)

        let removeSettingsRow: @convention(block) (JSValue?) -> Void = { [weak self] idValue in
            guard let self, let id = idValue?.toString() else {
                return
            }
            self.settingsRows.removeAll { $0.id == id }
            self.onSettingsChanged()
        }
        mg.setObject(removeSettingsRow, forKeyedSubscript: "removeSettingsRow" as NSString)

        // --- Notifications -----------------------------------------------------------------

        let notifications = JSValue(newObjectIn: self.context)
        if let notifications {
            let requestPermission: @convention(block) (JSValue?) -> Void = { callback in
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async {
                        callback?.call(withArguments: [granted])
                    }
                }
            }
            notifications.setObject(requestPermission, forKeyedSubscript: "requestPermission" as NSString)

            let schedule: @convention(block) (JSValue?) -> Void = { descriptor in
                guard let descriptor, descriptor.isObject else {
                    return
                }
                let identifier = descriptor.objectForKeyedSubscript("id")?.toString() ?? UUID().uuidString
                let content = UNMutableNotificationContent()
                content.title = descriptor.objectForKeyedSubscript("title")?.toString() ?? ""
                if let subtitle = descriptor.objectForKeyedSubscript("subtitle")?.toString(), !subtitle.isEmpty {
                    content.subtitle = subtitle
                }
                content.body = descriptor.objectForKeyedSubscript("body")?.toString() ?? ""
                if descriptor.objectForKeyedSubscript("sound")?.toBool() ?? true {
                    content.sound = .default
                }
                if let badge = descriptor.objectForKeyedSubscript("badge"), badge.isNumber {
                    content.badge = NSNumber(value: badge.toInt32())
                }
                content.userInfo = ["megram_plugin_id": pluginId, "megram_notification_id": identifier]

                // UNTimeIntervalNotificationTrigger rejects intervals below 1s outright, and a
                // repeating trigger below 60s, so a plugin asking for "as soon as possible" gets
                // the smallest interval iOS will actually accept rather than a silent no-op.
                let repeats = descriptor.objectForKeyedSubscript("repeating")?.toBool() ?? false
                let requested = descriptor.objectForKeyedSubscript("delay")?.toDouble() ?? 0.0
                let interval = max(repeats ? 60.0 : 1.0, requested.isFinite ? requested : 0.0)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: repeats)

                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }
            notifications.setObject(schedule, forKeyedSubscript: "schedule" as NSString)

            let cancel: @convention(block) (JSValue?) -> Void = { idValue in
                guard let identifier = idValue?.toString() else {
                    return
                }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            }
            notifications.setObject(cancel, forKeyedSubscript: "cancel" as NSString)

            // Only this plugin's own notifications — one plugin must not be able to wipe another's.
            let cancelAll: @convention(block) () -> Void = {
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    let identifiers = requests
                        .filter { ($0.content.userInfo["megram_plugin_id"] as? String) == pluginId }
                        .map { $0.identifier }
                    guard !identifiers.isEmpty else {
                        return
                    }
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
                }
            }
            notifications.setObject(cancelAll, forKeyedSubscript: "cancelAll" as NSString)

            let list: @convention(block) (JSValue?) -> Void = { callback in
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    let items: [[String: Any]] = requests
                        .filter { ($0.content.userInfo["megram_plugin_id"] as? String) == pluginId }
                        .map { request in
                            return [
                                "id": request.identifier,
                                "title": request.content.title,
                                "body": request.content.body
                            ]
                        }
                    DispatchQueue.main.async {
                        callback?.call(withArguments: [items])
                    }
                }
            }
            notifications.setObject(list, forKeyedSubscript: "list" as NSString)

            let status: @convention(block) (JSValue?) -> Void = { callback in
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    let text: String
                    switch settings.authorizationStatus {
                    case .authorized: text = "authorized"
                    case .provisional: text = "provisional"
                    case .ephemeral: text = "ephemeral"
                    case .denied: text = "denied"
                    case .notDetermined: text = "notDetermined"
                    @unknown default: text = "unknown"
                    }
                    DispatchQueue.main.async {
                        callback?.call(withArguments: [text])
                    }
                }
            }
            notifications.setObject(status, forKeyedSubscript: "status" as NSString)

            mg.setObject(notifications, forKeyedSubscript: "notifications" as NSString)
        }

        // --- Timers & console ----------------------------------------------------------------

        self.installTimers()
        self.installConsole()

        mg.setObject(self.plugin.manifest.id, forKeyedSubscript: "pluginId" as NSString)
        mg.setObject(self.plugin.manifest.version, forKeyedSubscript: "pluginVersion" as NSString)

        self.context.setObject(mg, forKeyedSubscript: "mg" as NSString)
        // Whitegram plugins address the host as `wg`. Same object, so a ported plugin runs
        // unmodified and a plugin written for Megram reads naturally.
        self.context.setObject(mg, forKeyedSubscript: "wg" as NSString)

        self.context.evaluateScript(MGPluginRuntime.prelude)
    }

    /// JS-side sugar layered over the native primitives. Kept here rather than in Swift because
    /// these are pure shapes — aliases, argument juggling, namespacing.
    private static let prelude = """
    (function () {
        'use strict';
        if (typeof mg === 'undefined') { return; }

        mg.fetch = function (url, callback) { mg.request(url, 'GET', '', callback); };
        mg.get = mg.fetch;
        mg.post = function (url, body, callback) { mg.request(url, 'POST', body, callback); };

        mg.notify = function (title, body, delay) {
            mg.notifications.schedule({
                id: 'mg_' + mg.pluginId + '_' + Date.now(),
                title: title,
                body: body,
                delay: delay || 1
            });
        };
        mg.requestNotificationPermission = function (cb) { mg.notifications.requestPermission(cb); };

        mg.settings = {
            addRow: function (row) { mg.addSettingsRow(row); },
            removeRow: function (id) { mg.removeSettingsRow(id); }
        };

        mg.ui = {
            pushWebView: mg.pushWebView,
            pushURL: mg.pushWebViewURL,
            toast: mg.toast,
            alert: mg.alert
        };
    })();
    """

    private func installTimers() {
        let setTimer: @convention(block) (JSValue?, JSValue?, Bool) -> Int = { [weak self] callback, delayValue, repeats in
            guard let self, let callback, !callback.isUndefined else {
                return 0
            }
            let id = self.nextTimerId
            self.nextTimerId += 1
            // JS timers are in milliseconds; a missing or nonsensical delay means "next runloop".
            let milliseconds = delayValue?.toDouble() ?? 0.0
            let interval = max(0.0, milliseconds.isFinite ? milliseconds : 0.0) / 1000.0
            if repeats {
                self.repeatingTimers.insert(id)
            }
            self.scheduleTimer(id: id, interval: interval, repeats: repeats, callback: callback)
            return id
        }

        let setTimeout: @convention(block) (JSValue?, JSValue?) -> Int = { callback, delay in
            return setTimer(callback, delay, false)
        }
        let setInterval: @convention(block) (JSValue?, JSValue?) -> Int = { callback, delay in
            return setTimer(callback, delay, true)
        }
        let clearTimer: @convention(block) (JSValue?) -> Void = { [weak self] idValue in
            guard let self, let id = idValue?.toNumber()?.intValue else {
                return
            }
            self.timers[id]?.cancel()
            self.timers.removeValue(forKey: id)
            self.repeatingTimers.remove(id)
        }

        self.context.setObject(setTimeout, forKeyedSubscript: "setTimeout" as NSString)
        self.context.setObject(setInterval, forKeyedSubscript: "setInterval" as NSString)
        self.context.setObject(clearTimer, forKeyedSubscript: "clearTimeout" as NSString)
        self.context.setObject(clearTimer, forKeyedSubscript: "clearInterval" as NSString)
    }

    private func scheduleTimer(id: Int, interval: TimeInterval, repeats: Bool, callback: JSValue) {
        let item = DispatchWorkItem { [weak self] in
            guard let self, !self.isDisposed else {
                return
            }
            // A repeating timer re-arms only while it is still registered, so clearInterval from
            // inside the callback stops it rather than letting one more tick through.
            let stillArmed = self.repeatingTimers.contains(id)
            if !repeats {
                self.timers.removeValue(forKey: id)
            }
            callback.call(withArguments: [])
            if repeats, stillArmed, self.repeatingTimers.contains(id) {
                self.scheduleTimer(id: id, interval: interval, repeats: true, callback: callback)
            }
        }
        self.timers[id] = item
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: item)
    }

    private func installConsole() {
        guard let console = JSValue(newObjectIn: self.context) else {
            return
        }
        let write: @convention(block) (JSValue?) -> Void = { [weak self] value in
            guard let self else {
                return
            }
            self.onLog(self.plugin.id, value?.toString() ?? "")
        }
        for name in ["log", "info", "warn", "error", "debug"] {
            console.setObject(write, forKeyedSubscript: name as NSString)
        }
        self.context.setObject(console, forKeyedSubscript: "console" as NSString)
    }
}
