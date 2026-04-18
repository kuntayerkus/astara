import Foundation
import ComposableArchitecture
#if canImport(WidgetKit)
import WidgetKit
#endif

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var dailyHoroscope: DailyHoroscope?
        var elementEnergy: [Element: Int] = [:]
        var activeRetrogrades: [Retrograde] = []
        var upcomingRetrogrades: [Retrograde] = []
        var planetPositions: [Planet] = []
        var selectedTab: Tab = .home
        var isLoading: Bool = false
        var errorMessage: String?
        var lastUpdated: Date?
        var streakCount: Int = 0
        var longestStreak: Int = 0
        var taskDateKey: String = ""
        var completedTasks: Set<String> = []
        var todaysMood: Int?
        var moodNote: String = ""
        var moodHistory: [MoodEntry] = []
        var shareMessage: String?
        var weekTransits: [Transit] = []
        var ritualPrompt: String = ""
        var friendDynamics: [FriendDynamic] = []
        var astaraScore: AstaraScore = .zero
        var isPremium: Bool = false
        var showAskAstara: Bool = false
        var askQuestionText: String = ""
        var askResponse: String?
        var askQuotaRemaining: Int = 1
        var isAskingAstara: Bool = false
        var showTimeTravel: Bool = false
        var timeTravelDate: Date = Date()
        var timeTravelInsight: TimeTravelInsight?
        var hasNewDailyContent: Bool = false

        // User data (set from onboarding)
        var userSunSign: ZodiacSign = .aries
        var userChart: BirthChart?

        // Child features
        var chart: ChartFeature.State = .init()
        var daily: DailyHoroscopeFeature.State = .init()
        var compatibility: CompatibilityFeature.State = .init()
        var profile: ProfileFeature.State = .init()
        var friends: FriendsFeature.State = .init()
    }

    enum Tab: String, CaseIterable, Equatable {
        case home, chart, daily, compatibility, profile

        var icon: String {
            switch self {
            case .home: "house.fill"
            case .chart: "circle.grid.cross.fill"
            case .daily: "sun.max.fill"
            case .compatibility: "heart.fill"
            case .profile: "person.fill"
            }
        }

        var title: String {
            switch self {
            case .home: String(localized: "tab_home")
            case .chart: String(localized: "tab_chart")
            case .daily: String(localized: "tab_daily")
            case .compatibility: String(localized: "tab_compatibility")
            case .profile: String(localized: "tab_profile")
            }
        }
    }

    enum Action: Equatable {
        case onAppear
        case selectTab(Tab)
        case loadDailyData
        case dailyDataLoaded(DailyHoroscope, [Element: Int], [Retrograde])
        case dailyDataLoadFailed
        case retryDailyData
        case loadPlanetPositions
        case planetPositionsLoaded([Planet])
        case loadEngagement
        case engagementLoaded(UserEngagementState, Bool)
        case userIdLoaded(UUID)
        case completeTask(String)
        case setMood(Int)
        case setMoodNote(String)
        case saveMoodCheckin
        case shareDailySummary
        case clearShareMessage
        case loadWeek360Data
        case week360Loaded([Transit], [FriendDynamic], String)
        case loadAstaraScore
        case astaraScoreLoaded(AstaraScore)
        case openAskAstara(Bool)
        case setAskQuestionText(String)
        case submitAskQuestion
        case askAnswered(String)
        case openTimeTravel(Bool)
        case setTimeTravelDate(Date)
        case loadTimeTravelInsight
        case timeTravelInsightLoaded(TimeTravelInsight)

        // Child features
        case chart(ChartFeature.Action)
        case daily(DailyHoroscopeFeature.Action)
        case compatibility(CompatibilityFeature.Action)
        case profile(ProfileFeature.Action)
        case friends(FriendsFeature.Action)
    }

    @Dependency(\.horoscopeService) var horoscopeService
    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.weeklyGuidanceService) var weeklyGuidanceService
    @Dependency(\.askAstaraService) var askAstaraService
    @Dependency(\.compatibilityEngine) var compatibilityEngine
    @Dependency(\.notificationService) var notificationService

    var body: some ReducerOf<Self> {
        Scope(state: \.chart, action: \.chart) {
            ChartFeature()
        }

        Scope(state: \.daily, action: \.daily) {
            DailyHoroscopeFeature()
        }

        Scope(state: \.compatibility, action: \.compatibility) {
            CompatibilityFeature()
        }

        Scope(state: \.profile, action: \.profile) {
            ProfileFeature()
        }

        Scope(state: \.friends, action: \.friends) {
            FriendsFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .send(.loadEngagement),
                    .send(.loadDailyData),
                    .send(.loadPlanetPositions),
                    .send(.loadAstaraScore)
                )

            case .selectTab(let tab):
                state.selectedTab = tab
                if tab == .daily {
                    state.hasNewDailyContent = false
                }
                return .none

            case .retryDailyData:
                state.errorMessage = nil
                return .send(.loadDailyData)

            case .loadDailyData:
                state.isLoading = true
                state.errorMessage = nil
                let sign = state.userSunSign
                return .run { send in
                    async let horoscopes = horoscopeService.fetchDailyHoroscopes()
                    async let energy = horoscopeService.fetchDailyEnergy()
                    async let retros = horoscopeService.fetchRetroCalendar()
                    do {
                        let (h, e, r) = try await (horoscopes, energy, retros)
                        let daily = h.first(where: { $0.sign == sign }) ?? h.first
                        if let daily {
                            await send(.dailyDataLoaded(daily, e, r))
                        } else {
                            await send(.dailyDataLoadFailed)
                        }
                    } catch {
                        await send(.dailyDataLoadFailed)
                    }
                }

            case .dailyDataLoaded(let horoscope, let energy, let retrogrades):
                state.isLoading = false
                state.dailyHoroscope = horoscope
                state.elementEnergy = energy
                state.activeRetrogrades = retrogrades.filter { $0.isActive }
                state.upcomingRetrogrades = retrogrades.filter { !$0.isActive && $0.isFuture }
                state.lastUpdated = Date()
                state.hasNewDailyContent = true
                let shouldPersistReadTask = state.completedTasks.contains("read_daily_card") == false
                if shouldPersistReadTask {
                    state.completedTasks.insert("read_daily_card")
                }
                // Sync user's sign into child features
                state.daily.selectedSign = state.userSunSign
                state.compatibility.sign1 = state.userSunSign
                // Refresh the home-screen widget snapshot with the freshly
                // loaded daily context. Cheap file write + WidgetKit reload.
                persistWidgetSnapshot(from: state)
                if shouldPersistReadTask {
                    return .merge(
                        .run { [engagement = currentEngagement(from: state)] _ in
                            await persistenceClient.updateEngagement(engagement)
                        },
                        .send(.loadWeek360Data),
                        .send(.loadAstaraScore)
                    )
                }
                return .merge(
                    .send(.loadWeek360Data),
                    .send(.loadAstaraScore)
                )

            case .dailyDataLoadFailed:
                state.isLoading = false
                state.errorMessage = String(localized: "error_load_failed")
                return .none

            case .loadPlanetPositions:
                return .run { send in
                    do {
                        let positions = try await horoscopeService.fetchPlanetPositions()
                        await send(.planetPositionsLoaded(positions))
                    } catch {
                        // Silently fail — planet positions are supplementary
                    }
                }

            case .planetPositionsLoaded(let planets):
                state.planetPositions = planets
                return .none

            case .loadEngagement:
                return .run { send in
                    if let user = await persistenceClient.loadUser() {
                        await send(.userIdLoaded(user.id))
                        await send(.engagementLoaded(user.engagement, user.isPremium))
                    }
                }

            case .userIdLoaded(let id):
                state.compatibility.userId = id
                return .none

            case .engagementLoaded(var engagement, let isPremium):
                let today = dayKey(for: Date())
                if engagement.taskDateKey != today {
                    engagement.taskDateKey = today
                    engagement.completedTasks = []
                    let previous = engagement.lastOpenDate
                    engagement.lastOpenDate = Date()
                    if let previous {
                        let days = daysBetween(previous, Date())
                        if days == 1 {
                            engagement.streakCount += 1
                        } else if days > 1 {
                            engagement.streakCount = 1
                        } else if engagement.streakCount == 0 {
                            engagement.streakCount = 1
                        }
                    } else {
                        engagement.streakCount = max(engagement.streakCount, 1)
                    }
                    engagement.longestStreak = max(engagement.longestStreak, engagement.streakCount)
                }

                state.streakCount = engagement.streakCount
                state.longestStreak = engagement.longestStreak
                state.taskDateKey = engagement.taskDateKey
                state.completedTasks = engagement.completedTasks
                state.moodHistory = engagement.moods
                state.todaysMood = engagement.moods.first(where: { dayKey(for: $0.date) == engagement.taskDateKey })?.mood
                state.isPremium = isPremium
                state.chart.isPremium = isPremium
                state.compatibility.isPremium = isPremium
                if engagement.askDateKey != today {
                    engagement.askDateKey = today
                    engagement.askCountToday = 0
                }
                state.askQuotaRemaining = max(0, state.isPremium ? 99 : 1 - engagement.askCountToday)
                // Premium flag just changed — re-emit the widget snapshot so
                // the medium/large tiers flip between paywall and real content.
                persistWidgetSnapshot(from: state)
                return .run { [engagement] _ in
                    await persistenceClient.updateEngagement(engagement)
                }

            case .completeTask(let taskId):
                state.completedTasks.insert(taskId)
                return .run { [engagement = currentEngagement(from: state)] _ in
                    await persistenceClient.updateEngagement(engagement)
                }

            case .setMood(let mood):
                state.todaysMood = mood
                return .none

            case .setMoodNote(let note):
                state.moodNote = note
                return .none

            case .saveMoodCheckin:
                guard let mood = state.todaysMood else { return .none }
                var moods = state.moodHistory.filter { dayKey(for: $0.date) != state.taskDateKey }
                moods.insert(MoodEntry(date: Date(), mood: mood, note: state.moodNote), at: 0)
                state.moodHistory = Array(moods.prefix(30))
                state.completedTasks.insert("mood_checkin")
                if state.moodNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    state.completedTasks.insert("ritual_journal")
                }
                state.moodNote = ""
                return .merge(
                    .run { [engagement = currentEngagement(from: state)] _ in
                        await persistenceClient.updateEngagement(engagement)
                    },
                    .send(.loadAstaraScore)
                )

            case .shareDailySummary:
                state.completedTasks.insert("share_card")
                state.shareMessage = dailyShareText(from: state)
                return .merge(
                    .run { [engagement = currentEngagement(from: state)] _ in
                        await persistenceClient.updateEngagement(engagement)
                    },
                    .send(.loadAstaraScore)
                )

            case .clearShareMessage:
                state.shareMessage = nil
                return .none

            case .loadWeek360Data:
                let sign = state.userSunSign
                let retros = state.activeRetrogrades
                let locale = AppLocale.current.rawValue
                return .run { send in
                    let transits = await weeklyGuidanceService.buildWeekTransits(sign, retros)
                    let ritual = await weeklyGuidanceService.ritualPrompt(retros, locale)

                    // Real partners stored via Feature 3 synastry flow. Falls
                    // back to an empty list — Home card renders a "Add your
                    // first partner" hint when no partners exist.
                    let partners = await persistenceClient.listPartners()
                    var friends: [FriendDynamic] = []
                    for partner in partners.prefix(3) {
                        let partnerSign = partner.approximateSunSign
                        let cmp = await compatibilityEngine.calculate(sign, partnerSign)
                        friends.append(
                            FriendDynamic(
                                friendName: partner.name,
                                friendSign: partnerSign,
                                compatibility: cmp,
                                insight: "\(partner.name) ile bugün iletişim tonu sonucu belirler.",
                                suggestedAction: "Kısa ve net mesaj at."
                            )
                        )
                    }
                    await send(.week360Loaded(transits, friends, ritual))
                }

            case .week360Loaded(let transits, let friends, let ritual):
                state.weekTransits = transits
                state.friendDynamics = friends
                state.ritualPrompt = ritual
                guard let next = transits.first else { return .none }
                return .run { _ in
                    await notificationService.scheduleTransitAlert(
                        "Bugun transit etkisi",
                        "\(next.planet.turkishName): \(next.description)",
                        10
                    )
                }

            case .loadAstaraScore:
                return .run { [daily = state.dailyHoroscope, tasks = state.completedTasks, mood = state.todaysMood] send in
                    let score = await weeklyGuidanceService.scoreForDay(daily, tasks, mood)
                    await send(.astaraScoreLoaded(score))
                }

            case .astaraScoreLoaded(let score):
                state.astaraScore = score
                return .none

            case .openAskAstara(let show):
                state.showAskAstara = show
                if show == false {
                    state.askQuestionText = ""
                    state.askResponse = nil
                    state.isAskingAstara = false
                }
                return .none

            case .setAskQuestionText(let text):
                state.askQuestionText = text
                return .none

            case .submitAskQuestion:
                let trimmed = state.askQuestionText.trimmingCharacters(in: .whitespacesAndNewlines)
                // First-pass sanitize at the call site so the empty-check below
                // catches questions that were *only* injection tokens. The service
                // re-sanitizes (defense in depth) before hitting the prompt builder.
                let question = PromptSanitizer.sanitizeUserInput(trimmed)
                guard question.isEmpty == false else { return .none }
                guard state.isPremium || state.askQuotaRemaining > 0 else {
                    state.askResponse = String(localized: "ask_astara_quota_exceeded")
                    return .none
                }
                let sign = state.userSunSign
                let horoscope = state.dailyHoroscope
                let chart = state.userChart
                let locale = AppLocale.current.rawValue
                state.askResponse = nil
                state.isAskingAstara = true
                return .run { send in
                    let answer = await askAstaraService.ask(question, sign, horoscope, chart, locale)
                    await send(.askAnswered(answer))
                }

            case .askAnswered(let answer):
                state.isAskingAstara = false
                state.askResponse = answer
                state.completedTasks.insert("ask_astara")
                if state.isPremium == false, state.askQuotaRemaining > 0 {
                    state.askQuotaRemaining -= 1
                }
                return .run { [engagement = currentEngagement(from: state)] _ in
                    await persistenceClient.updateEngagement(engagement)
                }

            case .openTimeTravel(let show):
                state.showTimeTravel = show
                return .none

            case .setTimeTravelDate(let date):
                state.timeTravelDate = date
                return .send(.loadTimeTravelInsight)

            case .loadTimeTravelInsight:
                let date = state.timeTravelDate
                let sign = state.userSunSign
                let locale = AppLocale.current.rawValue
                return .run { send in
                    let insight = await weeklyGuidanceService.timeTravelInsight(date, sign, locale)
                    await send(.timeTravelInsightLoaded(insight))
                }

            case .timeTravelInsightLoaded(let insight):
                state.timeTravelInsight = insight
                return .none

            case .chart(.requestPremium):
                return .send(.profile(.setSubscriptionPresented(true)))

            case .chart:
                return .none

            case .daily(.requestPremium):
                return .send(.profile(.setSubscriptionPresented(true)))

            case .daily:
                return .none

            case .compatibility(.requestPremium):
                return .send(.profile(.setSubscriptionPresented(true)))

            case .compatibility:
                return .none

            case .profile:
                return .none

            case .friends:
                return .none
            }
        }
    }
}

private func dayKey(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

private func daysBetween(_ from: Date, _ to: Date) -> Int {
    let calendar = Calendar(identifier: .gregorian)
    let start = calendar.startOfDay(for: from)
    let end = calendar.startOfDay(for: to)
    return calendar.dateComponents([.day], from: start, to: end).day ?? 0
}

private func currentEngagement(from state: HomeFeature.State) -> UserEngagementState {
    UserEngagementState(
        streakCount: state.streakCount,
        longestStreak: state.longestStreak,
        lastOpenDate: Date(),
        taskDateKey: state.taskDateKey.isEmpty ? dayKey(for: Date()) : state.taskDateKey,
        completedTasks: state.completedTasks,
        moods: state.moodHistory,
        lastShareDate: state.completedTasks.contains("share_card") ? Date() : nil,
        askDateKey: dayKey(for: Date()),
        askCountToday: state.isPremium ? 0 : max(0, 1 - state.askQuotaRemaining),
        journalCount: state.moodHistory.filter { $0.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }.count
    )
}

private func dailyShareText(from state: HomeFeature.State) -> String {
    let energy = state.dailyHoroscope?.energy ?? 0
    return "Astara gunluk enerji: %\(energy) | Streak: \(state.streakCount) gun | Focus: \(state.astaraScore.focus)"
}

// MARK: - Widget snapshot bridge

/// Builds a ``WidgetSnapshot`` from the current Home state and writes it to the
/// App Group-backed store, then asks WidgetKit to refresh timelines. Silent
/// no-op if there's no daily horoscope yet (e.g. before first load).
private func persistWidgetSnapshot(from state: HomeFeature.State) {
    guard let horoscope = state.dailyHoroscope else { return }

    let retroBanner = state.activeRetrogrades
        .first
        .map { "\($0.planet.turkishName) retrosu aktif" }

    let snapshot = WidgetSnapshot(
        sunSignRawValue: state.userSunSign.rawValue,
        energy: horoscope.energy,
        theme: horoscope.theme,
        luckyColorHex: luckyColorHex(for: horoscope.luckyColor, sign: state.userSunSign),
        tip: horoscope.tip,
        retroBanner: retroBanner,
        isPremium: state.isPremium,
        localePrefix: AppLocale.current.rawValue,
        updatedAt: Date()
    )

    WidgetSnapshotStore.write(snapshot)
    #if canImport(WidgetKit)
    WidgetCenter.shared.reloadAllTimelines()
    #endif
}

/// Best-effort Turkish color-name → hex mapping. Falls back to Astara gold so
/// the widget always has *something* to render as the lucky dot.
private func luckyColorHex(for name: String?, sign: ZodiacSign) -> String {
    guard let name = name?.lowercased().trimmingCharacters(in: .whitespaces), !name.isEmpty else {
        return "#C9A96E"
    }
    let table: [String: String] = [
        "mor": "#8B5CF6", "purple": "#8B5CF6",
        "kirmizi": "#EF4444", "kırmızı": "#EF4444", "red": "#EF4444",
        "mavi": "#38BDF8", "blue": "#38BDF8",
        "yesil": "#16A34A", "yeşil": "#16A34A", "green": "#16A34A",
        "sari": "#FACC15", "sarı": "#FACC15", "yellow": "#FACC15",
        "turuncu": "#FB923C", "orange": "#FB923C",
        "pembe": "#F472B6", "pink": "#F472B6",
        "beyaz": "#F8FAFC", "white": "#F8FAFC",
        "siyah": "#1F2937", "black": "#1F2937",
        "altin": "#C9A96E", "altın": "#C9A96E", "gold": "#C9A96E",
        "gumus": "#C8D4E8", "gümüş": "#C8D4E8", "silver": "#C8D4E8",
        "lacivert": "#1E3A8A", "navy": "#1E3A8A",
        "bordo": "#9F1239", "maroon": "#9F1239",
        "turkuaz": "#14B8A6", "teal": "#14B8A6"
    ]
    return table[name] ?? "#C9A96E"
}
