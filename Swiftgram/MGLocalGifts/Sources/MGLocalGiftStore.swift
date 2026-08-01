import Foundation
import SGSimpleSettings

public extension Notification.Name {
    /// Posted whenever a local gift is bought or removed, so open profile panes refresh.
    static let megramLocalGiftsDidChange = Notification.Name("megram.localGifts.didChange")
}

public enum MGLocalGiftPurchaseError: LocalizedError {
    case walletDisabled
    case insufficientBalance(price: Int64, balance: Int64)
    case unknownKind

    public var errorDescription: String? {
        switch self {
        case .walletDisabled:
            return "Локальные звёзды выключены. Включите их в настройках nameless."
        case let .insufficientBalance(price, balance):
            return "Не хватает звёзд: нужно \(price), на балансе \(balance)."
        case .unknownKind:
            return "Такого подарка нет в каталоге."
        }
    }
}

/// Owns the purchased-gift ledger. Persistence only — no UI, no Telegram.
public final class MGLocalGiftStore {
    public static let shared = MGLocalGiftStore()

    private let defaults = UserDefaults.standard
    private let storageKey = "megram.localGifts.v1"

    private init() {}

    // MARK: - Reading

    /// Every gift ever bought, newest first.
    public func allGifts() -> [MGLocalGift] {
        guard let raw = self.defaults.string(forKey: self.storageKey),
              let data = raw.data(using: .utf8),
              let gifts = try? JSONDecoder().decode([MGLocalGift].self, from: data)
        else {
            return []
        }
        return gifts.sorted { $0.date > $1.date }
    }

    /// Gifts shown on a given profile. A gift sent to someone appears on their profile; a gift
    /// kept for yourself appears on your own.
    public func gifts(forPeerId peerId: String) -> [MGLocalGift] {
        return self.allGifts().filter { $0.recipientPeerId == peerId }
    }

    public func count(forPeerId peerId: String) -> Int {
        return self.gifts(forPeerId: peerId).count
    }

    // MARK: - Writing

    /// Buys one gift and records it. Deducts from the local wallet first, so a purchase that
    /// cannot be paid for leaves no trace — the same order a real payment would use.
    @discardableResult
    public func purchase(
        kindId: String,
        recipientPeerId: String,
        recipientName: String,
        message: String
    ) throws -> MGLocalGift {
        guard let kind = MGLocalGiftCatalog.kind(id: kindId) else {
            throw MGLocalGiftPurchaseError.unknownKind
        }
        let settings = SGSimpleSettings.shared
        guard settings.localStarsEnabled else {
            throw MGLocalGiftPurchaseError.walletDisabled
        }
        guard settings.spendLocalStars(kind.price) else {
            throw MGLocalGiftPurchaseError.insufficientBalance(price: kind.price, balance: settings.localStarsBalance)
        }

        // Serials run per kind in purchase order and stop at the declared supply, so a collectible
        // reads the way the real ones do ("1 of 5677") instead of inventing a number.
        var serial: Int?
        if let supply = kind.supply {
            let minted = self.allGifts().filter { $0.kindId == kindId }.count
            serial = min(supply, minted + 1)
        }

        let gift = MGLocalGift(
            kindId: kindId,
            recipientPeerId: recipientPeerId,
            recipientName: recipientName,
            message: message,
            serial: serial
        )

        var gifts = self.allGifts()
        gifts.insert(gift, at: 0)
        self.save(gifts)
        return gift
    }

    public func remove(giftId: String) {
        self.save(self.allGifts().filter { $0.id != giftId })
    }

    public func removeAll() {
        self.save([])
    }

    private func save(_ gifts: [MGLocalGift]) {
        guard let data = try? JSONEncoder().encode(gifts),
              let raw = String(data: data, encoding: .utf8)
        else {
            return
        }
        self.defaults.set(raw, forKey: self.storageKey)
        NotificationCenter.default.post(name: .megramLocalGiftsDidChange, object: nil)
    }
}
