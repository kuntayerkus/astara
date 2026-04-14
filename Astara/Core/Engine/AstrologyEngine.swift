import Foundation
import ComposableArchitecture

/// Validates chart data and provides local fallback calculations.
/// Fallback math is aligned with the legacy web engine's low-precision formulas.
@DependencyClient
struct AstrologyEngineClient {
    /// Validate that a BirthChart from VPS has sensible data
    var validateChart: @Sendable (BirthChart) -> Bool = { _ in false }
    /// Get zodiac sign for a given ecliptic degree (0-360)
    var signForDegree: @Sendable (Double) -> ZodiacSign = { _ in .aries }
    /// Build a local fallback chart when remote calculation is unavailable
    var fallbackChart: @Sendable (_ date: String, _ time: String, _ lat: Double, _ lng: Double, _ timezone: String) throws -> BirthChart
}

extension AstrologyEngineClient: DependencyKey {
    static let liveValue = AstrologyEngineClient(
        validateChart: { chart in
            // Sanity checks:
            // 1. Must have at least the classical planets (Sun through Saturn)
            guard chart.planets.count >= 7 else { return false }
            // 2. All degrees must be 0-360
            for planet in chart.planets {
                guard (0...360).contains(planet.degree) else { return false }
            }
            // 3. Must have 12 houses
            guard chart.houses.count == 12 else { return false }
            return true
        },
        signForDegree: { degree in
            let normalized = normalize360(degree)
            let index = Int(normalized / 30)
            return ZodiacSign.allCases[min(index, 11)]
        },
        fallbackChart: { date, time, lat, lng, timezone in
            let dateParts = date.split(separator: "-").compactMap { Int($0) }
            let timeParts = time.split(separator: ":").compactMap { Double($0) }
            guard dateParts.count == 3, timeParts.count == 2 else {
                throw APIError.invalidURL
            }

            let year = dateParts[0]
            let month = dateParts[1]
            let day = dateParts[2]
            let hour = timeParts[0]
            let minute = timeParts[1]

            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            components.hour = Int(hour)
            components.minute = Int(minute)
            components.second = 0
            components.calendar = Calendar(identifier: .gregorian)
            let resolvedTimeZone = TimeZone(identifier: timezone) ?? TimeZone(secondsFromGMT: 0) ?? .current
            components.timeZone = resolvedTimeZone
            let localDate = components.date ?? Date()
            let tzOffsetHours = Double(resolvedTimeZone.secondsFromGMT(for: localDate)) / 3600.0

            let d = dayNumber(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                timezoneOffsetHours: tzOffsetHours
            )

            let sunData = sunLongitude(dayNumber: d)
            let moonLongitude = moonLongitude(dayNumber: d, sun: sunData)
            let ascendant = ascendantLongitude(dayNumber: d, latitude: lat, longitude: lng)
            let midheaven = midheavenLongitude(dayNumber: d, longitude: lng)

            // Mean longitudes for remaining planets (legacy-compatible low-precision fallback)
            let mercury = normalize360(252.25084 + 4.09233445 * d)
            let venus = normalize360(181.97973 + 1.60213034 * d)
            let mars = normalize360(355.433 + 0.52402068 * d)
            let jupiter = normalize360(34.351 + 0.0830853 * d)
            let saturn = normalize360(50.077 + 0.03344414 * d)
            let uranus = normalize360(314.055 + 0.01172834 * d)
            let neptune = normalize360(304.348 + 0.00598103 * d)
            let pluto = normalize360(238.929 + 0.003964 * d)
            let vertex = normalize360(ascendant + 180)

            let longitudes: [PlanetKey: Double] = [
                .gunes: sunData.longitude,
                .ay: moonLongitude,
                .merkur: mercury,
                .venus: venus,
                .mars: mars,
                .jupiter: jupiter,
                .saturn: saturn,
                .uranus: uranus,
                .neptun: neptune,
                .pluton: pluto,
                .yukselen: ascendant,
                .mc: midheaven,
                .vertex: vertex
            ]

            let planets = PlanetKey.allCases.compactMap { key -> Planet? in
                guard let degree = longitudes[key] else { return nil }
                let sign = signForLongitude(degree)
                let inSign = degree.truncatingRemainder(dividingBy: 30)
                let minute = Int((inSign - floor(inSign)) * 60)
                return Planet(
                    key: key,
                    sign: sign,
                    degree: degree,
                    minute: minute,
                    isRetrograde: false
                )
            }

            let houses: [House] = (0..<12).map { index in
                let degree = normalize360(ascendant + Double(index) * 30)
                return House(number: index + 1, sign: signForLongitude(degree), degree: degree)
            }

            var aspects: [Aspect] = []
            let mainPlanets = planets.filter { $0.key.isPlanet }
            for i in 0..<mainPlanets.count {
                for j in (i + 1)..<mainPlanets.count {
                    let p1 = mainPlanets[i]
                    let p2 = mainPlanets[j]
                    if let type = AspectCalculator.detectAspect(p1.degree, p2.degree) {
                        let deviation = abs(AspectCalculator.angularDistance(p1.degree, p2.degree) - type.exactAngle)
                        aspects.append(Aspect(planet1: p1.key, planet2: p2.key, type: type, orb: deviation))
                    }
                }
            }

            return BirthChart(planets: planets, houses: houses, aspects: aspects)
        }
    )

    static let previewValue = AstrologyEngineClient(
        validateChart: { _ in true },
        signForDegree: { _ in .aries },
        fallbackChart: { _, _, _, _, _ in .preview }
    )
}

extension DependencyValues {
    var astrologyEngine: AstrologyEngineClient {
        get { self[AstrologyEngineClient.self] }
        set { self[AstrologyEngineClient.self] = newValue }
    }
}

private func normalize360(_ degree: Double) -> Double {
    let normalized = degree.truncatingRemainder(dividingBy: 360)
    return normalized < 0 ? normalized + 360 : normalized
}

private func sind(_ degree: Double) -> Double {
    sin(degree * .pi / 180)
}

private func cosd(_ degree: Double) -> Double {
    cos(degree * .pi / 180)
}

private func atan2d(_ y: Double, _ x: Double) -> Double {
    atan2(y, x) * 180 / .pi
}

private func dayNumber(
    year: Int,
    month: Int,
    day: Int,
    hour: Double,
    minute: Double,
    timezoneOffsetHours: Double
) -> Double {
    let dateComponent = Double(day) + (hour - timezoneOffsetHours) / 24 + minute / 1440
    let y = Double(year)
    let m = Double(month)
    return 367 * y
        - floor(7 * (y + floor((m + 9) / 12)) / 4)
        + floor(275 * m / 9)
        + dateComponent
        - 730530
}

private func signForLongitude(_ degree: Double) -> ZodiacSign {
    let normalized = normalize360(degree)
    let index = Int(normalized / 30)
    return ZodiacSign.allCases[min(index, 11)]
}

private struct SunData {
    let longitude: Double
    let meanAnomaly: Double
}

private func sunLongitude(dayNumber d: Double) -> SunData {
    let w = normalize360(282.9404 + 0.0000470935 * d)
    let e = 0.016709 - 0.000000001151 * d
    let m = normalize360(356.047 + 0.9856002585 * d)
    let eAnomaly = m + e * (180 / Double.pi) * sind(m) * (1 + e * cosd(m))
    let x = cosd(eAnomaly) - e
    let y = sind(eAnomaly) * sqrt(1 - e * e)
    let v = atan2d(y, x)
    return SunData(longitude: normalize360(v + w), meanAnomaly: m)
}

private func moonLongitude(dayNumber d: Double, sun: SunData) -> Double {
    let n = normalize360(125.1228 - 0.0529538083 * d)
    let i = 5.1454
    let w = normalize360(318.0634 + 0.1643573223 * d)
    let a = 60.2666
    let e = 0.0549
    let m = normalize360(115.3654 + 13.0649929509 * d)

    let eAnomaly = m + e * (180 / Double.pi) * sind(m) * (1 + e * cosd(m))
    let x = a * (cosd(eAnomaly) - e)
    let y = a * (sind(eAnomaly) * sqrt(1 - e * e))
    let v = atan2d(y, x)
    let lon = normalize360(v + w)

    let xEcl = cosd(n) * cosd(lon) - sind(n) * sind(lon) * cosd(i)
    let yEcl = sind(n) * cosd(lon) + cosd(n) * sind(lon) * cosd(i)
    var moon = normalize360(atan2d(yEcl, xEcl) + n)

    let dAngle = moon - sun.longitude
    let f = moon - n

    moon += -1.274 * sind(m - 2 * dAngle)
    moon += 0.658 * sind(2 * dAngle)
    moon += -0.186 * sind(sun.meanAnomaly)
    moon += -0.059 * sind(2 * m - 2 * dAngle)
    moon += -0.057 * sind(m - 2 * dAngle + sun.meanAnomaly)
    moon += 0.053 * sind(m + 2 * dAngle)
    moon += 0.046 * sind(2 * dAngle - sun.meanAnomaly)
    moon += 0.041 * sind(m - dAngle)
    moon += -0.035 * sind(dAngle)
    moon += -0.031 * sind(m + sun.meanAnomaly)
    moon += -0.015 * sind(2 * f - 2 * dAngle)
    moon += 0.011 * sind(m - 4 * dAngle)

    return normalize360(moon)
}

private func ascendantLongitude(dayNumber d: Double, latitude: Double, longitude: Double) -> Double {
    let gmst0 = 280.46061837 + 0.98564736629 * d
    let lst = normalize360(gmst0 + longitude)
    let obliquity = 23.4393 - 0.0000003563 * d
    let latRad = latitude * .pi / 180
    let x = -cosd(lst)
    let y = sind(lst) * cosd(obliquity) + tan(latRad) * sind(obliquity)
    return normalize360(atan2d(x, y))
}

private func midheavenLongitude(dayNumber d: Double, longitude: Double) -> Double {
    let gmst0 = 280.46061837 + 0.98564736629 * d
    let lst = normalize360(gmst0 + longitude)
    let obliquity = 23.4393 - 0.0000003563 * d
    let x = cosd(lst)
    let y = sind(lst) * cosd(obliquity)
    return normalize360(atan2d(y, x))
}
