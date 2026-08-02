import Foundation
import UIKit

// MARK: - Auto-format (file-level type — not nested in extension)

public enum NamelessAutoFormatMode: String, CaseIterable {
    case none
    case bold
    case italic
    case underline
    case strikethrough
    case code
    case pre
    case blockquote
    case spoiler

    public var titleRu: String {
        switch self {
        case .none: return "Обычный"
        case .bold: return "Жирный"
        case .italic: return "Курсив"
        case .underline: return "Подчёркнутый"
        case .strikethrough: return "Зачёркнутый"
        case .code: return "Моноширинный"
        case .pre: return "Блок кода"
        case .blockquote: return "Цитата"
        case .spoiler: return "Спойлер"
        }
    }
}

public enum NamelessColorParse {
    public static func color(fromHex hex: String) -> UIColor? {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8, let value = UInt64(s, radix: 16) else { return nil }
        let r, g, b, a: CGFloat
        if s.count == 8 {
            r = CGFloat((value & 0xFF000000) >> 24) / 255
            g = CGFloat((value & 0x00FF0000) >> 16) / 255
            b = CGFloat((value & 0x0000FF00) >> 8) / 255
            a = CGFloat(value & 0x000000FF) / 255
        } else {
            r = CGFloat((value & 0xFF0000) >> 16) / 255
            g = CGFloat((value & 0x00FF00) >> 8) / 255
            b = CGFloat(value & 0x0000FF) / 255
            a = 1
        }
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

private enum NamelessSettingsKey {
    static let showDeletedMessages = "nameless.showDeletedMessages"
    static let saveDeletedMessagesMedia = "nameless.saveDeletedMessagesMedia"
    static let saveDeletedMessagesReactions = "nameless.saveDeletedMessagesReactions"
    static let saveDeletedMessagesForBots = "nameless.saveDeletedMessagesForBots"
    static let saveEditHistory = "nameless.saveEditHistory"
    static let enableLocalMessageEditing = "nameless.enableLocalMessageEditing"
    static let keepRemovedChannels = "nameless.keepRemovedChannels"
    static let disableOnlineStatus = "nameless.disableOnlineStatus"
    static let disableTypingStatus = "nameless.disableTypingStatus"
    static let disableRecordingVideoStatus = "nameless.disableRecordingVideoStatus"
    static let disableUploadingVideoStatus = "nameless.disableUploadingVideoStatus"
    static let disableVCMessageRecordingStatus = "nameless.disableVCMessageRecordingStatus"
    static let disableVCMessageUploadingStatus = "nameless.disableVCMessageUploadingStatus"
    static let disableUploadingPhotoStatus = "nameless.disableUploadingPhotoStatus"
    static let disableUploadingFileStatus = "nameless.disableUploadingFileStatus"
    static let disableChoosingLocationStatus = "nameless.disableChoosingLocationStatus"
    static let disableChoosingContactStatus = "nameless.disableChoosingContactStatus"
    static let disablePlayingGameStatus = "nameless.disablePlayingGameStatus"
    static let disableRecordingRoundVideoStatus = "nameless.disableRecordingRoundVideoStatus"
    static let disableUploadingRoundVideoStatus = "nameless.disableUploadingRoundVideoStatus"
    static let disableSpeakingInGroupCallStatus = "nameless.disableSpeakingInGroupCallStatus"
    static let disableChoosingStickerStatus = "nameless.disableChoosingStickerStatus"
    static let disableEmojiInteractionStatus = "nameless.disableEmojiInteractionStatus"
    static let disableEmojiAcknowledgementStatus = "nameless.disableEmojiAcknowledgementStatus"
    static let disableMessageReadReceipt = "nameless.disableMessageReadReceipt"
    static let disableStoryReadReceipt = "nameless.disableStoryReadReceipt"
    static let disableAllAds = "nameless.disableAllAds"
    static let hideProxySponsor = "nameless.hideProxySponsor"
    static let enableSavingProtectedContent = "nameless.enableSavingProtectedContent"
    static let enableSavingSelfDestructingMessages = "nameless.enableSavingSelfDestructingMessages"
    static let disableScreenshotDetection = "nameless.disableScreenshotDetection"
    static let disableSecretChatBlurOnScreenshot = "nameless.disableSecretChatBlurOnScreenshot"
    static let enableLocalPremium = "nameless.enableLocalPremium"
    static let liquidGlassEnabled = "nameless.liquidGlassEnabled"
    static let disableCompactNumbers = "nameless.disableCompactNumbers"
    static let disableZalgoText = "nameless.disableZalgoText"
    static let chatExportEnabled = "nameless.chatExportEnabled"
    static let scrollToTopButtonEnabled = "nameless.scrollToTopButtonEnabled"
    static let unlimitedFavoriteStickers = "nameless.unlimitedFavoriteStickers"
    static let enableTelescope = "nameless.enableTelescope"
    static let enableVideoToCircleOrVoice = "nameless.enableVideoToCircleOrVoice"
    static let emojiDownloaderEnabled = "nameless.emojiDownloaderEnabled"
    static let feelRichEnabled = "nameless.feelRichEnabled"
    static let feelRichStarsAmount = "nameless.feelRichStarsAmount"
    // Free-form override for the device model reported to Telegram. Empty string = off.
    // Read directly by MTApiEnvironment from UserDefaults so MtProtoKit does not have to
    // link SGSimpleSettings; the key literal is duplicated in MTApiEnvironment.m.
    static let deviceModelSpoof = "nameless.deviceModelSpoof"
    static let hideNewChatSticker = "nameless.hideNewChatSticker"
    static let hideBusinessChats = "nameless.hideBusinessChats"
    static let megramGlobalClearGlass = "megram.globalClearGlass"
    static let megramFullGiftCatalog = "megram.fullGiftCatalog"
    static let megramPureClearBubbles = "megram.pureClearBubbles"
    // MARK: Megram — Nextgram parity keys (UI-only for now, no consumers)
    static let nxHideGiftsTab = "megram.nx.hideGiftsTab"
    static let nxHideContactsTab = "megram.nx.hideContactsTab"
    static let nxHideCallsTab = "megram.nx.hideCallsTab"
    static let nxSearchButtonNearTabBar = "megram.nx.searchButtonNearTabBar"
    static let nxFoldersAtBottom = "megram.nx.foldersAtBottom"
    static let nxRememberLastFolder = "megram.nx.rememberLastFolder"
    static let nxNewChatListLook = "megram.nx.newChatListLook"
    static let nxHideChatsTitle = "megram.nx.hideChatsTitle"
    static let nxRamUnderClock = "megram.nx.ramUnderClock"
    static let nxPremiumBadgeInChatList = "megram.nx.premiumBadgeInChatList"
    static let nxAccountSwitcherInChatList = "megram.nx.accountSwitcherInChatList"
    static let nxPipOnSwipe = "megram.nx.pipOnSwipe"
    static let nxRoundVideoBackCamera = "megram.nx.roundVideoBackCamera"
    static let nxCameraInGallery = "megram.nx.cameraInGallery"
    static let nxStripPhotoMetadata = "megram.nx.stripPhotoMetadata"
    static let nxFormattingPanel = "megram.nx.formattingPanel"
    static let nxVoiceOneTime = "megram.nx.voiceOneTime"
    static let nxTranscribeAppleSpeech = "megram.nx.transcribeAppleSpeech"
    static let nxVoiceMorpherEnabled = "megram.nx.voiceMorpherEnabled"
    static let nxForceTCPCalls = "megram.nx.forceTCPCalls"
    static let nxMusicCrossfade = "megram.nx.musicCrossfade"
    static let nxMusicEqualizer = "megram.nx.musicEqualizer"
    static let nxLiveActivityWidget = "megram.nx.liveActivityWidget"
    static let nxWinterSnow = "megram.nx.winterSnow"
    static let nxCustomFontEnabled = "megram.nx.customFontEnabled"
    static let nxAutoClearCacheOnLaunch = "megram.nx.autoClearCacheOnLaunch"
    static let nxHapticsOnUI = "megram.nx.hapticsOnUI"
    static let nxThermalCalmDown = "megram.nx.thermalCalmDown"
    static let settingsBigAvatar = "nameless.settingsBigAvatar"
    static let forwardWarnAuthor = "nameless.forwardWarnAuthor"
    static let profileMusicCard = "nameless.profileMusicCard"
    /// Local (fake) stars wallet: master switch and how much of the configured amount
    /// has already been "spent" locally.
    static let localStarsEnabled = "nameless.localStarsEnabled"
    static let localStarsSpent = "nameless.localStarsSpent"
    static let fakeLocationEnabled = "nameless.fakeLocationEnabled"
    static let fakeLatitude = "nameless.fakeLatitude"
    static let fakeLongitude = "nameless.fakeLongitude"
    static let enableOnlineStatusRecording = "nameless.enableOnlineStatusRecording"
    static let onlineStatusRecordingIntervalMinutes = "nameless.onlineStatusRecordingIntervalMinutes"
    static let ghostModeMessageSendDelaySeconds = "nameless.ghostModeMessageSendDelaySeconds"
    static let ghostModeEnabled = "nameless.ghostMode.enabled"
    static let ghostModeAllStatuses = "nameless.ghostMode.allStatuses"
    static let ghostModeFakeTyping = "nameless.ghostMode.fakeTyping"
    static let ghostModeAntiSpam = "nameless.ghostMode.antiSpam"
    static let ghostModeHideVideoWatch = "nameless.ghostMode.hideVideoWatch"
    static let ghostModeAutoCleanHistory = "nameless.ghostMode.autoCleanHistory"
    static let ghostModeAutoCleanDays = "nameless.ghostMode.autoCleanDays"
    static let ghostModeAlwaysOnline = "nameless.ghostMode.alwaysOnline"
    static let giftIdEnabled = "nameless.giftIdEnabled"
    static let fakeProfileEnabled = "nameless.fakeProfileEnabled"
    static let fakeProfileTargetUserId = "nameless.fakeProfileTargetUserId"
    static let fakeProfileId = "nameless.fakeProfileId"
    static let fakeProfileFirstName = "nameless.fakeProfileFirstName"
    static let fakeProfileLastName = "nameless.fakeProfileLastName"
    static let fakeProfileUsername = "nameless.fakeProfileUsername"
    static let fakeProfilePhone = "nameless.fakeProfilePhone"
    static let fakeProfilePremium = "nameless.fakeProfilePremium"
    static let fakeProfileVerified = "nameless.fakeProfileVerified"
    static let fakeProfileScam = "nameless.fakeProfileScam"
    static let fakeProfileFake = "nameless.fakeProfileFake"
    static let fakeProfileSupport = "nameless.fakeProfileSupport"
    static let fakeProfileBot = "nameless.fakeProfileBot"
    static let enableFontReplacement = "nameless.enableFontReplacement"
    static let fontReplacementName = "nameless.fontReplacementName"
    static let fontReplacementFilePath = "nameless.fontReplacementFilePath"
    static let fontReplacementBoldName = "nameless.fontReplacementBoldName"
    static let fontReplacementBoldFilePath = "nameless.fontReplacementBoldFilePath"
    static let fontReplacementSizeMultiplier = "nameless.fontReplacementSizeMultiplier"
    static let profileCoverMediaPath = "nameless.profileCoverMediaPath"
    static let profileCoverIsVideo = "nameless.profileCoverIsVideo"
    static let pluginSystemEnabled = "nameless.pluginSystemEnabled"
    static let installedPluginsJson = "nameless.installedPluginsJson"
    static let doubleBottomEnabled = "nameless.doubleBottomEnabled"
    static let messageReadReceiptsSendToPeerIds = "nameless.messageReadReceiptsSendToPeerIds"
    static let currentAccountPeerId = "nameless.currentAccountPeerId"
    static let mutedAccountIds = "nameless.mutedAccountIds"
    static let gatedFeatureKeys = "nameless.gatedFeatureKeys"
    static let unlockedFeatureKeys = "nameless.unlockedFeatureKeys"

    static let liquidGlassMessages = "nameless.liquidGlass.messages"
    static let liquidGlassOutgoingMessages = "nameless.liquidGlass.outgoingMessages"
    static let liquidGlassSettings = "nameless.liquidGlass.settings"
    static let liquidGlassProfile = "nameless.liquidGlass.profile"
    static let liquidGlassProfileGifts = "nameless.liquidGlass.profileGifts"
    static let liquidGlassInlineButtons = "nameless.liquidGlass.inlineButtons"
    static let liquidGlassTinting = "nameless.liquidGlass.tinting"
    static let liquidGlassPopup = "nameless.liquidGlass.popup"
    static let liquidGlassContextMenu = "nameless.liquidGlass.contextMenu"
    static let liquidGlassSearch = "nameless.liquidGlass.search"
    static let liquidGlassIntensity = "nameless.liquidGlass.intensity"
    static let liquidGlassFadeAnimation = "nameless.liquidGlass.fadeAnimation"
    static let liquidGlassReactions = "nameless.liquidGlass.reactions"
    static let liquidGlassStickers = "nameless.liquidGlass.stickers"
    static let liquidGlassCalls = "nameless.liquidGlass.calls"
    static let liquidGlassMedia = "nameless.liquidGlass.media"
    static let liquidGlassChatList = "nameless.liquidGlass.chatList"
    static let videoBackgroundEnabled = "nameless.videoBackground.enabled"
    static let videoBackgroundPath = "nameless.videoBackground.path"
    // MARK: - Appearance (Внешний вид)
    static let squareAvatars = "nameless.squareAvatars"
    static let compactChatList = "nameless.compactChatList"
    static let newChatList = "nameless.newChatList"
    static let newChatHeader = "nameless.newChatHeader"
    static let blurInsteadGlass = "nameless.blurInsteadGlass"
    static let oledMode = "nameless.oledMode"
    static let customSettingsIcons = "nameless.customSettingsIcons"
    static let telegramAppIcons = "nameless.telegramAppIcons"
    static let swipeChatOptions = "nameless.swipeChatOptions"
    static let hideVoiceRecordButton = "nameless.hideVoiceRecordButton"
    static let foldersAtBottom = "nameless.foldersAtBottom"
    static let ramUsageUnderClock = "nameless.ramUsageUnderClock"
    static let chatListTitle = "nameless.chatListTitle"
    static let premiumStatusInHeader = "nameless.premiumStatusInHeader"
    static let searchButtonInChatList = "nameless.searchButtonInChatList"
    static let unlimitedPinnedChats = "nameless.unlimitedPinnedChats"
    static let newAccountSwitcher = "nameless.newAccountSwitcher"
    static let profileColorBackground = "nameless.profileColorBackground"
    static let profileAvatarBlur = "nameless.profileAvatarBlur"
    static let profileAvatarBlurMinimal = "nameless.profileAvatarBlurMinimal"
    static let profileAvatarBlurTinting = "nameless.profileAvatarBlurTinting"
    static let musicAlbumBlur = "nameless.musicAlbumBlur"
    static let musicPlayerEffect = "nameless.musicPlayerEffect"
    static let badgeIslandColor = "nameless.badgeIslandColor"
    static let messageOutline = "nameless.messageOutline"
    static let messageTransparent = "nameless.messageTransparent"
    static let messageSemiTransparent = "nameless.messageSemiTransparent"
    static let messageBlurEffect = "nameless.messageBlurEffect"
    static let wideChannelPosts = "nameless.wideChannelPosts"
    static let particleEffectEnabled = "nameless.particleEffect.enabled"
    static let particleEffectSpeed = "nameless.particleEffect.speed"
    static let particleEffectDensity = "nameless.particleEffect.density"
    static let stickerSize = "nameless.stickerSize"
    static let accountColorsSaturation = "nameless.accountColorsSaturation"
    // MARK: - Messages (Сообщения)
    static let deletedMessageOpacity = "nameless.deletedMessageOpacity"
    static let deletedTrashColorHex = "nameless.deletedTrashColorHex"
    static let autoFormatMode = "nameless.autoFormatMode"
    static let showOriginalEdited = "nameless.showOriginalEdited"
    static let truncateLongMessages = "nameless.truncateLongMessages"
    static let saveChatHistory = "nameless.saveChatHistory"
    static let saveOnceMedia = "nameless.saveOnceMedia"
    static let noAutoNextVoice = "nameless.noAutoNextVoice"
    static let semiTransparentWhenMentioned = "nameless.semiTransparentWhenMentioned"
    static let charCounterInput = "nameless.charCounterInput"
    static let charCounterInChat = "nameless.charCounterInChat"
    static let hideMyDeleted = "nameless.hideMyDeleted"
    static let hideMyEdited = "nameless.hideMyEdited"
    static let hideBotEdited = "nameless.hideBotEdited"
    static let hideBotDeleted = "nameless.hideBotDeleted"
    static let doubleTapToEdit = "nameless.doubleTapToEdit"
    // MARK: - Camera (Камера)
    static let defaultCameraBack = "nameless.camera.defaultBack"
    static let useDeviceMicrophone = "nameless.camera.useDeviceMic"
    static let sendHDPhoto = "nameless.camera.sendHDPhoto"
    static let jpegQuality = "nameless.camera.jpegQuality"
    static let rememberLastCamera = "nameless.camera.rememberLast"
    static let staticZoomRecording = "nameless.camera.staticZoom"
    static let alwaysSendHD = "nameless.camera.alwaysSendHD"
    // MARK: - Info (Информация)
    static let showIdAndDC = "nameless.showIdAndDC"
    static let showSeconds = "nameless.showSeconds"
    static let showFullViews = "nameless.showFullViews"
    static let hidePhoneNumber = "nameless.hidePhoneNumber"
    static let showCreationDate = "nameless.showCreationDate"
    static let showIfMutualContacts = "nameless.showIfMutualContacts"
    static let showRegistrationDate = "nameless.showRegistrationDate"
    // MARK: - Additional (Дополнительно)
    static let vibrationEnabled = "nameless.vibration.enabled"
    static let reactionsEnabled = "nameless.reactions.enabled"
    static let speedBoostEnabled = "nameless.speedBoost.enabled"
    // MARK: - Notifications
    static let localNotificationsEnabled = "nameless.notifications.local"
    // MARK: - Privacy/Confidentiality
    static let bypassProtectedContent = "nameless.bypassProtectedContent"
    static let removeSpoilersEverywhere = "nameless.removeSpoilersEverywhere"
    static let antiScamEnabled = "nameless.antiScam"
    static let warnBeforeCall = "nameless.warnBeforeCall"
    static let outgoingPhotoQuality = "nameless.outgoingPhotoQuality"
    // MARK: - Attachment UI
    // When enabled, the '+' attachment picker replaces the classic horizontal tab bar with
    // a compact rounded glass sheet stacking the same buttons as a vertical list.
    static let namelessCompactAttachmentSheet = "nameless.compactAttachmentSheet"

    // MARK: - Megram profile
    /// Draws the saved track as a card with its blurred cover behind it,
    /// instead of the flat one-line strip.
    static let profileTrackCard = "nameless.profile.trackCard"
    /// Replaces the Swiftgram id/dc rows with tappable chips under the username.
    static let profileIdChips = "nameless.profile.idChips"
    static let hideProfileEmojiStatus = "nameless.profile.hideEmojiStatus"
    static let hideProfileColorRow = "nameless.profile.hideColorRow"
    static let hideProfilePhotoRow = "nameless.profile.hidePhotoRow"
    static let hideProfileIdRow = "nameless.profile.hideIdRow"

    // MARK: - Megram peer menu (the three-dot menu in a private chat)
    static let hideMenuWallpaper = "nameless.peerMenu.hideWallpaper"
    static let hideMenuSecretChat = "nameless.peerMenu.hideSecretChat"
    static let hideMenuSendContact = "nameless.peerMenu.hideSendContact"
    static let hideMenuAutoDelete = "nameless.peerMenu.hideAutoDelete"
    static let hideMenuCopyProtection = "nameless.peerMenu.hideCopyProtection"
    static let hideMenuClearHistory = "nameless.peerMenu.hideClearHistory"
    static let hideMenuBlock = "nameless.peerMenu.hideBlock"

    // MARK: - Megram tabs and profile extras
    static let deviceModelSpoofEnabled = "nameless.deviceModelSpoofEnabled"
    static let hideProfileGiftsTab = "nameless.profile.hideGiftsTab"
    static let hideContactsTab = "nameless.tabs.hideContacts"
    static let hideCallsTab = "nameless.tabs.hideCalls"
    static let tabBarHeightScale = "nameless.tabs.heightScale"
    static let tabBarWidthScale = "nameless.tabs.widthScale"

    // MARK: - Megram settings sections
    static let hideSettingsSavedMessages = "nameless.settingsSection.savedMessages"
    static let hideSettingsDevices = "nameless.settingsSection.devices"
    static let hideSettingsChatFolders = "nameless.settingsSection.chatFolders"
    static let hideSettingsPowerSaving = "nameless.settingsSection.powerSaving"
    static let hideSettingsLanguage = "nameless.settingsSection.language"
    static let hideSettingsNotifications = "nameless.settingsSection.notifications"
    static let hideSettingsPrivacy = "nameless.settingsSection.privacy"
    static let hideSettingsDataAndStorage = "nameless.settingsSection.dataAndStorage"
    static let hideSettingsAppearance = "nameless.settingsSection.appearance"
    static let hideSettingsProxy = "nameless.settingsSection.proxy"
    static let hideSettingsMyProfile = "nameless.settingsSection.myProfile"
    static let hideSettingsRecentCalls = "nameless.settingsSection.recentCalls"
    static let hideSettingsPremium = "nameless.settingsSection.premium"
    static let hideSettingsStars = "nameless.settingsSection.stars"
    static let hideSettingsBusiness = "nameless.settingsSection.business"
    static let hideSettingsSupport = "nameless.settingsSection.support"
    static let hideSettingsFaq = "nameless.settingsSection.faq"
    static let hideSettingsTips = "nameless.settingsSection.tips"
    static let hideSettingsSendGift = "nameless.settingsSection.sendGift"
}

private enum NamelessRollbackStorage {
    static let snapshotKey = "nameless.rollback.snapshot.v1"
    static let managedPrefixes = ["nameless.", "VoiceMorpher."]
}

private extension UserDefaults {
    func namelessBool(_ key: String, default defaultValue: Bool = false) -> Bool {
        if self.object(forKey: key) == nil {
            return defaultValue
        }
        return self.bool(forKey: key)
    }

    func namelessInt32(_ key: String, default defaultValue: Int32 = 0) -> Int32 {
        if self.object(forKey: key) == nil {
            return defaultValue
        }
        return Int32(self.integer(forKey: key))
    }

    func namelessInt64(_ key: String, default defaultValue: Int64 = 0) -> Int64 {
        if self.object(forKey: key) == nil {
            return defaultValue
        }
        return Int64(self.integer(forKey: key))
    }

    func namelessDouble(_ key: String, default defaultValue: Double = 0.0) -> Double {
        if self.object(forKey: key) == nil {
            return defaultValue
        }
        return self.double(forKey: key)
    }

    func namelessString(_ key: String, default defaultValue: String = "") -> String {
        return self.string(forKey: key) ?? defaultValue
    }

    func namelessStringArray(_ key: String) -> [String] {
        return self.stringArray(forKey: key) ?? []
    }
}

public extension Notification.Name {
    static let luxgramLiquidGlassDidChange = Notification.Name("nameless.liquidGlassDidChange")
    static let namelessVideoBackgroundDidChange = Notification.Name("nameless.videoBackgroundDidChange")
    static let sgHideProxySponsorDidChange = Notification.Name("nameless.hideProxySponsorDidChange")
    static let namelessLocalStarsDidChange = Notification.Name("nameless.localStarsDidChange")
}

public extension SGSimpleSettings {
    private var storage: UserDefaults {
        return .standard
    }

    func beginNamelessRollbackSnapshot() {
        let values = storage.dictionaryRepresentation().filter { key, _ in
            for prefix in NamelessRollbackStorage.managedPrefixes {
                if key.hasPrefix(prefix) {
                    return true
                }
            }
            return false
        }

        if let data = try? JSONSerialization.data(withJSONObject: values, options: []) {
            storage.set(data, forKey: NamelessRollbackStorage.snapshotKey)
        }
    }

    @discardableResult
    func restoreNamelessRollbackSnapshot() -> Bool {
        guard let data = storage.data(forKey: NamelessRollbackStorage.snapshotKey),
              let values = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return false
        }

        let existing = storage.dictionaryRepresentation()
        for key in existing.keys {
            for prefix in NamelessRollbackStorage.managedPrefixes {
                if key.hasPrefix(prefix) {
                    storage.removeObject(forKey: key)
                    break
                }
            }
        }

        for (key, value) in values {
            storage.set(value, forKey: key)
        }

        storage.synchronize()
        return true
    }

    // Default ON — anti-delete must work out of the box (was false → feature appeared broken)
    var showDeletedMessages: Bool { get { storage.namelessBool(NamelessSettingsKey.showDeletedMessages, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.showDeletedMessages) } }
    var saveDeletedMessagesMedia: Bool { get { storage.namelessBool(NamelessSettingsKey.saveDeletedMessagesMedia, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.saveDeletedMessagesMedia) } }
    var saveDeletedMessagesReactions: Bool { get { storage.namelessBool(NamelessSettingsKey.saveDeletedMessagesReactions) } set { storage.set(newValue, forKey: NamelessSettingsKey.saveDeletedMessagesReactions) } }
    var saveDeletedMessagesForBots: Bool { get { storage.namelessBool(NamelessSettingsKey.saveDeletedMessagesForBots) } set { storage.set(newValue, forKey: NamelessSettingsKey.saveDeletedMessagesForBots) } }
    var saveEditHistory: Bool { get { storage.namelessBool(NamelessSettingsKey.saveEditHistory) } set { storage.set(newValue, forKey: NamelessSettingsKey.saveEditHistory) } }
    var enableLocalMessageEditing: Bool { get { storage.namelessBool(NamelessSettingsKey.enableLocalMessageEditing) } set { storage.set(newValue, forKey: NamelessSettingsKey.enableLocalMessageEditing) } }
    var keepRemovedChannels: Bool { get { storage.namelessBool(NamelessSettingsKey.keepRemovedChannels) } set { storage.set(newValue, forKey: NamelessSettingsKey.keepRemovedChannels) } }
    var disableOnlineStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableOnlineStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableOnlineStatus) } }
    var disableTypingStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableTypingStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableTypingStatus) } }
    var disableRecordingVideoStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableRecordingVideoStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableRecordingVideoStatus) } }
    var disableUploadingVideoStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableUploadingVideoStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableUploadingVideoStatus) } }
    var disableVCMessageRecordingStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableVCMessageRecordingStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableVCMessageRecordingStatus) } }
    var disableVCMessageUploadingStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableVCMessageUploadingStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableVCMessageUploadingStatus) } }
    var disableUploadingPhotoStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableUploadingPhotoStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableUploadingPhotoStatus) } }
    var disableUploadingFileStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableUploadingFileStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableUploadingFileStatus) } }
    var disableChoosingLocationStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableChoosingLocationStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableChoosingLocationStatus) } }
    var disableChoosingContactStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableChoosingContactStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableChoosingContactStatus) } }
    var disablePlayingGameStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disablePlayingGameStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disablePlayingGameStatus) } }
    var disableRecordingRoundVideoStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableRecordingRoundVideoStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableRecordingRoundVideoStatus) } }
    var disableUploadingRoundVideoStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableUploadingRoundVideoStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableUploadingRoundVideoStatus) } }
    var disableSpeakingInGroupCallStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableSpeakingInGroupCallStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableSpeakingInGroupCallStatus) } }
    var disableChoosingStickerStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableChoosingStickerStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableChoosingStickerStatus) } }
    var disableEmojiInteractionStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableEmojiInteractionStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableEmojiInteractionStatus) } }
    var disableEmojiAcknowledgementStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.disableEmojiAcknowledgementStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableEmojiAcknowledgementStatus) } }
    var disableMessageReadReceipt: Bool { get { storage.namelessBool(NamelessSettingsKey.disableMessageReadReceipt) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableMessageReadReceipt) } }
    var disableStoryReadReceipt: Bool { get { storage.namelessBool(NamelessSettingsKey.disableStoryReadReceipt) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableStoryReadReceipt) } }
    var disableAllAds: Bool { get { storage.namelessBool(NamelessSettingsKey.disableAllAds) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableAllAds) } }
    var hideProxySponsor: Bool { get { storage.namelessBool(NamelessSettingsKey.hideProxySponsor) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideProxySponsor) } }
    var enableSavingProtectedContent: Bool { get { storage.namelessBool(NamelessSettingsKey.enableSavingProtectedContent) } set { storage.set(newValue, forKey: NamelessSettingsKey.enableSavingProtectedContent) } }
    var enableSavingSelfDestructingMessages: Bool { get { storage.namelessBool(NamelessSettingsKey.enableSavingSelfDestructingMessages) } set { storage.set(newValue, forKey: NamelessSettingsKey.enableSavingSelfDestructingMessages) } }
    var disableScreenshotDetection: Bool { get { storage.namelessBool(NamelessSettingsKey.disableScreenshotDetection) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableScreenshotDetection) } }
    var disableSecretChatBlurOnScreenshot: Bool { get { storage.namelessBool(NamelessSettingsKey.disableSecretChatBlurOnScreenshot) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableSecretChatBlurOnScreenshot) } }
    var enableLocalPremium: Bool { get { storage.namelessBool(NamelessSettingsKey.enableLocalPremium, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.enableLocalPremium) } }
    /// Apple liquid glass on every surface. Mutually exclusive with `blurInsteadGlass`, which is
    /// literally the request to render those surfaces with a plain blur instead.
    var liquidGlassEnabled: Bool {
        get { storage.namelessBool(NamelessSettingsKey.liquidGlassEnabled, default: true) }
        set {
            storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassEnabled)
            if newValue {
                storage.set(false, forKey: NamelessSettingsKey.blurInsteadGlass)
            }
        }
    }
    var disableCompactNumbers: Bool { get { storage.namelessBool(NamelessSettingsKey.disableCompactNumbers) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableCompactNumbers) } }
    var disableZalgoText: Bool { get { storage.namelessBool(NamelessSettingsKey.disableZalgoText) } set { storage.set(newValue, forKey: NamelessSettingsKey.disableZalgoText) } }
    var chatExportEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.chatExportEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.chatExportEnabled) } }
    var scrollToTopButtonEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.scrollToTopButtonEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.scrollToTopButtonEnabled) } }
    var unlimitedFavoriteStickers: Bool { get { storage.namelessBool(NamelessSettingsKey.unlimitedFavoriteStickers) } set { storage.set(newValue, forKey: NamelessSettingsKey.unlimitedFavoriteStickers) } }
    var enableTelescope: Bool { get { storage.namelessBool(NamelessSettingsKey.enableTelescope) } set { storage.set(newValue, forKey: NamelessSettingsKey.enableTelescope) } }
    var enableVideoToCircleOrVoice: Bool { get { storage.namelessBool(NamelessSettingsKey.enableVideoToCircleOrVoice) } set { storage.set(newValue, forKey: NamelessSettingsKey.enableVideoToCircleOrVoice) } }
    var emojiDownloaderEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.emojiDownloaderEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.emojiDownloaderEnabled) } }
    var feelRichEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.feelRichEnabled, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.feelRichEnabled) } }
    var feelRichStarsAmount: String { get { storage.namelessString(NamelessSettingsKey.feelRichStarsAmount, default: "1598") } set { storage.set(newValue, forKey: NamelessSettingsKey.feelRichStarsAmount) } }

    /// Custom device model reported to Telegram (initConnection, active sessions,
    /// login-code emails). Empty string means "use the real hardware model".
    var deviceModelSpoof: String {
        get { storage.namelessString(NamelessSettingsKey.deviceModelSpoof, default: "") }
        set { storage.set(newValue, forKey: NamelessSettingsKey.deviceModelSpoof) }
    }

    /// Hide the greeting sticker on empty chats.
    var hideNewChatSticker: Bool {
        get { storage.namelessBool(NamelessSettingsKey.hideNewChatSticker) }
        set { storage.set(newValue, forKey: NamelessSettingsKey.hideNewChatSticker) }
    }

    /// Hide the "bot manages this chat" panel that appears at the top of chats delegated
    /// to a Telegram Business assistant bot.
    var hideBusinessChats: Bool {
        get { storage.namelessBool(NamelessSettingsKey.hideBusinessChats) }
        set { storage.set(newValue, forKey: NamelessSettingsKey.hideBusinessChats) }
    }

    /// Megram — force UIGlassEffect(.clear) everywhere GlassBackgroundView renders `.panel`
    /// glass. Global switch, on by default so the user sees the see-through look right away
    /// (navigation, input panel, buttons, sheets, settings pills).
    /// Draw message bubbles and inline buttons as untinted `UIGlassEffect(.clear)` — pure glass,
    /// no colour at all.
    ///
    /// The trade-off is deliberate and worth knowing: without a tint there is nothing left to
    /// distinguish an incoming bubble from an outgoing one except its side of the screen and the
    /// delivery checks. Turning this off brings back a faint tint from the theme's bubble colour.
    var megramPureClearBubbles: Bool {
        get { storage.namelessBool(NamelessSettingsKey.megramPureClearBubbles, default: true) }
        set { storage.set(newValue, forKey: NamelessSettingsKey.megramPureClearBubbles) }
    }

    /// Ask the server for the complete star-gift catalog instead of "only what changed".
    ///
    /// `payments.getStarGifts` takes a hash of the catalog the client already has; when it matches,
    /// the server answers `starGiftsNotModified` and the client keeps showing its cached list —
    /// which is why gifts that were sold out or withdrawn quietly stop appearing. Sending hash 0
    /// makes the answer unconditional, so the full catalog comes back every time.
    ///
    /// The cost is real and worth stating: the catalog is re-downloaded on every refresh instead of
    /// being skipped, so this is a switch rather than unconditional behaviour.
    var megramFullGiftCatalog: Bool {
        get { storage.namelessBool(NamelessSettingsKey.megramFullGiftCatalog, default: true) }
        set { storage.set(newValue, forKey: NamelessSettingsKey.megramFullGiftCatalog) }
    }

    var megramGlobalClearGlass: Bool {
        get { storage.namelessBool(NamelessSettingsKey.megramGlobalClearGlass, default: true) }
        set { storage.set(newValue, forKey: NamelessSettingsKey.megramGlobalClearGlass) }
    }

    // MARK: Megram — Nextgram parity properties. Every one is a plain Bool with no
    // downstream consumer; they exist so the settings UI can list the toggle now and the
    // behaviour can be wired in later without a settings-model change.
    var nxHideGiftsTab: Bool { get { storage.namelessBool(NamelessSettingsKey.nxHideGiftsTab) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxHideGiftsTab) } }
    var nxHideContactsTab: Bool { get { storage.namelessBool(NamelessSettingsKey.nxHideContactsTab) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxHideContactsTab) } }
    var nxHideCallsTab: Bool { get { storage.namelessBool(NamelessSettingsKey.nxHideCallsTab) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxHideCallsTab) } }
    var nxSearchButtonNearTabBar: Bool { get { storage.namelessBool(NamelessSettingsKey.nxSearchButtonNearTabBar) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxSearchButtonNearTabBar) } }
    var nxFoldersAtBottom: Bool { get { storage.namelessBool(NamelessSettingsKey.nxFoldersAtBottom) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxFoldersAtBottom) } }
    var nxRememberLastFolder: Bool { get { storage.namelessBool(NamelessSettingsKey.nxRememberLastFolder) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxRememberLastFolder) } }
    var nxNewChatListLook: Bool { get { storage.namelessBool(NamelessSettingsKey.nxNewChatListLook) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxNewChatListLook) } }
    var nxHideChatsTitle: Bool { get { storage.namelessBool(NamelessSettingsKey.nxHideChatsTitle) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxHideChatsTitle) } }
    var nxRamUnderClock: Bool { get { storage.namelessBool(NamelessSettingsKey.nxRamUnderClock) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxRamUnderClock) } }
    var nxPremiumBadgeInChatList: Bool { get { storage.namelessBool(NamelessSettingsKey.nxPremiumBadgeInChatList) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxPremiumBadgeInChatList) } }
    var nxAccountSwitcherInChatList: Bool { get { storage.namelessBool(NamelessSettingsKey.nxAccountSwitcherInChatList) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxAccountSwitcherInChatList) } }
    var nxPipOnSwipe: Bool { get { storage.namelessBool(NamelessSettingsKey.nxPipOnSwipe) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxPipOnSwipe) } }
    var nxRoundVideoBackCamera: Bool { get { storage.namelessBool(NamelessSettingsKey.nxRoundVideoBackCamera) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxRoundVideoBackCamera) } }
    var nxCameraInGallery: Bool { get { storage.namelessBool(NamelessSettingsKey.nxCameraInGallery) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxCameraInGallery) } }
    var nxStripPhotoMetadata: Bool { get { storage.namelessBool(NamelessSettingsKey.nxStripPhotoMetadata) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxStripPhotoMetadata) } }
    var nxFormattingPanel: Bool { get { storage.namelessBool(NamelessSettingsKey.nxFormattingPanel) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxFormattingPanel) } }
    var nxVoiceOneTime: Bool { get { storage.namelessBool(NamelessSettingsKey.nxVoiceOneTime) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxVoiceOneTime) } }
    var nxTranscribeAppleSpeech: Bool { get { storage.namelessBool(NamelessSettingsKey.nxTranscribeAppleSpeech) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxTranscribeAppleSpeech) } }
    var nxVoiceMorpherEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.nxVoiceMorpherEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxVoiceMorpherEnabled) } }
    var nxForceTCPCalls: Bool { get { storage.namelessBool(NamelessSettingsKey.nxForceTCPCalls) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxForceTCPCalls) } }
    var nxMusicCrossfade: Bool { get { storage.namelessBool(NamelessSettingsKey.nxMusicCrossfade) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxMusicCrossfade) } }
    var nxMusicEqualizer: Bool { get { storage.namelessBool(NamelessSettingsKey.nxMusicEqualizer) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxMusicEqualizer) } }
    var nxLiveActivityWidget: Bool { get { storage.namelessBool(NamelessSettingsKey.nxLiveActivityWidget) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxLiveActivityWidget) } }
    var nxWinterSnow: Bool { get { storage.namelessBool(NamelessSettingsKey.nxWinterSnow) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxWinterSnow) } }
    var nxCustomFontEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.nxCustomFontEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxCustomFontEnabled) } }
    var nxAutoClearCacheOnLaunch: Bool { get { storage.namelessBool(NamelessSettingsKey.nxAutoClearCacheOnLaunch) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxAutoClearCacheOnLaunch) } }
    var nxHapticsOnUI: Bool { get { storage.namelessBool(NamelessSettingsKey.nxHapticsOnUI) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxHapticsOnUI) } }
    var nxThermalCalmDown: Bool { get { storage.namelessBool(NamelessSettingsKey.nxThermalCalmDown) } set { storage.set(newValue, forKey: NamelessSettingsKey.nxThermalCalmDown) } }

    /// Open Settings with the avatar already expanded (fills the top of the screen).
    /// Megram: part of the client's look rather than a preference, so it is
    /// always on and no longer carries a switch. The setter is kept so existing
    /// call sites compile, but the stored value no longer decides anything.
    var settingsBigAvatar: Bool {
        get { true }
        set { storage.set(newValue, forKey: NamelessSettingsKey.settingsBigAvatar) }
    }

    /// Confirm-with-cooldown alert when forwarding a message back to its author.
    var forwardWarnAuthor: Bool {
        get { storage.namelessBool(NamelessSettingsKey.forwardWarnAuthor, default: true) }
        set { storage.set(newValue, forKey: NamelessSettingsKey.forwardWarnAuthor) }
    }

    /// Render the "now playing" card in a peer's profile header.
    var profileMusicCard: Bool {
        get { storage.namelessBool(NamelessSettingsKey.profileMusicCard, default: true) }
        set { storage.set(newValue, forKey: NamelessSettingsKey.profileMusicCard) }
    }


    // MARK: - Local (fake) stars wallet
    //
    // `feelRichStarsAmount` is the user-entered top-up; `localStarsSpent` accumulates what
    // has been "paid" locally. The displayed balance is the difference, so the wallet behaves
    // like a real one while never touching the server.

    /// Master switch for showing a locally-controlled stars balance instead of the real one.
    var localStarsEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.localStarsEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.localStarsEnabled) } }

    /// Total amount already spent from the local wallet.
    var localStarsSpent: Int64 {
        get { Int64(storage.namelessDouble(NamelessSettingsKey.localStarsSpent, default: 0.0)) }
        set { storage.set(Double(max(0, newValue)), forKey: NamelessSettingsKey.localStarsSpent) }
    }

    /// Configured top-up amount, parsed from the free-form text field.
    var localStarsTopUp: Int64 {
        return Int64(feelRichStarsAmount.filter { $0.isNumber }) ?? 0
    }

    /// What the UI should show: top-up minus everything spent, never negative.
    var localStarsBalance: Int64 {
        return max(0, localStarsTopUp - localStarsSpent)
    }

    /// Deducts from the local wallet. Returns false when the balance is insufficient,
    /// mirroring how a real payment would fail.
    @discardableResult
    func spendLocalStars(_ amount: Int64) -> Bool {
        guard localStarsEnabled, amount > 0 else { return false }
        guard localStarsBalance >= amount else { return false }
        localStarsSpent += amount
        NotificationCenter.default.post(name: .namelessLocalStarsDidChange, object: nil)
        return true
    }

    /// Resets the spent counter (a "top-up" of the fake wallet).
    func resetLocalStarsSpending() {
        localStarsSpent = 0
        NotificationCenter.default.post(name: .namelessLocalStarsDidChange, object: nil)
    }
    var fakeLocationEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.fakeLocationEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeLocationEnabled) } }
    var fakeLatitude: Double { get { storage.namelessDouble(NamelessSettingsKey.fakeLatitude) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeLatitude) } }
    var fakeLongitude: Double { get { storage.namelessDouble(NamelessSettingsKey.fakeLongitude) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeLongitude) } }
    var enableOnlineStatusRecording: Bool { get { storage.namelessBool(NamelessSettingsKey.enableOnlineStatusRecording, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.enableOnlineStatusRecording) } }
    var onlineStatusRecordingIntervalMinutes: Int32 { get { storage.namelessInt32(NamelessSettingsKey.onlineStatusRecordingIntervalMinutes, default: 10) } set { storage.set(Int(newValue), forKey: NamelessSettingsKey.onlineStatusRecordingIntervalMinutes) } }
    var ghostModeMessageSendDelaySeconds: Int32 { get { storage.namelessInt32(NamelessSettingsKey.ghostModeMessageSendDelaySeconds) } set { storage.set(Int(newValue), forKey: NamelessSettingsKey.ghostModeMessageSendDelaySeconds) } }
    /// Master ghost mode toggle. Individual switches retain their own values.
    /// Ghost mode hides the online status. Mutually exclusive with `ghostModeAlwaysOnline`, which
    /// forces the opposite — with both on, whichever wrote last silently won.
    var ghostModeEnabled: Bool {
        get { storage.namelessBool(NamelessSettingsKey.ghostModeEnabled) }
        set {
            storage.set(newValue, forKey: NamelessSettingsKey.ghostModeEnabled)
            if newValue {
                storage.set(false, forKey: NamelessSettingsKey.ghostModeAlwaysOnline)
            }
        }
    }

    /// Whether at least one Lead-compatible Ghost Mode subfeature is selected.
    var hasGhostModeSubfeatureEnabled: Bool {
        return disableOnlineStatus || disableTypingStatus || disableVCMessageRecordingStatus || disableVCMessageUploadingStatus || disableUploadingVideoStatus || disableRecordingVideoStatus || disableUploadingPhotoStatus || disableUploadingFileStatus || disableChoosingLocationStatus || disableChoosingContactStatus || disablePlayingGameStatus || disableRecordingRoundVideoStatus || disableUploadingRoundVideoStatus || disableSpeakingInGroupCallStatus || disableChoosingStickerStatus || disableEmojiInteractionStatus || disableEmojiAcknowledgementStatus || disableMessageReadReceipt || disableStoryReadReceipt
    }
    /// Fake typing — show "typing..." to contact even when not typing
    var ghostModeFakeTyping: Bool { get { storage.namelessBool(NamelessSettingsKey.ghostModeFakeTyping) } set { storage.set(newValue, forKey: NamelessSettingsKey.ghostModeFakeTyping) } }
    /// Anti-spam: auto-delete messages from non-contacts
    var ghostModeAntiSpam: Bool { get { storage.namelessBool(NamelessSettingsKey.ghostModeAntiSpam) } set { storage.set(newValue, forKey: NamelessSettingsKey.ghostModeAntiSpam) } }
    /// Hide that you are watching a video/circle
    var ghostModeHideVideoWatch: Bool { get { storage.namelessBool(NamelessSettingsKey.ghostModeHideVideoWatch) } set { storage.set(newValue, forKey: NamelessSettingsKey.ghostModeHideVideoWatch) } }
    /// Auto-clean history older than N days
    var ghostModeAutoCleanHistory: Bool { get { storage.namelessBool(NamelessSettingsKey.ghostModeAutoCleanHistory) } set { storage.set(newValue, forKey: NamelessSettingsKey.ghostModeAutoCleanHistory) } }
    var ghostModeAutoCleanDays: Int32 { get { storage.namelessInt32(NamelessSettingsKey.ghostModeAutoCleanDays, default: 30) } set { storage.set(Int(newValue), forKey: NamelessSettingsKey.ghostModeAutoCleanDays) } }
    /// Always show online status (overrides disableOnlineStatus)
    var ghostModeAlwaysOnline: Bool {
        get { storage.namelessBool(NamelessSettingsKey.ghostModeAlwaysOnline) }
        set {
            storage.set(newValue, forKey: NamelessSettingsKey.ghostModeAlwaysOnline)
            if newValue {
                storage.set(false, forKey: NamelessSettingsKey.ghostModeEnabled)
            }
        }
    }

    /// Changes only the Ghost Mode master switch, preserving individual feature choices.
    func applyGhostModeAll(enabled: Bool) {
        ghostModeEnabled = enabled
        NotificationCenter.default.post(name: NSNotification.Name("nameless.ghostModeDidChange"), object: nil)
    }
    var giftIdEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.giftIdEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.giftIdEnabled) } }
    var fakeProfileEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.fakeProfileEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeProfileEnabled) } }
    var fakeProfileTargetUserId: Int64 { get { storage.namelessInt64(NamelessSettingsKey.fakeProfileTargetUserId) } set { storage.set(Int(newValue), forKey: NamelessSettingsKey.fakeProfileTargetUserId) } }
    var fakeProfileId: Int64 { get { storage.namelessInt64(NamelessSettingsKey.fakeProfileId) } set { storage.set(Int(newValue), forKey: NamelessSettingsKey.fakeProfileId) } }
    var fakeProfileFirstName: String { get { storage.namelessString(NamelessSettingsKey.fakeProfileFirstName) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeProfileFirstName) } }
    var fakeProfileLastName: String { get { storage.namelessString(NamelessSettingsKey.fakeProfileLastName) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeProfileLastName) } }
    var fakeProfileUsername: String { get { storage.namelessString(NamelessSettingsKey.fakeProfileUsername) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeProfileUsername) } }
    var fakeProfilePhone: String { get { storage.namelessString(NamelessSettingsKey.fakeProfilePhone) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeProfilePhone) } }
    var fakeProfilePremium: Bool { get { storage.namelessBool(NamelessSettingsKey.fakeProfilePremium) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeProfilePremium) } }
    var fakeProfileVerified: Bool { get { storage.namelessBool(NamelessSettingsKey.fakeProfileVerified) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeProfileVerified) } }
    var fakeProfileScam: Bool { get { storage.namelessBool(NamelessSettingsKey.fakeProfileScam) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeProfileScam) } }
    var fakeProfileFake: Bool { get { storage.namelessBool(NamelessSettingsKey.fakeProfileFake) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeProfileFake) } }
    var fakeProfileSupport: Bool { get { storage.namelessBool(NamelessSettingsKey.fakeProfileSupport) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeProfileSupport) } }
    var fakeProfileBot: Bool { get { storage.namelessBool(NamelessSettingsKey.fakeProfileBot) } set { storage.set(newValue, forKey: NamelessSettingsKey.fakeProfileBot) } }
    var enableFontReplacement: Bool { get { storage.namelessBool(NamelessSettingsKey.enableFontReplacement) } set { storage.set(newValue, forKey: NamelessSettingsKey.enableFontReplacement) } }
    var fontReplacementName: String { get { storage.namelessString(NamelessSettingsKey.fontReplacementName) } set { storage.set(newValue, forKey: NamelessSettingsKey.fontReplacementName) } }
    var fontReplacementFilePath: String { get { storage.namelessString(NamelessSettingsKey.fontReplacementFilePath) } set { storage.set(newValue, forKey: NamelessSettingsKey.fontReplacementFilePath) } }
    var fontReplacementBoldName: String { get { storage.namelessString(NamelessSettingsKey.fontReplacementBoldName) } set { storage.set(newValue, forKey: NamelessSettingsKey.fontReplacementBoldName) } }
    var fontReplacementBoldFilePath: String { get { storage.namelessString(NamelessSettingsKey.fontReplacementBoldFilePath) } set { storage.set(newValue, forKey: NamelessSettingsKey.fontReplacementBoldFilePath) } }
    var fontReplacementSizeMultiplier: Int32 { get { storage.namelessInt32(NamelessSettingsKey.fontReplacementSizeMultiplier, default: 100) } set { storage.set(Int(newValue), forKey: NamelessSettingsKey.fontReplacementSizeMultiplier) } }
    var profileCoverMediaPath: String { get { storage.namelessString(NamelessSettingsKey.profileCoverMediaPath) } set { storage.set(newValue, forKey: NamelessSettingsKey.profileCoverMediaPath) } }
    var profileCoverIsVideo: Bool { get { storage.namelessBool(NamelessSettingsKey.profileCoverIsVideo) } set { storage.set(newValue, forKey: NamelessSettingsKey.profileCoverIsVideo) } }
    var pluginSystemEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.pluginSystemEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.pluginSystemEnabled) } }
    var installedPluginsJson: String { get { storage.namelessString(NamelessSettingsKey.installedPluginsJson, default: "[]") } set { storage.set(newValue, forKey: NamelessSettingsKey.installedPluginsJson) } }
    var doubleBottomEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.doubleBottomEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.doubleBottomEnabled) } }
    var messageReadReceiptsSendToPeerIds: [String] { get { storage.namelessStringArray(NamelessSettingsKey.messageReadReceiptsSendToPeerIds) } set { storage.set(newValue, forKey: NamelessSettingsKey.messageReadReceiptsSendToPeerIds) } }
    var unlockedFeatureKeys: [String] { get { storage.namelessStringArray(NamelessSettingsKey.unlockedFeatureKeys) } set { storage.set(newValue, forKey: NamelessSettingsKey.unlockedFeatureKeys) } }

    var currentAccountPeerId: String { get { storage.namelessString(NamelessSettingsKey.currentAccountPeerId) } set { storage.set(newValue, forKey: NamelessSettingsKey.currentAccountPeerId) } }

    var namelessLiquidGlassMessages: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassMessages, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassMessages) } }
    var namelessLiquidGlassOutgoingMessages: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassOutgoingMessages, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassOutgoingMessages) } }
    var namelessLiquidGlassSettings: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassSettings, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassSettings) } }
    var namelessLiquidGlassProfile: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassProfile, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassProfile) } }
    var namelessLiquidGlassProfileGifts: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassProfileGifts, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassProfileGifts) } }
    var namelessLiquidGlassInlineButtons: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassInlineButtons, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassInlineButtons) } }
    var namelessLiquidGlassTinting: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassTinting) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassTinting) } }
    var namelessLiquidGlassPopup: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassPopup, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassPopup) } }
    var namelessLiquidGlassContextMenu: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassContextMenu, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassContextMenu) } }
    var namelessLiquidGlassSearch: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassSearch, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassSearch) } }
    /// Glass intensity 0.0 (thinnest, most see-through glass) … 1.0 (densest). Default = 1.0.
    /// `namelessDouble` already returns the default when the key was never written, so the
    /// whole range stays addressable — a stored 0.0 means "as transparent as possible",
    /// not "unset".
    var namelessLiquidGlassIntensity: Double {
        get {
            let v = storage.namelessDouble(NamelessSettingsKey.liquidGlassIntensity, default: 1.0)
            return min(1.0, max(0.0, v))
        }
        set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassIntensity) }
    }
    /// Fade in/out animation when toggling glass on/off
    var namelessLiquidGlassFadeAnimation: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassFadeAnimation, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassFadeAnimation) } }
    var namelessLiquidGlassReactions: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassReactions, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassReactions) } }
    var namelessLiquidGlassStickers: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassStickers, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassStickers) } }
    var namelessLiquidGlassCalls: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassCalls, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassCalls) } }
    var namelessLiquidGlassMedia: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassMedia, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassMedia) } }
    var namelessLiquidGlassChatList: Bool { get { storage.namelessBool(NamelessSettingsKey.liquidGlassChatList, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.liquidGlassChatList) } }
    var namelessVideoBackgroundEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.videoBackgroundEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.videoBackgroundEnabled) } }
    var namelessVideoBackgroundPath: String { get { storage.namelessString(NamelessSettingsKey.videoBackgroundPath) } set { storage.set(newValue, forKey: NamelessSettingsKey.videoBackgroundPath) } }
    // MARK: Appearance
    var squareAvatars: Bool { get { storage.namelessBool(NamelessSettingsKey.squareAvatars) } set { storage.set(newValue, forKey: NamelessSettingsKey.squareAvatars) } }
    var newChatList: Bool { get { storage.namelessBool(NamelessSettingsKey.newChatList) } set { storage.set(newValue, forKey: NamelessSettingsKey.newChatList) } }
    var newChatHeader: Bool { get { storage.namelessBool(NamelessSettingsKey.newChatHeader) } set { storage.set(newValue, forKey: NamelessSettingsKey.newChatHeader) } }
    // Default OFF — official liquid glass, not custom blur
    var blurInsteadGlass: Bool {
        get { storage.namelessBool(NamelessSettingsKey.blurInsteadGlass, default: false) }
        set {
            storage.set(newValue, forKey: NamelessSettingsKey.blurInsteadGlass)
            if newValue {
                storage.set(false, forKey: NamelessSettingsKey.liquidGlassEnabled)
            }
        }
    }
    var oledMode: Bool { get { storage.namelessBool(NamelessSettingsKey.oledMode) } set { storage.set(newValue, forKey: NamelessSettingsKey.oledMode) } }
    var customSettingsIcons: Bool { get { storage.namelessBool(NamelessSettingsKey.customSettingsIcons) } set { storage.set(newValue, forKey: NamelessSettingsKey.customSettingsIcons) } }
    var telegramAppIcons: Bool { get { storage.namelessBool(NamelessSettingsKey.telegramAppIcons, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.telegramAppIcons) } }
    var swipeChatOptions: Bool { get { storage.namelessBool(NamelessSettingsKey.swipeChatOptions) } set { storage.set(newValue, forKey: NamelessSettingsKey.swipeChatOptions) } }
    var hideVoiceRecordButton: Bool { get { storage.namelessBool(NamelessSettingsKey.hideVoiceRecordButton) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideVoiceRecordButton) } }
    var foldersAtBottom: Bool { get { storage.namelessBool(NamelessSettingsKey.foldersAtBottom) } set { storage.set(newValue, forKey: NamelessSettingsKey.foldersAtBottom) } }
    var ramUsageUnderClock: Bool { get { storage.namelessBool(NamelessSettingsKey.ramUsageUnderClock) } set { storage.set(newValue, forKey: NamelessSettingsKey.ramUsageUnderClock) } }
    var chatListTitle: Bool { get { storage.namelessBool(NamelessSettingsKey.chatListTitle) } set { storage.set(newValue, forKey: NamelessSettingsKey.chatListTitle) } }
    var premiumStatusInHeader: Bool { get { storage.namelessBool(NamelessSettingsKey.premiumStatusInHeader, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.premiumStatusInHeader) } }
    var searchButtonInChatList: Bool { get { storage.namelessBool(NamelessSettingsKey.searchButtonInChatList) } set { storage.set(newValue, forKey: NamelessSettingsKey.searchButtonInChatList) } }
    var unlimitedPinnedChats: Bool { get { storage.namelessBool(NamelessSettingsKey.unlimitedPinnedChats, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.unlimitedPinnedChats) } }
    var newAccountSwitcher: Bool { get { storage.namelessBool(NamelessSettingsKey.newAccountSwitcher) } set { storage.set(newValue, forKey: NamelessSettingsKey.newAccountSwitcher) } }
    var profileColorBackground: Bool { get { storage.namelessBool(NamelessSettingsKey.profileColorBackground, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.profileColorBackground) } }
    // Megram: off by default. The frost layer only exists on the profile
    // header, so a blurred avatar there next to a crisp one in the gallery
    // read as a defect rather than a feature.
    var profileAvatarBlur: Bool { get { storage.namelessBool(NamelessSettingsKey.profileAvatarBlur) } set { storage.set(newValue, forKey: NamelessSettingsKey.profileAvatarBlur) } }
    var profileAvatarBlurMinimal: Bool { get { storage.namelessBool(NamelessSettingsKey.profileAvatarBlurMinimal, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.profileAvatarBlurMinimal) } }
    var profileAvatarBlurTinting: Bool { get { storage.namelessBool(NamelessSettingsKey.profileAvatarBlurTinting) } set { storage.set(newValue, forKey: NamelessSettingsKey.profileAvatarBlurTinting) } }
    var musicAlbumBlur: Bool { get { storage.namelessBool(NamelessSettingsKey.musicAlbumBlur, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.musicAlbumBlur) } }
    var musicPlayerEffect: Bool { get { storage.namelessBool(NamelessSettingsKey.musicPlayerEffect, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.musicPlayerEffect) } }
    var messageOutline: Bool { get { storage.namelessBool(NamelessSettingsKey.messageOutline) } set { storage.set(newValue, forKey: NamelessSettingsKey.messageOutline) } }
    /// Fully transparent bubbles. Mutually exclusive with `messageSemiTransparent` — both set the
    /// same alpha, and with both on the semi-transparent value was silently ignored.
    var messageTransparent: Bool {
        get { storage.namelessBool(NamelessSettingsKey.messageTransparent) }
        set {
            storage.set(newValue, forKey: NamelessSettingsKey.messageTransparent)
            if newValue {
                storage.set(false, forKey: NamelessSettingsKey.messageSemiTransparent)
            }
        }
    }
    var messageSemiTransparent: Bool {
        get { storage.namelessBool(NamelessSettingsKey.messageSemiTransparent) }
        set {
            storage.set(newValue, forKey: NamelessSettingsKey.messageSemiTransparent)
            if newValue {
                storage.set(false, forKey: NamelessSettingsKey.messageTransparent)
            }
        }
    }
    var messageBlurEffect: Bool { get { storage.namelessBool(NamelessSettingsKey.messageBlurEffect) } set { storage.set(newValue, forKey: NamelessSettingsKey.messageBlurEffect) } }
    var particleEffectEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.particleEffectEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.particleEffectEnabled) } }
    var particleEffectSpeed: Double { get { storage.namelessDouble(NamelessSettingsKey.particleEffectSpeed, default: 0.5) } set { storage.set(newValue, forKey: NamelessSettingsKey.particleEffectSpeed) } }
    var particleEffectDensity: Double { get { storage.namelessDouble(NamelessSettingsKey.particleEffectDensity, default: 0.5) } set { storage.set(newValue, forKey: NamelessSettingsKey.particleEffectDensity) } }
    /// Opacity 0…100 of deleted bubbles (default 37 ≈ photo look)
    var deletedMessageOpacity: Int32 { get { storage.namelessInt32(NamelessSettingsKey.deletedMessageOpacity, default: 37) } set { storage.set(Int(newValue), forKey: NamelessSettingsKey.deletedMessageOpacity) } }
    /// HEX color for trash mark on deleted messages (default red #FF3B30)
    var deletedTrashColorHex: String {
        get {
            let v = storage.namelessString(NamelessSettingsKey.deletedTrashColorHex, default: "#FF3B30")
            return v.isEmpty ? "#FF3B30" : v
        }
        set { storage.set(newValue, forKey: NamelessSettingsKey.deletedTrashColorHex) }
    }
    /// Auto-format outgoing text. Values: none, bold, italic, underline, strikethrough, code, pre, blockquote, spoiler
    var autoFormatMode: String {
        get { storage.namelessString(NamelessSettingsKey.autoFormatMode, default: "none") }
        set { storage.set(newValue, forKey: NamelessSettingsKey.autoFormatMode) }
    }

    /// Parsed UIColor from deletedTrashColorHex
    func deletedTrashUIColor() -> UIColor {
        return NamelessColorParse.color(fromHex: deletedTrashColorHex) ?? UIColor(red: 1, green: 0.23, blue: 0.19, alpha: 1)
    }

    /// Compatibility alias (public extension members are already public)
    typealias AutoFormatMode = NamelessAutoFormatMode
    static func color(fromHex hex: String) -> UIColor? {
        NamelessColorParse.color(fromHex: hex)
    }
    var showOriginalEdited: Bool { get { storage.namelessBool(NamelessSettingsKey.showOriginalEdited, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.showOriginalEdited) } }
    var truncateLongMessages: Bool { get { storage.namelessBool(NamelessSettingsKey.truncateLongMessages, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.truncateLongMessages) } }
    var saveChatHistory: Bool { get { storage.namelessBool(NamelessSettingsKey.saveChatHistory, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.saveChatHistory) } }
    var saveOnceMedia: Bool { get { storage.namelessBool(NamelessSettingsKey.saveOnceMedia, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.saveOnceMedia) } }
    var noAutoNextVoice: Bool { get { storage.namelessBool(NamelessSettingsKey.noAutoNextVoice, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.noAutoNextVoice) } }
    var semiTransparentWhenMentioned: Bool { get { storage.namelessBool(NamelessSettingsKey.semiTransparentWhenMentioned, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.semiTransparentWhenMentioned) } }
    var charCounterInput: Bool { get { storage.namelessBool(NamelessSettingsKey.charCounterInput, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.charCounterInput) } }
    var charCounterInChat: Bool { get { storage.namelessBool(NamelessSettingsKey.charCounterInChat, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.charCounterInChat) } }
    var hideMyDeleted: Bool { get { storage.namelessBool(NamelessSettingsKey.hideMyDeleted, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideMyDeleted) } }
    var hideMyEdited: Bool { get { storage.namelessBool(NamelessSettingsKey.hideMyEdited, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideMyEdited) } }
    var hideBotEdited: Bool { get { storage.namelessBool(NamelessSettingsKey.hideBotEdited, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideBotEdited) } }
    var hideBotDeleted: Bool { get { storage.namelessBool(NamelessSettingsKey.hideBotDeleted, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideBotDeleted) } }
    var doubleTapToEdit: Bool { get { storage.namelessBool(NamelessSettingsKey.doubleTapToEdit) } set { storage.set(newValue, forKey: NamelessSettingsKey.doubleTapToEdit) } }
    // MARK: Camera
    var cameraDefaultBack: Bool { get { storage.namelessBool(NamelessSettingsKey.defaultCameraBack) } set { storage.set(newValue, forKey: NamelessSettingsKey.defaultCameraBack) } }
    var cameraUseDeviceMicrophone: Bool { get { storage.namelessBool(NamelessSettingsKey.useDeviceMicrophone) } set { storage.set(newValue, forKey: NamelessSettingsKey.useDeviceMicrophone) } }
    // MARK: Mutually exclusive switches
    //
    // Two switches that answer the same question must never both be on. The rule lives in the
    // setters rather than in the settings screen, so it holds no matter who writes the value —
    // a settings row, a plugin, an import, a migration. Each branch only clears when the new
    // value is `true`, so the cascade terminates after one step and can never recurse.

    /// Send camera photos in HD. Mutually exclusive with `cameraAlwaysSendHD`.
    var cameraSendHDPhoto: Bool {
        get { storage.namelessBool(NamelessSettingsKey.sendHDPhoto) }
        set {
            storage.set(newValue, forKey: NamelessSettingsKey.sendHDPhoto)
            if newValue {
                storage.set(false, forKey: NamelessSettingsKey.alwaysSendHD)
            }
        }
    }
    var cameraJpegQuality: Int32 { get { storage.namelessInt32(NamelessSettingsKey.jpegQuality, default: 70) } set { storage.set(Int(newValue), forKey: NamelessSettingsKey.jpegQuality) } }
    var cameraRememberLast: Bool { get { storage.namelessBool(NamelessSettingsKey.rememberLastCamera) } set { storage.set(newValue, forKey: NamelessSettingsKey.rememberLastCamera) } }
    var cameraStaticZoom: Bool { get { storage.namelessBool(NamelessSettingsKey.staticZoomRecording) } set { storage.set(newValue, forKey: NamelessSettingsKey.staticZoomRecording) } }
    /// Always send in HD, regardless of source. Mutually exclusive with `cameraSendHDPhoto`.
    var cameraAlwaysSendHD: Bool {
        get { storage.namelessBool(NamelessSettingsKey.alwaysSendHD, default: true) }
        set {
            storage.set(newValue, forKey: NamelessSettingsKey.alwaysSendHD)
            if newValue {
                storage.set(false, forKey: NamelessSettingsKey.sendHDPhoto)
            }
        }
    }
    // MARK: Info
    var showIdAndDC: Bool { get { storage.namelessBool(NamelessSettingsKey.showIdAndDC, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.showIdAndDC) } }
    var showSeconds: Bool { get { storage.namelessBool(NamelessSettingsKey.showSeconds, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.showSeconds) } }
    var showFullViews: Bool { get { storage.namelessBool(NamelessSettingsKey.showFullViews, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.showFullViews) } }
    var hidePhoneNumber: Bool { get { storage.namelessBool(NamelessSettingsKey.hidePhoneNumber) } set { storage.set(newValue, forKey: NamelessSettingsKey.hidePhoneNumber) } }
    var showIfMutualContacts: Bool { get { storage.namelessBool(NamelessSettingsKey.showIfMutualContacts, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.showIfMutualContacts) } }
    var showRegistrationDate: Bool { get { storage.namelessBool(NamelessSettingsKey.showRegistrationDate, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.showRegistrationDate) } }
    // MARK: Additional
    var vibrationEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.vibrationEnabled, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.vibrationEnabled) } }
    var speedBoostEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.speedBoostEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.speedBoostEnabled) } }
    // MARK: Privacy/Confidentiality
    var bypassProtectedContent: Bool { get { storage.namelessBool(NamelessSettingsKey.bypassProtectedContent, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.bypassProtectedContent) } }
    var removeSpoilersEverywhere: Bool { get { storage.namelessBool(NamelessSettingsKey.removeSpoilersEverywhere, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.removeSpoilersEverywhere) } }
    var antiScamEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.antiScamEnabled, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.antiScamEnabled) } }
    var warnBeforeCall: Bool { get { storage.namelessBool(NamelessSettingsKey.warnBeforeCall, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.warnBeforeCall) } }
    // MARK: Notifications
    var localNotificationsEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.localNotificationsEnabled, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.localNotificationsEnabled) } }

    // MARK: Megram profile
    var profileTrackCard: Bool { get { storage.namelessBool(NamelessSettingsKey.profileTrackCard, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.profileTrackCard) } }
    var profileIdChips: Bool { get { storage.namelessBool(NamelessSettingsKey.profileIdChips, default: true) } set { storage.set(newValue, forKey: NamelessSettingsKey.profileIdChips) } }
    var hideProfileEmojiStatus: Bool { get { storage.namelessBool(NamelessSettingsKey.hideProfileEmojiStatus) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideProfileEmojiStatus) } }
    var hideProfileColorRow: Bool { get { storage.namelessBool(NamelessSettingsKey.hideProfileColorRow) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideProfileColorRow) } }
    var hideProfilePhotoRow: Bool { get { storage.namelessBool(NamelessSettingsKey.hideProfilePhotoRow) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideProfilePhotoRow) } }
    var hideProfileIdRow: Bool { get { storage.namelessBool(NamelessSettingsKey.hideProfileIdRow) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideProfileIdRow) } }

    // MARK: Megram peer menu
    var hideMenuWallpaper: Bool { get { storage.namelessBool(NamelessSettingsKey.hideMenuWallpaper) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideMenuWallpaper) } }
    var hideMenuSecretChat: Bool { get { storage.namelessBool(NamelessSettingsKey.hideMenuSecretChat) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideMenuSecretChat) } }
    var hideMenuSendContact: Bool { get { storage.namelessBool(NamelessSettingsKey.hideMenuSendContact) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideMenuSendContact) } }
    var hideMenuAutoDelete: Bool { get { storage.namelessBool(NamelessSettingsKey.hideMenuAutoDelete) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideMenuAutoDelete) } }
    var hideMenuCopyProtection: Bool { get { storage.namelessBool(NamelessSettingsKey.hideMenuCopyProtection) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideMenuCopyProtection) } }
    var hideMenuClearHistory: Bool { get { storage.namelessBool(NamelessSettingsKey.hideMenuClearHistory) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideMenuClearHistory) } }
    var hideMenuBlock: Bool { get { storage.namelessBool(NamelessSettingsKey.hideMenuBlock) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideMenuBlock) } }

    // MARK: Megram tabs and profile extras
    var deviceModelSpoofEnabled: Bool { get { storage.namelessBool(NamelessSettingsKey.deviceModelSpoofEnabled) } set { storage.set(newValue, forKey: NamelessSettingsKey.deviceModelSpoofEnabled) } }
    var hideProfileGiftsTab: Bool { get { storage.namelessBool(NamelessSettingsKey.hideProfileGiftsTab) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideProfileGiftsTab) } }
    var hideContactsTab: Bool { get { storage.namelessBool(NamelessSettingsKey.hideContactsTab) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideContactsTab) } }
    var hideCallsTab: Bool { get { storage.namelessBool(NamelessSettingsKey.hideCallsTab) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideCallsTab) } }
    /// Percent of the standard tab bar metric, 50...150. Stored as Int32 so it
    /// can drive the same percentage slider the other size settings use.
    var tabBarHeightScale: Int32 {
        get {
            let value = storage.namelessInt32(NamelessSettingsKey.tabBarHeightScale, default: 100)
            return value == 0 ? 100 : value
        }
        set { storage.set(newValue, forKey: NamelessSettingsKey.tabBarHeightScale) }
    }
    var tabBarWidthScale: Int32 {
        get {
            let value = storage.namelessInt32(NamelessSettingsKey.tabBarWidthScale, default: 100)
            return value == 0 ? 100 : value
        }
        set { storage.set(newValue, forKey: NamelessSettingsKey.tabBarWidthScale) }
    }

    // MARK: Megram settings sections
    var hideSettingsSavedMessages: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsSavedMessages) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsSavedMessages) } }
    var hideSettingsDevices: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsDevices) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsDevices) } }
    var hideSettingsChatFolders: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsChatFolders) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsChatFolders) } }
    var hideSettingsPowerSaving: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsPowerSaving) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsPowerSaving) } }
    var hideSettingsLanguage: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsLanguage) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsLanguage) } }
    var hideSettingsNotifications: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsNotifications) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsNotifications) } }
    var hideSettingsPrivacy: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsPrivacy) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsPrivacy) } }
    var hideSettingsDataAndStorage: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsDataAndStorage) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsDataAndStorage) } }
    var hideSettingsAppearance: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsAppearance) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsAppearance) } }
    var hideSettingsProxy: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsProxy) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsProxy) } }
    var hideSettingsMyProfile: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsMyProfile) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsMyProfile) } }
    var hideSettingsRecentCalls: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsRecentCalls) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsRecentCalls) } }
    var hideSettingsPremium: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsPremium) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsPremium) } }
    var hideSettingsStars: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsStars) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsStars) } }
    var hideSettingsBusiness: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsBusiness) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsBusiness) } }
    var hideSettingsSupport: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsSupport) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsSupport) } }
    var hideSettingsFaq: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsFaq) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsFaq) } }
    var hideSettingsTips: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsTips) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsTips) } }
    var hideSettingsSendGift: Bool { get { storage.namelessBool(NamelessSettingsKey.hideSettingsSendGift) } set { storage.set(newValue, forKey: NamelessSettingsKey.hideSettingsSendGift) } }

    func updateGatedFeatures(_ features: [(key: String, deeplinkPath: String)]) {
        storage.set(features.map(\.key), forKey: NamelessSettingsKey.gatedFeatureKeys)
    }

    func isFeatureVisible(_ key: String) -> Bool {
        let gated = Set(storage.namelessStringArray(NamelessSettingsKey.gatedFeatureKeys))
        if !gated.contains(key) {
            return true
        }
        return Set(self.unlockedFeatureKeys).contains(key)
    }

    func isAccountNotificationMuted(recordId: Int64) -> Bool {
        return Set(storage.namelessStringArray(NamelessSettingsKey.mutedAccountIds)).contains(String(recordId))
    }

    func setAccountNotificationMuted(recordId: Int64, muted: Bool) {
        var ids = Set(storage.namelessStringArray(NamelessSettingsKey.mutedAccountIds))
        if muted {
            ids.insert(String(recordId))
        } else {
            ids.remove(String(recordId))
        }
        storage.set(Array(ids).sorted(), forKey: NamelessSettingsKey.mutedAccountIds)
    }

    /// Replace the horizontal '+' attachment tab bar with a compact vertical rounded
    /// glass sheet floating above the input. Off by default so the classic behaviour
    /// stays the safety net; toggling this hides the tab bar and shows a stacked
    /// list of the same buttons.
    var namelessCompactAttachmentSheet: Bool {
        get { storage.namelessBool(NamelessSettingsKey.namelessCompactAttachmentSheet) }
        set { storage.set(newValue, forKey: NamelessSettingsKey.namelessCompactAttachmentSheet) }
    }
}
