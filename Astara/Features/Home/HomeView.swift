import SwiftUI
import ComposableArchitecture

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            homeTab
                .tag(HomeFeature.Tab.home)
                .tabItem {
                    Label(HomeFeature.Tab.home.title, systemImage: HomeFeature.Tab.home.icon)
                }

            ChartView(store: store.scope(state: \.chart, action: \.chart))
                .tag(HomeFeature.Tab.chart)
                .tabItem {
                    Label(HomeFeature.Tab.chart.title, systemImage: HomeFeature.Tab.chart.icon)
                }

            DailyHoroscopeView(store: store.scope(state: \.daily, action: \.daily))
                .tag(HomeFeature.Tab.daily)
                .tabItem {
                    Label(HomeFeature.Tab.daily.title, systemImage: HomeFeature.Tab.daily.icon)
                }

            CompatibilityView(store: store.scope(state: \.compatibility, action: \.compatibility))
                .tag(HomeFeature.Tab.compatibility)
                .tabItem {
                    Label(HomeFeature.Tab.compatibility.title, systemImage: HomeFeature.Tab.compatibility.icon)
                }

            ProfileView(store: store.scope(state: \.profile, action: \.profile))
                .tag(HomeFeature.Tab.profile)
                .tabItem {
                    Label(HomeFeature.Tab.profile.title, systemImage: HomeFeature.Tab.profile.icon)
                }
        }
        .tint(AstaraColors.gold)
        .preferredColorScheme(.dark)
        .onAppear {
            store.send(.onAppear)
        }
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        ZStack {
            GradientBackground()
            StarfieldView(starCount: 55)
                .opacity(0.18)

            ScrollView(showsIndicators: false) {
                VStack(spacing: AstaraSpacing.lg) {
                    // Header
                    header
                        .padding(.horizontal, AstaraSpacing.lg)
                    streakCard
                        .padding(.horizontal, AstaraSpacing.lg)
                    astaraScoreCard
                        .padding(.horizontal, AstaraSpacing.lg)
                    week360Card
                        .padding(.horizontal, AstaraSpacing.lg)
                    ritualJournalCard
                        .padding(.horizontal, AstaraSpacing.lg)
                    synastryFeedCard
                        .padding(.horizontal, AstaraSpacing.lg)
                    dailyTasksCard
                        .padding(.horizontal, AstaraSpacing.lg)
                    moodCheckinCard
                        .padding(.horizontal, AstaraSpacing.lg)

                    // Big Three mini-card (if chart exists)
                    if let chart = store.userChart {
                        bigThreeBar(chart: chart)
                            .padding(.horizontal, AstaraSpacing.lg)
                    }

                    // Retro alert
                    if !store.activeRetrogrades.isEmpty {
                        RetroAlertBanner(retrogrades: store.activeRetrogrades)
                            .padding(.horizontal, AstaraSpacing.lg)
                    }

                    // Daily energy card
                    if let horoscope = store.dailyHoroscope {
                        featuredDailyCard(horoscope: horoscope)
                            .padding(.horizontal, AstaraSpacing.lg)
                        DailyCardView(horoscope: horoscope)
                            .padding(.horizontal, AstaraSpacing.lg)
                    } else if store.isLoading {
                        shimmerCards
                    } else if let errorMessage = store.errorMessage {
                        errorBanner(message: errorMessage)
                            .padding(.horizontal, AstaraSpacing.lg)
                    }

                    // Element energy
                    if !store.elementEnergy.isEmpty {
                        elementEnergySection
                            .padding(.horizontal, AstaraSpacing.lg)
                    }

                    // Planet positions
                    if !store.planetPositions.isEmpty {
                        PlanetPositionsView(planets: store.planetPositions)
                            .padding(.horizontal, AstaraSpacing.lg)
                    }

                    // Last updated
                    if let lastUpdated = store.lastUpdated {
                        HStack(spacing: AstaraSpacing.xxs) {
                            Circle()
                                .fill(AstaraColors.sage400)
                                .frame(width: 6, height: 6)
                            Text("\(String(localized: "last_updated")): \(AstaraDateFormatters.timeOnly.string(from: lastUpdated))")
                                .font(AstaraTypography.caption)
                                .foregroundStyle(AstaraColors.textTertiary)
                        }
                        .padding(.top, AstaraSpacing.xs)
                    }

                    Button {
                        Haptics.selection()
                        store.send(.retryDailyData)
                    } label: {
                        HStack(spacing: AstaraSpacing.xs) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .semibold))
                            Text(String(localized: "retry"))
                                .font(AstaraTypography.labelMedium)
                        }
                        .foregroundStyle(AstaraColors.textSecondary)
                        .padding(.horizontal, AstaraSpacing.md)
                        .padding(.vertical, AstaraSpacing.sm)
                        .background(AstaraColors.cardBackground)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, AstaraSpacing.xs)

                    Button {
                        Haptics.selection()
                        store.send(.shareDailySummary)
                    } label: {
                        HStack(spacing: AstaraSpacing.xs) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Gunluk karti paylas")
                                .font(AstaraTypography.labelMedium)
                        }
                        .foregroundStyle(AstaraColors.textSecondary)
                        .padding(.horizontal, AstaraSpacing.md)
                        .padding(.vertical, AstaraSpacing.sm)
                        .background(AstaraColors.cardBackground)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: AstaraSpacing.sm) {
                        Button {
                            Haptics.selection()
                            store.send(.openAskAstara(true))
                        } label: {
                            Text("Ask Astara")
                                .font(AstaraTypography.labelMedium)
                                .foregroundStyle(AstaraColors.textSecondary)
                                .padding(.horizontal, AstaraSpacing.md)
                                .padding(.vertical, AstaraSpacing.sm)
                                .background(AstaraColors.cardBackground)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            Haptics.selection()
                            store.send(.openTimeTravel(true))
                            store.send(.loadTimeTravelInsight)
                        } label: {
                            Text("Time Travel")
                                .font(AstaraTypography.labelMedium)
                                .foregroundStyle(AstaraColors.textSecondary)
                                .padding(.horizontal, AstaraSpacing.md)
                                .padding(.vertical, AstaraSpacing.sm)
                                .background(AstaraColors.cardBackground)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    // Tagline
                    Text("Ad astra per aspera")
                        .font(.custom("CormorantGaramond-Regular", size: 13))
                        .foregroundStyle(AstaraColors.textTertiary.opacity(0.4))
                        .italic()
                        .padding(.top, AstaraSpacing.sm)
                }
                .padding(.top, AstaraSpacing.md)
                .padding(.bottom, AstaraSpacing.xxxl)
            }
            .refreshable {
                Haptics.selection()
                store.send(.retryDailyData)
            }
        }
        .onChange(of: store.shareMessage) { _, message in
            guard let message else { return }
            ShareManager.shareAsImage(dailyShareCard(caption: message))
            store.send(.clearShareMessage)
        }
        .sheet(isPresented: Binding(
            get: { store.showAskAstara },
            set: { store.send(.openAskAstara($0)) }
        )) {
            askAstaraSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(
            get: { store.showTimeTravel },
            set: { store.send(.openTimeTravel($0)) }
        )) {
            timeTravelSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        VStack(spacing: AstaraSpacing.md) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 32))
                .foregroundStyle(AstaraColors.gold.opacity(0.5))

            Text(message)
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textSecondary)
                .multilineTextAlignment(.center)

            AstaraButton(title: String(localized: "retry"), style: .secondary) {
                store.send(.retryDailyData)
            }
            .frame(maxWidth: 220)
        }
        .padding(AstaraSpacing.xl)
        .astaraCard()
    }

    // MARK: - Shimmer

    private var shimmerCards: some View {
        VStack(spacing: AstaraSpacing.md) {
            ShimmerView()
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg))
            ShimmerView()
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg))
        }
        .padding(.horizontal, AstaraSpacing.lg)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AstaraSpacing.xxs) {
                Text(greetingText)
                    .font(AstaraTypography.bodyMedium)
                    .foregroundStyle(AstaraColors.textSecondary)

                Text("ASTARA")
                    .font(.custom("CormorantGaramond-Bold", size: 32))
                    .foregroundStyle(AstaraColors.gold)
                    .tracking(6)

                Text(AstaraDateFormatters.displayDate.string(from: Date()))
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }

            Spacer()

            // Profile avatar
            Button {
                store.send(.selectTab(.profile))
            } label: {
                ZStack {
                    Circle()
                        .fill(AstaraColors.gold.opacity(0.12))
                        .frame(width: 50, height: 50)
                        .blur(radius: 6)
                    Circle()
                        .fill(AstaraColors.gold.opacity(0.1))
                        .frame(width: 46, height: 46)
                    Circle()
                        .stroke(AstaraColors.gold.opacity(0.3), lineWidth: 1)
                        .frame(width: 46, height: 46)
                    Text(store.userSunSign.symbol)
                        .font(.system(size: 21))
                }
            }
        }
    }

    // MARK: - Big Three Bar

    private func bigThreeBar(chart: BirthChart) -> some View {
        HStack(spacing: 0) {
            if let sun = chart.sunSign {
                bigThreeItem(label: "\u{2609}", title: String(localized: "sun_short"), sign: sun, color: AstaraColors.gold)
            }
            if chart.sunSign != nil && chart.moonSign != nil {
                dividerLine
            }
            if let moon = chart.moonSign {
                bigThreeItem(label: "\u{263D}", title: String(localized: "moon_short"), sign: moon, color: AstaraColors.mist400)
            }
            if chart.moonSign != nil && chart.risingSign != nil {
                dividerLine
            }
            if let rising = chart.risingSign {
                bigThreeItem(label: "ASC", title: String(localized: "rising_short"), sign: rising, color: AstaraColors.goldLight)
            }
        }
        .padding(.vertical, AstaraSpacing.md)
        .padding(.horizontal, AstaraSpacing.sm)
        .astaraCard()
    }

    private func bigThreeItem(label: String, title: String, sign: ZodiacSign, color: Color) -> some View {
        VStack(spacing: AstaraSpacing.xxs) {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(sign.symbol)
                .font(.system(size: 22))
            Text(sign.turkishName)
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textSecondary)
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(AstaraColors.textTertiary)
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func featuredDailyCard(horoscope: DailyHoroscope) -> some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.md) {
            HStack {
                Label(String(localized: "today"), systemImage: "sparkles")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.goldLight)
                    .padding(.horizontal, AstaraSpacing.sm)
                    .padding(.vertical, AstaraSpacing.xxs)
                    .background(AstaraColors.gold.opacity(0.15))
                    .clipShape(Capsule())
                Spacer()
                Text("\(horoscope.energy)%")
                    .font(AstaraTypography.labelLarge)
                    .foregroundStyle(AstaraColors.gold)
            }

            Text(horoscope.theme)
                .font(AstaraTypography.titleMedium)
                .foregroundStyle(AstaraColors.textPrimary)
                .lineLimit(1)

            Text(horoscope.text)
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textSecondary)
                .lineLimit(3)
        }
        .padding(AstaraSpacing.md)
        .background(
            LinearGradient(
                colors: [AstaraColors.gold.opacity(0.16), AstaraColors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg)
                .stroke(AstaraColors.gold.opacity(0.3), lineWidth: 1)
        )
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(AstaraColors.cardBorder)
            .frame(width: 1, height: 48)
    }

    private var streakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: AstaraSpacing.xxs) {
                Text("Streak")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
                Text("\(store.streakCount) gun")
                    .font(AstaraTypography.titleMedium)
                    .foregroundStyle(AstaraColors.gold)
                Text("En iyi: \(store.longestStreak)")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textSecondary)
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundStyle(AstaraColors.ember400)
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private var astaraScoreCard: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text("Astara Score")
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)
            HStack(spacing: AstaraSpacing.sm) {
                scorePill(title: "Love", value: store.astaraScore.love)
                scorePill(title: "Work", value: store.astaraScore.work)
                scorePill(title: "Energy", value: store.astaraScore.energy)
                scorePill(title: "Focus", value: store.astaraScore.focus)
            }
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private func scorePill(title: String, value: Int) -> some View {
        VStack(spacing: AstaraSpacing.xxs) {
            Text("\(value)")
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.gold)
            Text(title)
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AstaraSpacing.xs)
        .background(AstaraColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
    }

    private var week360Card: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text("My Week 360")
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)
            if store.weekTransits.isEmpty {
                Text("Haftalik akis hazirlaniyor...")
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textSecondary)
            } else {
                ForEach(store.weekTransits.prefix(3)) { transit in
                    HStack(alignment: .top, spacing: AstaraSpacing.sm) {
                        Text(transit.planet.symbol)
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: AstaraSpacing.xxs) {
                            Text("\(transit.fromSign.turkishName) → \(transit.toSign.turkishName)")
                                .font(AstaraTypography.labelMedium)
                                .foregroundStyle(AstaraColors.textPrimary)
                            Text(transit.description)
                                .font(AstaraTypography.caption)
                                .foregroundStyle(AstaraColors.textSecondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Text(transit.date)
                            .font(AstaraTypography.caption)
                            .foregroundStyle(AstaraColors.textTertiary)
                    }
                }
            }
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private var ritualJournalCard: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text("Ritual + Journal")
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)
            Text(store.ritualPrompt.isEmpty ? "Bugun icin rituel yukleniyor..." : store.ritualPrompt)
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textSecondary)
            TextField("Kisa not: bugun nasil hissediyorsun?", text: $store.moodNote.sending(\.setMoodNote))
                .textFieldStyle(.plain)
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textPrimary)
                .padding(.horizontal, AstaraSpacing.sm)
                .padding(.vertical, AstaraSpacing.xs)
                .background(AstaraColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private var synastryFeedCard: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text("Synastry Feed")
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)
            if store.friendDynamics.isEmpty {
                Text("Arkadas dinamikleri yukleniyor...")
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textSecondary)
            } else {
                ForEach(store.friendDynamics.prefix(2)) { item in
                    HStack(alignment: .top, spacing: AstaraSpacing.sm) {
                        Text(item.friendSign.symbol)
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: AstaraSpacing.xxs) {
                            Text("\(item.friendName) • %\(item.compatibility.overallScore)")
                                .font(AstaraTypography.labelMedium)
                                .foregroundStyle(AstaraColors.textPrimary)
                            Text(item.insight)
                                .font(AstaraTypography.caption)
                                .foregroundStyle(AstaraColors.textSecondary)
                            Text(item.suggestedAction)
                                .font(AstaraTypography.caption)
                                .foregroundStyle(AstaraColors.goldLight)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private var dailyTasksCard: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text("Bugunun gorevleri")
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)
            taskRow(id: "read_daily_card", title: "Gunluk yorumu oku")
            taskRow(id: "mood_checkin", title: "Mood check-in yap")
            taskRow(id: "ritual_journal", title: "Rituel notunu yaz")
            taskRow(id: "ask_astara", title: "Ask Astara sorusu sor")
            taskRow(id: "share_card", title: "Kart paylas")
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private func taskRow(id: String, title: String) -> some View {
        let done = store.completedTasks.contains(id)
        return Button {
            Haptics.selection()
            store.send(.completeTask(id))
        } label: {
            HStack {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? AstaraColors.sage400 : AstaraColors.textTertiary)
                Text(title)
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textSecondary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private var moodCheckinCard: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text("Mood check-in")
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)
            HStack(spacing: AstaraSpacing.xs) {
                ForEach(1...5, id: \.self) { mood in
                    Button {
                        Haptics.selection()
                        store.send(.setMood(mood))
                    } label: {
                        Text(moodEmoji(mood))
                            .font(.system(size: 22))
                            .padding(6)
                            .background((store.todaysMood == mood ? AstaraColors.gold.opacity(0.2) : .clear))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            AstaraButton(title: "Check-in kaydet", style: .secondary) {
                store.send(.saveMoodCheckin)
            }
            .disabled(store.todaysMood == nil)
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private func moodEmoji(_ value: Int) -> String {
        switch value {
        case 1: return "😞"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        default: return "😄"
        }
    }

    private func dailyShareCard(caption: String) -> some View {
        ZStack {
            GradientBackground()
            StarfieldView(starCount: 40)
                .opacity(0.2)
            VStack(spacing: AstaraSpacing.lg) {
                Text("ASTARA")
                    .font(.custom("CormorantGaramond-Bold", size: 48))
                    .foregroundStyle(AstaraColors.gold)
                Text(caption)
                    .font(AstaraTypography.titleMedium)
                    .foregroundStyle(AstaraColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AstaraSpacing.xl)
                Text("astara.app")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }
            .padding(AstaraSpacing.xl)
        }
    }

    private var askAstaraSheet: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.md) {
            Text("Ask Astara")
                .font(AstaraTypography.titleLarge)
                .foregroundStyle(AstaraColors.textPrimary)
            Text("Gunluk hak: \(store.isPremium ? "Sinirsiz" : "\(store.askQuotaRemaining)")")
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
            TextField("Sorunu yaz...", text: $store.askQuestionText.sending(\.setAskQuestionText))
                .textFieldStyle(.plain)
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textPrimary)
                .padding(AstaraSpacing.sm)
                .background(AstaraColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
            AstaraButton(title: "Sor", style: .primary, isDisabled: store.askQuestionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                store.send(.submitAskQuestion)
            }
            if let response = store.askResponse {
                Text(response)
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textSecondary)
                    .padding(AstaraSpacing.sm)
                    .background(AstaraColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
            }
            Spacer()
        }
        .padding(AstaraSpacing.lg)
        .astaraBackground()
    }

    private var timeTravelSheet: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.md) {
            Text("Time Travel")
                .font(AstaraTypography.titleLarge)
                .foregroundStyle(AstaraColors.textPrimary)
            DatePicker(
                "Tarih sec",
                selection: $store.timeTravelDate.sending(\.setTimeTravelDate),
                in: Calendar.current.date(byAdding: .day, value: -30, to: Date())!...Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            if let insight = store.timeTravelInsight {
                VStack(alignment: .leading, spacing: AstaraSpacing.xs) {
                    Text(insight.title)
                        .font(AstaraTypography.labelLarge)
                        .foregroundStyle(AstaraColors.gold)
                    Text(insight.summary)
                        .font(AstaraTypography.bodySmall)
                        .foregroundStyle(AstaraColors.textSecondary)
                    Text("Aksiyon: \(insight.action)")
                        .font(AstaraTypography.caption)
                        .foregroundStyle(AstaraColors.textTertiary)
                }
                .padding(AstaraSpacing.sm)
                .background(AstaraColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
            }
            Spacer()
        }
        .padding(AstaraSpacing.lg)
        .astaraBackground()
    }

    // MARK: - Element Energy

    private var elementEnergySection: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            HStack {
                Text(String(localized: "element_energy"))
                    .font(AstaraTypography.labelLarge)
                    .foregroundStyle(AstaraColors.textPrimary)
                Spacer()
                Text(String(localized: "today"))
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }

            HStack(spacing: AstaraSpacing.sm) {
                elementCircle(element: .fire, value: store.elementEnergy[.fire] ?? 0, emoji: "🔥")
                elementCircle(element: .earth, value: store.elementEnergy[.earth] ?? 0, emoji: "🌿")
                elementCircle(element: .air, value: store.elementEnergy[.air] ?? 0, emoji: "💨")
                elementCircle(element: .water, value: store.elementEnergy[.water] ?? 0, emoji: "💧")
            }
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private func elementCircle(element: Element, value: Int, emoji: String) -> some View {
        VStack(spacing: AstaraSpacing.xs) {
            ZStack {
                Circle()
                    .stroke(AstaraColors.cardBorder, lineWidth: 3)
                    .frame(width: 52, height: 52)

                Circle()
                    .trim(from: 0, to: CGFloat(value) / 100)
                    .stroke(elementColor(element), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))

                Text(emoji)
                    .font(.system(size: 18))
            }

            Text("\(value)%")
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textSecondary)

            Text(element.localizedName)
                .font(.system(size: 10))
                .foregroundStyle(AstaraColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func elementColor(_ element: Element) -> Color {
        switch element {
        case .fire: AstaraColors.fire
        case .earth: AstaraColors.earth
        case .air: AstaraColors.air
        case .water: AstaraColors.water
        }
    }

    // MARK: - Greeting

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return String(localized: "good_morning")
        case 12..<18: return String(localized: "good_afternoon")
        case 18..<22: return String(localized: "good_evening")
        default: return String(localized: "good_night")
        }
    }
}

#Preview {
    HomeView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
    )
}
