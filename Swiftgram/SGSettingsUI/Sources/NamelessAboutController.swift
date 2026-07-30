// MARK: nameless
import SGSimpleSettings
import Foundation
import UIKit
import Display
import SwiftSignalKit
import AccountContext
import ItemListUI
import TelegramPresentationData
import PresentationDataUtils
import UndoUI

private enum NASection: Int32 {
    case links = 0
    case info = 1
}

private enum NAEntry: ItemListNodeEntry {
    case channelLink
    case developerLink
    case vpnLink
    case infoText

    var section: ItemListSectionId {
        switch self {
        case .channelLink, .developerLink, .vpnLink:
            return NASection.links.rawValue
        case .infoText:
            return NASection.info.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .channelLink: return 0
        case .developerLink: return 1
        case .vpnLink: return 2
        case .infoText: return 10
        }
    }

    static func < (lhs: NAEntry, rhs: NAEntry) -> Bool {
        lhs.stableId < rhs.stableId
    }

    static func == (lhs: NAEntry, rhs: NAEntry) -> Bool {
        switch (lhs, rhs) {
        case (.channelLink, .channelLink): return true
        case (.developerLink, .developerLink): return true
        case (.vpnLink, .vpnLink): return true
        case (.infoText, .infoText): return true
        default: return false
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        switch self {
        case .channelLink:
            return ItemListActionItem(presentationData: presentationData, title: "Канал nameless", kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                if let url = URL(string: "https://t.me/nameless") {
                    UIApplication.shared.open(url)
                }
            })
        case .developerLink:
            return ItemListActionItem(presentationData: presentationData, title: "Разработчик noheya", kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                if let url = URL(string: "https://t.me/noheya") {
                    UIApplication.shared.open(url)
                }
            })
        case .vpnLink:
            return ItemListActionItem(presentationData: presentationData, title: "Stiven VPN", kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                if let url = URL(string: "https://t.me/StivenVPN") {
                    UIApplication.shared.open(url)
                }
            })
        case .infoText:
            return ItemListTextItem(presentationData: presentationData, text: .plain("nameless — кастомный iOS-клиент Telegram с Liquid Glass, режимом призрака и расширенными функциями."), sectionId: self.section)
        }
    }
}

private final class NAEmptyArguments {
    init() {}
}

public func namelessAboutController(context: AccountContext) -> ViewController {
    let signal: Signal<(ItemListControllerState, (ItemListNodeState, NAEmptyArguments)), NoError> = context.sharedContext.presentationData
        |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, NAEmptyArguments)) in
            let controllerState = ItemListControllerState(
                presentationData: ItemListPresentationData(presentationData),
                title: .text("О nameless"),
                leftNavigationButton: nil,
                rightNavigationButton: nil,
                backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
            )
            let entries: [NAEntry] = [
                .channelLink,
                .developerLink,
                .vpnLink,
                .infoText
            ]
            let listState = ItemListNodeState(
                presentationData: ItemListPresentationData(presentationData),
                entries: entries,
                style: .blocks
            )
            return (controllerState, (listState, NAEmptyArguments()))
    }

    let controller: ViewController = ItemListController(context: context, state: signal)
    return controller
}