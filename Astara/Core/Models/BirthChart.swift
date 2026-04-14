import Foundation

struct BirthChart: Codable, Equatable, Sendable {
    let planets: [Planet]
    let houses: [House]
    let aspects: [Aspect]

    // MARK: - Convenience Accessors

    var sunSign: ZodiacSign? {
        planets.first(where: { $0.key == .gunes })?.sign
    }

    var moonSign: ZodiacSign? {
        planets.first(where: { $0.key == .ay })?.sign
    }

    var risingSign: ZodiacSign? {
        planets.first(where: { $0.key == .yukselen })?.sign
    }

    var ascendant: Planet? {
        planets.first(where: { $0.key == .yukselen })
    }

    var midheaven: Planet? {
        planets.first(where: { $0.key == .mc })
    }

    func planet(for key: PlanetKey) -> Planet? {
        planets.first(where: { $0.key == key })
    }

    func house(_ number: Int) -> House? {
        houses.first(where: { $0.number == number })
    }

    func aspects(for planet: PlanetKey) -> [Aspect] {
        aspects.filter { $0.planet1 == planet || $0.planet2 == planet }
    }

    // MARK: - House for Planet

    func houseForPlanet(_ key: PlanetKey) -> Int? {
        guard let planet = planet(for: key),
              !houses.isEmpty else { return nil }

        let sorted = houses.sorted { $0.degree < $1.degree }
        for i in 0..<sorted.count {
            let current = sorted[i]
            let next = sorted[(i + 1) % sorted.count]

            let start = current.degree
            let end = next.degree

            if end > start {
                if planet.degree >= start && planet.degree < end {
                    return current.number
                }
            } else {
                // Wraps around 360°
                if planet.degree >= start || planet.degree < end {
                    return current.number
                }
            }
        }
        return sorted.last?.number
    }

    // MARK: - Element Distribution

    var elementDistribution: [Element: Int] {
        var counts: [Element: Int] = [.fire: 0, .earth: 0, .air: 0, .water: 0]
        for planet in planets where planet.key.isPlanet {
            counts[planet.sign.element, default: 0] += 1
        }
        return counts
    }
}

// MARK: - Mock Data

extension BirthChart {
    static let preview = BirthChart(
        planets: [
            Planet(key: .gunes, sign: .pisces, degree: 354.5, minute: 30, isRetrograde: false),
            Planet(key: .ay, sign: .leo, degree: 152.2, minute: 12, isRetrograde: false),
            Planet(key: .yukselen, sign: .cancer, degree: 98.7, minute: 42, isRetrograde: false),
            Planet(key: .merkur, sign: .pisces, degree: 340.1, minute: 6, isRetrograde: false),
            Planet(key: .venus, sign: .aquarius, degree: 318.4, minute: 24, isRetrograde: false),
            Planet(key: .mars, sign: .leo, degree: 148.9, minute: 54, isRetrograde: false),
            Planet(key: .jupiter, sign: .sagittarius, degree: 260.3, minute: 18, isRetrograde: false),
            Planet(key: .saturn, sign: .pisces, degree: 348.7, minute: 42, isRetrograde: true),
            Planet(key: .uranus, sign: .aquarius, degree: 305.1, minute: 6, isRetrograde: false),
            Planet(key: .neptun, sign: .capricorn, degree: 295.8, minute: 48, isRetrograde: false),
            Planet(key: .pluton, sign: .scorpio, degree: 239.2, minute: 12, isRetrograde: false),
        ],
        houses: (1...12).map { number in
            let degree = Double(number - 1) * 30 + 98.7
            let signIndex = Int(degree / 30) % 12
            return House(number: number, sign: ZodiacSign.allCases[signIndex], degree: degree.truncatingRemainder(dividingBy: 360))
        },
        aspects: [
            Aspect(planet1: .gunes, planet2: .saturn, type: .conjunction, orb: 2.3),
            Aspect(planet1: .ay, planet2: .mars, type: .conjunction, orb: 3.3),
            Aspect(planet1: .gunes, planet2: .neptun, type: .sextile, orb: 1.5),
        ]
    )
}
