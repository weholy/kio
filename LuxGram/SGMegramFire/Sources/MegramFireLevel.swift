import Foundation
import UIKit

// MARK: - Palette

/// Colours that drive both the flame artwork and the surrounding screen for a
/// given level. Every level owns its own background so the whole screen shifts
/// hue as the streak grows.
public struct MegramFirePalette {
    public let flameOuter: [UIColor]
    public let flameCore: [UIColor]
    public let glow: UIColor
    public let backgroundTop: UIColor
    public let backgroundBottom: UIColor
    public let accent: UIColor
    public let cardFill: UIColor
    public let cardStroke: UIColor

    public init(
        flameOuter: [UIColor],
        flameCore: [UIColor],
        glow: UIColor,
        backgroundTop: UIColor,
        backgroundBottom: UIColor,
        accent: UIColor,
        cardFill: UIColor,
        cardStroke: UIColor
    ) {
        self.flameOuter = flameOuter
        self.flameCore = flameCore
        self.glow = glow
        self.backgroundTop = backgroundTop
        self.backgroundBottom = backgroundBottom
        self.accent = accent
        self.cardFill = cardFill
        self.cardStroke = cardStroke
    }
}

private func megramColor(_ rgb: UInt32, _ alpha: CGFloat = 1.0) -> UIColor {
    return UIColor(
        red: CGFloat((rgb >> 16) & 0xff) / 255.0,
        green: CGFloat((rgb >> 8) & 0xff) / 255.0,
        blue: CGFloat(rgb & 0xff) / 255.0,
        alpha: alpha
    )
}

// MARK: - Levels

/// Three flame tiers. The ladder is data-driven so more levels can be appended
/// without touching the screen or the badge.
public enum MegramFireLevel: Int, CaseIterable {
    case ember = 0
    case azure = 1
    case inferno = 2

    /// First day of each level. Day 0-9 ember, 10-29 azure, 30+ inferno.
    public static let dayThresholds: [Int] = [0, 10, 30]

    public static func level(forDays days: Int) -> MegramFireLevel {
        var result: MegramFireLevel = .ember
        for level in MegramFireLevel.allCases where days >= level.startDay {
            result = level
        }
        return result
    }

    public var startDay: Int {
        return MegramFireLevel.dayThresholds[self.rawValue]
    }

    /// Day count that unlocks the next level, or nil when this is the top tier.
    public var nextThreshold: Int? {
        let next = self.rawValue + 1
        if next < MegramFireLevel.dayThresholds.count {
            return MegramFireLevel.dayThresholds[next]
        }
        return nil
    }

    public var titleRu: String {
        switch self {
        case .ember: return "Огонёк"
        case .azure: return "Синее пламя"
        case .inferno: return "Инферно"
        }
    }

    public var subtitleRu: String {
        switch self {
        case .ember: return "Начальный уровень"
        case .azure: return "Второй уровень"
        case .inferno: return "Третий уровень"
        }
    }

    public var palette: MegramFirePalette {
        switch self {
        // The background stays near black; the level colour arrives as a large,
        // saturated radial glow behind the flame, with light translucent cards
        // floating on top of it.
        case .ember:
            return MegramFirePalette(
                flameOuter: [megramColor(0xff8a1f), megramColor(0xff5a0a), megramColor(0xdd2c05)],
                flameCore: [megramColor(0xfff3b0), megramColor(0xffd954), megramColor(0xffab21)],
                glow: megramColor(0xff7a10),
                backgroundTop: megramColor(0x0a0603),
                backgroundBottom: megramColor(0x000000),
                accent: megramColor(0xffa432),
                cardFill: megramColor(0xffffff, 0.14),
                cardStroke: megramColor(0xffffff, 0.10)
            )
        case .azure:
            return MegramFirePalette(
                flameOuter: [megramColor(0x2f5bff), megramColor(0x5b2ef0), megramColor(0xb02bea)],
                flameCore: [megramColor(0xd8f6ff), megramColor(0x7de6ff), megramColor(0x8f7dff)],
                glow: megramColor(0x3552ff),
                backgroundTop: megramColor(0x03040f),
                backgroundBottom: megramColor(0x000000),
                accent: megramColor(0x8aa2ff),
                cardFill: megramColor(0xffffff, 0.14),
                cardStroke: megramColor(0xffffff, 0.10)
            )
        case .inferno:
            return MegramFirePalette(
                flameOuter: [megramColor(0xff5b12), megramColor(0xb81406), megramColor(0x35090a)],
                flameCore: [megramColor(0xfff0b8), megramColor(0xffb43c), megramColor(0xff6a12)],
                glow: megramColor(0xd41d06),
                backgroundTop: megramColor(0x0a0201),
                backgroundBottom: megramColor(0x000000),
                accent: megramColor(0xff7a3a),
                cardFill: megramColor(0xffffff, 0.14),
                cardStroke: megramColor(0xffffff, 0.10)
            )
        }
    }
}
