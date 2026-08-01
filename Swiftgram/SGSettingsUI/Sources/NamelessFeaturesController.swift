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
    case hubPill11 = 21
    case hubPill12 = 22
    case hubPill13 = 23
    case hubPill14 = 24
    case hubPill15 = 25
    case hubPill16 = 26
    case hubPill17 = 27
    case hubPill18 = 28
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
    case localStarsEnabled
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
    case namelessCompactAttachmentSheet
    case enableTelescope
    case emojiDownloaderEnabled
    case hideNewChatSticker
    case hideBusinessChats
    case settingsBigAvatar
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
    case showIfMutualContacts
    case showRegistrationDate
    // Additional
    case vibrationEnabled
    case speedBoostEnabled
    // MARK: Megram — Nextgram parity toggles (UI only, wiring intentionally deferred)
    case nxHideGiftsTab
    case nxHideContactsTab
    case nxHideCallsTab
    case nxSearchButtonNearTabBar
    case nxFoldersAtBottom
    case nxRememberLastFolder
    case nxNewChatListLook
    case nxHideChatsTitle
    case nxRamUnderClock
    case nxPremiumBadgeInChatList
    case nxAccountSwitcherInChatList
    case nxPipOnSwipe
    case nxRoundVideoBackCamera
    case nxCameraInGallery
    case nxStripPhotoMetadata
    case nxFormattingPanel
    case nxVoiceOneTime
    case nxTranscribeAppleSpeech
    case nxVoiceMorpherEnabled
    case nxForceTCPCalls
    case nxMusicCrossfade
    case nxMusicEqualizer
    case nxLiveActivityWidget
    case nxWinterSnow
    case nxCustomFontEnabled
    case nxAutoClearCacheOnLaunch
    case nxHapticsOnUI
    case nxThermalCalmDown
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
    case hubLiquidGlass
    case hubProfiles
    case hubTabs
    case hubFolders
    case hubChatList
    case hubStories
    case hubMediaCamera
    case hubInputEmoji
    case hubVoice
    case hubVoiceMorph
    case hubCalls
    case hubMusic
    case hubNetwork
    case hubSettingsSections
    case hubBackup
    case hubMisc
    case onlineHistory
    case ghostDetailsToggle
    case fakeLocationPicker
    case localStarsAmount
    case deviceModelSpoof
    case accountSwitcher
    case pluginsCenter
    case localGiftsShop
}

private enum NLAction: Int, CaseIterable {
    case exportSettings
    case importSettings
    case saveKeychain
    case resetAll
    case resetLocalStars
}

private enum NLHubCategory: String, CaseIterable {
    case search
    case appearance
    case liquidGlass
    case profiles
    case tabs
    case folders
    case chatList
    case stories
    case mediaCamera
    case inputEmoji
    case voice
    case voiceMorph
    case calls
    case music
    case network
    case settingsSections
    case backup
    case misc
    case ghost
    case other
    case plugins

    /// The shelves shown at the hub root, in order. Everything else in this enum still exists as a
    /// destination (deep links, search results) but is deliberately absent from the root: the hub
    /// is a short list of places, not an index of every switch in the client.
    static let rootCategories: [NLHubCategory] = [
        .appearance,
        .profiles,
        .ghost,
        .tabs,
        .settingsSections,
        .plugins,
        .misc
    ]

    var titleRu: String {
        switch self {
        case .search: return "Поиск"
        case .appearance: return "Внешний вид"
        case .liquidGlass: return "Стекло и эффекты"
        case .profiles: return "Профили"
        case .tabs: return "Вкладки"
        case .folders: return "Папки"
        case .chatList: return "Список чатов"
        case .stories: return "Истории"
        case .mediaCamera: return "Медиа и камера"
        case .inputEmoji: return "Ввод и эмодзи"
        case .voice: return "Голосовые"
        case .voiceMorph: return "Смена голоса"
        case .calls: return "Звонки"
        case .music: return "Музыка"
        case .network: return "Сеть"
        case .settingsSections: return "Разделы настроек"
        case .backup: return "Резервная копия"
        case .misc: return "Прочее"
        case .ghost: return "Режим призрака"
        case .other: return "Прочие функции"
        case .plugins: return "Плагины"
        }
    }

    var subtitleRu: String {
        switch self {
        case .search: return "Найти и перейти к настройке"
        case .appearance: return "Интерфейс, сообщения, Liquid Glass, камера"
        case .liquidGlass: return "Liquid Glass, блюр и сообщения"
        case .profiles: return "ID и дополнения профиля"
        case .tabs: return "Панель вкладок"
        case .folders: return "Папки чатов"
        case .chatList: return "Внешний вид и свайп-действия"
        case .stories: return "Запись и репост"
        case .mediaCamera: return "Видео, фото и камера"
        case .inputEmoji: return "Клавиатура, ввод и эмодзи"
        case .voice: return "Микрофон и голосовые"
        case .voiceMorph: return "Пресеты и свой голос"
        case .calls: return "Подтверждение звонков"
        case .music: return "Плеер, кроссфейд и эквалайзер"
        case .network: return "Ускорение отправки и загрузки"
        case .settingsSections: return "Скрытие стандартных разделов"
        case .backup: return "JSON и Keychain"
        case .misc: return "Разное"
        case .ghost: return "Онлайн, прочтение, приватность, геолокация"
        case .other: return "Контекст, сторис, медиа, экспорт"
        case .plugins: return "Установленные расширения клиента"
        }
    }

    var pillSection: NLSectionId {
        switch self {
        case .search: return .hubPill0
        case .appearance: return .hubPill1
        case .liquidGlass: return .hubPill2
        case .profiles: return .hubPill3
        case .tabs: return .hubPill4
        case .folders: return .hubPill5
        case .chatList: return .hubPill6
        case .stories: return .hubPill7
        case .mediaCamera: return .hubPill8
        case .inputEmoji: return .hubPill9
        case .voice: return .hubPill10
        case .voiceMorph: return .hubPill11
        case .calls: return .hubPill12
        case .music: return .hubPill13
        case .network: return .hubPill14
        case .settingsSections: return .hubPill15
        case .backup: return .hubPill16
        case .misc: return .hubPill17
        case .ghost: return .hubPill18
        case .other: return .hubActions
        case .plugins: return .hubPill2
        }
    }

    var disclosure: NLDisclosureLink {
        switch self {
        case .search: return .hubSearch
        case .appearance: return .hubAppearance
        case .liquidGlass: return .hubLiquidGlass
        case .profiles: return .hubProfiles
        case .tabs: return .hubTabs
        case .folders: return .hubFolders
        case .chatList: return .hubChatList
        case .stories: return .hubStories
        case .mediaCamera: return .hubMediaCamera
        case .inputEmoji: return .hubInputEmoji
        case .voice: return .hubVoice
        case .voiceMorph: return .hubVoiceMorph
        case .calls: return .hubCalls
        case .music: return .hubMusic
        case .network: return .hubNetwork
        case .settingsSections: return .hubSettingsSections
        case .backup: return .hubBackup
        case .misc: return .hubMisc
        case .ghost: return .hubGhost
        case .other: return .hubOther
        // Plugins is not a list of toggles, so it links straight to its own screen instead of
        // opening a hub category.
        case .plugins: return .pluginsCenter
        }
    }

    static func from(link: NLDisclosureLink) -> NLHubCategory? {
        switch link {
        case .hubAppearance: return .appearance
        case .hubSearch: return .search
        case .hubLiquidGlass: return .liquidGlass
        case .hubProfiles: return .profiles
        case .hubTabs: return .tabs
        case .hubFolders: return .folders
        case .hubChatList: return .chatList
        case .hubStories: return .stories
        case .hubMediaCamera: return .mediaCamera
        case .hubInputEmoji: return .inputEmoji
        case .hubVoice: return .voice
        case .hubVoiceMorph: return .voiceMorph
        case .hubCalls: return .calls
        case .hubMusic: return .music
        case .hubNetwork: return .network
        case .hubSettingsSections: return .settingsSections
        case .hubBackup: return .backup
        case .hubMisc: return .misc
        case .hubGhost: return .ghost
        case .hubOther: return .other
        case .none, .onlineHistory, .ghostDetailsToggle, .fakeLocationPicker, .localStarsAmount, .deviceModelSpoof, .accountSwitcher, .pluginsCenter, .localGiftsShop: return nil
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
    // MARK: Nameless — additional entries so every toggle is searchable
    // Appearance
    NLSearchableItem(title: "Надпись «Чаты» в списке", category: .appearance),
    NLSearchableItem(title: "Кнопка поиска в списке чатов", category: .appearance),
    NLSearchableItem(title: "Премиум-статус в шапке", category: .appearance),
    NLSearchableItem(title: "ОЗУ под часами", category: .appearance),
    NLSearchableItem(title: "Скрыть номер в настройках", category: .appearance),
    NLSearchableItem(title: "Скрыть «Все чаты»", category: .appearance),
    NLSearchableItem(title: "Скрыть истории", category: .appearance),
    NLSearchableItem(title: "Блюр вместо Liquid Glass", category: .appearance),
    NLSearchableItem(title: "Полупрозрачные сообщения", category: .appearance),
    NLSearchableItem(title: "Компактный превью сообщений", category: .appearance),
    NLSearchableItem(title: "Подписи вкладок таббара", category: .appearance),
    NLSearchableItem(title: "Круглые вкладки", category: .appearance),
    NLSearchableItem(title: "Свайп-опции чатов", category: .appearance),
    NLSearchableItem(title: "Эффект удаления сообщений", category: .appearance),
    NLSearchableItem(title: "Стандартные эмодзи первыми", category: .appearance),
    NLSearchableItem(title: "Сохранять историю чатов", category: .appearance),
    NLSearchableItem(title: "Локальное редактирование сообщений", category: .appearance),
    NLSearchableItem(title: "История чатов (сохранение)", category: .appearance),
    NLSearchableItem(title: "Одноразовые медиа в галерею", category: .appearance),
    NLSearchableItem(title: "Не слушать следующее голосовое", category: .appearance),
    NLSearchableItem(title: "Полупрозрачно когда отмечают", category: .appearance),
    NLSearchableItem(title: "Кнопка «Наверх»", category: .appearance),
    NLSearchableItem(title: "Скролл к следующему каналу", category: .appearance),
    NLSearchableItem(title: "Стиль автоформатирования", category: .appearance),
    NLSearchableItem(title: "Анимация фейда Liquid Glass", category: .appearance),
    NLSearchableItem(title: "Стекло: входящие сообщения", category: .appearance),
    NLSearchableItem(title: "Стекло: исходящие сообщения", category: .appearance),
    NLSearchableItem(title: "Стекло: настройки", category: .appearance),
    NLSearchableItem(title: "Стекло: профиль", category: .appearance),
    NLSearchableItem(title: "Стекло: подарки в профиле", category: .appearance),
    NLSearchableItem(title: "Стекло: инлайн-кнопки ботов", category: .appearance),
    NLSearchableItem(title: "Стекло: всплывающие окна", category: .appearance),
    NLSearchableItem(title: "Стекло: контекстное меню", category: .appearance),
    NLSearchableItem(title: "Стекло: панель поиска", category: .appearance),
    NLSearchableItem(title: "Стекло: тонирование", category: .appearance),
    NLSearchableItem(title: "Интенсивность Liquid Glass", category: .appearance),
    NLSearchableItem(title: "Задняя камера по умолчанию", category: .appearance),
    NLSearchableItem(title: "Микрофон устройства (камера)", category: .appearance),
    NLSearchableItem(title: "Качество JPEG камеры", category: .appearance),
    NLSearchableItem(title: "Видео → кружок или голосовое", category: .appearance),
    NLSearchableItem(title: "Минимальный блюр аватара", category: .appearance),
    NLSearchableItem(title: "Тонирование блюра аватара", category: .appearance),
    NLSearchableItem(title: "Иконки приложения Telegram", category: .appearance),
    // Ghost
    NLSearchableItem(title: "Скрыть отправку голосового", category: .ghost),
    NLSearchableItem(title: "Скрыть запись видео", category: .ghost),
    NLSearchableItem(title: "Если взаимно в контактах", category: .ghost),
    NLSearchableItem(title: "Показывать DC", category: .ghost),
    // Other
    NLSearchableItem(title: "Временные метки на стикерах", category: .other),
    NLSearchableItem(title: "Предупреждение при открытии сторис", category: .other),
    NLSearchableItem(title: "Системный шэринг", category: .other),
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

// MARK: Nameless — search helper.
// Extracts the user-visible title from any entry kind that a settings search should surface.
// Section headers, notice text, and search inputs are intentionally skipped.
private func nlSearchableTitle(from entry: NLEntry) -> String {
    switch entry {
    case let .toggle(_, _, _, _, text, _):
        return text
    case let .toggleWithIcon(_, _, _, _, text, _, _):
        return text
    case let .disclosure(_, _, _, text):
        return text
    case let .disclosureDetail(_, _, _, text, _):
        return text
    case let .oneFromManySelector(_, _, _, text, _, _):
        return text
    case let .action(_, _, _, text, _):
        return text
    default:
        return ""
    }
}

// MARK: - Build Entries

// MARK: - Category whitelists
//
// The category screens are all assembled by one long builder, so the switches a category is meant
// to show are declared here and applied to the finished list. Filtering the result is both smaller
// and safer than threading a condition through several hundred `entries.append` calls — and it
// makes the intended contents of a tab readable in one place instead of scattered through the
// builder.

/// "Внешний вид" — exactly these switches, in the order the builder already emits them.
private let nlAppearanceWhitelist: Set<NLBoolSetting> = [
    .squareAvatars,
    .unlimitedPinnedChats,
    .showTabNames,
    .roundTabs,
    .sendWithReturnKey,
    .disableSnapDeletionEffect,
    .forceEmojiTab,
    .hideNewChatSticker,
    .hideBusinessChats,
    .truncateLongMessages,
    .noAutoNextVoice,
    .charCounterInput,
    .charCounterInChat,
    .disableScrollToNextChannel2,
    .namelessLiquidGlassMessages,
    .namelessCompactAttachmentSheet,
    .cameraSendHDPhoto,
    .cameraAlwaysSendHD
]

/// Drops switches outside `allowed`, then drops any header left standing over nothing.
private func nlFiltered(_ entries: [NLEntry], keeping allowed: Set<NLBoolSetting>) -> [NLEntry] {
    var kept: [NLEntry] = []
    for entry in entries {
        switch entry {
        case let .toggle(_, _, settingName, _, _, _), let .toggleWithIcon(_, _, settingName, _, _, _, _):
            if allowed.contains(settingName) {
                kept.append(entry)
            }
        default:
            kept.append(entry)
        }
    }

    var pruned: [NLEntry] = []
    for (index, entry) in kept.enumerated() {
        if case .header = entry {
            // A header is only worth keeping when something other than the next header follows it.
            guard let next = kept[kept.index(after: index)...].first else {
                continue
            }
            if case .header = next {
                continue
            }
        }
        pruned.append(entry)
    }
    return pruned
}

private func nlBuildEntries(presentationData: PresentationData, state: NLControllerState, simpleUpdated: Bool) -> [NLEntry] {
    let s = SGSimpleSettings.shared
    var entries: [NLEntry] = []
    let id = SGItemListCounter()
    let query = (state.searchQuery ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let searching = !query.isEmpty

    // Hub root — 4 glass pills.
    // MARK: Nameless — dropped the "12.8 · Liquid Glass edition" tagline; it drifted out of
    // sync with the actual version and cluttered the header.
    // MARK: Nameless — dropped: hero "MEGRAM" plate (the app title is already in the nav
    // bar), the top search input (only the bottom one is kept), and the Export / Import /
    // Reset actions from the hub root per user request.
    if !searching, state.hubCategory == nil {
        // The quick account switcher used to sit here. Telegram's own switcher is one tap away in
        // the settings header, so a second one only made the hub root longer.
        for cat in NLHubCategory.rootCategories {
            entries.append(.disclosureDetail(
                id: id.count,
                section: cat.pillSection,
                link: cat.disclosure,
                text: cat.titleRu,
                detail: cat.subtitleRu
            ))
        }
        entries.append(.searchInput(id: id.count, section: .search, title: NSAttributedString(string: "🔍"), text: state.searchQuery ?? "", placeholder: "Поиск настроек"))
        return filterSGItemListUIEntrires(entries: entries, by: state.searchQuery)
    }

    // MARK: Nameless — search results. Instead of relying on the hand-maintained
    // `nlSearchIndex` (which drifts out of sync every time we add a toggle), rebuild the
    // full three-category tree with a throwaway id counter and pull the title/category
    // out of every renderable row. Anything the user can see anywhere in the settings is
    // then guaranteed to be searchable, and the fixed nlSearchIndex is only used as a
    // supplement for aliases (e.g. English keywords for Russian titles).
    if searching {
        entries.append(.searchInput(id: id.count, section: .search, title: NSAttributedString(string: "🔍"), text: state.searchQuery ?? "", placeholder: "Поиск настроек..."))
        var seen = Set<String>()
        var results: [(title: String, category: NLHubCategory)] = []

        for cat in [NLHubCategory.appearance, .ghost, .other] {
            var catState = NLControllerState()
            catState.hubCategory = cat
            catState.ghostModeExpanded = true
            let catEntries = nlBuildEntries(presentationData: presentationData, state: catState, simpleUpdated: false)
            for entry in catEntries {
                let title = nlSearchableTitle(from: entry)
                guard !title.isEmpty else { continue }
                guard title.lowercased().contains(query) else { continue }
                let key = title.lowercased()
                if seen.insert(key).inserted {
                    results.append((title: title, category: cat))
                }
            }
        }
        for extra in nlSearchIndex where extra.title.lowercased().contains(query) {
            let key = extra.title.lowercased()
            if seen.insert(key).inserted {
                results.append((title: extra.title, category: extra.category))
            }
        }

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
    let appearanceCategories: Set<NLHubCategory> = [.appearance, .liquidGlass, .profiles, .tabs, .folders, .chatList, .stories, .mediaCamera, .inputEmoji, .voice, .calls, .music]
    let ghostCategories: Set<NLHubCategory> = [.ghost]
    let otherCategories: Set<NLHubCategory> = [.other, .voiceMorph, .network, .settingsSections, .backup, .misc]
    let showAppearance = cat == nil || cat.map { appearanceCategories.contains($0) } == true
    let showGhost = cat == nil || cat.map { ghostCategories.contains($0) } == true
    let showOther = cat == nil || cat.map { otherCategories.contains($0) } == true

    // ═══════════════════════════════════════════
    // ВНЕШНИЙ ВИД — интерфейс + сообщения + Liquid Glass + камера + медиа + информация
    // ═══════════════════════════════════════════
    // MARK: Nameless — trimmed appearance tab: only toggles the audit confirmed as WIRED,
    // grouped tighter, with short descriptions under the non-obvious ones. Dead toggles
    // (newChatList, chatListTitle, searchButtonInChatList, premiumStatusInHeader,
    // foldersAtBottom, ramUsageUnderClock, newChatHeader, newAccountSwitcher, sendWithReturnKey,
    // saveEditHistory, enableLocalMessageEditing, saveChatHistory, saveOnceMedia,
    // noAutoNextVoice (wired but confusing), doubleTapToEdit, scrollToTopButtonEnabled,
    // showOriginalEdited, camera/particle/profile-blur/icons/music noise) removed.
    if showAppearance {

    // СПИСОК ЧАТОВ
    entries.append(.header(id: id.count, section: sec, text: "СПИСОК ЧАТОВ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .squareAvatars, value: s.squareAvatars, text: "Квадратные аватары", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .compactChatList, value: s.compactChatList, text: "Компактный список чатов", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Уменьшенные аватары и одна строка превью — больше чатов помещается на экран."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .unlimitedPinnedChats, value: s.unlimitedPinnedChats, text: "Безлимитное закрепление", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hidePhoneInSettings, value: s.hidePhoneInSettings, text: "Скрыть номер в настройках", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .allChatsHidden, value: s.allChatsHidden, text: "Скрыть «Все чаты»", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideStories, value: s.hideStories, text: "Скрыть истории", enabled: true))

    // ЧАТ И ИНТЕРФЕЙС
    entries.append(.header(id: id.count, section: sec, text: "ЧАТ И ИНТЕРФЕЙС", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .oledMode, value: s.oledMode, text: "OLED-режим (чёрный фон)", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .wideChannelPosts, value: s.wideChannelPosts, text: "Широкие посты в каналах", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .messageOutline, value: s.messageOutline, text: "Обводка сообщений", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .messageTransparent, value: s.messageTransparent, text: "Прозрачные сообщения", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .messageSemiTransparent, value: s.messageSemiTransparent, text: "Полупрозрачные сообщения", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .messageBlurEffect, value: s.messageBlurEffect, text: "Размытие фона сообщений", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Пузырь становится матовым и размывает обои чата за собой."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .compactMessagePreview, value: s.chatListLines != SGSimpleSettings.ChatListLines.three.rawValue, text: "Компактный превью", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .showTabNames, value: s.showTabNames, text: "Подписи вкладок", enabled: !s.hideTabBar))
    entries.append(.toggle(id: id.count, section: sec, settingName: .roundTabs, value: s.roundTabs, text: "Круглые вкладки", enabled: !s.hideTabBar))
    entries.append(.notice(id: id.count, section: sec, text: "Иконки таббара и кнопки профиля становятся круглыми со стеклом (только на iOS 26)."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideTabBar, value: s.hideTabBar, text: "Скрыть нижний таббар", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableChatSwipeOptions, value: !s.disableChatSwipeOptions, text: "Свайп-опции чатов", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideRecordingButton, value: !s.hideRecordingButton, text: "Кнопка записи голосовых", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .sendWithReturnKey, value: s.sendWithReturnKey, text: "Отправка по Return", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .secondsInMessages, value: s.secondsInMessages, text: "Секунды в метке времени", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideReactions, value: s.hideReactions, text: "Скрыть реакции", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableSnapDeletionEffect, value: !s.disableSnapDeletionEffect, text: "Эффект удаления", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .forceEmojiTab, value: s.forceEmojiTab, text: "Вкладка эмодзи первой", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .defaultEmojisFirst, value: s.defaultEmojisFirst, text: "Стандартные эмодзи первыми", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideNewChatSticker, value: s.hideNewChatSticker, text: "Скрыть приветственный стикер", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "В пустом чате не показывается большой стикер-приветствие, чтобы случайно не отправить его тапом."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .hideBusinessChats, value: s.hideBusinessChats, text: "Скрыть панель бизнес-бота", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Убирает баннер «бот управляет этим чатом» с кнопкой СТОП сверху чатов, делегированных Telegram Business ассистенту."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .settingsBigAvatar, value: s.settingsBigAvatar, text: "Большой аватар в шапке настроек", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Настройки открываются с уже развёрнутой фотографией во всю ширину, имя и юзернейм — поверх снизу."))

    // СООБЩЕНИЯ · ПОВЕДЕНИЕ
    entries.append(.header(id: id.count, section: sec, text: "СООБЩЕНИЯ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .truncateLongMessages, value: s.truncateLongMessages, text: "Сокращать длинные сообщения", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Длинные тексты в чате обрезаются с ссылкой «Ещё», как в предпросмотрах."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .noAutoNextVoice, value: s.noAutoNextVoice, text: "Не слушать след. голосовое", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "После окончания голосового следующее не запускается автоматически."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .charCounterInput, value: s.charCounterInput, text: "Счётчик символов при вводе", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .charCounterInChat, value: s.charCounterInChat, text: "Счётчик символов в чате", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableScrollToNextChannel2, value: !s.disableScrollToNextChannel, text: "Скролл к следующему каналу", enabled: true))
    entries.append(.oneFromManySelector(id: id.count, section: sec, settingName: .autoFormatMode, text: "Стиль при отправке", value: NamelessAutoFormatMode(rawValue: s.autoFormatMode)?.titleRu ?? "Обычный", enabled: true))

    // LIQUID GLASS — один тумблер
    entries.append(.header(id: id.count, section: sec, text: "LIQUID GLASS", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .liquidGlassEnabled, value: s.liquidGlassEnabled, text: "Liquid Glass на сообщения", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessCompactAttachmentSheet, value: s.namelessCompactAttachmentSheet, text: "Стеклянное меню вложений", enabled: s.liquidGlassEnabled))
    entries.append(.notice(id: id.count, section: sec, text: "Пузыри сообщений становятся стеклянными, преломляя фон чата (только на iOS 26)."))

    // КАМЕРА · КАЧЕСТВО
    entries.append(.header(id: id.count, section: sec, text: "КАМЕРА · КАЧЕСТВО", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .cameraSendHDPhoto, value: s.cameraSendHDPhoto, text: "HD-фото при отправке", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .cameraAlwaysSendHD, value: s.cameraAlwaysSendHD, text: "Всегда в HD", enabled: true))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .cameraJpegQuality, value: s.cameraJpegQuality))
    entries.append(.notice(id: id.count, section: sec, text: "Качество JPEG исходящих фото. Больше — выше вес."))

    // ЦВЕТА · СТИКЕРЫ
    entries.append(.header(id: id.count, section: sec, text: "ЦВЕТА · СТИКЕРЫ", badge: nil))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .accountColorsSaturation, value: s.accountColorsSaturation))
    entries.append(.notice(id: id.count, section: sec, text: "Насыщенность цветов имён и аватарок."))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .stickerSize, value: s.stickerSize))
    entries.append(.notice(id: id.count, section: sec, text: "Размер стикеров в чате."))

    // ФОНОВЫЕ ФУНКЦИИ
    entries.append(.header(id: id.count, section: sec, text: "ДОП. ЭФФЕКТЫ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .namelessVideoBackgroundEnabled, value: s.namelessVideoBackgroundEnabled, text: "Видео-обои чата", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .confirmCalls, value: s.confirmCalls, text: "Подтверждение звонка", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Диалог подтверждения при тапе на кнопку звонка — защита от случайных нажатий."))

    } // end appearance

    // ═══════════════════════════════════════════
    // РЕЖИМ ПРИЗРАКА — статусы + приватность + конфиденциальность + геолокация + информация
    // ═══════════════════════════════════════════
    if showGhost {
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
    // "Выбирает локацию" / "выбирает контакт" are not real Telegram activities — there is no
    // such `SendMessageAction`, so no toggle can suppress them. Rows removed rather than left
    // as switches that silently do nothing.
    id.increment(2)
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
    entries.append(.toggle(id: id.count, section: sec, settingName: .showIfMutualContacts, value: s.showIfMutualContacts, text: "Если взаимно в контактах", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .showRegistrationDate, value: s.showRegistrationDate, text: "Дата регистрации аккаунта", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .showDC, value: s.showDC, text: "Показывать DC", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .disableCompactNumbers, value: !s.disableCompactNumbers, text: "Компактные числа", enabled: true))

    }
    } // end ghost

    // ═══════════════════════════════════════════
    // ПРОЧИЕ ФУНКЦИИ — контекст, сторис, фото, доп.
    // ═══════════════════════════════════════════
    if showOther {
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

    // ЛОКАЛЬНЫЙ ПРЕМИУМ И ЗВЁЗДЫ
    entries.append(.header(id: id.count, section: sec, text: "ЛОКАЛЬНЫЙ ПРЕМИУМ И ЗВЁЗДЫ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .enableLocalPremium, value: s.enableLocalPremium, text: "Локальный премиум", enabled: true))
    entries.append(.toggle(id: id.count, section: sec, settingName: .localStarsEnabled, value: s.localStarsEnabled, text: "Локальные звёзды", enabled: true))
    entries.append(.disclosureDetail(id: id.count, section: sec, link: .localStarsAmount, text: "Баланс звёзд", detail: "\(s.localStarsBalance) ⭐ из \(s.localStarsTopUp)"))
    entries.append(.disclosureDetail(id: id.count, section: sec, link: .localGiftsShop, text: "Локальные подарки", detail: "Каталог и покупка за локальные звёзды"))
    if s.localStarsSpent > 0 {
        entries.append(.action(id: id.count, section: sec, actionType: .resetLocalStars, text: "Пополнить (сбросить траты: \(s.localStarsSpent) ⭐)", kind: .generic))
    } else {
        id.increment(1)
    }
    entries.append(.notice(id: id.count, section: sec, text: "Баланс виден только вам и не связан с сервером. При отправке подарков и платных реакций сумма списывается локально."))

    // УСТРОЙСТВО
    entries.append(.header(id: id.count, section: sec, text: "УСТРОЙСТВО", badge: nil))
    entries.append(.disclosureDetail(id: id.count, section: sec, link: .deviceModelSpoof, text: "Название устройства", detail: s.deviceModelSpoof.isEmpty ? "Реальное (по умолчанию)" : s.deviceModelSpoof))
    entries.append(.notice(id: id.count, section: sec, text: "Отображается в списке активных сессий и в письмах о входе. Меняется при следующем подключении."))

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

    // MARK: Megram — Nextgram parity block. Every row below is UI-only for now
    // (no behavioural wiring). Layout mirrors the reference screen groups.
    entries.append(.header(id: id.count, section: sec, text: "NEXTGRAM · ТАББАР", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxHideContactsTab, value: s.nxHideContactsTab, text: "Скрыть вкладку «Контакты»", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Убирает «Контакты» из нижнего таббара, не затрагивая адресную книгу."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxHideCallsTab, value: s.nxHideCallsTab, text: "Скрыть вкладку «Звонки»", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Убирает «Звонки» из нижнего таббара, сохраняя историю звонков в других разделах."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxSearchButtonNearTabBar, value: s.nxSearchButtonNearTabBar, text: "Кнопка поиска рядом с таббаром", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Добавляет отдельную кнопку поиска рядом с нижним таббаром для быстрого доступа."))

    entries.append(.header(id: id.count, section: sec, text: "NEXTGRAM · ПАПКИ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxFoldersAtBottom, value: s.nxFoldersAtBottom, text: "Папки снизу", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Переносит выбор папок чатов к нижним элементам управления для удобства одной рукой."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxRememberLastFolder, value: s.nxRememberLastFolder, text: "Открывать последнюю папку", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Возвращает последнюю выбранную папку вместо постоянного открытия «Все чаты»."))

    entries.append(.header(id: id.count, section: sec, text: "NEXTGRAM · СПИСОК ЧАТОВ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxNewChatListLook, value: s.nxNewChatListLook, text: "Обновлённый вид списка чатов", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Применяет к списку диалогов обновлённую компоновку и оформление Megram."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxHideChatsTitle, value: s.nxHideChatsTitle, text: "Убрать надпись «Чаты»", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Скрывает крупный заголовок «Чаты», освобождая место над списком диалогов."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxRamUnderClock, value: s.nxRamUnderClock, text: "ОЗУ под часами", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Показывает текущее потребление памяти приложением под часами в статус-баре."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxPremiumBadgeInChatList, value: s.nxPremiumBadgeInChatList, text: "Premium-значок в списке", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Показывает ваш значок Premium в верхней части списка чатов."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxAccountSwitcherInChatList, value: s.nxAccountSwitcherInChatList, text: "Переключение аккаунтов в списке", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Добавляет быстрый переход между аккаунтами без открытия настроек."))

    entries.append(.header(id: id.count, section: sec, text: "NEXTGRAM · ПРОФИЛИ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxHideGiftsTab, value: s.nxHideGiftsTab, text: "Скрыть вкладку «Подарки»", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Скрывает вкладку «Подарки» в профиле."))

    entries.append(.header(id: id.count, section: sec, text: "NEXTGRAM · МЕДИА И КАМЕРА", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxPipOnSwipe, value: s.nxPipOnSwipe, text: "Картинка в картинке", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Свайп видео вверх для перехода в режим PiP."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxRoundVideoBackCamera, value: s.nxRoundVideoBackCamera, text: "Кружок с задней камеры", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Начинать запись видеосообщений с задней камеры."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxCameraInGallery, value: s.nxCameraInGallery, text: "Камера в галерее", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Показывать ячейку камеры в медиа-галерее."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxStripPhotoMetadata, value: s.nxStripPhotoMetadata, text: "Очищать метаданные", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Удаляет EXIF/геолокацию из отправляемых фото."))

    entries.append(.header(id: id.count, section: sec, text: "NEXTGRAM · ВВОД", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxFormattingPanel, value: s.nxFormattingPanel, text: "Панель форматирования", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Добавляет над клавиатурой панель для быстрого применения жирного, курсива, подчёркивания, зачёркивания, моноширинного, спойлера, цитаты и ссылок."))

    entries.append(.header(id: id.count, section: sec, text: "NEXTGRAM · ГОЛОСОВЫЕ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxVoiceOneTime, value: s.nxVoiceOneTime, text: "Записи сразу одноразовые", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Новые голосовые по умолчанию отправляются как одноразовые."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxTranscribeAppleSpeech, value: s.nxTranscribeAppleSpeech, text: "Транскрипция через Apple Speech", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Переводит голосовые сообщения и кружки в текст без ограничений и без Premium."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxVoiceMorpherEnabled, value: s.nxVoiceMorpherEnabled, text: "Смена голоса", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Применяет выбранный эффект к новым голосовым сообщениям и кружкам."))

    entries.append(.header(id: id.count, section: sec, text: "NEXTGRAM · ЗВОНКИ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxForceTCPCalls, value: s.nxForceTCPCalls, text: "Использовать TCP", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Принудительно использовать TCP для звонков."))

    entries.append(.header(id: id.count, section: sec, text: "NEXTGRAM · МУЗЫКА", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxMusicCrossfade, value: s.nxMusicCrossfade, text: "Кроссфейд", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Плавное переключение треков."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxMusicEqualizer, value: s.nxMusicEqualizer, text: "Эквалайзер", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Включает встроенный эквалайзер для плеера."))

    entries.append(.header(id: id.count, section: sec, text: "NEXTGRAM · ПРОЧЕЕ", badge: nil))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxLiveActivityWidget, value: s.nxLiveActivityWidget, text: "Live Activity виджет", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Чёрный виджет Megram с иконкой на экране блокировки, показывает входящие уведомления. Требует iOS 16.1+."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxWinterSnow, value: s.nxWinterSnow, text: "Новогодний снег в чате", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Показывать падающий снег поверх обоев чата и снежинки по краям виджета."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxCustomFontEnabled, value: s.nxCustomFontEnabled, text: "Использовать свой шрифт", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Позволяет заменить системный шрифт на пользовательский TTF/OTF."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxAutoClearCacheOnLaunch, value: s.nxAutoClearCacheOnLaunch, text: "Автоочистка кэша при входе", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Проверяет общий размер медиа-кэша при каждом входе и безопасно очищает его в фоне после достижения лимита."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxHapticsOnUI, value: s.nxHapticsOnUI, text: "Вибрация по интерфейсу", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "Добавляет лёгкий отклик при открытии чата, тапах и нарастающую вибрацию при раскрытии панели вложений."))
    entries.append(.toggle(id: id.count, section: sec, settingName: .nxThermalCalmDown, value: s.nxThermalCalmDown, text: "Успокаивать при нагреве", enabled: true))
    entries.append(.notice(id: id.count, section: sec, text: "При нагреве устройства Megram упрощает себя: стеклянные сообщения становятся сплошной заливкой, снег останавливается."))

    } // end other

    // Applied only to the category screen, never to search results or the hub root: a search for a
    // switch that lives elsewhere must still find it.
    if state.hubCategory == .appearance, state.searchQuery?.isEmpty ?? true {
        entries = nlFiltered(entries, keeping: nlAppearanceWhitelist)
    }

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
            case .enableLocalPremium: s.enableLocalPremium = value; askForRestart?()
            case .localStarsEnabled:
                s.localStarsEnabled = value
                NotificationCenter.default.post(name: .namelessLocalStarsDidChange, object: nil)
                simplePromise.set(true)
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
            // MARK: Nameless — every glass toggle must both repaint live surfaces
            // (`.luxgramLiquidGlassDidChange`) *and* rebuild this list (`simplePromise`),
            // otherwise the dependent rows keep their stale `enabled:` state until the
            // screen is re-entered.
            case .liquidGlassEnabled:
                s.liquidGlassEnabled = value
                NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
                simplePromise.set(true)
            case .namelessLiquidGlassMessages:
                s.namelessLiquidGlassMessages = value
                NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
                simplePromise.set(true)
            case .namelessLiquidGlassOutgoingMessages:
                s.namelessLiquidGlassOutgoingMessages = value
                NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
                simplePromise.set(true)
            case .namelessLiquidGlassSettings:
                s.namelessLiquidGlassSettings = value
                NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
                simplePromise.set(true)
            case .namelessLiquidGlassProfile:
                s.namelessLiquidGlassProfile = value
                NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
                simplePromise.set(true)
            case .namelessLiquidGlassProfileGifts:
                s.namelessLiquidGlassProfileGifts = value
                NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
                simplePromise.set(true)
            case .namelessLiquidGlassInlineButtons:
                s.namelessLiquidGlassInlineButtons = value
                NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
                simplePromise.set(true)
            case .namelessLiquidGlassTinting:
                s.namelessLiquidGlassTinting = value
                NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
                simplePromise.set(true)
            case .namelessLiquidGlassPopup:
                s.namelessLiquidGlassPopup = value
                NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
                simplePromise.set(true)
            case .namelessLiquidGlassContextMenu:
                s.namelessLiquidGlassContextMenu = value
                NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
                simplePromise.set(true)
            case .namelessLiquidGlassSearch:
                s.namelessLiquidGlassSearch = value
                NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
                simplePromise.set(true)
            case .namelessLiquidGlassFadeAnimation:
                s.namelessLiquidGlassFadeAnimation = value
                simplePromise.set(true)
            case .namelessCompactAttachmentSheet:
                s.namelessCompactAttachmentSheet = value
                simplePromise.set(true)
            case .enableTelescope: s.enableTelescope = value
            case .emojiDownloaderEnabled: s.emojiDownloaderEnabled = value
            case .hideNewChatSticker: s.hideNewChatSticker = value; askForRestart?()
            case .hideBusinessChats: s.hideBusinessChats = value; simplePromise.set(true)
            case .settingsBigAvatar: s.settingsBigAvatar = value; askForRestart?()
            // MARK: Megram — Nextgram parity handlers. Just persist the flag; no behaviour
            // is wired yet, so we don't call askForRestart/simplePromise here.
            case .nxHideGiftsTab: s.nxHideGiftsTab = value
            case .nxHideContactsTab: s.nxHideContactsTab = value
            case .nxHideCallsTab: s.nxHideCallsTab = value
            case .nxSearchButtonNearTabBar: s.nxSearchButtonNearTabBar = value
            case .nxFoldersAtBottom: s.nxFoldersAtBottom = value
            case .nxRememberLastFolder: s.nxRememberLastFolder = value
            case .nxNewChatListLook: s.nxNewChatListLook = value
            case .nxHideChatsTitle: s.nxHideChatsTitle = value
            case .nxRamUnderClock: s.nxRamUnderClock = value
            case .nxPremiumBadgeInChatList: s.nxPremiumBadgeInChatList = value
            case .nxAccountSwitcherInChatList: s.nxAccountSwitcherInChatList = value
            case .nxPipOnSwipe: s.nxPipOnSwipe = value
            case .nxRoundVideoBackCamera: s.nxRoundVideoBackCamera = value
            case .nxCameraInGallery: s.nxCameraInGallery = value
            case .nxStripPhotoMetadata: s.nxStripPhotoMetadata = value
            case .nxFormattingPanel: s.nxFormattingPanel = value
            case .nxVoiceOneTime: s.nxVoiceOneTime = value
            case .nxTranscribeAppleSpeech: s.nxTranscribeAppleSpeech = value
            case .nxVoiceMorpherEnabled: s.nxVoiceMorpherEnabled = value
            case .nxForceTCPCalls: s.nxForceTCPCalls = value
            case .nxMusicCrossfade: s.nxMusicCrossfade = value
            case .nxMusicEqualizer: s.nxMusicEqualizer = value
            case .nxLiveActivityWidget: s.nxLiveActivityWidget = value
            case .nxWinterSnow: s.nxWinterSnow = value
            case .nxCustomFontEnabled: s.nxCustomFontEnabled = value
            case .nxAutoClearCacheOnLaunch: s.nxAutoClearCacheOnLaunch = value
            case .nxHapticsOnUI: s.nxHapticsOnUI = value
            case .nxThermalCalmDown: s.nxThermalCalmDown = value
            case .enableVideoToCircleOrVoice: s.enableVideoToCircleOrVoice = value
            case .namelessVideoBackgroundEnabled: s.namelessVideoBackgroundEnabled = value
            case .squareAvatars: s.squareAvatars = value; simplePromise.set(true)
            case .newChatList: s.newChatList = value; askForRestart?()
            case .newChatHeader: s.newChatHeader = value; askForRestart?()
            case .blurInsteadGlass:
                // Kills glass in favour of plain blur — every registered surface has to repaint.
                s.blurInsteadGlass = value
                NotificationCenter.default.post(name: .luxgramLiquidGlassDidChange, object: nil)
                simplePromise.set(true)
            case .oledMode: s.oledMode = value; askForRestart?()
            case .customSettingsIcons: s.customSettingsIcons = value; simplePromise.set(true)
            case .telegramAppIcons: s.telegramAppIcons = value; simplePromise.set(true)
            case .swipeChatOptions: s.swipeChatOptions = value
            case .hideVoiceRecordButton: s.hideVoiceRecordButton = value
            case .foldersAtBottom: s.foldersAtBottom = value; askForRestart?()
            case .ramUsageUnderClock: s.ramUsageUnderClock = value; askForRestart?()
            case .chatListTitle: s.chatListTitle = value; askForRestart?()
            case .premiumStatusInHeader: s.premiumStatusInHeader = value; askForRestart?()
            case .searchButtonInChatList: s.searchButtonInChatList = value; askForRestart?()
            case .unlimitedPinnedChats: s.unlimitedPinnedChats = value
            case .newAccountSwitcher: s.newAccountSwitcher = value; askForRestart?()
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
            if link == .localStarsAmount {
                pushControllerImpl?(namelessLocalStarsController(context: context, onSave: {
                    simplePromise.set(true)
                }))
                return
            }
            if link == .deviceModelSpoof {
                pushControllerImpl?(namelessDeviceModelSpoofController(context: context, onSave: {
                    simplePromise.set(true)
                    askForRestart?()
                }))
                return
            }
            if link == .pluginsCenter {
                pushControllerImpl?(mgPluginsController(context: context))
                return
            }
            if link == .localGiftsShop {
                pushControllerImpl?(mgLocalGiftsController(context: context))
                return
            }
            if link == .accountSwitcher {
                namelessShowAccountSwitcher(context: context, present: { c, a in
                    presentControllerImpl?(c, a as? ViewControllerPresentationArguments)
                })
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
            case .resetLocalStars:
                SGSimpleSettings.shared.resetLocalStarsSpending()
                simplePromise.set(true)
            }
        },
        searchInput: { query in
            updateState { state in
                var updated = state
                updated.searchQuery = query
                return updated
            }
        },
        longPressBool: { setting in
            // MARK: Nameless — long-press on a toggle → tooltip with the full description
            // (or a generic fallback when the map doesn't have an entry for this key).
            let key = "\(setting)"
            let description = NamelessToggleDescriptions.text(for: key) ?? "Описание пока не написано."
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            presentControllerImpl?(
                UndoOverlayController(presentationData: presentationData, content: .info(title: nil, text: description, timeout: 4.0, customUndoText: nil), elevatedLayout: false, action: { _ in true }),
                nil
            )
        },
        boolDescription: { setting in
            return NamelessToggleDescriptions.text(for: "\(setting)") ?? "Локальная функция Megram. Работает только в этом клиенте и не меняет серверные данные Telegram."
        }
    )

    let signal = combineLatest(simplePromise.get(), statePromise.get(), context.sharedContext.presentationData)
    |> map { _, state, presentationData -> (ItemListControllerState, (ItemListNodeState, NLArguments)) in
        let entries = nlBuildEntries(presentationData: presentationData, state: state, simpleUpdated: true)
        let title = state.hubCategory?.titleRu ?? ""
        let cs = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title.isEmpty ? "MEGRAM" : title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
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
