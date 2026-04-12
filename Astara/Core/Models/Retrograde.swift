import Foundation

struct Retrograde: Codable, Equatable, Identifiable {
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
        formatter.dateFormat = "yyyy-MM-dd"
        guard let start = formatter.date(from: startDate),
              let end = formatter.date(from: endDate) else { return false }
        let now = Date()
        return now >= start && now <= end
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
