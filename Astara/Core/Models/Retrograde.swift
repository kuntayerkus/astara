import Foundation

struct Retrograde: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let planet: PlanetKey
    let startDate: String
    let endDate: String
    let preRetroDate: String?
    let postRetroDate: String?

    init(
        id: UUID = UUID(),
        planet: PlanetKey,
        startDate: String,
        endDate: String,
        preRetroDate: String? = nil,
        postRetroDate: String? = nil
    ) {
        self.id = id
        self.planet = planet
        self.startDate = startDate
        self.endDate = endDate
        self.preRetroDate = preRetroDate
        self.postRetroDate = postRetroDate
    }

    var isActive: Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
        guard let start = formatter.date(from: startDate),
              let end = formatter.date(from: endDate) else { return false }
        let now = Date()
        // Include full end day by comparing against start of next day
        let calendar = Calendar.current
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: end) ?? end
        return now >= start && now < endOfDay
    }
}

// MARK: - Preview Data

extension Retrograde {
    static let preview = Retrograde(
        planet: .merkur,
        startDate: "2026-04-01",
        endDate: "2026-04-25",
        preRetroDate: "2026-03-18",
        postRetroDate: "2026-05-10"
    )
}
