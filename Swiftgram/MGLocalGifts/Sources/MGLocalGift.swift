import Foundation

// MARK: - Local gifts
//
// A parallel, entirely client-side gift economy. Nothing here ever reaches Telegram: no API call,
// no message, no attribute. A local gift exists only in this installation's storage and is drawn
// only by this client.
//
// That is the whole point and also the honest limitation — the recipient cannot see a local gift,
// even if they run this client, because there is no server carrying it. What the flow reproduces
// is the *experience* of buying and sending: a catalog, a price in local stars, a balance that
// goes down, a confirmation, and a permanent record in the profile.

/// One entry in the catalog — the thing you can buy.
public struct MGLocalGiftKind: Codable, Equatable {
    public let id: String
    public let title: String
    public let emoji: String
    public let price: Int64
    /// Two hex colours for the card's backdrop gradient, as `0xRRGGBB`.
    public let backdropTop: UInt32
    public let backdropBottom: UInt32
    /// Editions minted, mirroring how collectible gifts are described. Nil for a plain gift.
    public let supply: Int?

    public init(
        id: String,
        title: String,
        emoji: String,
        price: Int64,
        backdropTop: UInt32,
        backdropBottom: UInt32,
        supply: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.price = price
        self.backdropTop = backdropTop
        self.backdropBottom = backdropBottom
        self.supply = supply
    }

    public var isCollectible: Bool {
        return self.supply != nil
    }
}

/// A gift that was actually bought — an instance of a kind, with who/when/what-was-said.
public struct MGLocalGift: Codable, Equatable {
    public let id: String
    public let kindId: String
    /// Peer the gift was sent to, as the numeric part of the peer id. Empty means "kept for self".
    public let recipientPeerId: String
    public let recipientName: String
    public let message: String
    public let date: Double
    /// Serial within the kind's supply, assigned at purchase. Nil for non-collectibles.
    public let serial: Int?

    public init(
        id: String = UUID().uuidString,
        kindId: String,
        recipientPeerId: String,
        recipientName: String,
        message: String,
        date: Double = Date().timeIntervalSince1970,
        serial: Int?
    ) {
        self.id = id
        self.kindId = kindId
        self.recipientPeerId = recipientPeerId
        self.recipientName = recipientName
        self.message = message
        self.date = date
        self.serial = serial
    }
}

public enum MGLocalGiftCatalog {
    /// The catalog is a constant: local gifts are a client feature, so there is nothing to fetch
    /// and nothing that can go stale. Prices are in local stars.
    public static let all: [MGLocalGiftKind] = [
        MGLocalGiftKind(id: "heart", title: "Сердце", emoji: "❤️", price: 15, backdropTop: 0xFF6B8B, backdropBottom: 0xFF3B5C),
        MGLocalGiftKind(id: "teddy", title: "Мишка", emoji: "🧸", price: 15, backdropTop: 0xE8A87C, backdropBottom: 0xC7773F),
        MGLocalGiftKind(id: "rose", title: "Роза", emoji: "🌹", price: 25, backdropTop: 0xF06A8A, backdropBottom: 0xB3315A),
        MGLocalGiftKind(id: "cake", title: "Торт", emoji: "🎂", price: 50, backdropTop: 0xF3C969, backdropBottom: 0xD99B2B),
        MGLocalGiftKind(id: "bouquet", title: "Букет", emoji: "💐", price: 50, backdropTop: 0x9BD3A0, backdropBottom: 0x4FA35C),
        MGLocalGiftKind(id: "rocket", title: "Ракета", emoji: "🚀", price: 50, backdropTop: 0x7FA8F0, backdropBottom: 0x3B60C4),
        MGLocalGiftKind(id: "champagne", title: "Шампанское", emoji: "🍾", price: 50, backdropTop: 0xD7C08A, backdropBottom: 0xA3853F),
        MGLocalGiftKind(id: "trophy", title: "Кубок", emoji: "🏆", price: 100, backdropTop: 0xF2CE6B, backdropBottom: 0xC79A22),
        MGLocalGiftKind(id: "ring", title: "Кольцо", emoji: "💍", price: 100, backdropTop: 0xBFC7D6, backdropBottom: 0x7C8798),
        MGLocalGiftKind(id: "diamond", title: "Бриллиант", emoji: "💎", price: 200, backdropTop: 0x8FD8E8, backdropBottom: 0x2F93B5, supply: 5677),
        MGLocalGiftKind(id: "crown", title: "Корона", emoji: "👑", price: 500, backdropTop: 0xF5D06A, backdropBottom: 0xB8880F, supply: 2000),
        MGLocalGiftKind(id: "bag", title: "Сумочка", emoji: "👜", price: 500, backdropTop: 0xEE83B7, backdropBottom: 0xB93E7E, supply: 5677),
        MGLocalGiftKind(id: "guitar", title: "Гитара", emoji: "🎸", price: 750, backdropTop: 0xD08A6A, backdropBottom: 0x8B4A2B, supply: 1500),
        MGLocalGiftKind(id: "star", title: "Звезда", emoji: "⭐️", price: 1000, backdropTop: 0xFFD966, backdropBottom: 0xD6A100, supply: 1000)
    ]

    public static func kind(id: String) -> MGLocalGiftKind? {
        return self.all.first { $0.id == id }
    }
}
