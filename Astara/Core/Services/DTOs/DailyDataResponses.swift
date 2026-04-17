import Foundation

// MARK: - Daily Horoscope Response
// Handles /data/daily-horoscope.json

struct DailyHoroscopeResponse: Decodable {
    let date: String
    let signs: [String: DailyHoroscopeEntry]

    struct DailyHoroscopeEntry: Decodable {
        let text: String
        let energy: Int
        let theme: String
        let tip: String
        let luckyNumber: Int?
        let luckyColor: String?
        
        private enum CodingKeys: String, CodingKey {
            case text, energy, theme, tip
            case lucky = "lucky"
            case luckyColor
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            text = try container.decode(String.self, forKey: .text)
            energy = try container.decode(Int.self, forKey: .energy)
            theme = try container.decode(String.self, forKey: .theme)
            tip = try container.decode(String.self, forKey: .tip)
            
            if let stringValue = try? container.decode(String.self, forKey: .lucky) {
                luckyNumber = Int(stringValue)
            } else {
                luckyNumber = try? container.decode(Int.self, forKey: .lucky)
            }
            
            luckyColor = try? container.decode(String.self, forKey: .luckyColor)
        }
    }

    func toDailyHoroscopes() -> [DailyHoroscope] {
        signs.compactMap { (key, entry) in
            guard let zodiacSign = ZodiacSign(rawValue: key.lowercased()) else { return nil }
            return DailyHoroscope(
                sign: zodiacSign,
                date: date,
                text: entry.text,
                energy: entry.energy,
                theme: entry.theme,
                tip: entry.tip,
                luckyNumber: entry.luckyNumber,
                luckyColor: entry.luckyColor
            )
        }
    }
}

// MARK: - Daily Energy Response
// Handles /data/daily-energy.json

struct DailyEnergyResponse: Decodable {
    let date: String
    let elements: [String: ElementEntry]
    
    struct ElementEntry: Decodable {
        // `level` can be 0-100 (Int) or 0.0-1.0 (Double) depending on API version.
        let rawLevel: Double

        private enum CodingKeys: String, CodingKey { case level }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // Try Int first, then Double (handles both "level": 75 and "level": 0.75)
            if let intVal = try? container.decode(Int.self, forKey: .level) {
                rawLevel = Double(intVal)
            } else {
                rawLevel = (try? container.decode(Double.self, forKey: .level)) ?? 0
            }
        }

        /// Normalised 0-100 integer value.
        var level: Int {
            rawLevel <= 1.0 && rawLevel > 0 ? Int(rawLevel * 100) : Int(rawLevel)
        }
    }

    func toElementEnergy() -> [Element: Int] {
        let raw: [Element: Int] = [
            .fire: elements["fire"]?.level ?? 0,
            .earth: elements["earth"]?.level ?? 0,
            .air: elements["air"]?.level ?? 0,
            .water: elements["water"]?.level ?? 0
        ]
        let total = raw.values.reduce(0, +)
        // Normalize so values are proportional and the display ring (0-100%) is meaningful.
        guard total > 100 else { return raw }
        return raw.mapValues { Int(Double($0) * 100 / Double(total)) }
    }
}

// MARK: - Planet Positions Response
// Handles /data/planet-positions.json

struct PlanetPositionsResponse: Decodable {
    let date: String
    let planets: [PlanetPositionEntry]

    struct PlanetPositionEntry: Decodable {
        let name: String
        let signEn: String
        let degree: Double
        let retrograde: Bool?

        func toPlanet() -> Planet? {
            // Map Turkish names or english signs to PlanetKey
            let keyStr: String
            switch name.lowercased() {
            case "güneş": keyStr = "gunes"
            case "ay": keyStr = "ay"
            case "merkür": keyStr = "merkur"
            case "venüs": keyStr = "venus"
            case "mars": keyStr = "mars"
            case "jüpiter": keyStr = "jupiter"
            case "satürn": keyStr = "saturn"
            case "uranüs": keyStr = "uranus"
            case "neptün": keyStr = "neptun"
            case "plüton": keyStr = "pluton"
            default: return nil
            }
            
            guard let planetKey = PlanetKey(rawValue: keyStr),
                  let zodiacSign = ZodiacSign(rawValue: signEn.lowercased()) else { return nil }
            return Planet(key: planetKey, sign: zodiacSign, degree: degree,
                          minute: 0, isRetrograde: retrograde ?? false)
        }
    }

    func toPlanets() -> [Planet] {
        planets.compactMap { $0.toPlanet() }
    }
}

// MARK: - Retro Calendar Response
// Handles /data/retro-calendar.json

struct RetroCalendarResponse: Decodable {
    let retrogrades: [RetroCalendarEntry]

    struct RetroCalendarEntry: Decodable {
        let planet: String
        let start: String
        let end: String

        func toRetrograde() -> Retrograde? {
            let keyStr: String
            switch planet.lowercased() {
            case "güneş", "gunes": keyStr = "gunes"
            case "ay": keyStr = "ay"
            case "merkür", "merkur": keyStr = "merkur"
            case "venüs", "venus": keyStr = "venus"
            case "mars": keyStr = "mars"
            case "jüpiter", "jupiter": keyStr = "jupiter"
            case "satürn", "saturn": keyStr = "saturn"
            case "uranüs", "uranus": keyStr = "uranus"
            case "neptün", "neptun": keyStr = "neptun"
            case "plüton", "pluton": keyStr = "pluton"
            default: return nil
            }
            
            guard let planetKey = PlanetKey(rawValue: keyStr) else { return nil }
            return Retrograde(
                planet: planetKey,
                startDate: start,
                endDate: end,
                preRetroDate: nil,
                postRetroDate: nil
            )
        }
    }

    func toRetrogrades() -> [Retrograde] {
        retrogrades.compactMap { $0.toRetrograde() }
    }
}
