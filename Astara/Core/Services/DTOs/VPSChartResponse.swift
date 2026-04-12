import Foundation

// MARK: - VPS /api/harita Response DTOs

struct VPSChartResponse: Decodable {
    let planets: [VPSPlanet]
    let houses: [VPSHouse]
    let aspects: [VPSAspect]?

    // MARK: - Mapping to Domain Model

    func toBirthChart() -> BirthChart {
        let mappedPlanets = planets.compactMap { $0.toPlanet() }
        let mappedHouses = houses.compactMap { $0.toHouse() }
        let mappedAspects = (aspects ?? []).compactMap { $0.toAspect() }

        return BirthChart(
            planets: mappedPlanets,
            houses: mappedHouses,
            aspects: mappedAspects
        )
    }
}

// MARK: - VPS Planet

struct VPSPlanet: Decodable {
    let key: String
    let sign: String
    let degree: Double
    let minute: Int
    let isRetrograde: Bool

    private enum CodingKeys: String, CodingKey {
        case key
        case sign
        case degree
        case minute
        case isRetrograde = "is_retrograde"
    }

    // Fallback: try both snake_case and camelCase
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        sign = try container.decode(String.self, forKey: .sign)
        degree = try container.decode(Double.self, forKey: .degree)
        minute = try container.decodeIfPresent(Int.self, forKey: .minute) ?? 0
        // Try snake_case first, then camelCase fallback
        if let retro = try? container.decode(Bool.self, forKey: .isRetrograde) {
            isRetrograde = retro
        } else {
            // Fallback: try "retrograde" key
            let fallbackContainer = try decoder.container(keyedBy: FallbackKeys.self)
            isRetrograde = (try? fallbackContainer.decode(Bool.self, forKey: .retrograde)) ?? false
        }
    }

    private enum FallbackKeys: String, CodingKey {
        case retrograde
    }

    func toPlanet() -> Planet? {
        guard let planetKey = PlanetKey(rawValue: key),
              let zodiacSign = ZodiacSign(rawValue: sign) else {
            return nil
        }
        return Planet(
            key: planetKey,
            sign: zodiacSign,
            degree: degree,
            minute: minute,
            isRetrograde: isRetrograde
        )
    }
}

// MARK: - VPS House

struct VPSHouse: Decodable {
    let number: Int
    let sign: String
    let degree: Double

    func toHouse() -> House? {
        guard let zodiacSign = ZodiacSign(rawValue: sign) else {
            return nil
        }
        return House(
            number: number,
            sign: zodiacSign,
            degree: degree
        )
    }
}

// MARK: - VPS Aspect

struct VPSAspect: Decodable {
    let planet1: String
    let planet2: String
    let type: String
    let orb: Double
    let isApplying: Bool?

    private enum CodingKeys: String, CodingKey {
        case planet1
        case planet2
        case type
        case orb
        case isApplying = "is_applying"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        planet1 = try container.decode(String.self, forKey: .planet1)
        planet2 = try container.decode(String.self, forKey: .planet2)
        type = try container.decode(String.self, forKey: .type)
        orb = try container.decode(Double.self, forKey: .orb)
        isApplying = try? container.decode(Bool.self, forKey: .isApplying)
    }

    func toAspect() -> Aspect? {
        guard let key1 = PlanetKey(rawValue: planet1),
              let key2 = PlanetKey(rawValue: planet2),
              let aspectType = AspectType(rawValue: type) else {
            return nil
        }
        return Aspect(
            planet1: key1,
            planet2: key2,
            type: aspectType,
            orb: orb,
            isApplying: isApplying ?? false
        )
    }
}
