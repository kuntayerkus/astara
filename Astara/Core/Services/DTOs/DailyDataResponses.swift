import Foundation

// MARK: - Daily Horoscope Response
// Handles /data/daily-horoscope.json — array of horoscopes for all 12 signs

struct DailyHoroscopeResponse: Decodable {
    let date: String
    let horoscopes: [DailyHoroscopeEntry]

    struct DailyHoroscopeEntry: Decodable {
        let sign: String
        let text: String
        let energy: Int
        let theme: String
        let tip: String
        let luckyNumber: Int?
        let luckyColor: String?

        private enum CodingKeys: String, CodingKey {
            case sign, text, energy, theme, tip
            case luckyNumber = "lucky_number"
            case luckyColor = "lucky_color"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            sign = try container.decode(String.self, forKey: .sign)
            text = try container.decode(String.self, forKey: .text)
            energy = try container.decode(Int.self, forKey: .energy)
            theme = try container.decode(String.self, forKey: .theme)
            tip = try container.decode(String.self, forKey: .tip)
            luckyNumber = try? container.decode(Int.self, forKey: .luckyNumber)
            luckyColor = try? container.decode(String.self, forKey: .luckyColor)
        }
    }

    func toDailyHoroscopes() -> [DailyHoroscope] {
        horoscopes.compactMap { entry in
            guard let zodiacSign = ZodiacSign(rawValue: entry.sign) else { return nil }
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
// Handles /data/daily-energy.json — element energy percentages

struct DailyEnergyResponse: Decodable {
    let fire: Int
    let earth: Int
    let air: Int
    let water: Int

    func toElementEnergy() -> [Element: Int] {
        [
            .fire: fire,
            .earth: earth,
            .air: air,
            .water: water
        ]
    }
}

// MARK: - Planet Positions Response
// Handles /data/planet-positions.json — current sky positions

struct PlanetPositionsResponse: Decodable {
    let date: String
    let planets: [VPSPlanet]

    func toPlanets() -> [Planet] {
        planets.compactMap { $0.toPlanet() }
    }
}

// MARK: - Retro Calendar Response
// Handles /data/retro-calendar.json — retrograde schedule

struct RetroCalendarResponse: Decodable {
    let retrogrades: [RetroCalendarEntry]

    struct RetroCalendarEntry: Decodable {
        let planet: String
        let startDate: String
        let endDate: String
        let preRetroDate: String?
        let postRetroDate: String?

        private enum CodingKeys: String, CodingKey {
            case planet
            case startDate = "start_date"
            case endDate = "end_date"
            case preRetroDate = "pre_retro_date"
            case postRetroDate = "post_retro_date"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            planet = try container.decode(String.self, forKey: .planet)
            startDate = try container.decode(String.self, forKey: .startDate)
            endDate = try container.decode(String.self, forKey: .endDate)
            preRetroDate = try? container.decode(String.self, forKey: .preRetroDate)
            postRetroDate = try? container.decode(String.self, forKey: .postRetroDate)
        }
    }

    func toRetrogrades() -> [Retrograde] {
        retrogrades.compactMap { entry in
            guard let planetKey = PlanetKey(rawValue: entry.planet) else { return nil }
            return Retrograde(
                planet: planetKey,
                startDate: entry.startDate,
                endDate: entry.endDate,
                preRetroDate: entry.preRetroDate,
                postRetroDate: entry.postRetroDate
            )
        }
    }
}
