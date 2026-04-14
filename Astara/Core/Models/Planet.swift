import Foundation

// MARK: - Planet Key
// CRITICAL: No Turkish characters — these match VPS API expectations exactly

enum PlanetKey: String, Codable, CaseIterable, Identifiable, Sendable {
    case gunes, ay, merkur, venus, mars
    case jupiter, saturn, uranus, neptun, pluton
    case yukselen, mc, vertex

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .gunes: "\u{2609}"     // ☉
        case .ay: "\u{263D}"        // ☽
        case .merkur: "\u{263F}"    // ☿
        case .venus: "\u{2640}"     // ♀
        case .mars: "\u{2642}"      // ♂
        case .jupiter: "\u{2643}"   // ♃
        case .saturn: "\u{2644}"    // ♄
        case .uranus: "\u{2645}"    // ♅
        case .neptun: "\u{2646}"    // ♆
        case .pluton: "\u{2647}"    // ♇
        case .yukselen: "ASC"
        case .mc: "MC"
        case .vertex: "Vtx"
        }
    }

    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }

    var turkishName: String {
        switch self {
        case .gunes: "Güneş"
        case .ay: "Ay"
        case .merkur: "Merkür"
        case .venus: "Venüs"
        case .mars: "Mars"
        case .jupiter: "Jüpiter"
        case .saturn: "Satürn"
        case .uranus: "Uranüs"
        case .neptun: "Neptün"
        case .pluton: "Plüton"
        case .yukselen: "Yükselen"
        case .mc: "Gökyüzü Ortası"
        case .vertex: "Vertex"
        }
    }

    var isPlanet: Bool {
        switch self {
        case .yukselen, .mc, .vertex: false
        default: true
        }
    }
}

// MARK: - Planet Position

struct Planet: Codable, Equatable, Identifiable, Sendable {
    var id: String { key.rawValue }

    let key: PlanetKey
    let sign: ZodiacSign
    let degree: Double
    let minute: Int
    let isRetrograde: Bool

    var formattedDegree: String {
        let signDegree = Int(degree) % 30
        return "\(signDegree)°\(minute)'"
    }

    var fullDescription: String {
        let retro = isRetrograde ? " ℞" : ""
        return "\(key.turkishName) \(sign.turkishName) \(formattedDegree)\(retro)"
    }
}
