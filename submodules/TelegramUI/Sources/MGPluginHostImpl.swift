import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import PresentationDataUtils
import AccountContext
import UndoUI
import MGPluginKit

// MARK: - The app side of the plugin API
//
// `MGPluginKit` knows how to run JavaScript and how to talk to iOS. It deliberately knows nothing
// about Telegram, so everything that needs an account, a chat or the navigation stack arrives
// through this object. It is installed once at launch and resolves the *current* account context
// on every call — a plugin outlives account switches.

final class MGPluginHostImpl: MGPluginHostDelegate {
    static let shared = MGPluginHostImpl()

    /// Set by `AppDelegate` once an authorized context exists. Returning nil is normal (locked
    /// app, logged out), and every method below degrades to a no-op in that case.
    var resolveContext: (() -> AccountContext?)?

    private init() {}

    private var context: AccountContext? {
        return self.resolveContext?()
    }

    private var navigationController: NavigationController? {
        return self.context?.sharedContext.mainWindow?.viewController as? NavigationController
    }

    // MARK: - UI

    func pluginHostPresentToast(_ text: String) {
        guard let context = self.context, !text.isEmpty else {
            return
        }
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let controller = UndoOverlayController(
            presentationData: presentationData,
            content: .info(title: nil, text: text, timeout: nil, customUndoText: nil),
            elevatedLayout: false,
            action: { _ in return false }
        )
        self.present(controller)
    }

    func pluginHostPresentAlert(title: String?, message: String, completion: (() -> Void)?) {
        guard let context = self.context else {
            completion?()
            return
        }
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let controller = textAlertController(
            context: context,
            title: title,
            text: message,
            actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {
                completion?()
            })]
        )
        self.present(controller)
    }

    private func present(_ controller: ViewController) {
        self.context?.sharedContext.mainWindow?.present(controller, on: .root)
    }

    func pluginHostOpenURL(_ url: String) {
        guard let context = self.context, !url.isEmpty else {
            return
        }
        context.sharedContext.applicationBindings.openUrl(url)
    }

    // MARK: - Telegram

    func pluginHostCurrentChatPeerId() -> String? {
        guard let controller = self.currentChatController() else {
            return nil
        }
        guard let peerId = controller.chatLocation.peerId else {
            return nil
        }
        return "\(peerId.id._internalGetInt64Value())"
    }

    func pluginHostAccountId() -> String? {
        guard let context = self.context else {
            return nil
        }
        return "\(context.account.peerId.id._internalGetInt64Value())"
    }

    func pluginHostOpenChat(peerId: String) {
        guard let context = self.context,
              let navigationController = self.navigationController,
              let rawId = Int64(peerId)
        else {
            return
        }
        // Plugins carry the numeric part of a peer id — the same value `getCurrentChat` handed
        // them — so the namespace has to be recovered by looking for whichever peer owns it.
        let candidates = [
            PeerId(namespace: Namespaces.Peer.CloudUser, id: PeerId.Id._internalFromInt64Value(rawId)),
            PeerId(namespace: Namespaces.Peer.CloudChannel, id: PeerId.Id._internalFromInt64Value(rawId)),
            PeerId(namespace: Namespaces.Peer.CloudGroup, id: PeerId.Id._internalFromInt64Value(rawId))
        ]
        let _ = (context.account.postbox.transaction { transaction -> Peer? in
            for candidate in candidates {
                if let peer = transaction.getPeer(candidate) {
                    return peer
                }
            }
            return nil
        }
        |> deliverOnMainQueue).startStandalone(next: { peer in
            guard let peer else {
                return
            }
            context.sharedContext.navigateToChatController(NavigateToChatControllerParams(
                navigationController: navigationController,
                context: context,
                chatLocation: .peer(EnginePeer(peer))
            ))
        })
    }

    // MARK: - Chat input
    //
    // Reading and writing the composer means reaching into the open chat's interface state, which
    // only `ChatControllerImpl` may mutate. Until that path is exposed deliberately these report
    // "no chat", which is the same answer a plugin gets when no chat is open — so a plugin written
    // against them behaves correctly rather than incorrectly.

    func pluginHostInputText() -> String? {
        return nil
    }

    func pluginHostSetInputText(_ text: String) {
    }

    func pluginHostSendCurrentInput() {
    }

    // MARK: - Screens
    //
    // `pushWebView` renders plugin-authored HTML, which needs a WebKit container wired into
    // Telegram's navigation. Until that container exists, a plugin's HTML is surfaced as an alert
    // rather than dropped silently — the plugin still gets to say something, and the user is not
    // left tapping a button that does nothing.

    func pluginHostPushWebView(title: String, html: String) {
        let plain = html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.pluginHostPresentAlert(title: title.isEmpty ? nil : title, message: plain, completion: nil)
    }

    func pluginHostPushURL(title: String, url: String) {
        self.pluginHostOpenURL(url)
    }

    func pluginHostSettingsRowsDidChange() {
    }

    // MARK: - Helpers

    private func currentChatController() -> ChatControllerImpl? {
        guard let navigationController = self.navigationController else {
            return nil
        }
        for controller in navigationController.viewControllers.reversed() {
            if let chatController = controller as? ChatControllerImpl {
                return chatController
            }
        }
        return nil
    }
}
