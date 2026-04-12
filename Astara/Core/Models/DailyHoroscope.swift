import Foundation

struct DailyHoroscope: Codable, Equatable, Identifiable {
    var id: String { "\(sign.rawValue)-\(date)" }

    let sign: ZodiacSign
    let date: String
    let text: String
    let energy: Int // 0-100
    let theme: String
    let tip: String
    let luckyNumber: Int?
    let luckyColor: String?
}

// MARK: - Preview Data

extension DailyHoroscope {
    static let preview = DailyHoroscope(
        sign: .pisces,
        date: "2026-04-12",
        text: "Bugün duygusal enerjin yüksek. Sezgilerine güven, ama büyük kararları yarına bırak.",
        energy: 72,
        theme: "Sezgi",
        tip: "Yalnız vakit geçirmek sana iyi gelecek.",
        luckyNumber: 7,
        luckyColor: "Mor"
    )
}
