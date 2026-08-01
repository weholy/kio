import Foundation
import Postbox
import TelegramApi
import SwiftSignalKit
import SGSimpleSettings

public enum SavedStickerResult {
    case generic
    case limitExceeded(Int32, Int32)
}

func _internal_toggleStickerSaved(postbox: Postbox, network: Network, accountPeerId: PeerId, file: TelegramMediaFile, saved: Bool) -> Signal<SavedStickerResult, AddSavedStickerError> {
    if saved {
        return postbox.transaction { transaction -> Signal<SavedStickerResult, AddSavedStickerError> in
            let isPremium = transaction.getPeer(accountPeerId)?.isPremium ?? false
            let items = transaction.getOrderedListItems(collectionId: Namespaces.OrderedItemList.CloudSavedStickers)
            
            let appConfiguration = transaction.getPreferencesEntry(key: PreferencesKeys.appConfiguration)?.get(AppConfiguration.self) ?? .defaultValue
            let limitsConfiguration = UserLimitsConfiguration(appConfiguration: appConfiguration, isPremium: false)
            let premiumLimitsConfiguration = UserLimitsConfiguration(appConfiguration: appConfiguration, isPremium: true)
            
            // MARK: Nameless — "Безлимитные избранные стикеры": skip the local cap so the
            // "limit reached" sheet never appears. The server still trims the list on its side.
            let ignoreFavedLimit = SGSimpleSettings.shared.unlimitedFavoriteStickers

            let result: SavedStickerResult
            if ignoreFavedLimit {
                result = .generic
            } else if isPremium && items.count >= premiumLimitsConfiguration.maxFavedStickerCount {
                result = .limitExceeded(premiumLimitsConfiguration.maxFavedStickerCount, premiumLimitsConfiguration.maxFavedStickerCount)
            } else if !isPremium && items.count >= limitsConfiguration.maxFavedStickerCount {
                result = .limitExceeded(limitsConfiguration.maxFavedStickerCount, premiumLimitsConfiguration.maxFavedStickerCount)
            } else {
                result = .generic
            }

            let effectiveLimit = ignoreFavedLimit
                ? Int(Int32.max)
                : Int(isPremium ? premiumLimitsConfiguration.maxFavedStickerCount : limitsConfiguration.maxFavedStickerCount)
            return addSavedSticker(postbox: postbox, network: network, file: file, limit: effectiveLimit)
            |> map { _ -> SavedStickerResult in
                return .generic
            }
            |> filter { _ in
                return false
            }
            |> then(
                .single(result)
            )
        }
        |> castError(AddSavedStickerError.self)
        |> switchToLatest
    } else {
        return removeSavedSticker(postbox: postbox, mediaId: file.fileId)
        |> map { _ -> SavedStickerResult in
            return .generic
        }
        |> castError(AddSavedStickerError.self)
    }
}
