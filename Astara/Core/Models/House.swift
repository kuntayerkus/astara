import Foundation

struct House: Codable, Equatable, Identifiable, Sendable {
    var id: Int { number }

    let number: Int
    let sign: ZodiacSign
    let degree: Double

    var formattedDegree: String {
        let signDegree = Int(degree) % 30
        let minute = Int((degree - Double(Int(degree))) * 60)
        return "\(signDegree)°\(minute)'"
    }

    var romanNumeral: String {
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
        guard number >= 1, number <= 12 else { return "\(number)" }
        return numerals[number - 1]
    }

    var meaning: String {
        switch number {
        case 1: String(localized: "house_1_meaning")
        case 2: String(localized: "house_2_meaning")
        case 3: String(localized: "house_3_meaning")
        case 4: String(localized: "house_4_meaning")
        case 5: String(localized: "house_5_meaning")
        case 6: String(localized: "house_6_meaning")
        case 7: String(localized: "house_7_meaning")
        case 8: String(localized: "house_8_meaning")
        case 9: String(localized: "house_9_meaning")
        case 10: String(localized: "house_10_meaning")
        case 11: String(localized: "house_11_meaning")
        case 12: String(localized: "house_12_meaning")
        default: ""
        }
    }
}
