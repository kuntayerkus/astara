import Foundation

// MARK: - VPS /api/harita Actual Response
//
// API returns:
// {
//   "gezegenler": { "gunes": 354.4578, "ay": 154.8185, ... },  // ecliptic longitude 0–360°
//   "evler": [132.2041, 153.252, ...],                         // 12 house cusp longitudes
//   "ev_sistemi": "Placidus",
//   "asteroidler": {}
// }

struct VPSChartResponse: Decodable {
    let gezegenler: [String: Double]
    let evler: [Double]

    func toBirthChart() -> BirthChart {
        let planets = buildPlanets()
        let houses = buildHouses()
        let aspects = buildAspects(from: planets)
        return BirthChart(planets: planets, houses: houses, aspects: aspects)
    }

    // MARK: - Planets

    private func buildPlanets() -> [Planet] {
        PlanetKey.allCases.compactMap { key in
            guard let longitude = gezegenler[key.rawValue] else { return nil }
            return planet(key: key, longitude: longitude)
        }
    }

    private func planet(key: PlanetKey, longitude: Double) -> Planet {
        let l = normalise(longitude)
        let signIndex = Int(l / 30) % 12
        let sign = ZodiacSign.allCases[signIndex]
        let degWithinSign = l.truncatingRemainder(dividingBy: 30)
        let minute = Int(degWithinSign.truncatingRemainder(dividingBy: 1) * 60)
        return Planet(key: key, sign: sign, degree: l, minute: minute, isRetrograde: false)
    }

    // MARK: - Houses

    private func buildHouses() -> [House] {
        guard evler.count == 12 else { return [] }
        return evler.enumerated().map { index, longitude in
            let l = normalise(longitude)
            let signIndex = Int(l / 30) % 12
            let sign = ZodiacSign.allCases[signIndex]
            return House(number: index + 1, sign: sign, degree: l)
        }
    }

    // MARK: - Aspects (calculated locally — VPS does not return them)

    private func buildAspects(from planets: [Planet]) -> [Aspect] {
        var aspects: [Aspect] = []
        let mainPlanets = planets.filter { $0.key.isPlanet }
        for i in 0..<mainPlanets.count {
            for j in (i + 1)..<mainPlanets.count {
                let p1 = mainPlanets[i]
                let p2 = mainPlanets[j]
                if let type = AspectCalculator.detectAspect(p1.degree, p2.degree) {
                    let orb = AspectCalculator.angularDistance(p1.degree, p2.degree)
                    aspects.append(Aspect(planet1: p1.key, planet2: p2.key, type: type, orb: orb))
                }
            }
        }
        return aspects
    }

    // MARK: - Helpers

    private func normalise(_ longitude: Double) -> Double {
        let l = longitude.truncatingRemainder(dividingBy: 360)
        return l < 0 ? l + 360 : l
    }
}
