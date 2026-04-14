import Foundation
import ComposableArchitecture

@DependencyClient
struct WeeklyGuidanceService {
    var buildWeekTransits: @Sendable (_ sign: ZodiacSign, _ retrogrades: [Retrograde]) async -> [Transit] = { _, _ in [] }
    var ritualPrompt: @Sendable (_ retrogrades: [Retrograde]) async -> String = { _ in "" }
    var timeTravelInsight: @Sendable (_ date: Date, _ sign: ZodiacSign) async -> TimeTravelInsight = { date, _ in
        TimeTravelInsight(date: date, title: "", summary: "", action: "")
    }
    var scoreForDay: @Sendable (_ horoscope: DailyHoroscope?, _ completedTasks: Set<String>, _ mood: Int?) async -> AstaraScore = { _, _, _ in .zero }
}

extension WeeklyGuidanceService: DependencyKey {
    static let liveValue = WeeklyGuidanceService(
        buildWeekTransits: { sign, retrogrades in
            let calendar = Calendar(identifier: .gregorian)
            let activePlanets = Set(retrogrades.filter(\.isActive).map(\.planet))
            let signIndex = ZodiacSign.allCases.firstIndex(of: sign) ?? 0
            return (0..<7).map { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                let planet = planetForOffset(offset, activePlanets: activePlanets)
                let target = ZodiacSign.allCases[(signIndex + offset + 1) % ZodiacSign.allCases.count]
                return Transit(
                    planet: planet,
                    fromSign: sign,
                    toSign: target,
                    date: AstaraDateFormatters.apiDate.string(from: date),
                    description: dayDescription(for: offset, sign: sign, target: target, planet: planet)
                )
            }
        },
        ritualPrompt: { retrogrades in
            if let retro = retrogrades.first(where: \.isActive) {
                return "\(retro.planet.turkishName) retrosu aktif. 10 dakika sessizlik + 3 satir journaling yap."
            }
            return "Bugun niyet ritueli: 3 nefes al, 1 niyet yaz, 1 kucuk adim sec."
        },
        timeTravelInsight: { date, sign in
            let days = Calendar(identifier: .gregorian).dateComponents([.day], from: Date(), to: date).day ?? 0
            if days < 0 {
                return TimeTravelInsight(
                    date: date,
                    title: "Gecmis etkisi",
                    summary: "\(sign.turkishName) enerjinde kapanis temasi. O donemde sinirlar ve duzen vurgusu yuksek.",
                    action: "Neyi ogrendigini 3 madde yaz."
                )
            }
            return TimeTravelInsight(
                date: date,
                title: "Gelecek sinyali",
                summary: "\(sign.turkishName) icin hizlanan bir donem. Iletisim ve karar alma baskin.",
                action: "Onceligini simdiden netlestir, tek hedef sec."
            )
        },
        scoreForDay: { horoscope, completedTasks, mood in
            let baseEnergy = horoscope?.energy ?? 50
            let taskBoost = min(completedTasks.count * 8, 24)
            let moodBoost = ((mood ?? 3) - 3) * 6
            let energy = clamp(baseEnergy + taskBoost + moodBoost)
            let love = clamp(55 + moodBoost + (completedTasks.contains("share_card") ? 8 : 0))
            let work = clamp(50 + taskBoost + (completedTasks.contains("read_daily_card") ? 10 : 0))
            let focus = clamp(48 + taskBoost + (completedTasks.contains("mood_checkin") ? 8 : 0))
            return AstaraScore(love: love, work: work, energy: energy, focus: focus)
        }
    )

    static let previewValue = WeeklyGuidanceService(
        buildWeekTransits: { _, _ in [] },
        ritualPrompt: { _ in "Bugun niyet ritueli yap." },
        timeTravelInsight: { date, _ in TimeTravelInsight(date: date, title: "Preview", summary: "Preview", action: "Preview") },
        scoreForDay: { _, _, _ in AstaraScore(love: 60, work: 62, energy: 68, focus: 58) }
    )
}

extension DependencyValues {
    var weeklyGuidanceService: WeeklyGuidanceService {
        get { self[WeeklyGuidanceService.self] }
        set { self[WeeklyGuidanceService.self] = newValue }
    }
}

private func clamp(_ value: Int) -> Int {
    max(0, min(100, value))
}

private func planetForOffset(_ offset: Int, activePlanets: Set<PlanetKey>) -> PlanetKey {
    if let active = activePlanets.first {
        return active
    }
    let order: [PlanetKey] = [.gunes, .ay, .merkur, .venus, .mars, .jupiter, .saturn]
    return order[offset % order.count]
}

private func dayDescription(for offset: Int, sign: ZodiacSign, target: ZodiacSign, planet: PlanetKey) -> String {
    switch offset {
    case 0:
        return "\(planet.turkishName) etkisiyle bugun odak: net karar. \(sign.turkishName) enerjini dagitma."
    case 1...2:
        return "\(target.turkishName) vurgusu artiyor. Iletisimde niyetini acik kur."
    case 3...4:
        return "Tempon yukseliyor. Kisa plan + tek oncelik en iyi sonuc verir."
    default:
        return "Hafta kapanisinda duzen kur. Fazlaliklari birak, enerjini koru."
    }
}

