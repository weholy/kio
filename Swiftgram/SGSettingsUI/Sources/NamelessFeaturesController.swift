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
import AlertUI
import OverlayStatusController
import SGAppearance

// MARK: - Section

/// Sections are handed out per switch, so each lands in its own rounded card
/// with its description sitting outside it underneath. A shared section glues
/// neighbouring switches into one block, which is what the old layout did.
/// Hashable is spelled out because the enum this replaced got it for free, and
/// the entry filter is generic over it.
private struct NLSectionId: SGItemListSection, Hashable {
    let rawValue: Int32

    static let search = NLSectionId(rawValue: 0)
    static let hero = NLSectionId(rawValue: 1)
    static let items = NLSectionId(rawValue: 2)
    static let actions = NLSectionId(rawValue: 3)

    // Hub category pills
    static let hubPill0 = NLSectionId(rawValue: 10)
    static let hubPill1 = NLSectionId(rawValue: 11)
    static let hubPill2 = NLSectionId(rawValue: 12)
    static let hubPill3 = NLSectionId(rawValue: 13)
    static let hubPill4 = NLSectionId(rawValue: 14)
    static let hubPill5 = NLSectionId(rawValue: 15)
    static let hubPill6 = NLSectionId(rawValue: 16)
    static let hubPill7 = NLSectionId(rawValue: 17)
    static let hubPill8 = NLSectionId(rawValue: 18)
    static let hubPill9 = NLSectionId(rawValue: 19)
    static let hubPill10 = NLSectionId(rawValue: 20)
    static let hubPill11 = NLSectionId(rawValue: 21)
    static let hubPill12 = NLSectionId(rawValue: 22)
    static let hubPill13 = NLSectionId(rawValue: 23)
    static let hubPill14 = NLSectionId(rawValue: 24)
    static let hubPill15 = NLSectionId(rawValue: 25)
    static let hubPill16 = NLSectionId(rawValue: 26)
    static let hubPill17 = NLSectionId(rawValue: 27)
    static let hubPill18 = NLSectionId(rawValue: 28)
    static let hubActions = NLSectionId(rawValue: 30)
    /// Developer links at the foot of the hub — one card each, so the logos sit
    /// on their own rounded panels rather than in a single stacked block.
    static let devHeader = NLSectionId(rawValue: 40)
    static let devChannel = NLSectionId(rawValue: 41)
    static let devVPN = NLSectionId(rawValue: 42)
    static let devSupport = NLSectionId(rawValue: 43)

    /// One block per feature. The range starts well past the fixed sections so
    /// the two can never collide.
    static func feature(_ index: Int) -> NLSectionId {
        return NLSectionId(rawValue: 100 + Int32(index))
    }
}

/// MARK: Megram — the tab follows Telegram's own language.
///
/// Held as one value rather than threaded through every helper: the category
/// titles and subtitles live on enums that never see the presentation data, and
/// passing it to each of them would mean touching every case for one string.
/// Set once per rebuild, read only on the main thread while the list is built.
private enum MegramLanguage {
    static var isRussian: Bool = true

    static func update(_ baseLanguageCode: String) {
        self.isRussian = baseLanguageCode.hasPrefix("ru")
    }
}

/// Picks the Russian or the English string for the current app language.
/// English is the fallback for every language that has no translation yet.
private func megramText(_ ru: String, _ en: String) -> String {
    return MegramLanguage.isRussian ? ru : en
}

/// Where the developer rows point. Kept in one place so filling in an address
/// is a single edit; an empty string means the row says so rather than opening
/// nothing at all.
private enum MegramDeveloperLinks {
    // Left blank deliberately: guessing a t.me address would ship a row that
    // opens somebody else's channel. The row says it is not set up yet until
    // the real addresses are filled in here.
    static let channel = ""
    static let vpn = ""
    static let support = ""
}

/// Hands out a fresh section for every switch.
private final class NLFeatureSections {
    private var next: Int = 0

    func take() -> NLSectionId {
        defer { self.next += 1 }
        return NLSectionId.feature(self.next)
    }
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
    // Megram profile
    case profileTrackCard
    case profileIdChips
    case hideProfileEmojiStatus
    case hideProfileColorRow
    case hideProfilePhotoRow
    case hideProfileIdRow
    // Megram peer menu
    case hideMenuWallpaper
    case hideMenuSecretChat
    case hideMenuSendContact
    case hideMenuAutoDelete
    case hideMenuCopyProtection
    case hideMenuClearHistory
    case hideMenuBlock
    // Megram tabs
    case hideBottomTabPanel
    case hideContactsTab
    case hideCallsTab
    case tabBarSearchNearBottom
    case hideProfileGiftsTab
    case deviceModelSpoofEnabled
    // Megram settings sections
    case hideSettingsFavorites
    case hideSettingsDevices
    case hideSettingsChatFolders
    case hideSettingsPowerSaving
    case hideSettingsLanguage
    case hideSettingsNotifications
    case hideSettingsPrivacy
    case hideSettingsDataAndStorage
    case hideSettingsAppearance
    case hideSettingsProxy
    case hideSettingsMyProfile
    case hideSettingsRecentCalls
    case hideSettingsPremium
    case hideSettingsStars
    case hideSettingsBusiness
    case hideSettingsSupport
    case hideSettingsFaq
    case hideSettingsTips
    case hideSettingsSendGift
    // Megram deleted messages
    // enableSavingSelfDestructingMessages is declared near the top of this enum.
    case dimIncomingWhileReplying
    case saveDeletedMessagesReactions
    // Megram decoration
    case globalVideoBackground
    case globalPhotoBackground
    case profileWallpaper
    case profileBannerPhoto
    case profileBannerVideo
    case megramHideGlassBorder
}

private enum NLSliderSetting: String {
    case outgoingPhotoQuality
    case stickerSize
    case accountColorsSaturation
    case liquidGlassIntensity
    case cameraJpegQuality
    case particleEffectSpeed
    case particleEffectDensity
    case tabBarHeight
    case tabBarWidth
    case deletedMessageOpacity
    case deletedTrashSize
    case backgroundOpacity
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
    case deletedDetailsToggle
    case deletedTrashDesigner
    case fakeLocationPicker
    case localStarsAmount
    case deviceModelSpoof
    case accountSwitcher
    case pluginsCenter
    case localGiftsShop
    case hubDecoration
    // Each opens the picker for its own appearance slot.
    case pickGlobalVideo
    case pickGlobalPhoto
    case pickProfileWallpaper
    case pickProfileBannerPhoto
    case pickProfileBannerVideo
    // Developer links at the foot of the hub. They open Telegram resources, so
    // they route through the app's own URL handling rather than a browser.
    case devChannel
    case devVPN
    case devSupport
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
    case decoration

    /// The shelves shown at the hub root, in order. Everything else in this enum still exists as a
    /// destination (deep links, search results) but is deliberately absent from the root: the hub
    /// is a short list of places, not an index of every switch in the client.
    static let rootCategories: [NLHubCategory] = [
        .appearance,
        .decoration,
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
        case .decoration: return "Оформление"
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
        case .decoration: return "Фоны, обои и баннеры профиля"
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
        case .decoration: return .hubPill17
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
        case .decoration: return .hubDecoration
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
        case .hubDecoration: return .decoration
        case .none, .onlineHistory, .ghostDetailsToggle, .deletedDetailsToggle, .deletedTrashDesigner, .fakeLocationPicker, .localStarsAmount, .deviceModelSpoof, .accountSwitcher, .pluginsCenter, .localGiftsShop,
             .pickGlobalVideo, .pickGlobalPhoto, .pickProfileWallpaper, .pickProfileBannerPhoto, .pickProfileBannerVideo,
             .devChannel, .devVPN, .devSupport: return nil
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
    var deletedMessagesExpanded: Bool = false
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

/// "Профиль" — what the profile screen shows about a peer.
private let nlProfileWhitelist: Set<NLBoolSetting> = [
    .showIdAndDC,
    .showDC,
    .hidePhoneNumber,
    .nxHideGiftsTab,
    .showIfMutualContacts,
    .showCreationDate,
    .showSeconds
]

/// "Вкладки" — the bottom tab bar. The height and width controls are sliders, which the filter
/// passes through untouched.
private let nlTabsWhitelist: Set<NLBoolSetting> = [
    .hideTabBar,
    .nxHideContactsTab,
    .nxHideCallsTab,
    .nxSearchButtonNearTabBar
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
    MegramLanguage.update(presentationData.strings.baseLanguageCode)
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
        entries.append(.searchInput(id: id.count, section: .search, title: NSAttributedString(string: "🔍"), text: state.searchQuery ?? "", placeholder: megramText("Поиск настроек", "Search settings")))

        // MARK: Megram — developer links, at the foot of the hub.
        entries.append(.header(id: id.count, section: .devHeader, text: megramText("РАЗРАБОТЧИК", "DEVELOPER"), badge: nil))
        entries.append(.disclosureWithIcon(id: id.count, section: .devChannel, link: .devChannel, text: megramText("Канал «Эйай в кармане»", "«AI in your pocket» channel"), iconRef: "MegramDevChannel"))
        entries.append(.disclosureWithIcon(id: id.count, section: .devVPN, link: .devVPN, text: "NeteVPN", iconRef: "MegramDevVPN"))
        entries.append(.disclosureWithIcon(id: id.count, section: .devSupport, link: .devSupport, text: megramText("Техническая поддержка", "Technical support"), iconRef: "MegramDevSupport"))

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
    // MARK: Megram — one rounded card per switch, description underneath.
    let featureSections = NLFeatureSections()
    func megramFeature(_ setting: NLBoolSetting, _ value: Bool, _ text: String, _ description: String? = nil, enabled: Bool = true) {
        let section = featureSections.take()
        entries.append(.toggle(id: id.count, section: section, settingName: setting, value: value, text: text, enabled: enabled))
        // Falls back to the shared description table so a switch converted from
        // a bare row keeps the text it already had, just below the card now.
        let note = description ?? NamelessToggleDescriptions.text(for: "\(setting)") ?? ""
        if !note.isEmpty {
            entries.append(.notice(id: id.count, section: section, text: note))
        }
    }
    let cat = state.hubCategory
    // MARK: Megram — each tab draws only its own block.
    //
    // Previously several categories shared one blanket flag, so opening Профиль
    // rendered the whole appearance block and every Nextgram-parity switch
    // underneath it. Matching the category exactly is what keeps a tab to its
    // own contents; the hub root (cat == nil) shows nothing but the pills.
    let showAppearance = cat == .appearance
    let showProfile = cat == .profiles
    let showTabs = cat == .tabs
    let showSettingsSections = cat == .settingsSections
    let showGhost = cat == .ghost
    let showOther = cat == .other
    let showDecoration = cat == .decoration

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

    // MARK: Megram — exactly the list the user specified, one card per switch.
    entries.append(.header(id: id.count, section: sec, text: "ВНЕШНИЙ ВИД", badge: nil))
    megramFeature(.squareAvatars, s.squareAvatars, "Квадратные аватары", "Аватары в списке чатов рисуются скруглённым квадратом вместо круга.")
    megramFeature(.unlimitedPinnedChats, s.unlimitedPinnedChats, "Безлимитное закрепление", "Снимает ограничение на число закреплённых чатов.")
    megramFeature(.showTabNames, s.showTabNames, "Подписи вкладок", "Показывает названия под значками нижней панели.")
    megramFeature(.roundTabs, s.roundTabs, "Круглые вкладки", "Значки нижней панели получают круглую подложку.")
    megramFeature(.sendWithReturnKey, s.sendWithReturnKey, "Отправка по Return", "Клавиша ввода отправляет сообщение, а не переносит строку.")
    megramFeature(.disableSnapDeletionEffect, !s.disableSnapDeletionEffect, "Эффект удаления", "Сообщение рассыпается при удалении. Выключите, чтобы оно исчезало сразу.")
    megramFeature(.forceEmojiTab, s.forceEmojiTab, "Вкладка эмодзи", "Клавиатура открывается на эмодзи, а не на стикерах.")
    megramFeature(.hideNewChatSticker, s.hideNewChatSticker, "Скрыть приветственный эмодзи", "В пустом чате не показывается большой стикер-приветствие, чтобы случайно не отправить его тапом.")
    megramFeature(.hideBusinessChats, s.hideBusinessChats, "Скрыть панель бизнес-бота", "Убирает баннер «бот управляет этим чатом» с кнопкой СТОП над перепиской.")
    megramFeature(.truncateLongMessages, s.truncateLongMessages, "Сокращать длинные сообщения", "Длинное сообщение сворачивается до нескольких строк с кнопкой «Ещё».")
    megramFeature(.charCounterInput, s.charCounterInput, "Счётчик символов при вводе", "Показывает число набранных символов над полем ввода.")
    megramFeature(.charCounterInChat, s.charCounterInChat, "Счётчик символов в чате", "Показывает длину сообщения рядом со временем отправки.")
    megramFeature(.disableScrollToNextChannel2, !s.disableScrollToNextChannel, "Скролл к следующему каналу", "Прокрутка за конец переписки переходит в следующий непрочитанный канал.")
    // Liquid Glass has no switch any more: it is always on, so a row here
    // would promise control that no longer exists.
    megramFeature(.namelessCompactAttachmentSheet, s.namelessCompactAttachmentSheet, "Стеклянное меню вложения", "Кнопка «+» открывает компактное стеклянное меню вместо стандартной панели.")
    megramFeature(.megramHideGlassBorder, s.megramHideGlassBorder, "Убрать полоску", "Убирает светлую обводку по краю стеклянных поверхностей — контекстного меню при удержании чата, карточек настроек, таблеток и панелей. Стекло остаётся, исчезает только рамка.")
    // Mutually exclusive: HD on demand and HD always answer the same question,
    // and leaving both on hides which one is in charge.
    megramFeature(.cameraSendHDPhoto, s.cameraSendHDPhoto, "HD-фото при отправке", "Кнопка «HD» в галерее отправляет фото без сжатия.", enabled: !s.cameraAlwaysSendHD)
    megramFeature(.cameraAlwaysSendHD, s.cameraAlwaysSendHD, "Всегда в HD", "Каждое фото уходит без сжатия. Отключает «HD-фото при отправке».")

    // Стикеры — ползунок оставлен как единственный размерный параметр вкладки.
    let stickerSection = featureSections.take()
    entries.append(.percentageSlider(id: id.count, section: stickerSection, settingName: .stickerSize, value: s.stickerSize))
    entries.append(.notice(id: id.count, section: stickerSection, text: "Размер стикеров и анимированных эмодзи в переписке."))

    } // end appearance

    // ═══════════════════════════════════════════
    // ОФОРМЛЕНИЕ — фоны, обои и баннеры из своей галереи
    // ═══════════════════════════════════════════
    if showDecoration {
    entries.append(.header(id: id.count, section: sec, text: "ФОН ПРИЛОЖЕНИЯ", badge: nil))

    // The picker row is always present. It used to appear only once the slot
    // reported itself enabled — and `isEnabled` is the switch AND a file on
    // disk, so with nothing picked yet the row never appeared, the switch sprang
    // straight back off, and there was no way in. The switch is what waits for
    // the file now, not the other way round.
    func decorationSlot(
        _ setting: NLBoolSetting,
        _ link: NLDisclosureLink,
        _ slot: MegramAppearanceStore.Slot,
        _ title: String,
        _ pickTitle: String,
        _ description: String
    ) {
        let section = featureSections.take()
        let hasMedia = MegramAppearanceStore.hasMedia(for: slot)
        entries.append(.toggle(id: id.count, section: section, settingName: setting, value: MegramAppearanceStore.isSwitchedOn(slot), text: title, enabled: hasMedia))
        entries.append(.disclosureDetail(
            id: id.count,
            section: section,
            link: link,
            text: hasMedia ? "Заменить или удалить" : pickTitle,
            detail: hasMedia ? "Файл выбран" : "Файл не выбран"
        ))
        entries.append(.notice(id: id.count, section: section, text: description))
    }

    decorationSlot(.globalVideoBackground, .pickGlobalVideo, .globalVideo, "Видео-фон", "Выбрать видео", "Зацикленное видео без звука за всеми экранами. При выборе видео сжимается до 720p и теряет звуковую дорожку.")
    decorationSlot(.globalPhotoBackground, .pickGlobalPhoto, .globalPhoto, "Фото-фон", "Выбрать фото", "Неподвижное изображение за всеми экранами. Если включён видео-фон, показывается он.")

    let opacitySection = featureSections.take()
    entries.append(.percentageSlider(id: id.count, section: opacitySection, settingName: .backgroundOpacity, value: Int32(MegramAppearanceStore.backgroundOpacity * 100.0)))
    entries.append(.notice(id: id.count, section: opacitySection, text: "Насколько фон просвечивает сквозь интерфейс. Чем выше, тем светлее фон и тем труднее читать текст."))

    entries.append(.header(id: id.count, section: sec, text: "ПРОФИЛЬ", badge: nil))
    decorationSlot(.profileWallpaper, .pickProfileWallpaper, .profileWallpaper, "Обои профиля", "Выбрать изображение", "Фон экрана профиля — своего и чужих.")
    decorationSlot(.profileBannerPhoto, .pickProfileBannerPhoto, .profileBannerPhoto, "Фото-баннер", "Выбрать фото", "Полоса от верха экрана до карточки трека в своём профиле. Видна только вам — отправить её собеседнику нельзя.")
    decorationSlot(.profileBannerVideo, .pickProfileBannerVideo, .profileBannerVideo, "Видео-баннер", "Выбрать видео", "То же место, но зацикленным видео. Если включены оба баннера, показывается видео.")
    } // end decoration

    // ═══════════════════════════════════════════
    // РЕЖИМ ПРИЗРАКА — статусы + приватность + конфиденциальность + геолокация + информация
    // ═══════════════════════════════════════════
    if showGhost {
    entries.append(.header(id: id.count, section: sec, text: "👻 РЕЖИМ ПРИЗРАКА", badge: nil))
    megramFeature(.ghostModeEnabled, s.ghostModeEnabled, "Режим призрака", enabled: true)
    entries.append(.disclosureDetail(id: id.count, section: sec, link: .ghostDetailsToggle, text: "Дополнительные настройки", detail: state.ghostModeExpanded ? "Скрыть настройки режима призрака" : "Показать настройки режима призрака"))

    // MARK: Megram — «Удалённые сообщения» устроены так же, как призрак:
    // переключатель и раскрывающийся блок подробностей рядом с ним.
    let deletedSection = featureSections.take()
    entries.append(.toggle(id: id.count, section: deletedSection, settingName: .showDeletedMessages, value: s.showDeletedMessages, text: "Удалённые сообщения", enabled: true))
    entries.append(.disclosureDetail(id: id.count, section: deletedSection, link: .deletedDetailsToggle, text: "Дополнительные настройки", detail: state.deletedMessagesExpanded ? "Скрыть настройки удалённых" : "Показать настройки удалённых"))

    if state.deletedMessagesExpanded {
    megramFeature(.showOriginalEdited, s.showOriginalEdited, "Показывать оригинальный текст", "У изменённого сообщения показывается текст до правки.")
    megramFeature(.hideMyDeleted, !s.hideMyDeleted, "Отображать мои удалённые", "Ваши собственные удалённые сообщения тоже остаются в переписке.")
    megramFeature(.hideBotDeleted, !s.hideBotDeleted, "Отображать удалённые ботов", "Сообщения ботов сохраняются наравне с остальными.")
    megramFeature(.hideMyEdited, !s.hideMyEdited, "Оригинал моих изменённых", "Хранит текст ваших сообщений до правки.")
    megramFeature(.hideBotEdited, !s.hideBotEdited, "Оригинал изменённых ботов", "Хранит текст сообщений ботов до правки.")
    megramFeature(.saveDeletedMessagesMedia, s.saveDeletedMessagesMedia, "Хранить медиа удалённых", "Фото и видео удалённого сообщения остаются на устройстве. Занимает место.")
    megramFeature(.saveDeletedMessagesReactions, s.saveDeletedMessagesReactions, "Хранить реакции удалённых", "Реакции сохраняются вместе с сообщением.")
    megramFeature(.enableSavingSelfDestructingMessages, s.enableSavingSelfDestructingMessages, "Сохранять одноразовые", "Одноразовые фото и видео сохраняются при просмотре.")
    megramFeature(.saveEditHistory, s.saveEditHistory, "История изменений", "Хранит все редакции сообщения — доступны через меню Megram.")
    megramFeature(.doubleTapToEdit, s.doubleTapToEdit, "Редактирование по двойному тапу", "Двойное нажатие по своему сообщению открывает правку.")
    megramFeature(.enableLocalMessageEditing, s.enableLocalMessageEditing, "Локальное изменение сообщений", "Пункт «Локально изм.» в меню Megram правит текст только у вас, без пометки «изменено».")
    megramFeature(.dimIncomingWhileReplying, s.dimIncomingWhileReplying, "Приглушать сообщение при ответе", "Пока вы пишете ответ, сообщение собеседника становится полупрозрачным.")

    let opacitySection = featureSections.take()
    entries.append(.percentageSlider(id: id.count, section: opacitySection, settingName: .deletedMessageOpacity, value: s.deletedMessageOpacity))
    entries.append(.notice(id: id.count, section: opacitySection, text: "Прозрачность удалённых сообщений в переписке."))

    let trashSizeSection = featureSections.take()
    entries.append(.percentageSlider(id: id.count, section: trashSizeSection, settingName: .deletedTrashSize, value: s.deletedTrashSize))
    entries.append(.notice(id: id.count, section: trashSizeSection, text: "Размер значка корзины у удалённого сообщения, в процентах от обычного."))
    }

    if state.ghostModeExpanded {
    entries.append(.header(id: id.count, section: sec, text: "СКРЫТИЕ СТАТУСОВ", badge: nil))
    megramFeature(.ghostModeAlwaysOnline, s.ghostModeAlwaysOnline, "Всегда онлайн", enabled: true)
    megramFeature(.disableOnlineStatus, s.disableOnlineStatus, "Скрыть онлайн-статус", enabled: !s.ghostModeAlwaysOnline)
    megramFeature(.disableTypingStatus, s.disableTypingStatus, "Скрыть «печатает»", enabled: true)
    megramFeature(.disableVCMessageRecordingStatus, s.disableVCMessageRecordingStatus, "Скрыть запись голосового", enabled: true)
    megramFeature(.disableVCMessageUploadingStatus, s.disableVCMessageUploadingStatus, "Скрыть отправку голосового", enabled: true)
    megramFeature(.disableUploadingFileStatus, s.disableUploadingFileStatus, "Скрыть загрузку файлов", enabled: true)
    megramFeature(.disableUploadingPhotoStatus, s.disableUploadingPhotoStatus, "Скрыть отправку фото", enabled: true)
    megramFeature(.disableUploadingVideoStatus, s.disableUploadingVideoStatus, "Скрыть отправку видео", enabled: true)
    megramFeature(.disableRecordingVideoStatus, s.disableRecordingVideoStatus, "Скрыть запись видео", enabled: true)
    // "Выбирает локацию" / "выбирает контакт" are not real Telegram activities — there is no
    // such `SendMessageAction`, so no toggle can suppress them. Rows removed rather than left
    // as switches that silently do nothing.
    id.increment(2)
    megramFeature(.disablePlayingGameStatus, s.disablePlayingGameStatus, "Скрыть статус игры", enabled: true)
    megramFeature(.disableRecordingRoundVideoStatus, s.disableRecordingRoundVideoStatus, "Скрыть запись кружка", enabled: true)
    megramFeature(.disableUploadingRoundVideoStatus, s.disableUploadingRoundVideoStatus, "Скрыть отправку кружка", enabled: true)
    megramFeature(.disableSpeakingInGroupCallStatus, s.disableSpeakingInGroupCallStatus, "Скрыть говорение в звонке", enabled: true)
    megramFeature(.disableChoosingStickerStatus, s.disableChoosingStickerStatus, "Скрыть выбор стикера", enabled: true)
    megramFeature(.disableEmojiInteractionStatus, s.disableEmojiInteractionStatus, "Скрыть эмодзи-взаимодействие", enabled: true)
    megramFeature(.disableEmojiAcknowledgementStatus, s.disableEmojiAcknowledgementStatus, "Скрыть эмодзи-подтверждение", enabled: true)
    megramFeature(.ghostModeHideVideoWatch, s.ghostModeHideVideoWatch, "Скрыть просмотр видео/кружка", enabled: true)

    entries.append(.header(id: id.count, section: sec, text: "ПРОЧТЕНИЕ И ПРОСМОТР", badge: nil))
    megramFeature(.disableMessageReadReceipt, s.disableMessageReadReceipt, "Скрыть прочтение (галочки)", enabled: true)
    megramFeature(.disableStoryReadReceipt, s.disableStoryReadReceipt, "Скрыть просмотр сторис", enabled: true)

    entries.append(.header(id: id.count, section: sec, text: "ДОПОЛНИТЕЛЬНО", badge: nil))
    megramFeature(.ghostModeMessageSendDelay, s.ghostModeMessageSendDelaySeconds > 0, "Задержка отправки 12 сек", enabled: true)
    megramFeature(.ghostModeFakeTyping, s.ghostModeFakeTyping, "Fake typing (показывать «печатает»)", enabled: true)
    megramFeature(.ghostModeAntiSpam, s.ghostModeAntiSpam, "Анти-спам входящих", enabled: true)
    megramFeature(.ghostModeAutoCleanHistory, s.ghostModeAutoCleanHistory, "Авто-очистка архива удалённых", enabled: true)
    entries.append(.notice(id: id.count, section: sec, text: "Сохранённые копии удалённых сообщений старше \(max(1, Int(s.ghostModeAutoCleanDays))) дн. стираются с устройства. Настоящая переписка не трогается."))
    megramFeature(.enableOnlineStatusRecording, s.enableOnlineStatusRecording, "История онлайна собеседников", enabled: true)
    entries.append(.disclosure(id: id.count, section: sec, link: .onlineHistory, text: "Открыть историю онлайна"))
    megramFeature(.fakeLocationEnabled, s.fakeLocationEnabled, "Подмена геолокации", enabled: true)
    entries.append(.disclosure(id: id.count, section: sec, link: .fakeLocationPicker, text: "Выбрать местоположение"))

    // КОНФИДЕНЦИАЛЬНОСТЬ (перенесена из отдельной вкладки)
    entries.append(.header(id: id.count, section: sec, text: "КОНФИДЕНЦИАЛЬНОСТЬ", badge: nil))
    megramFeature(.bypassProtectedContent, s.bypassProtectedContent, "Обход защищённого контента", enabled: true)
    megramFeature(.removeSpoilersEverywhere, s.removeSpoilersEverywhere, "Убрать спойлеры везде", enabled: true)
    megramFeature(.antiScamEnabled, s.antiScamEnabled, "Защита от мошенников", enabled: true)
    megramFeature(.disableAllAds, s.disableAllAds, "Отключить рекламу", enabled: true)
    megramFeature(.enableSavingProtectedContent, s.enableSavingProtectedContent, "Сохранять защищённый контент", enabled: true)
    megramFeature(.enableSavingSelfDestructingMessages, s.enableSavingSelfDestructingMessages, "Сохранять самоуничтожающиеся", enabled: true)
    megramFeature(.disableScreenshotDetection, s.disableScreenshotDetection, "Без определения скриншотов", enabled: true)
    megramFeature(.disableSecretChatBlurOnScreenshot, s.disableSecretChatBlurOnScreenshot, "Без размытия при скриншоте", enabled: true)
    megramFeature(.hideProxySponsor, s.hideProxySponsor, "Скрыть спонсора прокси", enabled: true)
    } // end ghostModeExpanded
    } // end ghost

    // ═══════════════════════════════════════════
    // ПРОФИЛЬ
    // ═══════════════════════════════════════════
    if showProfile {
    entries.append(.header(id: id.count, section: sec, text: "ПРОФИЛЬ", badge: nil))
    megramFeature(.showProfileId, s.showProfileId, "Отображать ID аккаунта в профиле", "Добавляет в профиль числовой идентификатор аккаунта, который можно скопировать нажатием.")
    megramFeature(.showDC, s.showDC, "Отображать DC аккаунта в профиле", "Показывает дата-центр Telegram, где хранится аккаунт, и при наличии страну номера.")
    megramFeature(.hidePhoneNumber, s.hidePhoneNumber, "Скрыть номер телефона", "Скрывает номер телефона и в настройках, и в профиле.")
    megramFeature(.hideProfileGiftsTab, s.hideProfileGiftsTab, "Скрыть вкладку «Подарки»", "Убирает вкладку с подарками из профиля.")
    megramFeature(.showIfMutualContacts, s.showIfMutualContacts, "Значок взаимного контакта", "Добавляет значок, если вы и собеседник сохранили друг друга.")
    megramFeature(.showCreationDate, s.showCreationDate, "Отображать дату создания чата", "Показывает, когда переписка или канал были созданы.")
    megramFeature(.showSeconds, s.showSeconds, "Точное время захода в сеть", "Рядом с «был в сети» показывается точное время до секунд.")
    megramFeature(.profileTrackCard, s.profileTrackCard, "Карточка трека", "Прикреплённая музыка рисуется карточкой с размытой обложкой вместо плоской строки. Без обложки карточка не показывается.")
    megramFeature(.profileIdChips, s.profileIdChips, "ID и DC кнопками", "Круглые кнопки под юзернеймом вместо строк списка. Нажатие копирует значение.")
    megramFeature(.hideProfileEmojiStatus, s.hideProfileEmojiStatus, "Скрыть «Установить эмодзи-статус»", "Убирает строку из своего профиля.")
    megramFeature(.hideProfileColorRow, s.hideProfileColorRow, "Скрыть «Изменить цвет профиля»", "Убирает строку из своего профиля.")
    megramFeature(.hideProfilePhotoRow, s.hideProfilePhotoRow, "Скрыть «Изменить фотографию»", "Убирает строку из своего профиля.")
    megramFeature(.hideProfileIdRow, s.hideProfileIdRow, "Скрыть строку ID", "Убирает строку с идентификатором из своего профиля.")

    } // end profile

    // ═══════════════════════════════════════════
    // ВКЛАДКИ
    // ═══════════════════════════════════════════
    if showTabs {
    entries.append(.header(id: id.count, section: sec, text: "ВКЛАДКИ", badge: nil))
    megramFeature(.hideBottomTabPanel, s.hideTabBar, "Скрыть панель вкладок", "Нижняя панель убирается полностью, переключение — свайпом и через поиск.")
    megramFeature(.hideContactsTab, s.hideContactsTab, "Скрыть вкладку «Контакты»", "Убирает контакты из нижней панели.", enabled: !s.hideTabBar)
    megramFeature(.hideCallsTab, s.hideCallsTab, "Скрыть вкладку «Звонки»", "Убирает звонки из нижней панели.", enabled: !s.hideTabBar)
    megramFeature(.tabBarSearchNearBottom, s.tabBarSearchEnabled, "Кнопка поиска у панели", "Круглая кнопка поиска встаёт рядом с нижней панелью.", enabled: !s.hideTabBar)

    let tabHeightSection = featureSections.take()
    entries.append(.percentageSlider(id: id.count, section: tabHeightSection, settingName: .tabBarHeight, value: s.tabBarHeightScale))
    entries.append(.notice(id: id.count, section: tabHeightSection, text: "Высота нижней панели в процентах от стандартной."))
    let tabWidthSection = featureSections.take()
    entries.append(.percentageSlider(id: id.count, section: tabWidthSection, settingName: .tabBarWidth, value: s.tabBarWidthScale))
    entries.append(.notice(id: id.count, section: tabWidthSection, text: "Ширина нижней панели в процентах от стандартной."))

    } // end tabs

    // ═══════════════════════════════════════════
    // РАЗДЕЛЫ НАСТРОЕК — каждый переключатель прячет одноимённый пункт
    // ═══════════════════════════════════════════
    if showSettingsSections {
    entries.append(.header(id: id.count, section: sec, text: "РАЗДЕЛЫ НАСТРОЕК", badge: nil))
    entries.append(.notice(id: id.count, section: sec, text: "Включённый переключатель скрывает соответствующий пункт из настроек."))
    megramFeature(.hideSettingsFavorites, s.hideSettingsSavedMessages, "Избранное", "")
    megramFeature(.hideSettingsDevices, s.hideSettingsDevices, "Устройства", "")
    megramFeature(.hideSettingsChatFolders, s.hideSettingsChatFolders, "Папки с чатами", "")
    megramFeature(.hideSettingsPowerSaving, s.hideSettingsPowerSaving, "Энергосбережение", "")
    megramFeature(.hideSettingsLanguage, s.hideSettingsLanguage, "Язык", "")
    megramFeature(.hideSettingsNotifications, s.hideSettingsNotifications, "Уведомления", "")
    megramFeature(.hideSettingsPrivacy, s.hideSettingsPrivacy, "Конфиденциальность", "")
    megramFeature(.hideSettingsDataAndStorage, s.hideSettingsDataAndStorage, "Данные и память", "")
    megramFeature(.hideSettingsAppearance, s.hideSettingsAppearance, "Оформление", "")
    megramFeature(.hideSettingsProxy, s.hideSettingsProxy, "Прокси", "")
    megramFeature(.hideSettingsMyProfile, s.hideSettingsMyProfile, "Мой профиль", "")
    megramFeature(.hideSettingsRecentCalls, s.hideSettingsRecentCalls, "Недавние звонки", "")
    megramFeature(.hideSettingsPremium, s.hideSettingsPremium, "Premium", "")
    megramFeature(.hideSettingsStars, s.hideSettingsStars, "Звёзды", "")
    megramFeature(.hideSettingsBusiness, s.hideSettingsBusiness, "Бизнес", "")
    megramFeature(.hideSettingsSupport, s.hideSettingsSupport, "Поддержка", "")
    megramFeature(.hideSettingsFaq, s.hideSettingsFaq, "Вопросы и ответы", "")
    megramFeature(.hideSettingsTips, s.hideSettingsTips, "Советы", "")
    megramFeature(.hideSettingsSendGift, s.hideSettingsSendGift, "Отправить подарок", "")
    megramFeature(.hideProfileEmojiStatus, s.hideProfileEmojiStatus, "Установить статус-эмодзи", "")
    megramFeature(.hideProfileColorRow, s.hideProfileColorRow, "Изменить цвет профиля", "")
    megramFeature(.hideProfilePhotoRow, s.hideProfilePhotoRow, "Изменить фотографию", "")
    } // end settingsSections

    // ═══════════════════════════════════════════
    // ПРОЧИЕ ФУНКЦИИ — контекст, сторис, фото, доп.
    // ═══════════════════════════════════════════
    if showOther {
    // КОНТЕКСТНОЕ МЕНЮ
    entries.append(.header(id: id.count, section: sec, text: "✦ ПРОЧИЕ ФУНКЦИИ", badge: nil))
    // Перенесено из «Внешнего вида»: это про воспроизведение, не про облик.
    megramFeature(.noAutoNextVoice, s.noAutoNextVoice, "Не слушать следующее голосовое", "После окончания голосового следующее не запускается автоматически.")

    // MEGRAM · МЕНЮ ПРОФИЛЯ — the three-dot menu inside a private chat.
    entries.append(.header(id: id.count, section: sec, text: "MEGRAM · МЕНЮ ПРОФИЛЯ", badge: nil))
    entries.append(.notice(id: id.count, section: sec, text: "Скрывает пункты меню «⋯» в профиле собеседника. Пункт Megram скрыть нельзя."))
    megramFeature(.hideMenuWallpaper, s.hideMenuWallpaper, "Скрыть «Изменить обои»", enabled: true)
    megramFeature(.hideMenuSecretChat, s.hideMenuSecretChat, "Скрыть «Начать секретный чат»", enabled: true)
    megramFeature(.hideMenuSendContact, s.hideMenuSendContact, "Скрыть «Отправить контакт»", enabled: true)
    megramFeature(.hideMenuAutoDelete, s.hideMenuAutoDelete, "Скрыть «Автоудаление»", enabled: true)
    megramFeature(.hideMenuCopyProtection, s.hideMenuCopyProtection, "Скрыть «Запретить копирование»", enabled: true)
    megramFeature(.hideMenuClearHistory, s.hideMenuClearHistory, "Скрыть «Удалить переписку»", enabled: true)
    megramFeature(.hideMenuBlock, s.hideMenuBlock, "Скрыть «Заблокировать»", enabled: true)

    entries.append(.header(id: id.count, section: sec, text: "КОНТЕКСТНОЕ МЕНЮ", badge: nil))
    megramFeature(.contextShowSaveToCloud, s.contextShowSaveToCloud, "Сохранить в облако", enabled: true)
    megramFeature(.contextShowHideForwardName, s.contextShowHideForwardName, "Скрыть имя пересылки", enabled: true)
    megramFeature(.contextShowSelectFromUser, s.contextShowSelectFromUser, "Выбрать от пользователя", enabled: true)
    megramFeature(.contextShowRestrict, s.contextShowRestrict, "Ограничить", enabled: true)
    megramFeature(.contextShowReport, s.contextShowReport, "Пожаловаться", enabled: true)
    megramFeature(.contextShowReply, s.contextShowReply, "Ответить", enabled: true)
    megramFeature(.contextShowPin, s.contextShowPin, "Закрепить", enabled: true)
    megramFeature(.contextShowSaveMedia, s.contextShowSaveMedia, "Сохранить медиа", enabled: true)
    megramFeature(.contextShowMessageReplies, s.contextShowMessageReplies, "Ответы на сообщение", enabled: true)
    megramFeature(.contextShowJson, s.contextShowJson, "JSON", enabled: true)

    // ЛОКАЛЬНЫЙ ПРЕМИУМ И ЗВЁЗДЫ
    megramFeature(.enableLocalPremium, s.enableLocalPremium, "Локальный премиум", "Премиум-функции включаются на этом устройстве. Собеседники значка не увидят.")
    // Баланс появляется только вместе с включёнными звёздами: строка ввода без
    // самой функции ведёт в никуда.
    let starsSection = featureSections.take()
    entries.append(.toggle(id: id.count, section: starsSection, settingName: .localStarsEnabled, value: s.localStarsEnabled, text: "Локальные звёзды", enabled: true))
    if s.localStarsEnabled {
        entries.append(.disclosureDetail(id: id.count, section: starsSection, link: .localStarsAmount, text: "Баланс звёзд", detail: "\(s.localStarsBalance) ⭐"))
    } else {
        id.increment(1)
    }
    entries.append(.notice(id: id.count, section: starsSection, text: "Баланс виден только вам и не связан с сервером. При отправке платных реакций сумма списывается локально."))

    // УСТРОЙСТВО — поле раскрывается вместе со своим переключателем.
    let deviceSection = featureSections.take()
    entries.append(.toggle(id: id.count, section: deviceSection, settingName: .deviceModelSpoofEnabled, value: s.deviceModelSpoofEnabled, text: "Своё название устройства", enabled: true))
    if s.deviceModelSpoofEnabled {
        entries.append(.disclosureDetail(id: id.count, section: deviceSection, link: .deviceModelSpoof, text: "Название устройства", detail: s.deviceModelSpoof.isEmpty ? "Не задано" : s.deviceModelSpoof))
    } else {
        id.increment(1)
    }
    entries.append(.notice(id: id.count, section: deviceSection, text: "Отображается в списке активных сессий и в письмах о входе. Меняется при следующем подключении."))

    // ДОПОЛНИТЕЛЬНО
    entries.append(.header(id: id.count, section: sec, text: "ДОПОЛНИТЕЛЬНО", badge: nil))
    megramFeature(.quickTranslateButton, s.quickTranslateButton, "Кнопка «Перевести»", enabled: true)
    megramFeature(.disableZalgoText, s.disableZalgoText, "Zalgo-фильтр", enabled: true)
    megramFeature(.uploadSpeedBoost, s.uploadSpeedBoost, "Ускорение отправки", enabled: true)
    // Megram: the stored value is an English key; the row shows it translated.
    let downloadBoostTitle: String
    switch s.downloadSpeedBoost {
    case "medium": downloadBoostTitle = "Среднее"
    case "maximum": downloadBoostTitle = "Максимальное"
    default: downloadBoostTitle = "Выключено"
    }
    entries.append(.oneFromManySelector(id: id.count, section: sec, settingName: .downloadSpeedBoost, text: "Ускорение загрузки", value: downloadBoostTitle, enabled: true))
    megramFeature(.unlimitedFavoriteStickers, s.unlimitedFavoriteStickers, "Безлимитные избранные стикеры", enabled: true)

    // СТИКЕРЫ
    entries.append(.header(id: id.count, section: sec, text: "СТИКЕРЫ", badge: nil))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .stickerSize, value: s.stickerSize))
    megramFeature(.stickerTimestamp, s.stickerTimestamp, "Временные метки на стикерах", enabled: true)

    // ФОТО
    entries.append(.header(id: id.count, section: sec, text: "ФОТО", badge: nil))
    entries.append(.percentageSlider(id: id.count, section: sec, settingName: .outgoingPhotoQuality, value: s.outgoingPhotoQuality))
    megramFeature(.sendLargePhotos, s.sendLargePhotos, "Отправлять большие фото", enabled: true)

    // СТОРИС
    entries.append(.header(id: id.count, section: sec, text: "СТОРИС", badge: nil))
    megramFeature(.disableSwipeToRecordStory, s.disableSwipeToRecordStory, "Скрыть свайп для записи сторис", enabled: true)
    megramFeature(.warnOnStoriesOpen, s.warnOnStoriesOpen, "Предупреждение при открытии сторис", enabled: true)
    if s.canUseStealthMode {
        megramFeature(.storyStealthMode, s.storyStealthMode, "Stealth-режим сторис", enabled: true)
    } else {
        id.increment(1)
    }
    megramFeature(.showRepostToStory, s.showRepostToStoryV2, "Переслать в историю", enabled: true)

    // ПРОЧЕЕ
    entries.append(.header(id: id.count, section: sec, text: "ПРОЧЕЕ", badge: nil))
    megramFeature(.forceSystemSharing, s.forceSystemSharing, "Системный шэринг", enabled: true)
    megramFeature(.emojiDownloaderEnabled, s.emojiDownloaderEnabled, "Скачивание эмодзи", enabled: true)
    megramFeature(.swipeForVideoPIP, s.videoPIPSwipeDirection == SGSimpleSettings.VideoPIPSwipeDirection.up.rawValue, "Свайп для PiP видео", enabled: true)
    megramFeature(.forceBuiltInMic, s.forceBuiltInMic, "Встроенный микрофон", enabled: true)

    } // end other

    // MARK: Megram — whitelist filtering is off.
    //
    // Trimming the finished list looked cheap on paper, but a category screen is not a flat run of
    // switches: it is headers, notices and switches emitted across two blocks, and removing rows
    // from the middle left tabs looking empty rather than curated. Reaching the exact lists means
    // editing the builders themselves — dropping the `entries.append` calls that should not be
    // there — so the screen is built right instead of built wide and then cut down.
    //
    // Until that is done the full lists stay: a tab with more switches than intended is a
    // cosmetic problem, a tab with none is a broken screen.

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
    /// PHPicker is a UIKit controller, so it cannot go through the Display
    /// presentation stack — it needs a real UIViewController to present from.
    /// Wired to the live controller's own window below.
    var openDecorationPickerImpl: ((MegramAppearanceStore.Slot) -> Void)?

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
            case .megramHideGlassBorder:
                s.megramHideGlassBorder = value
                // Surfaces already drawn keep their edge image until something
                // asks them to rebuild it, which is what this notification does.
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
            case .profileTrackCard: s.profileTrackCard = value; simplePromise.set(true)
            case .profileIdChips: s.profileIdChips = value; simplePromise.set(true)
            case .hideProfileEmojiStatus: s.hideProfileEmojiStatus = value; simplePromise.set(true)
            case .hideProfileColorRow: s.hideProfileColorRow = value; simplePromise.set(true)
            case .hideProfilePhotoRow: s.hideProfilePhotoRow = value; simplePromise.set(true)
            case .hideProfileIdRow: s.hideProfileIdRow = value; simplePromise.set(true)
            case .hideMenuWallpaper: s.hideMenuWallpaper = value
            case .hideMenuSecretChat: s.hideMenuSecretChat = value
            case .hideMenuSendContact: s.hideMenuSendContact = value
            case .hideMenuAutoDelete: s.hideMenuAutoDelete = value
            case .hideMenuCopyProtection: s.hideMenuCopyProtection = value
            case .hideMenuClearHistory: s.hideMenuClearHistory = value
            case .hideMenuBlock: s.hideMenuBlock = value
            // Turning a decoration slot off keeps its file, so switching back
            // on does not require picking the media again.
            case .globalVideoBackground: MegramAppearanceStore.setEnabled(.globalVideo, value); simplePromise.set(true)
            case .globalPhotoBackground: MegramAppearanceStore.setEnabled(.globalPhoto, value); simplePromise.set(true)
            case .profileWallpaper: MegramAppearanceStore.setEnabled(.profileWallpaper, value); simplePromise.set(true)
            case .profileBannerPhoto: MegramAppearanceStore.setEnabled(.profileBannerPhoto, value); simplePromise.set(true)
            case .profileBannerVideo: MegramAppearanceStore.setEnabled(.profileBannerVideo, value); simplePromise.set(true)
            case .hideBottomTabPanel: s.hideTabBar = value; simplePromise.set(true); askForRestart?()
            case .hideContactsTab: s.hideContactsTab = value; simplePromise.set(true); askForRestart?()
            case .hideCallsTab: s.hideCallsTab = value; simplePromise.set(true); askForRestart?()
            case .tabBarSearchNearBottom: s.tabBarSearchEnabled = value; simplePromise.set(true)
            case .hideProfileGiftsTab: s.hideProfileGiftsTab = value; simplePromise.set(true)
            case .deviceModelSpoofEnabled: s.deviceModelSpoofEnabled = value; simplePromise.set(true)
            case .hideSettingsFavorites: s.hideSettingsSavedMessages = value; simplePromise.set(true)
            case .hideSettingsDevices: s.hideSettingsDevices = value; simplePromise.set(true)
            case .hideSettingsChatFolders: s.hideSettingsChatFolders = value; simplePromise.set(true)
            case .hideSettingsPowerSaving: s.hideSettingsPowerSaving = value; simplePromise.set(true)
            case .hideSettingsLanguage: s.hideSettingsLanguage = value; simplePromise.set(true)
            case .hideSettingsNotifications: s.hideSettingsNotifications = value; simplePromise.set(true)
            case .hideSettingsPrivacy: s.hideSettingsPrivacy = value; simplePromise.set(true)
            case .hideSettingsDataAndStorage: s.hideSettingsDataAndStorage = value; simplePromise.set(true)
            case .hideSettingsAppearance: s.hideSettingsAppearance = value; simplePromise.set(true)
            case .hideSettingsProxy: s.hideSettingsProxy = value; simplePromise.set(true)
            case .hideSettingsMyProfile: s.hideSettingsMyProfile = value; simplePromise.set(true)
            case .hideSettingsRecentCalls: s.hideSettingsRecentCalls = value; simplePromise.set(true)
            case .hideSettingsPremium: s.hideSettingsPremium = value; simplePromise.set(true)
            case .hideSettingsStars: s.hideSettingsStars = value; simplePromise.set(true)
            case .hideSettingsBusiness: s.hideSettingsBusiness = value; simplePromise.set(true)
            case .hideSettingsSupport: s.hideSettingsSupport = value; simplePromise.set(true)
            case .hideSettingsFaq: s.hideSettingsFaq = value; simplePromise.set(true)
            case .hideSettingsTips: s.hideSettingsTips = value; simplePromise.set(true)
            case .hideSettingsSendGift: s.hideSettingsSendGift = value; simplePromise.set(true)
            case .dimIncomingWhileReplying: s.dimIncomingWhileReplying = value; simplePromise.set(true)
            case .saveDeletedMessagesReactions: s.saveDeletedMessagesReactions = value; simplePromise.set(true)
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
            // Megram: HD on demand and HD always are two answers to the same
            // question, so turning one on retires the other.
            case .cameraSendHDPhoto:
                s.cameraSendHDPhoto = value
                if value { s.cameraAlwaysSendHD = false }
                simplePromise.set(true)
            case .cameraRememberLast: s.cameraRememberLast = value
            case .cameraStaticZoom: s.cameraStaticZoom = value
            case .cameraAlwaysSendHD:
                s.cameraAlwaysSendHD = value
                if value { s.cameraSendHDPhoto = false }
                simplePromise.set(true)
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
            // Clamped so the tab bar cannot collapse to nothing or swallow the screen.
            case .tabBarHeight:
                let clamped = max(50, min(150, value))
                if s.tabBarHeightScale != clamped { s.tabBarHeightScale = clamped; simplePromise.set(true) }
            case .tabBarWidth:
                let clamped = max(50, min(150, value))
                if s.tabBarWidthScale != clamped { s.tabBarWidthScale = clamped; simplePromise.set(true) }
            case .deletedMessageOpacity:
                if s.deletedMessageOpacity != value { s.deletedMessageOpacity = value; simplePromise.set(true) }
            case .deletedTrashSize:
                let clamped = max(50, min(200, value))
                if s.deletedTrashSize != clamped { s.deletedTrashSize = clamped; simplePromise.set(true) }
            case .backgroundOpacity:
                MegramAppearanceStore.setBackgroundOpacity(CGFloat(max(10, min(100, value))) / 100.0)
                simplePromise.set(true)
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
                    // Megram: the raw values are English keys, so the sheet
                    // shows translated titles instead of none/medium/maximum.
                    let title: String
                    switch value.rawValue {
                    case "medium": title = "Среднее"
                    case "maximum": title = "Максимальное"
                    default: title = "Выключено"
                    }
                    items.append(ActionSheetButtonItem(title: title, color: .accent, action: { [weak actionSheet] in
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
            // MARK: Megram — developer links. Opened through the app's own URL
            // handling so a t.me address resolves inside Telegram instead of
            // bouncing out to a browser.
            switch link {
            case .devChannel, .devVPN, .devSupport:
                let address: String
                switch link {
                case .devChannel: address = MegramDeveloperLinks.channel
                case .devVPN: address = MegramDeveloperLinks.vpn
                default: address = MegramDeveloperLinks.support
                }
                if address.isEmpty {
                    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                    presentControllerImpl?(textAlertController(context: context, title: nil, text: megramText("Ссылка ещё не настроена.", "This link is not set up yet."), actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]), nil)
                } else {
                    context.sharedContext.applicationBindings.openUrl(address)
                }
                return
            default:
                break
            }

            // MARK: Megram — appearance pickers. The picker needs a live view
            // controller to present from, which only the presentation callback
            // can supply here.
            let decorationSlot: MegramAppearanceStore.Slot?
            switch link {
            case .pickGlobalVideo: decorationSlot = .globalVideo
            case .pickGlobalPhoto: decorationSlot = .globalPhoto
            case .pickProfileWallpaper: decorationSlot = .profileWallpaper
            case .pickProfileBannerPhoto: decorationSlot = .profileBannerPhoto
            case .pickProfileBannerVideo: decorationSlot = .profileBannerVideo
            default: decorationSlot = nil
            }
            if let decorationSlot {
                let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                // A slot that already holds a file offers to swap or drop it
                // first; going straight to the library would make deleting one
                // impossible.
                if MegramAppearanceStore.hasMedia(for: decorationSlot) {
                    let actionSheet = ActionSheetController(presentationData: presentationData)
                    actionSheet.setItemGroups([ActionSheetItemGroup(items: [
                        ActionSheetButtonItem(title: "Выбрать другой файл", color: .accent, action: { [weak actionSheet] in
                            actionSheet?.dismissAnimated()
                            openDecorationPickerImpl?(decorationSlot)
                        }),
                        ActionSheetButtonItem(title: "Удалить файл", color: .destructive, action: { [weak actionSheet] in
                            actionSheet?.dismissAnimated()
                            MegramAppearanceStore.clear(decorationSlot)
                            simplePromise.set(true)
                        })
                    ]), ActionSheetItemGroup(items: [
                        ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                            actionSheet?.dismissAnimated()
                        })
                    ])])
                    presentControllerImpl?(actionSheet, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
                } else {
                    openDecorationPickerImpl?(decorationSlot)
                }
            if link == .deletedDetailsToggle {
                updateState { current in
                    var updated = current
                    updated.deletedMessagesExpanded.toggle()
                    return updated
                }
                return
            }
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
        boolDescription: { _ in
            // MARK: Megram — the description belongs under the card, not inside
            // it. `megramFeature` appends it as a separate notice below the
            // rounded panel; returning it here as well printed every one twice.
            return nil
        }
    )

    let signal = combineLatest(simplePromise.get(), statePromise.get(), context.sharedContext.presentationData)
    |> map { _, state, presentationData -> (ItemListControllerState, (ItemListNodeState, NLArguments)) in
        let entries = nlBuildEntries(presentationData: presentationData, state: state, simpleUpdated: true)
        let title = state.hubCategory?.titleRu ?? ""
        let cs = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title.isEmpty ? "Megram" : title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
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
    openDecorationPickerImpl = { [weak controller] slot in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        // The library sheet itself is instant; the spinner is for the transcode
        // that follows a video pick, so it only goes up once that reports work.
        let progressController = OverlayStatusController(theme: presentationData.theme, type: .loading(cancelled: nil))
        var progressShown = false
        let picker = MegramMediaPicker(slot: slot, progress: { _ in
            if !progressShown {
                progressShown = true
                presentControllerImpl?(progressController, nil)
            }
        }, completion: { result in
            if progressShown {
                progressController.dismiss()
            }
            switch result {
            case .success:
                simplePromise.set(true)
            case let .failure(error):
                if case .cancelled = error {
                    break
                }
                presentControllerImpl?(textAlertController(context: context, title: nil, text: "Не удалось обработать файл. Попробуйте другой.", actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]), nil)
            }
        })
        // The controller's own window root, the way the rest of this codebase
        // presents UIKit controllers. Walking down the presented chain — what
        // this used to do — lands on whatever modal happens to be up and can
        // refuse the presentation outright, which is why nothing opened.
        guard #available(iOS 14.0, *), let root = controller?.view.window?.rootViewController else {
            presentControllerImpl?(textAlertController(context: context, title: nil, text: "Не удалось открыть галерею.", actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]), nil)
            return
        }
        picker.present(in: root)
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
