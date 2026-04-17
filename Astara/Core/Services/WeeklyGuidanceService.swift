import Foundation
import ComposableArchitecture

@DependencyClient
struct WeeklyGuidanceService {
    var buildWeekTransits: @Sendable (_ sign: ZodiacSign, _ retrogrades: [Retrograde]) async -> [Transit] = { _, _ in [] }
    var ritualPrompt: @Sendable (_ retrogrades: [Retrograde], _ locale: String) async -> String = { _, _ in "" }
    var timeTravelInsight: @Sendable (_ date: Date, _ sign: ZodiacSign, _ locale: String) async -> TimeTravelInsight = { date, _, _ in
        TimeTravelInsight(date: date, title: "", summary: "", action: "")
    }
    var scoreForDay: @Sendable (_ horoscope: DailyHoroscope?, _ completedTasks: Set<String>, _ mood: Int?) async -> AstaraScore = { _, _, _ in .zero }
}

extension WeeklyGuidanceService: DependencyKey {
    static let liveValue: WeeklyGuidanceService = {
        @Dependency(\.geminiService) var geminiService

        return WeeklyGuidanceService(
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
            ritualPrompt: { retrogrades, locale in
                // Template first so we always have a fallback string.
                let template = templateRitual(retrogrades: retrogrades, locale: locale)
                let activePlanet = retrogrades.first(where: \.isActive)?.planet
                let cacheKey = "ritual_\(locale.prefix(2))_\(todayKey())_\(activePlanet?.rawValue ?? "none")"

                let prompt = ritualGeminiPrompt(activePlanet: activePlanet, locale: locale)
                let config = GeminiConfig(
                    maxOutputTokens: 120,
                    temperature: 0.7,
                    cacheKey: cacheKey,
                    cachePolicy: .aiResponse,
                    locale: locale
                )
                do {
                    return try await geminiService.generate(prompt, config)
                } catch {
                    return template
                }
            },
            timeTravelInsight: { date, sign, locale in
                let template = templateInsight(date: date, sign: sign, locale: locale)

                let dateKey = AstaraDateFormatters.apiDate.string(from: date)
                let cacheKey = "timetravel_\(sign.rawValue)_\(locale.prefix(2))_\(dateKey)"

                let prompt = timeTravelGeminiPrompt(date: date, sign: sign, locale: locale)
                let config = GeminiConfig(
                    maxOutputTokens: 180,
                    temperature: 0.75,
                    cacheKey: cacheKey,
                    cachePolicy: .aiResponse,
                    locale: locale
                )
                do {
                    let aiSummary = try await geminiService.generate(prompt, config)
                    // Keep template title/action so UX stays structured; swap summary for AI text.
                    return TimeTravelInsight(
                        date: template.date,
                        title: template.title,
                        summary: aiSummary,
                        action: template.action
                    )
                } catch {
                    return template
                }
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
    }()

    static let previewValue = WeeklyGuidanceService(
        buildWeekTransits: { _, _ in [] },
        ritualPrompt: { _, _ in "Bugun niyet ritueli yap." },
        timeTravelInsight: { date, _, _ in TimeTravelInsight(date: date, title: "Preview", summary: "Preview", action: "Preview") },
        scoreForDay: { _, _, _ in AstaraScore(love: 60, work: 62, energy: 68, focus: 58) }
    )
}

extension DependencyValues {
    var weeklyGuidanceService: WeeklyGuidanceService {
        get { self[WeeklyGuidanceService.self] }
        set { self[WeeklyGuidanceService.self] = newValue }
    }
}

// MARK: - Templates (fallback + preview)

private func templateRitual(retrogrades: [Retrograde], locale: String) -> String {
    let isEnglish = locale.hasPrefix("en")
    if let retro = retrogrades.first(where: \.isActive) {
        return isEnglish
            ? "\(retro.planet.rawValue.capitalized) is retrograde. Try 10 minutes of silence + 3 lines of journaling."
            : "\(retro.planet.turkishName) retrosu aktif. 10 dakika sessizlik + 3 satır journaling yap."
    }
    return isEnglish
        ? "Intention ritual: 3 breaths, 1 intention written down, 1 small step chosen."
        : "Bugün niyet ritüeli: 3 nefes al, 1 niyet yaz, 1 küçük adım seç."
}

private func templateInsight(date: Date, sign: ZodiacSign, locale: String) -> TimeTravelInsight {
    let days = Calendar(identifier: .gregorian).dateComponents([.day], from: Date(), to: date).day ?? 0
    let isEnglish = locale.hasPrefix("en")

    if days < 0 {
        return TimeTravelInsight(
            date: date,
            title: isEnglish ? "Past echo" : "Geçmiş etkisi",
            summary: isEnglish
                ? "\(sign.rawValue.capitalized) energy carried a closure theme — boundaries and order were loud."
                : "\(sign.turkishName) enerjinde kapanış teması. O dönemde sınırlar ve düzen vurgusu yüksek.",
            action: isEnglish ? "Write 3 lessons you took from it." : "Neler öğrendiğini 3 madde yaz."
        )
    }
    return TimeTravelInsight(
        date: date,
        title: isEnglish ? "Future signal" : "Gelecek sinyali",
        summary: isEnglish
            ? "Accelerating stretch for \(sign.rawValue.capitalized). Communication and decisions lead."
            : "\(sign.turkishName) için hızlanan bir dönem. İletişim ve karar alma baskın.",
        action: isEnglish ? "Lock your priority now — pick one goal." : "Önceliğini şimdiden netleştir, tek hedef seç."
    )
}

// MARK: - AI Prompts

private func ritualGeminiPrompt(activePlanet: PlanetKey?, locale: String) -> String {
    let isEnglish = locale.hasPrefix("en")
    let retroLine: String = {
        guard let planet = activePlanet else { return "" }
        return isEnglish
            ? "\(planet.rawValue.capitalized) is retrograde right now.\n"
            : "Su anda \(planet.turkishName) retrosu aktif.\n"
    }()

    if isEnglish {
        return """
        You are Astara — a warm, witty astrology companion.
        \(retroLine)Write a 1-2 sentence daily ritual prompt the user can do in under 10 minutes.
        Concrete, sensory, never generic "meditate and breathe" filler.
        No astrology jargon. No "as an AI". English.
        """
    }
    return """
    Sen Astara'sin — samimi, hafif ironik bir astroloji arkadasi.
    \(retroLine)Kullaniciya 10 dakikadan kisa, somut bir gunluk ritueli yaz (1-2 cumle).
    "Meditasyon yap, nefes al" gibi klise cumleler YOK. Somut ve duyusal ol.
    Astroloji jargonu kullanma. "Ben bir yapay zekayim" deme. Turkce yaz.
    """
}

private func timeTravelGeminiPrompt(date: Date, sign: ZodiacSign, locale: String) -> String {
    let isEnglish = locale.hasPrefix("en")
    let days = Calendar(identifier: .gregorian).dateComponents([.day], from: Date(), to: date).day ?? 0
    let direction: String = {
        if days < 0 {
            return isEnglish ? "\(abs(days)) days in the past" : "\(abs(days)) gun onceye"
        } else if days > 0 {
            return isEnglish ? "\(days) days in the future" : "\(days) gun sonraya"
        }
        return isEnglish ? "today" : "bugune"
    }()

    if isEnglish {
        return """
        You are Astara — warm, slightly witty astrology companion.
        User's sun sign: \(sign.rawValue.capitalized).
        Time-travel target: \(direction).

        In 2-3 sentences, describe the astrological flavour of that date for this sign.
        Poetic but grounded. No disclaimers. No "as an AI". English.
        """
    }
    return """
    Sen Astara'sin — samimi, hafif ironik bir astroloji arkadasi.
    Kullanicinin gunes burcu: \(sign.turkishName).
    Zaman yolculugu hedefi: \(direction).

    O tarihin bu burc icin astrolojik tonunu 2-3 cumleyle anlat.
    Siirsel ama somut ol. Uyari metni koyma. "Ben bir yapay zekayim" deme. Turkce yaz.
    """
}

// MARK: - Helpers

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
        return "\(planet.turkishName) etkisiyle bugün odak: net karar. \(sign.turkishName) enerjini dağıtma."
    case 1...2:
        return "\(target.turkishName) vurgusu artıyor. İletişimde niyetini açık kur."
    case 3...4:
        return "Tempon yükseliyor. Kısa plan + tek öncelik en iyi sonuç verir."
    default:
        return "Hafta kapanışında düzen kur. Fazlalıkları bırak, enerjini koru."
    }
}

private func todayKey() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: Date())
}
