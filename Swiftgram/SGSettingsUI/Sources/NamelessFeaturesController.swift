// MARK: nameless — Features Controller (restructured)
// 4 вкладки: Внешний вид | Режим призрака | Прочие функции | Поиск
import SGSimpleSettings
import SGItemListUI
import SGFakeLocation
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
    case showTabNames
    case roundTabs
    case wideTabBar
    case hideStories
    case compactChatList
    case hideRecordingButton
    case sendWithReturnKey
    case wideChannelPosts
    case compactMessagePreview
    case disableChatSwipeOptions
    case disableDeleteChatSwipeOption
    case secondsInMessages
    case hideReactions
    case hideChannelBottomButton
    case disableSnapDeletionEffect
    case disableSendAsButton
    case hideTabBar
    case tabBarSearchEnabled
    case allChatsHidden
    case compactFolderNames
    case forceEmojiTab
    case defaultEmojisFirst
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
    case disableScrollToNextChannel2
    case disableScrollToNextTopic2
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
    // Ghost Mode statuses
    case disableOnlineStatus
    case disableTypingStatus
    case disableVCMessageRecordingStatus
    case disableVCMessageUploadingStatus
    case disableUploadingFileStatus
    case disableUploadingPhotoStatus
    case disableUploadingVideoStatus
    case disableRecordingVideoStatus
    case disableChoosingLocationStatus
    case disableChoosingContactStatus
    case disablePlayingGameStatus
    case disableRecordingRoundVideoStatus
    case disableUploadingRoundVideoStatus
    case disableSpeakingInGroupCallStatus
    case disableChoosingStickerStatus
    case disableEmojiInteractionStatus
    case disableEmojiAcknowledgementStatus
    case disableMessageReadReceipt
    case disableStoryReadReceipt
    case enableOnlineStatusRecording
    case fakeLocationEnabled
    case ghostModeMessageSendDelay
    case ghostModeEnabled
    case ghostModeFakeTyping
    case ghostModeAntiSpam
    case ghostModeHideVideoWatch
    case ghostModeAutoCleanHistory
    case ghostModeAlwaysOnline
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
    // Liquid Glass
    case liquidGlassEnabled
    case namelessLiquidGlassMessages
    case namelessLiquidGlassOutgoingMessages
    case namelessLiquidGlassSettings
    case namelessLiquidGlassProfile
    case namelessLiquidGlassProfileGifts
    case namelessLiquidGlassInlineButtons
    case namelessLiquidGlassTinting
    case namelessLiquidGlassPopup
    case namelessLiquidGlassContextMenu
    case namelessLiquidGlassSearch
    case namelessLiquidGlassFadeAnimation
    case enableTelescope
    case emojiDownloaderEnabled
    case enableVideoToCircleOrVoice
    case namelessVideoBackgroundEnabled
    // Appearance
    case squareAvatars
    case newChatList
    case newChatHeader
    case blurInsteadGlass
    case oledMode
    case customSettingsIcons
    case telegramAppIcons
    case swipeChatOptions
    case hideVoiceRecordButton
    case foldersAtBottom
    case ramUsageUnderClock
    case chatListTitle
    case premiumStatusInHeader
    case searchButtonInChatList
    case unlimitedPinnedChats
    case newAccountSwitcher
    case profileColorBackground
    case profileAvatarBlur
    case profileAvatarBlurMinimal
    case profileAvatarBlurTinting
    case musicAlbumBlur
    case musicPlayerEffect
    case messageOutline
    case messageTransparent
    case messageSemiTransparent
    case messageBlurEffect
    case particleEffectEnabled
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
    case cameraUseDeviceMicrophone
    case cameraSendHDPhoto
    case cameraRememberLast
    case cameraStaticZoom
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
    case liquidGlassIntensity
    case cameraJpegQuality
    case particleEffectSpeed
    case particleEffectDensity
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
    case ghostDetailsToggle
    case fakeLocationPicker
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
        case .appearance: return "Интерфейс, сообщения, Liquid Glass, камера"
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
        case .none, .onlineHistory, .ghostDetailsToggle, .fakeLocationPicker: return nil
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
    NLSearchableItem(title: "Новый список чатов", category: .appearance),
    NLSearchableItem(title: "Компактный список чатов", category: .appearance),
    NLSearchableItem(title: "Безлимитное закрепление", category: .appearance),
    NLSearchableItem(title: "Папки снизу", category: .appearance),
    NLSearchableItem(title: "OLED-режим", category: .appearance),
    NLSearchableItem(title: "Обводка сообщений", category: .appearance),
    NLSearchableItem(title: "Прозрачные сообщения", category: .appearance),
    NLSearchableItem(title: "Размытие сообщений", category: .appearance),
    NLSearchableItem(title: "Широкие посты", category: .appearance),
    NLSearchableItem(title: "Эффект частиц", category: .appearance),
    NLSearchableItem(title: "Блюр аватара", category: .appearance),
    NLSearchableItem(title: "Цвет профиля", category: .appearance),
    NLSearchableItem(title: "Видео-фон чата", category: .appearance),
    NLSearchableItem(title: "Liquid Glass", category: .appearance),
    NLSearchableItem(title: "Камера HD", category: .appearance),
    NLSearchableItem(title: "Телескоп", category: .appearance),
    NLSearchableItem(title: "Счётчик символов", category: .appearance),
    NLSearchableItem(title: "Сокращать сообщения", category: .appearance),
    NLSearchableItem(title: "Оригинал редактирования", category: .appearance),
    NLSearchableItem(title: "Двойной тап редактирование", category: .appearance),
    NLSearchableItem(title: "Секунды в метке времени", category: .appearance),
    NLSearchableItem(title: "Новый вид заголовка", category: .appearance),
    NLSearchableItem(title: "Новый переключатель аккаунтов", category: .appearance),
    NLSearchableItem(title: "Скрыть нижний таббар", category: .appearance),
    NLSearchableItem(title: "Кнопка записи голосовых", category: .appearance),
    NLSearchableItem(title: "Отправка по Return", category: .appearance),
    NLSearchableItem(title: "Скрыть реакции", category: .appearance),
    NLSearchableItem(title: "Вкладка эмодзи первой", category: .appearance),
    NLSearchableItem(title: "Кастомные иконки", category: .appearance),
    NLSearchableItem(title: "Насыщенность цветов", category: .appearance),
    NLSearchableItem(title: "Размер стикеров", category: .appearance),
    NLSearchableItem(title: "Блюр обложки плеера", category: .appearance),
    NLSearchableItem(title: "Эффект в плеере", category: .appearance),
    NLSearchableItem(title: "Предупреждение при звонке", category: .appearance),
    // Ghost
    NLSearchableItem(title: "Режим призрака", category: .ghost),
    NLSearchableItem(title: "Скрыть онлайн", category: .ghost),
    NLSearchableItem(title: "Скрыть печатает", category: .ghost),
    NLSearchableItem(title: "Скрыть запись голосового", category: .ghost),
    NLSearchableItem(title: "Скрыть загрузку файлов", category: .ghost),
    NLSearchableItem(title: "Скрыть отправку фото", category: .ghost),
    NLSearchableItem(title: "Скрыть отправку видео", category: .ghost),
    NLSearchableItem(title: "Скрыть выбор локации", category: .ghost),
    NLSearchableItem(title: "Скрыть выбор контакта", category: .ghost),
    NLSearchableItem(title: "Скрыть статус игры", category: .ghost),
    NLSearchableItem(title: "Скрыть запись кружка", category: .ghost),
    NLSearchableItem(title: "Скрыть говорение в звонке", category: .ghost),
    NLSearchableItem(title: "Скрыть выбор стикера", category: .ghost),
    NLSearchableItem(title: "Скрыть прочтение", category: .ghost),
    NLSearchableItem(title: "Скрыть просмотр сторис", category: .ghost),
    NLSearchableItem(title: "Задержка отправки", category: .ghost),
    NLSearchableItem(title: "Fake typing", category: .ghost),
    NLSearchableItem(title: "Анти-спам", category: .ghost),
    NLSearchableItem(title: "Авто-очистка истории", category: .ghost),
    NLSearchableItem(title: "Всегда онлайн", category: .ghost),
    NLSearchableItem(title: "История онлайна", category: .ghost),
    NLSearchableItem(title: "Подмена геолокации", category: .ghost),
    NLSearchableItem(title: "Фейковая геолокация", category: .ghost),
    NLSearchableItem(title: "Обход защищённого контента", category: .ghost),
    NLSearchableItem(title: "Сохранять защищённый контент", category: .ghost),
    NLSearchableItem(title: "Самоуничтожающиеся", category: .ghost),
    NLSearchableItem(title: "Без скриншотов", category: .ghost),
    NLSearchableItem(title: "Без размытия секретных", category: .ghost),
    NLSearchableItem(title: "Отключить рекламу", category: .ghost),
    NLSearchableItem(title: "Скрыть номер телефона", category: .ghost),
    NLSearchableItem(title: "ID и DC в профиле", category: .ghost),
    NLSearchableItem(title: "Дата регистрации", category: .ghost),
    NLSearchableItem(title: "Защита от мошенников", category: .ghost),
    NLSearchableItem(title: "Убрать спойлеры", category: .ghost),
    NLSearchableItem(title: "Скрыть спонсора прокси", category: .ghost),
    NLSearchableItem(title: "Скрыть просмотр видео", category: .ghost),
    NLSearchableItem(title: "Эмодзи взаимодействие", category: .ghost),
    NLSearchableItem(title: "Эмодзи подтверждение", category: .ghost),
    NLSearchableItem(title: "Скрыть отправку кружка", category: .ghost),
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
    NLSearchableItem(title: "Статичный зум", category: .other),
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
    var ghostModeExpanded: Bool = false
}

// MARK: - Entry type

private typealias NLEntry = SGItemListUIEntry<NLSectionId, NLBoolSetting, NLSliderSetting, NLOneFromManySetting, NLDisclosureLink, NLAction>
private typealias NLArguments = SGItemListArguments<NLBoolSetting, NLSliderSetting, NLOneFromManySetting, NLDisclosureLink, NLAction>

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
        entries.append(.notice(id: id.count, section: .hero, text: "12.8 · Liquid Glass edition"))
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
            entries.append(.disclosureDetail(
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
    // ВНЕШНИЙ ВИД — интерфейс + сообщения + Liquid Glass + камера + медиа + информация
    // ═══════════════════════════════════════════
    if cat == nil || cat == .appearance {
    entries.append(.header(id: id.count, section: sec, text: "✦ ВНЕШНИЙ ВИД", badge: nil))

    // СПИСОК ЧАТОВ
    entries.append(.header(id: id.count, section: sec, text: "СПИСОК ЧАТОВ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .squareAvatars, value: s.squareAvatars, text: "Квадратные аватары", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .newChatList, value: s.newChatList, text: "Новый список чатов (карточки)", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .compactChatList, value: s.compactChatList, text: "Компактный список чатов", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .unlimitedPinnedChats, value: s.unlimitedPinnedChats, text: "Закрепление чатов (без лимита)", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .chatListTitle, value: s.chatListTitle, text: "Надпись «Чаты» в списке", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .searchButtonInChatList, value: s.searchButtonInChatList, text: "Кнопка поиска (лупа)", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .premiumStatusInHeader, value: s.premiumStatusInHeader, text: "Премиум-статус в шапке", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .foldersAtBottom, value: s.foldersAtBottom, text: "Папки снизу", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .ramUsageUnderClock, value: s.ramUsageUnderClock, text: "ОЗУ под часами", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hidePhoneInSettings, value: s.hidePhoneInSettings, text: "Скрыть номер в настройках", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .allChatsHidden, value: s.allChatsHidden, text: "Скрыть «Все чаты»", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideStories, value: s.hideStories, text: "Скрыть истории", enabled: true))

    // ЧАТ И ИНТЕРФЕЙС
    entries.append(.header(id: id.count, section: sec, text: "ЧАТ И ИНТЕРФЕЙС", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .newChatHeader, value: s.newChatHeader, text: "Новый вид заголовка чата", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .newAccountSwitcher, value: s.newAccountSwitcher, text: "Новый вид переключения аккаунтов", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .blurInsteadGlass, value: s.blurInsteadGlass, text: "Блюр вместо Liquid Glass", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .oledMode, value: s.oledMode, text: "OLED-режим (чёрный фон)", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .wideChannelPosts, value: s.wideChannelPosts, text: "Широкие посты в каналах", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .messageOutline, value: s.messageOutline, text: "Обводка сообщений", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .messageTransparent, value: s.messageTransparent, text: "Прозрачные сообщения", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .messageSemiTransparent, value: s.messageSemiTransparent, text: "Полупрозрачные сообщения", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .messageBlurEffect, value: s.messageBlurEffect, text: "Размытие сообщений", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .compactMessagePreview, value: s.chatListLines != SGSimpleSettings.ChatListLines.three.rawValue, text: "Компактный превью", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .showTabNames, value: s.showTabNames, text: "Подписи вкладок", enabled: !s.hideTabBar))
    entries.append(.toggle(id: id.count, section: sec, settingName: .roundTabs, value: s.roundTabs, text: "Круглые вкладки (иконки без текста)", enabled: !s.hideTabBar))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideTabBar, value: s.hideTabBar, text: "Скрыть нижний таббар", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableChatSwipeOptions, value: !s.disableChatSwipeOptions, text: "Свайп-опции чатов", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideRecordingButton, value: !s.hideRecordingButton, text: "Кнопка записи голосовых", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .sendWithReturnKey, value: s.sendWithReturnKey, text: "Отправка по Return", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .secondsInMessages, value: s.secondsInMessages, text: "Секунды в метке времени", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideReactions, value: s.hideReactions, text: "Скрыть реакции", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableSnapDeletionEffect, value: !s.disableSnapDeletionEffect, text: "Эффект удаления", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .forceEmojiTab, value: s.forceEmojiTab, text: "Вкладка эмодзи первой", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .defaultEmojisFirst, value: s.defaultEmojisFirst, text: "Стандартные эмодзи первыми", enabled: true))

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
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableScrollToNextChannel2, value: !s.disableScrollToNextChannel, text: "Скролл к следующему каналу", enabled: true))
    entries.append(.oneFromManySelector(id: id.count, section: sec, settingName: .autoFormatMode, text: "Стиль при отправке", value: NamelessAutoFormatMode(rawValue: s.autoFormatMode)?.titleRu ?? "Обычный", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .showOriginalEdited, value: s.showOriginalEdited, text: "Оригинал изменений", enabled: true))

    // LIQUID GLASS (перенесён из отдельной вкладки)
    entries.append(.header(id: id.count, section: sec, text: "LIQUID GLASS (iOS 26)", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .liquidGlassEnabled, value: s.liquidGlassEnabled, text: "Жидкое стекло — мастер", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessLiquidGlassFadeAnimation, value: s.namelessLiquidGlassFadeAnimation, text: "Анимация фейда при включении", enabled: s.liquidGlassEnabled))
    entries.append(.header(id: id.count, section: sec, text: "ЗОНЫ СТЕКЛА", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessLiquidGlassMessages, value: s.namelessLiquidGlassMessages, text: "Входящие сообщения", enabled: s.liquidGlassEnabled))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessLiquidGlassOutgoingMessages, value: s.namelessLiquidGlassOutgoingMessages, text: "Исходящие сообщения", enabled: s.liquidGlassEnabled))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessLiquidGlassSettings, value: s.namelessLiquidGlassSettings, text: "Настройки", enabled: s.liquidGlassEnabled))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessLiquidGlassProfile, value: s.namelessLiquidGlassProfile, text: "Профиль", enabled: s.liquidGlassEnabled))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessLiquidGlassProfileGifts, value: s.namelessLiquidGlassProfileGifts, text: "Подарки в профиле", enabled: s.liquidGlassEnabled))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessLiquidGlassInlineButtons, value: s.namelessLiquidGlassInlineButtons, text: "Инлайн-кнопки ботов", enabled: s.liquidGlassEnabled))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessLiquidGlassPopup, value: s.namelessLiquidGlassPopup, text: "Всплывающие окна (попапы)", enabled: s.liquidGlassEnabled))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessLiquidGlassContextMenu, value: s.namelessLiquidGlassContextMenu, text: "Контекстное меню", enabled: s.liquidGlassEnabled))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessLiquidGlassSearch, value: s.namelessLiquidGlassSearch, text: "Панель поиска", enabled: s.liquidGlassEnabled))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessLiquidGlassTinting, value: s.namelessLiquidGlassTinting, text: "Тонирование (цвет акцента)", enabled: s.liquidGlassEnabled))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .liquidGlassIntensity, value: Int32(s.namelessLiquidGlassIntensity * 100)))

    // КАМЕРА (перенесена из отдельной вкладки)
    entries.append(.header(id: id.count, section: sec, text: "КАМЕРА", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .enableTelescope, value: s.enableTelescope, text: "Телескоп (зум камеры)", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .cameraDefaultBack, value: s.cameraDefaultBack, text: "По умолчанию задняя камера", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .cameraUseDeviceMicrophone, value: s.cameraUseDeviceMicrophone, text: "Микрофон устройства", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .cameraSendHDPhoto, value: s.cameraSendHDPhoto, text: "Отправлять в HD фото", enabled: true))
    entries.append(.header(id: id.count, section: sec, text: "КАЧЕСТВО JPEG ФОТО", badge: nil))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .cameraJpegQuality, value: s.cameraJpegQuality))
    entries.append(.toggle(id: id.count, section: sec, settingName: .cameraRememberLast, value: s.cameraRememberLast, text: "Запоминать последнюю камеру", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .cameraStaticZoom, value: s.cameraStaticZoom, text: "Статичный зум при записи", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .cameraAlwaysSendHD, value: s.cameraAlwaysSendHD, text: "Всегда в HD", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .enableVideoToCircleOrVoice, value: s.enableVideoToCircleOrVoice, text: "Видео → кружок или голосовое", enabled: true))

    // МЕДИА И ПЛЕЕР
    entries.append(.header(id: id.count, section: sec, text: "МЕДИА И ПЛЕЕР", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .musicAlbumBlur, value: s.musicAlbumBlur, text: "Блюр обложки трека", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .musicPlayerEffect, value: s.musicPlayerEffect, text: "Эффект в плеере", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessVideoBackgroundEnabled, value: s.namelessVideoBackgroundEnabled, text: "Видео-обои чата", enabled: true))

    // ПРОФИЛЬ
    entries.append(.header(id: id.count, section: sec, text: "ПРОФИЛЬ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .profileColorBackground, value: s.profileColorBackground, text: "Цвет на фоне в профиле", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .profileAvatarBlur, value: s.profileAvatarBlur, text: "Блюр аватара в профиле", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .profileAvatarBlurMinimal, value: s.profileAvatarBlurMinimal, text: "Минимальный блюр", enabled: s.profileAvatarBlur))
    entries.append(.toggle(id: id.count, section: sec, settingName: .profileAvatarBlurTinting, value: s.profileAvatarBlurTinting, text: "Тонирование блюра", enabled: s.profileAvatarBlur))

    // ИКОНКИ
    entries.append(.header(id: id.count, section: sec, text: "ИКОНКИ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .telegramAppIcons, value: s.telegramAppIcons, text: "Иконки приложения Telegram", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .customSettingsIcons, value: s.customSettingsIcons, text: "Кастомные иконки настроек", enabled: true))

    // ЭФФЕКТ ЧАСТИЦ
    entries.append(.header(id: id.count, section: sec, text: "ЭФФЕКТ ЧАСТИЦ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .particleEffectEnabled, value: s.particleEffectEnabled, text: "Эффект частиц", enabled: true))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .particleEffectSpeed, value: Int32(s.particleEffectSpeed * 100)))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .particleEffectDensity, value: Int32(s.particleEffectDensity * 100)))

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
    // РЕЖИМ ПРИЗРАКА — статусы + приватность + конфиденциальность + геолокация + информация
    // ═══════════════════════════════════════════
    if cat == nil || cat == .ghost {
    entries.append(.header(id: id.count, section: sec, text: "👻 РЕЖИМ ПРИЗРАКА", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .ghostModeEnabled, value: s.ghostModeEnabled, text: "Режим призрака", enabled: true))
    entries.append(.disclosureDetail(id: id.count, section: sec, link: .ghostDetailsToggle, text: "Дополнительные настройки", detail: state.ghostModeExpanded ? "Скрыть настройки режима призрака" : "Показать настройки режима призрака"))

    if state.ghostModeExpanded {
    entries.append(.header(id: id.count, section: sec, text: "СКРЫТИЕ СТАТУСОВ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .ghostModeAlwaysOnline, value: s.ghostModeAlwaysOnline, text: "Всегда онлайн", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableOnlineStatus, value: s.disableOnlineStatus, text: "Скрыть онлайн-статус", enabled: !s.ghostModeAlwaysOnline))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableTypingStatus, value: s.disableTypingStatus, text: "Скрыть «печатает»", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableVCMessageRecordingStatus, value: s.disableVCMessageRecordingStatus, text: "Скрыть запись голосового", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableVCMessageUploadingStatus, value: s.disableVCMessageUploadingStatus, text: "Скрыть отправку голосового", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableUploadingFileStatus, value: s.disableUploadingFileStatus, text: "Скрыть загрузку файлов", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableUploadingPhotoStatus, value: s.disableUploadingPhotoStatus, text: "Скрыть отправку фото", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableUploadingVideoStatus, value: s.disableUploadingVideoStatus, text: "Скрыть отправку видео", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableRecordingVideoStatus, value: s.disableRecordingVideoStatus, text: "Скрыть запись видео", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableChoosingLocationStatus, value: s.disableChoosingLocationStatus, text: "Скрыть выбор локации", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableChoosingContactStatus, value: s.disableChoosingContactStatus, text: "Скрыть выбор контакта", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disablePlayingGameStatus, value: s.disablePlayingGameStatus, text: "Скрыть статус игры", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableRecordingRoundVideoStatus, value: s.disableRecordingRoundVideoStatus, text: "Скрыть запись кружка", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableUploadingRoundVideoStatus, value: s.disableUploadingRoundVideoStatus, text: "Скрыть отправку кружка", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableSpeakingInGroupCallStatus, value: s.disableSpeakingInGroupCallStatus, text: "Скрыть говорение в звонке", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableChoosingStickerStatus, value: s.disableChoosingStickerStatus, text: "Скрыть выбор стикера", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableEmojiInteractionStatus, value: s.disableEmojiInteractionStatus, text: "Скрыть эмодзи-взаимодействие", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableEmojiAcknowledgementStatus, value: s.disableEmojiAcknowledgementStatus, text: "Скрыть эмодзи-подтверждение", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .ghostModeHideVideoWatch, value: s.ghostModeHideVideoWatch, text: "Скрыть просмотр видео/кружка", enabled: true))

    entries.append(.header(id: id.count, section: sec, text: "ПРОЧТЕНИЕ И ПРОСМОТР", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableMessageReadReceipt, value: s.disableMessageReadReceipt, text: "Скрыть прочтение (галочки)", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableStoryReadReceipt, value: s.disableStoryReadReceipt, text: "Скрыть просмотр сторис", enabled: true))

    entries.append(.header(id: id.count, section: sec, text: "ДОПОЛНИТЕЛЬНО", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .ghostModeMessageSendDelay, value: s.ghostModeMessageSendDelaySeconds > 0, text: "Задержка отправки 12 сек", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .ghostModeFakeTyping, value: s.ghostModeFakeTyping, text: "Fake typing (показывать «печатает»)", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .ghostModeAntiSpam, value: s.ghostModeAntiSpam, text: "Анти-спам входящих", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .ghostModeAutoCleanHistory, value: s.ghostModeAutoCleanHistory, text: "Авто-очистка истории", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .enableOnlineStatusRecording, value: s.enableOnlineStatusRecording, text: "История онлайна собеседников", enabled: true))
    entries.append(.disclosure(id: id.count, section: sec, link: .onlineHistory, text: "Открыть историю онлайна"))
    entries.append(.toggle(id: id.count, section: sec, settingName: .fakeLocationEnabled, value: s.fakeLocationEnabled, text: "Подмена геолокации", enabled: true))
    entries.append(.disclosure(id: id.count, section: sec, link: .fakeLocationPicker, text: "Выбрать местоположение"))

    // КОНФИДЕНЦИАЛЬНОСТЬ (перенесена из отдельной вкладки)
    entries.append(.header(id: id.count, section: sec, text: "КОНФИДЕНЦИАЛЬНОСТЬ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .bypassProtectedContent, value: s.bypassProtectedContent, text: "Обход защищённого контента", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .removeSpoilersEverywhere, value: s.removeSpoilersEverywhere, text: "Убрать спойлеры везде", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .antiScamEnabled, value: s.antiScamEnabled, text: "Защита от мошенников", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableAllAds, value: s.disableAllAds, text: "Отключить рекламу", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .enableSavingProtectedContent, value: s.enableSavingProtectedContent, text: "Сохранять защищённый контент", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .enableSavingSelfDestructingMessages, value: s.enableSavingSelfDestructingMessages, text: "Сохранять самоуничтожающиеся", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableScreenshotDetection, value: s.disableScreenshotDetection, text: "Без определения скриншотов", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableSecretChatBlurOnScreenshot, value: s.disableSecretChatBlurOnScreenshot, text: "Без размытия при скриншоте", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideProxySponsor, value: s.hideProxySponsor, text: "Скрыть спонсора прокси", enabled: true))

    // ИНФОРМАЦИЯ (перенесена из отдельной вкладки)
    entries.append(.header(id: id.count, section: sec, text: "ИНФОРМАЦИЯ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .showProfileId, value: s.showProfileId, text: "ID и DC в профиле", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .showSeconds, value: s.showSeconds, text: "Секунды в метке времени", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .showFullViews, value: s.showFullViews, text: "Полные просмотры", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hidePhoneNumber, value: s.hidePhoneNumber, text: "Скрыть номер телефона", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .showCreationDate, value: s.showCreationDate, text: "Дата создания чата/канала", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .visualUsername, value: s.visualUsername, text: "Визуальный юзернейм", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .showIfMutualContacts, value: s.showIfMutualContacts, text: "Если взаимно в контактах", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .showRegistrationDate, value: s.showRegistrationDate, text: "Дата регистрации аккаунта", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .showDC, value: s.showDC, text: "Показывать DC", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableCompactNumbers, value: !s.disableCompactNumbers, text: "Компактные числа", enabled: true))

    }
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

    let arguments: NLArguments = SGItemListArguments<NLBoolSetting, NLSliderSetting, NLOneFromManySetting, NLDisclosureLink, NLAction>(
        context: context,
        setBoolValue: { setting, value in
            let s = SGSimpleSettings.shared
            switch setting {
            case .hidePhoneInSettings: s.hidePhoneInSettings = value; askForRestart?()
            case .showTabNames: s.showTabNames = value; askForRestart?()
            case .roundTabs: s.roundTabs = value; askForRestart?()
            case .wideTabBar: s.wideTabBar = value; askForRestart?()
            case .hideStories: s.hideStories = value
            case .compactChatList: s.compactChatList = value; askForRestart?()
            case .hideRecordingButton: s.hideRecordingButton = !value
            case .sendWithReturnKey: s.sendWithReturnKey = value
            case .compactMessagePreview: s.chatListLines = value ? SGSimpleSettings.ChatListLines.two.rawValue : SGSimpleSettings.ChatListLines.three.rawValue; askForRestart?()
            case .disableChatSwipeOptions: s.disableChatSwipeOptions = !value; simplePromise.set(true); askForRestart?()
            case .disableDeleteChatSwipeOption: s.disableDeleteChatSwipeOption = !value; askForRestart?()
            case .secondsInMessages: s.secondsInMessages = value
            case .hideReactions: s.hideReactions = value
            case .hideChannelBottomButton: s.hideChannelBottomButton = !value
            case .disableSnapDeletionEffect: s.disableSnapDeletionEffect = !value
            case .disableSendAsButton: s.disableSendAsButton = !value
            case .hideTabBar: s.hideTabBar = value; simplePromise.set(true); askForRestart?()
            case .tabBarSearchEnabled: s.tabBarSearchEnabled = value
            case .allChatsHidden: s.allChatsHidden = value; askForRestart?()
            case .compactFolderNames: s.compactFolderNames = value; askForRestart?()
            case .forceEmojiTab: s.forceEmojiTab = value
            case .defaultEmojisFirst: s.defaultEmojisFirst = value
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
            case .disableScrollToNextChannel2: s.disableScrollToNextChannel = !value
            case .disableScrollToNextTopic2: s.disableScrollToNextChannel = !value
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
            case .disableOnlineStatus:
                s.disableOnlineStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableTypingStatus:
                s.disableTypingStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableVCMessageRecordingStatus:
                s.disableVCMessageRecordingStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableVCMessageUploadingStatus:
                s.disableVCMessageUploadingStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableUploadingFileStatus:
                s.disableUploadingFileStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableUploadingPhotoStatus:
                s.disableUploadingPhotoStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableUploadingVideoStatus:
                s.disableUploadingVideoStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableRecordingVideoStatus:
                s.disableRecordingVideoStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableChoosingLocationStatus:
                s.disableChoosingLocationStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableChoosingContactStatus:
                s.disableChoosingContactStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disablePlayingGameStatus:
                s.disablePlayingGameStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableRecordingRoundVideoStatus:
                s.disableRecordingRoundVideoStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableUploadingRoundVideoStatus:
                s.disableUploadingRoundVideoStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableSpeakingInGroupCallStatus:
                s.disableSpeakingInGroupCallStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableChoosingStickerStatus:
                s.disableChoosingStickerStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableEmojiInteractionStatus:
                s.disableEmojiInteractionStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableEmojiAcknowledgementStatus:
                s.disableEmojiAcknowledgementStatus = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableMessageReadReceipt:
                s.disableMessageReadReceipt = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .disableStoryReadReceipt:
                s.disableStoryReadReceipt = value
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .enableOnlineStatusRecording:
                s.enableOnlineStatusRecording = value
                simplePromise.set(true)
            case .fakeLocationEnabled:
                s.fakeLocationEnabled = value
                simplePromise.set(true)
            case .ghostModeMessageSendDelay:
                s.ghostModeMessageSendDelaySeconds = value ? 12 : 0
                simplePromise.set(true)
            case .ghostModeEnabled:
                s.applyGhostModeAll(enabled: value)
                simplePromise.set(true)
            case .ghostModeFakeTyping: s.ghostModeFakeTyping = value; simplePromise.set(true)
            case .ghostModeAntiSpam: s.ghostModeAntiSpam = value
            case .ghostModeHideVideoWatch: s.ghostModeHideVideoWatch = value
            case .ghostModeAutoCleanHistory: s.ghostModeAutoCleanHistory = value
            case .ghostModeAlwaysOnline:
                s.ghostModeAlwaysOnline = value
                if value { s.disableOnlineStatus = false }
                NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
                simplePromise.set(true)
            case .liquidGlassEnabled: s.liquidGlassEnabled = value; NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
            case .namelessLiquidGlassMessages: s.namelessLiquidGlassMessages = value; NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
            case .namelessLiquidGlassOutgoingMessages: s.namelessLiquidGlassOutgoingMessages = value; NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
            case .namelessLiquidGlassSettings: s.namelessLiquidGlassSettings = value; NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
            case .namelessLiquidGlassProfile: s.namelessLiquidGlassProfile = value; NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
            case .namelessLiquidGlassProfileGifts: s.namelessLiquidGlassProfileGifts = value; NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
            case .namelessLiquidGlassInlineButtons: s.namelessLiquidGlassInlineButtons = value; NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
            case .namelessLiquidGlassTinting: s.namelessLiquidGlassTinting = value; NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
            case .namelessLiquidGlassPopup: s.namelessLiquidGlassPopup = value; NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
            case .namelessLiquidGlassContextMenu: s.namelessLiquidGlassContextMenu = value; NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
            case .namelessLiquidGlassSearch: s.namelessLiquidGlassSearch = value; NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
            case .namelessLiquidGlassFadeAnimation: s.namelessLiquidGlassFadeAnimation = value
            case .enableTelescope: s.enableTelescope = value
            case .emojiDownloaderEnabled: s.emojiDownloaderEnabled = value
            case .enableVideoToCircleOrVoice: s.enableVideoToCircleOrVoice = value
            case .namelessVideoBackgroundEnabled: s.namelessVideoBackgroundEnabled = value
            case .squareAvatars: s.squareAvatars = value
            case .newChatList: s.newChatList = value
            case .newChatHeader: s.newChatHeader = value
            case .blurInsteadGlass: s.blurInsteadGlass = value
            case .oledMode: s.oledMode = value
            case .customSettingsIcons: s.customSettingsIcons = value
            case .telegramAppIcons: s.telegramAppIcons = value
            case .swipeChatOptions: s.swipeChatOptions = value
            case .hideVoiceRecordButton: s.hideVoiceRecordButton = value
            case .foldersAtBottom: s.foldersAtBottom = value
            case .ramUsageUnderClock: s.ramUsageUnderClock = value
            case .chatListTitle: s.chatListTitle = value
            case .premiumStatusInHeader: s.premiumStatusInHeader = value
            case .searchButtonInChatList: s.searchButtonInChatList = value
            case .unlimitedPinnedChats: s.unlimitedPinnedChats = value
            case .newAccountSwitcher: s.newAccountSwitcher = value
            case .profileColorBackground: s.profileColorBackground = value
            case .profileAvatarBlur: s.profileAvatarBlur = value
            case .profileAvatarBlurMinimal: s.profileAvatarBlurMinimal = value
            case .profileAvatarBlurTinting: s.profileAvatarBlurTinting = value
            case .musicAlbumBlur: s.musicAlbumBlur = value
            case .musicPlayerEffect: s.musicPlayerEffect = value
            case .messageOutline: s.messageOutline = value
            case .messageTransparent: s.messageTransparent = value
            case .messageSemiTransparent: s.messageSemiTransparent = value
            case .messageBlurEffect: s.messageBlurEffect = value
            case .wideChannelPosts: s.wideChannelPosts = value
            case .particleEffectEnabled: s.particleEffectEnabled = value
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
            case .cameraUseDeviceMicrophone: s.cameraUseDeviceMicrophone = value
            case .cameraSendHDPhoto: s.cameraSendHDPhoto = value
            case .cameraRememberLast: s.cameraRememberLast = value
            case .cameraStaticZoom: s.cameraStaticZoom = value
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
            case .liquidGlassIntensity:
                let newIntensity = Double(value) / 100.0
                if abs(s.namelessLiquidGlassIntensity - newIntensity) > 0.001 {
                    s.namelessLiquidGlassIntensity = newIntensity
                    NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
                    simplePromise.set(true)
                }
            case .cameraJpegQuality:
                if s.cameraJpegQuality != value { s.cameraJpegQuality = value; simplePromise.set(true) }
            case .particleEffectSpeed:
                let v = Double(value) / 100.0
                if abs(s.particleEffectSpeed - v) > 0.001 { s.particleEffectSpeed = v; simplePromise.set(true) }
            case .particleEffectDensity:
                let v = Double(value) / 100.0
                if abs(s.particleEffectDensity - v) > 0.001 { s.particleEffectDensity = v; simplePromise.set(true) }
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
            if link == .ghostDetailsToggle {
                updateState { state in
                    var updated = state
                    updated.ghostModeExpanded.toggle()
                    return updated
                }
                return
            }
            if link == .onlineHistory {
                pushControllerImpl?(namelessOnlineHistoryController(context: context))
                return
            }
            if link == .fakeLocationPicker {
                let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                pushControllerImpl?(FakeLocationPickerController(presentationData: presentationData, onSave: {
                    simplePromise.set(true)
                }))
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
    |> map { _, state, presentationData -> (ItemListControllerState, (ItemListNodeState, NLArguments)) in
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
