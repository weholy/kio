import Foundation
import UIKit
import Display
import SwiftSignalKit
import AccountContext
import TelegramPresentationData

// MARK: - Nameless account switcher
//
// Presents an action sheet with every logged-in account. Tapping a row switches to that
// account via SharedAccountContext.switchToAccount. No new UI framework, no navigation
// rewiring — same primitive Telegram itself uses when switching from the accounts list
// in Settings, just surfaced as a single tap from anywhere.

public func namelessShowAccountSwitcher(context: AccountContext, present: @escaping (ViewController, Any?) -> Void) {
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let currentAccountId = context.account.id

    let _ = (context.sharedContext.activeAccountsWithInfo
    |> take(1)
    |> deliverOnMainQueue).startStandalone(next: { primary, accounts in
        let actionSheet = ActionSheetController(presentationData: presentationData)
        var items: [ActionSheetItem] = []

        for accountInfo in accounts {
            let title: String
            if let username = accountInfo.peer.addressName, !username.isEmpty {
                title = "\(accountInfo.peer.debugDisplayTitle)  @\(username)"
            } else {
                title = accountInfo.peer.debugDisplayTitle
            }
            let isCurrent = accountInfo.account.id == currentAccountId
            items.append(ActionSheetButtonItem(title: isCurrent ? "\(title)  ✓" : title, color: .accent, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
                guard !isCurrent else { return }
                context.sharedContext.switchToAccount(id: accountInfo.account.id, fromSettingsController: nil, withChatListController: nil)
            }))
        }

        actionSheet.setItemGroups([
            ActionSheetItemGroup(items: items),
            ActionSheetItemGroup(items: [
                ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .default, enabled: true, action: { [weak actionSheet] in actionSheet?.dismissAnimated() })
            ])
        ])
        present(actionSheet, nil)
    })
}
