// MARK: nameless — Features Controller (restructured)
// 4 вкладки: Внешний вид | Режим призрака | Прочие функции | Поиск
import SGSimpleSettings
import SGItemListUI
import ItemListUI
import Foundation
import UIKit
import Display
import SwiftSignalKit
import AccountContext
import TelegramPresentationData
import PresentationDataUtils
import UndoUI
import TelegramCore
import TelegramUIPreferences

// MARK: - Section

private enum NLSectionId: Int32, SGItemListSection {
    case search = 0
    case hero = 1
    case items = 2
    case actions = 3
    // Hub category pills
    case hubPill0 = 10
    case hubPill1 = 11
    case hubPill2 = 12
    case hubPill3 = 13
    case hubPill4 = 14
    case hubPill5 = 15
    case hubPill6 = 16
    case hubPill7 = 17
    case hubPill8 = 18
    case hubPill9 = 19
    case hubPill10 = 20
    case hubActions = 30
}

// MARK: - Settings

private enum NLBoolSetting: String {
    case hidePhoneInSettings
    case roundTabs
    case wideTabBar
    case hideStories
    case hideRecordingButton
    case hideChannelBottomButton
    case disableSendAsButton
    case tabBarSearchEnabled
    case allChatsHidden
    case compactFolderNames
    case messageDoubleTapActionOutgoingEdit
    case showProfileId
    case showDC
    case showCreationDate
    case showRegDate
    case confirmCalls
    case swipeForVideoPIP
    case sendLargePhotos
    case stickerTimestamp
    case forceBuiltInMic
    case rememberLastFolder
    case showDeletedMessages
    case saveDeletedMessagesMedia
    case saveEditHistory
    case enableLocalMessageEditing
    case scrollToTopButtonEnabled
    case enableSavingProtectedContent
    case enableSavingSelfDestructingMessages
    case disableScreenshotDetection
    case disableSecretChatBlurOnScreenshot
    case disableAllAds
    case hideProxySponsor
    case disableZalgoText
    case quickTranslateButton
    case enableLocalPremium
    case uploadSpeedBoost
    case unlimitedFavoriteStickers
    case storyStealthMode
    case warnOnStoriesOpen
    case disableSwipeToRecordStory
    case forceSystemSharing
    case startTelescopeWithRearCam
    case disableGalleryCamera
    case disableGalleryCameraPreview
    // Privacy
    case bypassProtectedContent
    case removeSpoilersEverywhere
    case antiScamEnabled
    case warnBeforeCall
    // Notifications
    case localNotificationsEnabled
    case disableCompactNumbers
    // Context menu
    case contextShowSaveToCloud
    case contextShowHideForwardName
    case contextShowSelectFromUser
    case contextShowRestrict
    case contextShowReport
    case contextShowReply
    case contextShowPin
    case contextShowSaveMedia
    case contextShowMessageReplies
    case contextShowJson
    case showRepostToStory
    case emojiDownloaderEnabled
    case enableVideoToCircleOrVoice
    case namelessVideoBackgroundEnabled
    // Appearance
    case squareAvatars
    case swipeChatOptions
    case hideVoiceRecordButton
    case foldersAtBottom
    case premiumStatusInHeader
    case searchButtonInChatList
    case unlimitedPinnedChats
    case newAccountSwitcher
    case profileColorBackground
    case messageOutline
    case secondsInMessages
    case hideReactions
    // Messages (moved INTO appearance)
    case showOriginalEdited
    case truncateLongMessages
    case saveChatHistory
    case saveOnceMedia
    case noAutoNextVoice
    case semiTransparentWhenMentioned
    case charCounterInput
    case charCounterInChat
    case hideMyDeleted
    case hideMyEdited
    case hideBotEdited
    case hideBotDeleted
    case doubleTapToEdit
    // Camera
    case cameraDefaultBack
    case cameraSendHDPhoto
    case cameraRememberLast
    case cameraAlwaysSendHD
    // Info
    case showIdAndDC
    case showSeconds
    case showFullViews
    case hidePhoneNumber
    case visualUsername
    case showIfMutualContacts
    case showRegistrationDate
    // Additional
    case vibrationEnabled
    case speedBoostEnabled
}

private enum NLSliderSetting: String {
    case outgoingPhotoQuality
    case stickerSize
    case accountColorsSaturation
    case cameraJpegQuality
}

private enum NLOneFromManySetting: String {
    case downloadSpeedBoost
    case autoFormatMode
}

private enum NLDisclosureLink: String {
    case none
    case hubAppearance
    case hubGhost
    case hubOther
    case hubSearch
    case onlineHistory
}

private enum NLAction: Int, CaseIterable {
    case exportSettings
    case importSettings
    case saveKeychain
    case resetAll
}

/// 4 категории для нового layout (вместо 9)
private enum NLHubCategory: String, CaseIterable {
    case appearance   // Внешний вид — всё что связано с интерфейсом + сообщения
    case ghost        // Режим призрака — привacidad + геолокация + статусы
    case other        // Прочие функции — контекст, сторис, медиа, экспорт
    case search       // Поиск — поиск по настройкам с навигацией

    var titleRu: String {
        switch self {
        case .appearance: return "Внешний вид"
        case .ghost: return "Режим призрака"
        case .other: return "Прочие функции"
        case .search: return "Поиск"
        }
    }

    var subtitleRu: String {
        switch self {
        case .appearance: return "Интерфейс, сообщения, камера"
        case .ghost: return "Онлайн, прочтение, приватность, геолокация"
        case .other: return "Контекст, сторис, медиа, экспорт"
        case .search: return "Найти и перейти к настройке"
        }
    }

    var pillSection: NLSectionId {
        switch self {
        case .appearance: return .hubPill0
        case .ghost: return .hubPill1
        case .other: return .hubPill2
        case .search: return .hubPill3
        }
    }

    var disclosure: NLDisclosureLink {
        switch self {
        case .appearance: return .hubAppearance
        case .ghost: return .hubGhost
        case .other: return .hubOther
        case .search: return .hubSearch
        }
    }

    static func from(link: NLDisclosureLink) -> NLHubCategory? {
        switch link {
        case .hubAppearance: return .appearance
        case .hubGhost: return .ghost
        case .hubOther: return .other
        case .hubSearch: return .search
        case .none, .onlineHistory: return nil
        }
    }
}

// MARK: - Search index item — maps search query to a category

private struct NLSearchableItem {
    let title: String
    let category: NLHubCategory
}

/// Full-text searchable index of all settings
private let nlSearchIndex: [NLSearchableItem] = [
    // Appearance
    NLSearchableItem(title: "Квадратные аватары", category: .appearance),
    NLSearchableItem(title: "Безлимитное закрепление", category: .appearance),
    NLSearchableItem(title: "Папки снизу", category: .appearance),
    NLSearchableItem(title: "Обводка сообщений", category: .appearance),
    NLSearchableItem(title: "Цвет профиля", category: .appearance),
    NLSearchableItem(title: "Видео-фон чата", category: .appearance),
    NLSearchableItem(title: "Камера HD", category: .appearance),
    NLSearchableItem(title: "Счётчик символов", category: .appearance),
    NLSearchableItem(title: "Сокращать сообщения", category: .appearance),
    NLSearchableItem(title: "Оригинал редактирования", category: .appearance),
    NLSearchableItem(title: "Двойной тап редактирование", category: .appearance),
    NLSearchableItem(title: "Секунды в метке времени", category: .appearance),
    NLSearchableItem(title: "Новый переключатель аккаунтов", category: .appearance),
    NLSearchableItem(title: "Кнопка записи голосовых", category: .appearance),
    NLSearchableItem(title: "Скрыть реакции", category: .appearance),
    NLSearchableItem(title: "Насыщенность цветов", category: .appearance),
    NLSearchableItem(title: "Размер стикеров", category: .appearance),
    NLSearchableItem(title: "Предупреждение при звонке", category: .appearance),
    // Other
    NLSearchableItem(title: "Контекстное меню", category: .other),
    NLSearchableItem(title: "Сохранить в облако", category: .other),
    NLSearchableItem(title: "Скрыть имя пересылки", category: .other),
    NLSearchableItem(title: "Выбрать от пользователя", category: .other),
    NLSearchableItem(title: "Ограничить", category: .other),
    NLSearchableItem(title: "Пожаловаться", category: .other),
    NLSearchableItem(title: "Ответить", category: .other),
    NLSearchableItem(title: "Закрепить", category: .other),
    NLSearchableItem(title: "Сохранить медиа", category: .other),
    NLSearchableItem(title: "Ответы на сообщение", category: .other),
    NLSearchableItem(title: "JSON", category: .other),
    NLSearchableItem(title: "Локальный премиум", category: .other),
    NLSearchableItem(title: "Перевести", category: .other),
    NLSearchableItem(title: "Zalgo-фильтр", category: .other),
    NLSearchableItem(title: "Ускорение отправки", category: .other),
    NLSearchableItem(title: "Безлимитные стикеры", category: .other),
    NLSearchableItem(title: "Сторис", category: .other),
    NLSearchableItem(title: "Stealth-режим", category: .other),
    NLSearchableItem(title: "Переслать в историю", category: .other),
    NLSearchableItem(title: "Экспорт настроек", category: .other),
    NLSearchableItem(title: "Импорт настроек", category: .other),
    NLSearchableItem(title: "Сбросить nameless", category: .other),
    NLSearchableItem(title: "Скачивание эмодзи", category: .other),
    NLSearchableItem(title: "Видео в кружок", category: .other),
    NLSearchableItem(title: "Свайп PiP видео", category: .other),
    NLSearchableItem(title: "Встроенный микрофон", category: .other),
    NLSearchableItem(title: "Отправка больших фото", category: .other),
    NLSearchableItem(title: "Качество JPEG", category: .other),
    NLSearchableItem(title: "Запомнить камеру", category: .other),
    NLSearchableItem(title: "Всегда HD", category: .other),
    NLSearchableItem(title: "Дата создания чата", category: .other),
    NLSearchableItem(title: "Полные просмотры", category: .other),
    NLSearchableItem(title: "Визуальный юзернейм", category: .other),
    NLSearchableItem(title: "Компактные числа", category: .other),
]

// MARK: - State

private struct NLControllerState: Equatable {
    var searchQuery: String?
    /// nil = hub root shelves; non-nil = category toggles screen
    var hubCategory: NLHubCategory? = nil
}

// MARK: - Entry type

private typealias NLEntry = SGItemListUIEntry<NLSectionId, NLBoolSetting, NLSliderSetting, NLOneFromManySetting, NLDisclosureLink, NLAction>

// MARK: - Build Entries

private func nlBuildEntries(presentationData: PresentationData, state: NLControllerState, simpleUpdated: Bool) -> [NLEntry] {
    let s = SGSimpleSettings.shared
    var entries: [NLEntry] = []
    let id = SGItemListCounter()
    let query = (state.searchQuery ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let searching = !query.isEmpty

    // Hub root — 4 glass pills
    if !searching, state.hubCategory == nil {
        entries.append(.notice(id: id.count, section: .hero, text: "**nameless**"))
        entries.append(.searchInput(id: id.count, section: .search, title: NSAttributedString(string: "🔍"), text: state.searchQuery ?? "", placeholder: "Поиск настроек"))
        for cat in NLHubCategory.allCases {
            entries.append(.disclosureDetail(
                id: id.count,
                section: cat.pillSection,
                link: cat.disclosure,
                text: cat.titleRu,
                detail: cat.subtitleRu
            ))
        }
        entries.append(.action(id: id.count, section: .hubActions, actionType: .exportSettings, text: "Экспорт настроек", kind: .generic))
        entries.append(.action(id: id.count, section: .hubPill4, actionType: .importSettings, text: "Импорт настроек", kind: .generic))
        entries.append(.action(id: id.count, section: .hubPill5, actionType: .resetAll, text: "Сбросить nameless", kind: .destructive))
        return filterSGItemListUIEntrires(entries: entries, by: state.searchQuery)
    }

    // Search mode — show filtered results with category labels
    if searching {
        entries.append(.searchInput(id: id.count, section: .search, title: NSAttributedString(string: "🔍"), text: state.searchQuery ?? "", placeholder: "Поиск настроек..."))
        let results = nlSearchIndex.filter { $0.title.lowercased().contains(query) }
        if results.isEmpty {
            entries.append(.notice(id: id.count, section: .items, text: "Ничего не найдено"))
            return entries
        }
        for result in results {
            entries.append(.disclosure(
                id: id.count,
                section: .items,
                link: result.category.disclosure,
                text: result.title,
                detail: result.category.titleRu
            ))
        }
        return entries
    }

    entries.append(.searchInput(id: id.count, section: .search, title: NSAttributedString(string: "🔍"), text: state.searchQuery ?? "", placeholder: "Поиск настроек"))
    let sec: NLSectionId = .items
    let cat = state.hubCategory

    // ═══════════════════════════════════════════
    // ВНЕШНИЙ ВИД — интерфейс + сообщения + камера + медиа + информация
    // ═══════════════════════════════════════════
    if cat == nil || cat == .appearance {
    entries.append(.header(id: id.count, section: sec, text: "✦ ВНЕШНИЙ ВИД", badge: nil))

    // СПИСОК ЧАТОВ
    entries.append(.header(id: id.count, section: sec, text: "СПИСОК ЧАТОВ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .squareAvatars, value: s.squareAvatars, text: "Квадратные аватары", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .unlimitedPinnedChats, value: s.unlimitedPinnedChats, text: "Закрепление чатов (без лимита)", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .searchButtonInChatList, value: s.searchButtonInChatList, text: "Кнопка поиска (лупа)", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .premiumStatusInHeader, value: s.premiumStatusInHeader, text: "Премиум-статус в шапке", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .foldersAtBottom, value: s.foldersAtBottom, text: "Папки снизу", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hidePhoneInSettings, value: s.hidePhoneInSettings, text: "Скрыть номер в настройках", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .allChatsHidden, value: s.allChatsHidden, text: "Скрыть «Все чаты»", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideStories, value: s.hideStories, text: "Скрыть истории", enabled: true))

    // ЧАТ И ИНТЕРФЕЙС
    entries.append(.header(id: id.count, section: sec, text: "ЧАТ И ИНТЕРФЕЙС", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .newAccountSwitcher, value: s.newAccountSwitcher, text: "Новый вид переключения аккаунтов", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .messageOutline, value: s.messageOutline, text: "Обводка сообщений", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .roundTabs, value: s.roundTabs, text: "Круглые вкладки (иконки без текста)", enabled: !s.hideTabBar))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideRecordingButton, value: !s.hideRecordingButton, text: "Кнопка записи голосовых", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .secondsInMessages, value: s.secondsInMessages, text: "Секунды в метке времени", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideReactions, value: s.hideReactions, text: "Скрыть реакции", enabled: true))

    // СООБЩЕНИЯ (перенесены из вкладки Сообщения — БЕЗ удалённых/прозрачности/корзины)
    entries.append(.header(id: id.count, section: sec, text: "СООБЩЕНИЯ", badge: nil))
    entries.append(.header(id: id.count, section: sec, text: "ПОВЕДЕНИЕ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .saveEditHistory, value: s.saveEditHistory, text: "Сохранять историю чатов", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .enableLocalMessageEditing, value: s.enableLocalMessageEditing, text: "Локальное редактирование", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .truncateLongMessages, value: s.truncateLongMessages, text: "Сокращать сообщения", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .saveChatHistory, value: s.saveChatHistory, text: "История чатов", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .saveOnceMedia, value: s.saveOnceMedia, text: "Одноразовые → галерея", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .noAutoNextVoice, value: s.noAutoNextVoice, text: "Не слушать след. голосовое", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .semiTransparentWhenMentioned, value: s.semiTransparentWhenMentioned, text: "Полупрозрачно когда отмечают", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .charCounterInput, value: s.charCounterInput, text: "Счётчик символов при вводе", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .charCounterInChat, value: s.charCounterInChat, text: "Счётчик символов в чате", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .doubleTapToEdit, value: s.doubleTapToEdit, text: "Двойной тап для редактирования", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .scrollToTopButtonEnabled, value: s.scrollToTopButtonEnabled, text: "Кнопка «Наверх»", enabled: true))
    entries.append(.oneFromManySelector(id: id.count, section: sec, settingName: .autoFormatMode, text: "Стиль при отправке", value: NamelessAutoFormatMode(rawValue: s.autoFormatMode)?.titleRu ?? "Обычный", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .showOriginalEdited, value: s.showOriginalEdited, text: "Оригинал изменений", enabled: true))

    // КАМЕРА (перенесена из отдельной вкладки)
    entries.append(.header(id: id.count, section: sec, text: "КАМЕРА", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .cameraDefaultBack, value: s.cameraDefaultBack, text: "По умолчанию задняя камера", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .cameraSendHDPhoto, value: s.cameraSendHDPhoto, text: "Отправлять в HD фото", enabled: true))
    entries.append(.header(id: id.count, section: sec, text: "КАЧЕСТВО JPEG ФОТО", badge: nil))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .cameraJpegQuality, value: s.cameraJpegQuality))
    entries.append(.toggle(id: id.count, section: sec, settingName: .cameraRememberLast, value: s.cameraRememberLast, text: "Запоминать последнюю камеру", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .cameraAlwaysSendHD, value: s.cameraAlwaysSendHD, text: "Всегда в HD", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .enableVideoToCircleOrVoice, value: s.enableVideoToCircleOrVoice, text: "Видео → кружок или голосовое", enabled: true))

    // МЕДИА И ПЛЕЕР
    entries.append(.header(id: id.count, section: sec, text: "МЕДИА И ПЛЕЕР", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessVideoBackgroundEnabled, value: s.namelessVideoBackgroundEnabled, text: "Видео-обои чата", enabled: true))

    // ПРОФИЛЬ
    entries.append(.header(id: id.count, section: sec, text: "ПРОФИЛЬ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .profileColorBackground, value: s.profileColorBackground, text: "Цвет на фоне в профиле", enabled: true))

    // НАСЫЩЕННОСТЬ И РАЗМЕРЫ
    entries.append(.header(id: id.count, section: sec, text: "НАСЫЩЕННОСТЬ ЦВЕТОВ", badge: nil))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .accountColorsSaturation, value: s.accountColorsSaturation))
    entries.append(.header(id: id.count, section: sec, text: "РАЗМЕР СТИКЕРОВ", badge: nil))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .stickerSize, value: s.stickerSize))

    // УВЕДОМЛЕНИЯ
    entries.append(.header(id: id.count, section: sec, text: "УВЕДОМЛЕНИЯ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .confirmCalls, value: s.confirmCalls, text: "Предупреждение при звонке", enabled: true))

    } // end appearance

    // ═══════════════════════════════════════════
    // РЕЖИМ ПРИЗРАКА — вкладка сохранена, функции удалены
    // ═══════════════════════════════════════════
    if cat == nil || cat == .ghost {
    entries.append(.header(id: id.count, section: sec, text: "👻 РЕЖИМ ПРИЗРАКА", badge: nil))
    entries.append(.notice(id: id.count, section: sec, text: "Функции этого раздела отключены"))
    } // end ghost

    // ═══════════════════════════════════════════
    // ПРОЧИЕ ФУНКЦИИ — контекст, сторис, фото, доп.
    // ═══════════════════════════════════════════
    if cat == nil || cat == .other {
    // КОНТЕКСТНОЕ МЕНЮ
    entries.append(.header(id: id.count, section: sec, text: "✦ ПРОЧИЕ ФУНКЦИИ", badge: nil))
    entries.append(.header(id: id.count, section: sec, text: "КОНТЕКСТНОЕ МЕНЮ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .contextShowSaveToCloud, value: s.contextShowSaveToCloud, text: "Сохранить в облако", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .contextShowHideForwardName, value: s.contextShowHideForwardName, text: "Скрыть имя пересылки", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .contextShowSelectFromUser, value: s.contextShowSelectFromUser, text: "Выбрать от пользователя", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .contextShowRestrict, value: s.contextShowRestrict, text: "Ограничить", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .contextShowReport, value: s.contextShowReport, text: "Пожаловаться", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .contextShowReply, value: s.contextShowReply, text: "Ответить", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .contextShowPin, value: s.contextShowPin, text: "Закрепить", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .contextShowSaveMedia, value: s.contextShowSaveMedia, text: "Сохранить медиа", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .contextShowMessageReplies, value: s.contextShowMessageReplies, text: "Ответы на сообщение", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .contextShowJson, value: s.contextShowJson, text: "JSON", enabled: true))

    // ЛОКАЛЬНЫЕ ЗВЁЗДЫ
    entries.append(.header(id: id.count, section: sec, text: "ЛОКАЛЬНЫЕ ЗВЁЗДЫ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .enableLocalPremium, value: s.enableLocalPremium, text: "Локальный премиум", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Локальный баланс: \(s.feelRichStarsAmount) ⭐ (настройка feel rich)"))

    // ДОПОЛНИТЕЛЬНО
    entries.append(.header(id: id.count, section: sec, text: "ДОПОЛНИТЕЛЬНО", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .quickTranslateButton, value: s.quickTranslateButton, text: "Кнопка «Перевести»", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableZalgoText, value: s.disableZalgoText, text: "Zalgo-фильтр", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .uploadSpeedBoost, value: s.uploadSpeedBoost, text: "Ускорение отправки", enabled: true))
    entries.append(.oneFromManySelector(id: id.count, section: sec, settingName: .downloadSpeedBoost, text: "Ускорение загрузки", value: s.downloadSpeedBoost, enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .unlimitedFavoriteStickers, value: s.unlimitedFavoriteStickers, text: "Безлимитные избранные стикеры", enabled: true))

    // СТИКЕРЫ
    entries.append(.header(id: id.count, section: sec, text: "СТИКЕРЫ", badge: nil))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .stickerSize, value: s.stickerSize))
    entries.append(.toggle(id: id.count, section: sec, settingName: .stickerTimestamp, value: s.stickerTimestamp, text: "Временные метки на стикерах", enabled: true))

    // ФОТО
    entries.append(.header(id: id.count, section: sec, text: "ФОТО", badge: nil))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .outgoingPhotoQuality, value: s.outgoingPhotoQuality))
    entries.append(.toggle(id: id.count, section: sec, settingName: .sendLargePhotos, value: s.sendLargePhotos, text: "Отправлять большие фото", enabled: true))

    // СТОРИС
    entries.append(.header(id: id.count, section: sec, text: "СТОРИС", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableSwipeToRecordStory, value: s.disableSwipeToRecordStory, text: "Скрыть свайп для записи сторис", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .warnOnStoriesOpen, value: s.warnOnStoriesOpen, text: "Предупреждение при открытии сторис", enabled: true))
    if s.canUseStealthMode {
        entries.append(.toggle(id: id.count, section: sec, settingName: .storyStealthMode, value: s.storyStealthMode, text: "Stealth-режим сторис", enabled: true))
    } else {
        id.increment(1)
    }
    entries.append(.toggle(id: id.count, section: sec, settingName: .showRepostToStory, value: s.showRepostToStoryV2, text: "Переслать в историю", enabled: true))

    // ПРОЧЕЕ
    entries.append(.header(id: id.count, section: sec, text: "ПРОЧЕЕ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .forceSystemSharing, value: s.forceSystemSharing, text: "Системный шэринг", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .emojiDownloaderEnabled, value: s.emojiDownloaderEnabled, text: "Скачивание эмодзи", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .swipeForVideoPIP, value: s.videoPIPSwipeDirection == SGSimpleSettings.VideoPIPSwipeDirection.up.rawValue, text: "Свайп для PiP видео", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .forceBuiltInMic, value: s.forceBuiltInMic, text: "Встроенный микрофон", enabled: true))

    // ЭКСПОРТ / ИМПОРТ
    let actSec: NLSectionId = .actions
    entries.append(.header(id: id.count, section: actSec, text: "ЭКСПОРТ / ИМПОРТ", badge: nil))
    entries.append(.action(id: id.count, section: actSec, actionType: .exportSettings, text: "Экспорт настроек в JSON", kind: .generic))
    entries.append(.action(id: id.count, section: actSec, actionType: .importSettings, text: "Импорт настроек из JSON", kind: .generic))
    entries.append(.action(id: id.count, section: actSec, actionType: .saveKeychain, text: "Сохранить настройки в Keychain", kind: .generic))
    entries.append(.action(id: id.count, section: actSec, actionType: .resetAll, text: "Сбросить все настройки nameless", kind: .destructive))
    } // end other

    return filterSGItemListUIEntrires(entries: entries, by: state.searchQuery)
}

// MARK: - Public API

private func namelessFeaturesCategoryController(context: AccountContext, category: NLHubCategory) -> ViewController {
    return namelessFeaturesControllerImpl(context: context, initialCategory: category)
}

public func namelessFeaturesController(context: AccountContext) -> ViewController {
    return namelessFeaturesControllerImpl(context: context, initialCategory: nil)
}

private func namelessFeaturesControllerImpl(context: AccountContext, initialCategory: NLHubCategory?) -> ViewController {
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    var pushControllerImpl: ((ViewController) -> Void)?
    var askForRestart: (() -> Void)?

    let initialState = NLControllerState(hubCategory: initialCategory)
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: ((NLControllerState) -> NLControllerState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }

    let simplePromise = ValuePromise(true, ignoreRepeated: false)

    let arguments = SGItemListArguments<NLBoolSetting, NLSliderSetting, NLOneFromManySetting, NLDisclosureLink, NLAction>(
        context: context,
        setBoolValue: { setting, value in
            let s = SGSimpleSettings.shared
            switch setting {
            case .hidePhoneInSettings: s.hidePhoneInSettings = value; askForRestart?()
            case .roundTabs: s.roundTabs = value; askForRestart?()
            case .wideTabBar: s.wideTabBar = value; askForRestart?()
            case .hideStories: s.hideStories = value
            case .hideRecordingButton: s.hideRecordingButton = !value
            case .secondsInMessages: s.secondsInMessages = value
            case .hideReactions: s.hideReactions = value
            case .hideChannelBottomButton: s.hideChannelBottomButton = !value
            case .disableSendAsButton: s.disableSendAsButton = !value
            case .tabBarSearchEnabled: s.tabBarSearchEnabled = value
            case .allChatsHidden: s.allChatsHidden = value; askForRestart?()
            case .compactFolderNames: s.compactFolderNames = value; askForRestart?()
            case .messageDoubleTapActionOutgoingEdit: s.messageDoubleTapActionOutgoing = value ? SGSimpleSettings.MessageDoubleTapAction.edit.rawValue : SGSimpleSettings.MessageDoubleTapAction.default.rawValue
            case .showProfileId: s.showProfileId = value
            case .showDC: s.showDC = value
            case .showRegDate: s.showRegDate = value
            case .confirmCalls: s.confirmCalls = value
            case .swipeForVideoPIP: s.videoPIPSwipeDirection = value ? SGSimpleSettings.VideoPIPSwipeDirection.up.rawValue : SGSimpleSettings.VideoPIPSwipeDirection.none.rawValue
            case .sendLargePhotos: s.sendLargePhotos = value
            case .stickerTimestamp: s.stickerTimestamp = value
            case .forceBuiltInMic: s.forceBuiltInMic = value
            case .rememberLastFolder: s.rememberLastFolder = value
            case .showDeletedMessages: s.showDeletedMessages = value
            case .saveDeletedMessagesMedia: s.saveDeletedMessagesMedia = value
            case .saveEditHistory: s.saveEditHistory = value
            case .enableLocalMessageEditing: s.enableLocalMessageEditing = value
            case .scrollToTopButtonEnabled: s.scrollToTopButtonEnabled = value
            case .enableSavingProtectedContent: s.enableSavingProtectedContent = value
            case .enableSavingSelfDestructingMessages: s.enableSavingSelfDestructingMessages = value
            case .disableScreenshotDetection: s.disableScreenshotDetection = value
            case .disableSecretChatBlurOnScreenshot: s.disableSecretChatBlurOnScreenshot = value
            case .disableAllAds: s.disableAllAds = value
            case .hideProxySponsor: s.hideProxySponsor = value
            case .disableZalgoText: s.disableZalgoText = value
            case .quickTranslateButton: s.quickTranslateButton = value
            case .enableLocalPremium: s.enableLocalPremium = value
            case .uploadSpeedBoost: s.uploadSpeedBoost = value
            case .unlimitedFavoriteStickers: s.unlimitedFavoriteStickers = value
            case .storyStealthMode: s.storyStealthMode = value
            case .warnOnStoriesOpen: s.warnOnStoriesOpen = value
            case .disableSwipeToRecordStory: s.disableSwipeToRecordStory = value
            case .forceSystemSharing: s.forceSystemSharing = value
            case .startTelescopeWithRearCam: s.startTelescopeWithRearCam = value
            case .disableGalleryCamera: s.disableGalleryCamera = !value; simplePromise.set(true)
            case .disableGalleryCameraPreview: s.disableGalleryCameraPreview = !value
            case .emojiDownloaderEnabled: s.emojiDownloaderEnabled = value
            case .enableVideoToCircleOrVoice: s.enableVideoToCircleOrVoice = value
            case .namelessVideoBackgroundEnabled: s.namelessVideoBackgroundEnabled = value
            case .squareAvatars: s.squareAvatars = value
            case .swipeChatOptions: s.swipeChatOptions = value
            case .hideVoiceRecordButton: s.hideVoiceRecordButton = value
            case .foldersAtBottom: s.foldersAtBottom = value
            case .premiumStatusInHeader: s.premiumStatusInHeader = value
            case .searchButtonInChatList: s.searchButtonInChatList = value
            case .unlimitedPinnedChats: s.unlimitedPinnedChats = value
            case .newAccountSwitcher: s.newAccountSwitcher = value
            case .profileColorBackground: s.profileColorBackground = value
            case .messageOutline: s.messageOutline = value
            case .showOriginalEdited: s.showOriginalEdited = value
            case .truncateLongMessages: s.truncateLongMessages = value
            case .saveChatHistory: s.saveChatHistory = value
            case .saveOnceMedia: s.saveOnceMedia = value
            case .noAutoNextVoice: s.noAutoNextVoice = value
            case .semiTransparentWhenMentioned: s.semiTransparentWhenMentioned = value
            case .charCounterInput: s.charCounterInput = value
            case .charCounterInChat: s.charCounterInChat = value
            case .hideMyDeleted: s.hideMyDeleted = value
            case .hideMyEdited: s.hideMyEdited = value
            case .hideBotEdited: s.hideBotEdited = value
            case .hideBotDeleted: s.hideBotDeleted = value
            case .doubleTapToEdit:
                s.doubleTapToEdit = value
                s.messageDoubleTapActionOutgoing = value
                    ? SGSimpleSettings.MessageDoubleTapAction.edit.rawValue
                    : SGSimpleSettings.MessageDoubleTapAction.default.rawValue
            case .cameraDefaultBack: s.cameraDefaultBack = value
            case .cameraSendHDPhoto: s.cameraSendHDPhoto = value
            case .cameraRememberLast: s.cameraRememberLast = value
            case .cameraAlwaysSendHD: s.cameraAlwaysSendHD = value
            case .showIdAndDC: s.showIdAndDC = value
            case .showSeconds: s.showSeconds = value
            case .showFullViews: s.showFullViews = value
            case .hidePhoneNumber: s.hidePhoneNumber = value
            case .showCreationDate: s.showCreationDate = value
            case .visualUsername: s.visualUsername = value
            case .showIfMutualContacts: s.showIfMutualContacts = value
            case .showRegistrationDate: s.showRegistrationDate = value
            case .vibrationEnabled: s.vibrationEnabled = value
            case .speedBoostEnabled: s.speedBoostEnabled = value
            case .bypassProtectedContent: s.bypassProtectedContent = value
            case .removeSpoilersEverywhere: s.removeSpoilersEverywhere = value
            case .antiScamEnabled: s.antiScamEnabled = value
            case .warnBeforeCall: s.warnBeforeCall = value
            case .localNotificationsEnabled: s.localNotificationsEnabled = value
            case .disableCompactNumbers: s.disableCompactNumbers = !value
            case .contextShowSaveToCloud: s.contextShowSaveToCloud = value
            case .contextShowHideForwardName: s.contextShowHideForwardName = value
            case .contextShowSelectFromUser: s.contextShowSelectFromUser = value
            case .contextShowRestrict: s.contextShowRestrict = value
            case .contextShowReport: s.contextShowReport = value
            case .contextShowReply: s.contextShowReply = value
            case .contextShowPin: s.contextShowPin = value
            case .contextShowSaveMedia: s.contextShowSaveMedia = value
            case .contextShowMessageReplies: s.contextShowMessageReplies = value
            case .contextShowJson: s.contextShowJson = value
            case .showRepostToStory: s.showRepostToStoryV2 = value
            }
        },
        updateSliderValue: { slider, value in
            let s = SGSimpleSettings.shared
            switch slider {
            case .outgoingPhotoQuality: if s.outgoingPhotoQuality != value { s.outgoingPhotoQuality = value; simplePromise.set(true) }
            case .stickerSize: if s.stickerSize != value { s.stickerSize = value; simplePromise.set(true) }
            case .accountColorsSaturation: if s.accountColorsSaturation != value { s.accountColorsSaturation = value; simplePromise.set(true) }
            case .cameraJpegQuality:
                if s.cameraJpegQuality != value { s.cameraJpegQuality = value; simplePromise.set(true) }
            }
        },
        setOneFromManyValue: { setting in
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let actionSheet = ActionSheetController(presentationData: presentationData)
            var items: [ActionSheetItem] = []

            switch setting {
            case .downloadSpeedBoost:
                let setAction: (String) -> Void = { value in
                    SGSimpleSettings.shared.downloadSpeedBoost = value
                    simplePromise.set(true)
                    let enableDownloadX: Bool = value != SGSimpleSettings.DownloadSpeedBoostValues.none.rawValue
                    let _ = updateNetworkSettingsInteractively(postbox: context.account.postbox, network: context.account.network, { settings in
                        var settings = settings
                        settings.useExperimentalDownload = enableDownloadX
                        return settings
                    }).start(completed: {
                        Queue.mainQueue().async { askForRestart?() }
                    })
                }
                for value in SGSimpleSettings.DownloadSpeedBoostValues.allCases {
                    items.append(ActionSheetButtonItem(title: value.rawValue, color: .accent, action: { [weak actionSheet] in
                        actionSheet?.dismissAnimated()
                        setAction(value.rawValue)
                    }))
                }
            case .autoFormatMode:
                for mode in NamelessAutoFormatMode.allCases {
                    items.append(ActionSheetButtonItem(title: mode.titleRu, color: .accent, action: { [weak actionSheet] in
                        actionSheet?.dismissAnimated()
                        SGSimpleSettings.shared.autoFormatMode = mode.rawValue
                        simplePromise.set(true)
                    }))
                }
            }
            actionSheet.setItemGroups([ActionSheetItemGroup(items: items), ActionSheetItemGroup(items: [
                ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                    actionSheet?.dismissAnimated()
                })
            ])])
            presentControllerImpl?(actionSheet, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
        },
        openDisclosureLink: { link in
            if link == .onlineHistory {
                pushControllerImpl?(namelessOnlineHistoryController(context: context))
                return
            }
            guard let category = NLHubCategory.from(link: link) else { return }
            pushControllerImpl?(namelessFeaturesCategoryController(context: context, category: category))
        },
        action: { actionType in
            switch actionType {
            case .exportSettings:
                var dict: [String: Any] = [:]
                for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("nameless.") || key.hasPrefix("VoiceMorpher.") { dict[key] = UserDefaults.standard.object(forKey: key) }
                if let d = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted), let s = String(data: d, encoding: .utf8) { UIPasteboard.general.string = s }
            case .importSettings:
                if let s = UIPasteboard.general.string, let d = s.data(using: .utf8), let dict = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
                    for (k, v) in dict where k.hasPrefix("nameless.") || k.hasPrefix("VoiceMorpher.") { UserDefaults.standard.set(v, forKey: k) }
                }
                simplePromise.set(true)
            case .saveKeychain:
                SGSimpleSettings.shared.beginNamelessRollbackSnapshot()
            case .resetAll:
                SGSimpleSettings.shared.restoreNamelessRollbackSnapshot()
                for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("nameless.") { UserDefaults.standard.removeObject(forKey: key) }
                simplePromise.set(true)
            }
        },
        searchInput: { query in
            updateState { state in
                var updated = state
                updated.searchQuery = query
                return updated
            }
        }
    )

    let signal = combineLatest(simplePromise.get(), statePromise.get(), context.sharedContext.presentationData)
    |> map { _, state, presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let entries = nlBuildEntries(presentationData: presentationData, state: state, simpleUpdated: true)
        let title = state.hubCategory?.titleRu ?? ""
        let cs = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title.isEmpty ? "nameless" : title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let ls = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks)
        return (cs, (ls, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    askForRestart = { [weak context] in
        guard let context = context else { return }
        let pd = context.sharedContext.currentPresentationData.with { $0 }
        presentControllerImpl?(
            UndoOverlayController(presentationData: pd, content: .info(title: nil, text: "Пожалуйста, перезапустите приложение", timeout: nil, customUndoText: "Перезапустить"), elevatedLayout: false, action: { action in if action == .undo { exit(0) }; return true }),
            nil
        )
    }
    return controller
}
