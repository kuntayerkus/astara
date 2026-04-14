import Foundation

struct Transit: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let planet: PlanetKey
    let fromSign: ZodiacSign
    let toSign: ZodiacSign
    let date: String
    let description: String

    init(
        id: UUID = UUID(),
        planet: PlanetKey,
        fromSign: ZodiacSign,
        toSign: ZodiacSign,
        date: String,
        description: String
    ) {
        self.id = id
        self.planet = planet
        self.fromSign = fromSign
        self.toSign = toSign
        self.date = date
        self.description = description
    }
}
