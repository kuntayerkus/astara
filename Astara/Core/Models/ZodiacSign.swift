import Foundation

enum ZodiacSign: String, Codable, CaseIterable, Identifiable, Sendable {
    case aries, taurus, gemini, cancer, leo, virgo
    case libra, scorpio, sagittarius, capricorn, aquarius, pisces

    var id: String { rawValue }

    // MARK: - Display

    var symbol: String {
        switch self {
        case .aries: "\u{2648}"
        case .taurus: "\u{2649}"
        case .gemini: "\u{264A}"
        case .cancer: "\u{264B}"
        case .leo: "\u{264C}"
        case .virgo: "\u{264D}"
        case .libra: "\u{264E}"
        case .scorpio: "\u{264F}"
        case .sagittarius: "\u{2650}"
        case .capricorn: "\u{2651}"
        case .aquarius: "\u{2652}"
        case .pisces: "\u{2653}"
        }
    }

    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }

    var turkishName: String {
        switch self {
        case .aries: "Koç"
        case .taurus: "Boğa"
        case .gemini: "İkizler"
        case .cancer: "Yengeç"
        case .leo: "Aslan"
        case .virgo: "Başak"
        case .libra: "Terazi"
        case .scorpio: "Akrep"
        case .sagittarius: "Yay"
        case .capricorn: "Oğlak"
        case .aquarius: "Kova"
        case .pisces: "Balık"
        }
    }

    // MARK: - Astrology Properties

    var element: Element {
        switch self {
        case .aries, .leo, .sagittarius: .fire
        case .taurus, .virgo, .capricorn: .earth
        case .gemini, .libra, .aquarius: .air
        case .cancer, .scorpio, .pisces: .water
        }
    }

    var modality: Modality {
        switch self {
        case .aries, .cancer, .libra, .capricorn: .cardinal
        case .taurus, .leo, .scorpio, .aquarius: .fixed
        case .gemini, .virgo, .sagittarius, .pisces: .mutable
        }
    }

    var rulingPlanet: PlanetKey {
        switch self {
        case .aries: .mars
        case .taurus: .venus
        case .gemini: .merkur
        case .cancer: .ay
        case .leo: .gunes
        case .virgo: .merkur
        case .libra: .venus
        case .scorpio: .pluton
        case .sagittarius: .jupiter
        case .capricorn: .saturn
        case .aquarius: .uranus
        case .pisces: .neptun
        }
    }

    var degreeRange: ClosedRange<Double> {
        let index = Double(ZodiacSign.allCases.firstIndex(of: self)!)
        return (index * 30)...(index * 30 + 30)
    }
}

// MARK: - Element

enum Element: String, Codable, CaseIterable, Sendable {
    case fire, earth, air, water

    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

// MARK: - Modality

enum Modality: String, Codable, CaseIterable, Sendable {
    case cardinal, fixed, mutable

    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}
