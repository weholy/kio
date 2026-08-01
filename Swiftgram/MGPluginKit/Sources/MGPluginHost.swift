import Foundation
import UIKit

/// A row a plugin contributed to its page in Megram settings.
public struct MGPluginSettingsRow: Equatable {
    public let pluginId: String
    public let id: String
    public let title: String
    public let subtitle: String
    /// Hook fired when the row is tapped, e.g. `"onWGN_toggle"`.
    public let hookName: String

    public init(pluginId: String, id: String, title: String, subtitle: String, hookName: String) {
        self.pluginId = pluginId
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.hookName = hookName
    }
}

/// Everything a plugin can ask of the app that `MGPluginKit` cannot do on its own — anything
/// touching Telegram state or the navigation stack.
///
/// The app installs one implementation at launch. Every method is called on the main thread and
/// must tolerate being called when there is no chat on screen: plugins run whether or not the
/// user is looking at anything in particular.
public protocol MGPluginHostDelegate: AnyObject {
    func pluginHostPresentToast(_ text: String)
    func pluginHostPresentAlert(title: String?, message: String, completion: (() -> Void)?)

    func pluginHostCurrentChatPeerId() -> String?
    func pluginHostAccountId() -> String?
    func pluginHostOpenChat(peerId: String)

    func pluginHostInputText() -> String?
    func pluginHostSetInputText(_ text: String)
    func pluginHostSendCurrentInput()

    func pluginHostPushWebView(title: String, html: String)
    func pluginHostPushURL(title: String, url: String)
    func pluginHostOpenURL(_ url: String)

    /// Called after a plugin adds/removes a settings row so an open settings screen can refresh.
    func pluginHostSettingsRowsDidChange()
}

/// Names of the events plugins can subscribe to with `mg.on(...)`.
///
/// Plugins may also subscribe to arbitrary names — settings rows dispatch their own `hookName`,
/// and `mg.emit` lets a plugin talk to itself. These constants only cover the events the app
/// itself raises.
public enum MGPluginHook {
    public static let appStart = "onAppStart"
    public static let appForeground = "onAppForeground"
    public static let appBackground = "onAppBackground"
    public static let messageReceive = "onMessageReceive"
    public static let messageSend = "onMessageSend"
    public static let chatOpen = "onChatOpen"
    public static let chatClose = "onChatClose"
    public static let notificationTap = "onNotificationTap"
    public static let themeChange = "onThemeChange"
    public static let activate = "onActivate"
}

/// Payload for `onMessageReceive` / `onMessageSend`, mirrored into JS as a plain object.
public struct MGPluginMessage {
    public let peerId: String
    public let messageId: String
    public let text: String
    public let isOutgoing: Bool
    public let senderId: String
    public let senderName: String
    public let chatName: String
    public let date: Double
    public let mediaType: String
    public let isMuted: Bool
    public let accountId: String

    public init(
        peerId: String,
        messageId: String,
        text: String,
        isOutgoing: Bool,
        senderId: String = "",
        senderName: String = "",
        chatName: String = "",
        date: Double = 0.0,
        mediaType: String = "",
        isMuted: Bool = false,
        accountId: String = ""
    ) {
        self.peerId = peerId
        self.messageId = messageId
        self.text = text
        self.isOutgoing = isOutgoing
        self.senderId = senderId
        self.senderName = senderName
        self.chatName = chatName
        self.date = date
        self.mediaType = mediaType
        self.isMuted = isMuted
        self.accountId = accountId
    }

    public var jsRepresentation: [String: Any] {
        return [
            "peerId": self.peerId,
            "messageId": self.messageId,
            "text": self.text,
            "isOutgoing": self.isOutgoing,
            "senderId": self.senderId,
            "senderName": self.senderName,
            "chatName": self.chatName,
            "date": self.date,
            "mediaType": self.mediaType,
            "isMuted": self.isMuted,
            "accountId": self.accountId
        ]
    }
}
