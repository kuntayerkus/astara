import SwiftUI
import ComposableArchitecture

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    @State private var appeared = false

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            homeTab
                .tag(HomeFeature.Tab.home)
                .tabItem {
                    Label(HomeFeature.Tab.home.title, systemImage: HomeFeature.Tab.home.icon)
                }
                .badge(store.activeRetrogrades.isEmpty ? 0 : store.activeRetrogrades.count)

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
                .badge(store.hasNewDailyContent ? "●" : nil)

            CompatibilityView(store: store.scope(state: \.compatibility, action: \.compatibility))
                .tag(HomeFeature.Tab.compatibility)
                .tabItem {
                    Label(HomeFeature.Tab.compatibility.title, systemImage: HomeFeature.Tab.compatibility.icon)
                }

            ProfileView(
                store: store.scope(state: \.profile, action: \.profile),
                friendsStore: store.scope(state: \.friends, action: \.friends)
            )
                .tag(HomeFeature.Tab.profile)
                .tabItem {
                    Label(HomeFeature.Tab.profile.title, systemImage: HomeFeature.Tab.profile.icon)
                }
        }
        .tint(AstaraColors.gold)
        .preferredColorScheme(.dark)
        .onAppear { store.send(.onAppear) }
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        ZStack {
            GradientBackground(ambient: .home)
            StarfieldView(starCount: 55).opacity(0.15)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // ── HEADER ──────────────────────────────────────
                    header
                        .padding(.horizontal, AstaraSpacing.lg)
                        .padding(.top, AstaraSpacing.md)
                        .chapterEntrance(appeared: appeared, delay: 0.0)

                    // ── CHAPTER I: TODAY ─────────────────────────────
                    chapterDivider(number: "I", title: String(localized: "today"))
                        .chapterEntrance(appeared: appeared, delay: 0.06)

                    chapterToday
                        .padding(.horizontal, AstaraSpacing.lg)
                        .chapterEntrance(appeared: appeared, delay: 0.10)

                    // ── CHAPTER II: ASTARA SCORE ─────────────────────
                    chapterDivider(number: "II", title: String(localized: "astara_score"))
                        .chapterEntrance(appeared: appeared, delay: 0.16)

                    chapterScore
                        .chapterEntrance(appeared: appeared, delay: 0.20)

                    // ── CHAPTER III: CELESTIAL WEEK ──────────────────
                    chapterDivider(number: "III", title: String(localized: "week_360_title"))
                        .chapterEntrance(appeared: appeared, delay: 0.26)

                    chapterCelestialWeek
                        .padding(.horizontal, AstaraSpacing.lg)
                        .chapterEntrance(appeared: appeared, delay: 0.30)

                    // ── CHAPTER IV: YOUR SKY ─────────────────────────
                    chapterDivider(number: "IV", title: String(localized: "element_energy"))
                        .chapterEntrance(appeared: appeared, delay: 0.36)

                    chapterYourSky
                        .padding(.horizontal, AstaraSpacing.lg)
                        .chapterEntrance(appeared: appeared, delay: 0.40)

                    // ── CHAPTER V: RITUAL & ASK ──────────────────────
                    chapterDivider(number: "V", title: String(localized: "ritual_journal"))
                        .chapterEntrance(appeared: appeared, delay: 0.46)

                    chapterRitualAsk
                        .padding(.horizontal, AstaraSpacing.lg)
                        .chapterEntrance(appeared: appeared, delay: 0.50)

                    // ── CHAPTER VI: CONNECTIONS (only when data exists)
                    if !store.friendDynamics.isEmpty {
                        chapterDivider(number: "VI", title: String(localized: "synastry_feed"))
                            .chapterEntrance(appeared: appeared, delay: 0.56)

                        chapterConnections
                            .padding(.horizontal, AstaraSpacing.lg)
                            .chapterEntrance(appeared: appeared, delay: 0.60)
                    }

                    // ── FOOTER ───────────────────────────────────────
                    footer
                        .padding(.bottom, AstaraSpacing.xxxl)
                        .chapterEntrance(appeared: appeared, delay: 0.64)
                }
                .onAppear {
                    if !appeared {
                        withAnimation { appeared = true }
                    }
                }
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
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AstaraColors.backgroundDeep)
        }
        .sheet(isPresented: Binding(
            get: { store.showTimeTravel },
            set: { store.send(.openTimeTravel($0)) }
        )) {
            timeTravelSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AstaraColors.backgroundDeep)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(AstaraTypography.sectionMark)
                    .foregroundStyle(AstaraColors.textTertiary)
                    .tracking(2)
                    .textCase(.uppercase)

                HStack(spacing: AstaraSpacing.sm) {
                    Text("ASTARA")
                        .font(.custom("CormorantGaramond-Bold", size: 34))
                        .foregroundStyle(AstaraColors.gold)
                        .tracking(8)
                        .shadow(color: AstaraColors.goldGlow.opacity(0.5), radius: 12)
                    MoonPhaseView(size: 28, showName: false)
                        .offset(y: 2)
                }

                Text(AstaraDateFormatters.displayDate.string(from: Date()))
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }

            Spacer()

            Button {
                store.send(.selectTab(.profile))
            } label: {
                ZStack {
                    Circle()
                        .fill(AstaraColors.gold.opacity(0.08))
                        .frame(width: 48, height: 48)
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [AstaraColors.gold.opacity(0.5), AstaraColors.gold.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 48, height: 48)
                    Text(store.userSunSign.symbol)
                        .font(.system(size: 22))
                }
            }
        }
        .padding(.bottom, AstaraSpacing.xs)
    }

    // MARK: - Chapter I: TODAY

    private var chapterToday: some View {
        VStack(spacing: AstaraSpacing.md) {
            if store.isLoading && store.dailyHoroscope == nil {
                shimmerChronicle
            } else if let horoscope = store.dailyHoroscope {
                // Hero daily chronicle card
                VStack(alignment: .leading, spacing: AstaraSpacing.md) {
                    // Energy + streak inline
                    HStack {
                        HStack(spacing: AstaraSpacing.xs) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(AstaraColors.ember400)
                            Text(String(format: String(localized: "streak_days"), store.streakCount))
                                .font(AstaraTypography.sectionMark)
                                .foregroundStyle(AstaraColors.textTertiary)
                                .tracking(1)
                        }
                        Spacer()
                        Text("\(horoscope.energy)%")
                            .font(.custom("CormorantGaramond-SemiBold", size: 28))
                            .foregroundStyle(AstaraColors.gold)
                            .shadow(color: AstaraColors.goldGlow.opacity(0.6), radius: 8)
                        Text(String(localized: "element_energy").lowercased())
                            .font(AstaraTypography.sectionMark)
                            .foregroundStyle(AstaraColors.textTertiary)
                            .tracking(1)
                            .padding(.top, 8)
                    }

                    // Theme — hero typography
                    Text(horoscope.theme)
                        .font(AstaraTypography.heroLabel)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AstaraColors.goldLight, AstaraColors.gold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: AstaraColors.goldGlow.opacity(0.4), radius: 12)
                        .fixedSize(horizontal: false, vertical: true)

                    // Body text
                    Text(horoscope.text)
                        .font(AstaraTypography.bodyMedium)
                        .foregroundStyle(AstaraColors.textSecondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)

                    // Action row
                    HStack(spacing: AstaraSpacing.sm) {
                        microActionButton(
                            icon: "square.and.arrow.up",
                            label: String(localized: "share_daily_btn")
                        ) { store.send(.shareDailySummary) }

                        microActionButton(
                            icon: "arrow.clockwise",
                            label: String(localized: "retry")
                        ) { store.send(.retryDailyData) }
                    }
                }
                .padding(AstaraSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .chronicleCard()

                // Big Three inline (if chart exists)
                if let chart = store.userChart {
                    bigThreeInline(chart: chart)
                }

            } else if let errorMessage = store.errorMessage {
                errorBanner(message: errorMessage)
            }
        }
    }

    private var shimmerChronicle: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.md) {
            ShimmerView().frame(height: 18).frame(maxWidth: 140)
            ShimmerView().frame(height: 32).frame(maxWidth: 260)
            ShimmerView().frame(height: 15).frame(maxWidth: .infinity)
            ShimmerView().frame(height: 15).frame(maxWidth: 200)
        }
        .padding(AstaraSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusXl))
        .background(AstaraColors.cardBackground)
    }

    // MARK: - Chapter II: ASTARA SCORE

    private var chapterScore: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AstaraSpacing.md) {
                Spacer().frame(width: AstaraSpacing.lg - AstaraSpacing.md)

                scoreChronicle(
                    title: String(localized: "score_love"),
                    value: store.astaraScore.love,
                    color: AstaraColors.water,
                    icon: "heart.fill"
                )
                scoreChronicle(
                    title: String(localized: "score_work"),
                    value: store.astaraScore.work,
                    color: AstaraColors.earth,
                    icon: "briefcase.fill"
                )
                scoreChronicle(
                    title: String(localized: "score_energy"),
                    value: store.astaraScore.energy,
                    color: AstaraColors.ember400,
                    icon: "bolt.fill"
                )
                scoreChronicle(
                    title: String(localized: "score_focus"),
                    value: store.astaraScore.focus,
                    color: AstaraColors.air,
                    icon: "target"
                )

                Spacer().frame(width: AstaraSpacing.lg - AstaraSpacing.md)
            }
        }
    }

    private func scoreChronicle(title: String, value: Int, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(color.opacity(0.8))

            Text("\(value)")
                .font(AstaraTypography.heroNumber)
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.3), radius: 10)
                .lineLimit(1)

            Text(title.uppercased())
                .font(AstaraTypography.sectionMark)
                .foregroundStyle(AstaraColors.textTertiary)
                .tracking(2)
        }
        .padding(.horizontal, AstaraSpacing.lg)
        .padding(.vertical, AstaraSpacing.md)
        .frame(width: 148, alignment: .leading)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)
                .padding(.vertical, 12)
        }
        .background(
            LinearGradient(
                colors: [AstaraColors.chronicleGradientTop, AstaraColors.backgroundDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.08), radius: 12, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(String(format: String(localized: "score_accessibility_value", defaultValue: "%d / 100"), value))
    }

    // MARK: - Chapter III: CELESTIAL WEEK

    private var chapterCelestialWeek: some View {
        VStack(spacing: AstaraSpacing.md) {
            // Active retro alert (inline banner)
            if !store.activeRetrogrades.isEmpty || !store.upcomingRetrogrades.isEmpty {
                retroInlineBanner
            }

            // Week 360 transits
            VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
                if store.weekTransits.isEmpty && store.isLoading {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: AstaraSpacing.sm) {
                            ShimmerView().frame(width: 28, height: 28).clipShape(Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                ShimmerView().frame(height: 13).frame(maxWidth: .infinity)
                                ShimmerView().frame(height: 11).frame(width: 160)
                            }
                        }
                    }
                } else if store.weekTransits.isEmpty {
                    Text(String(localized: "weekly_flow_loading"))
                        .font(AstaraTypography.bodySmall)
                        .foregroundStyle(AstaraColors.textSecondary)
                } else {
                    ForEach(store.weekTransits.prefix(3)) { transit in
                        transitRow(transit)
                    }

                    if !store.isPremium && store.weekTransits.count > 3 {
                        ZStack(alignment: .bottom) {
                            if let extra = store.weekTransits.dropFirst(3).first {
                                transitRow(extra).blur(radius: 6).allowsHitTesting(false)
                            }
                            PremiumLockOverlay(
                                title: String(localized: "week360_premium_title"),
                                subtitle: String(localized: "week360_premium_body")
                            ) {
                                store.send(.profile(.setSubscriptionPresented(true)))
                            }
                            .frame(height: 140)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
                    }
                }
            }
            .padding(AstaraSpacing.md)
            .astaraCard()
        }
    }

    private var retroInlineBanner: some View {
        HStack(spacing: AstaraSpacing.sm) {
            Circle()
                .fill(AstaraColors.ember400)
                .frame(width: 7, height: 7)
                .shadow(color: AstaraColors.ember400.opacity(0.7), radius: 4)

            if let retro = store.activeRetrogrades.first {
                Text("\(retro.planet.turkishName) \(String(localized: "retrograde_active", defaultValue: "retrosu aktif"))")
                    .font(AstaraTypography.labelMedium)
                    .foregroundStyle(AstaraColors.textPrimary)
            } else if let upcoming = store.upcomingRetrogrades.first {
                Text("\(upcoming.planet.turkishName) \(String(localized: "retrograde_upcoming", defaultValue: "retrosu yaklaşıyor"))")
                    .font(AstaraTypography.labelMedium)
                    .foregroundStyle(AstaraColors.textSecondary)
            }
            Spacer()
            Text("\(store.activeRetrogrades.count + store.upcomingRetrogrades.count)")
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
        }
        .padding(.horizontal, AstaraSpacing.md)
        .padding(.vertical, AstaraSpacing.sm)
        .background(AstaraColors.ember400.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd)
                .stroke(AstaraColors.ember400.opacity(0.25), lineWidth: 1)
        )
    }

    private func transitRow(_ transit: Transit) -> some View {
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

    // MARK: - Chapter IV: YOUR SKY

    private var chapterYourSky: some View {
        VStack(spacing: AstaraSpacing.md) {
            // Element circles
            if !store.elementEnergy.isEmpty {
                HStack(spacing: 0) {
                    elementCircle(element: .fire, value: store.elementEnergy[.fire] ?? 0, emoji: "🔥")
                    elementCircle(element: .earth, value: store.elementEnergy[.earth] ?? 0, emoji: "🌿")
                    elementCircle(element: .air, value: store.elementEnergy[.air] ?? 0, emoji: "💨")
                    elementCircle(element: .water, value: store.elementEnergy[.water] ?? 0, emoji: "💧")
                }
                .padding(.vertical, AstaraSpacing.md)
                .astaraCard()
            }

            // Planet positions
            if !store.planetPositions.isEmpty {
                PlanetPositionsView(planets: store.planetPositions)
            } else if store.isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AstaraSpacing.sm) {
                        ForEach(0..<7, id: \.self) { _ in
                            ShimmerView()
                                .frame(width: 64, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
                        }
                    }
                    .padding(.horizontal, AstaraSpacing.lg)
                }
            }

            // Big Three (if chart present)
            if let chart = store.userChart {
                bigThreeInline(chart: chart)
            }

            // Last updated caption
            if let lastUpdated = store.lastUpdated {
                HStack(spacing: AstaraSpacing.xxs) {
                    Circle().fill(AstaraColors.sage400).frame(width: 5, height: 5)
                    Text("\(String(localized: "last_updated")): \(AstaraDateFormatters.timeOnly.string(from: lastUpdated))")
                        .font(AstaraTypography.caption)
                        .foregroundStyle(AstaraColors.textTertiary)
                }
            }
        }
    }

    private func bigThreeInline(chart: BirthChart) -> some View {
        HStack(spacing: 0) {
            if let sun = chart.sunSign {
                bigThreeItem(label: "\u{2609}", title: String(localized: "sun_short"), sign: sun, color: AstaraColors.gold)
            }
            if chart.sunSign != nil && chart.moonSign != nil { thinDivider }
            if let moon = chart.moonSign {
                bigThreeItem(label: "\u{263D}", title: String(localized: "moon_short"), sign: moon, color: AstaraColors.starlight)
            }
            if chart.moonSign != nil && chart.risingSign != nil { thinDivider }
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
            Text(label).font(.system(size: 14)).foregroundStyle(color)
            Text(sign.symbol).font(.system(size: 22))
            Text(sign.turkishName).font(AstaraTypography.caption).foregroundStyle(AstaraColors.textSecondary)
            Text(title).font(.system(size: 9)).foregroundStyle(AstaraColors.textTertiary).textCase(.uppercase).tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(AstaraColors.cardBorder)
            .frame(width: 1, height: 44)
    }

    private func elementCircle(element: Element, value: Int, emoji: String) -> some View {
        VStack(spacing: AstaraSpacing.xs) {
            ZStack {
                Circle().stroke(AstaraColors.cardBorder, lineWidth: 3).frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: CGFloat(value) / 100)
                    .stroke(elementColor(element), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                Text(emoji).font(.system(size: 18))
            }
            Text("\(value)%").font(AstaraTypography.caption).foregroundStyle(AstaraColors.textSecondary)
            Text(element.localizedName).font(.system(size: 10)).foregroundStyle(AstaraColors.textTertiary)
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

    // MARK: - Chapter V: RITUAL & ASK

    private var chapterRitualAsk: some View {
        VStack(spacing: AstaraSpacing.md) {
            // Ritual chronicle card
            VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
                Text(store.ritualPrompt.isEmpty ? String(localized: "ritual_loading") : store.ritualPrompt)
                    .font(AstaraTypography.heroLabel)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AstaraColors.moonCream, AstaraColors.goldLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)

                TextField(String(localized: "ritual_note_placeholder"), text: $store.moodNote.sending(\.setMoodNote))
                    .textFieldStyle(.plain)
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textPrimary)
                    .padding(.horizontal, AstaraSpacing.sm)
                    .padding(.vertical, AstaraSpacing.xs)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
                    .overlay(
                        RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd)
                            .stroke(AstaraColors.gold.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(AstaraSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .chronicleCard()

            // Mood + Ask inline row
            HStack(spacing: AstaraSpacing.sm) {
                // Mood emoji selector (compact)
                HStack(spacing: AstaraSpacing.xs) {
                    ForEach(1...5, id: \.self) { mood in
                        Button {
                            Haptics.selection()
                            store.send(.setMood(mood))
                        } label: {
                            Text(moodEmoji(mood))
                                .font(.system(size: 22))
                                .scaleEffect(store.todaysMood == mood ? 1.18 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: store.todaysMood)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AstaraSpacing.sm)
                .padding(.vertical, AstaraSpacing.sm)
                .astaraCard()

                Spacer()

                // Ask Astara oracle button
                Button {
                    Haptics.selection()
                    store.send(.openAskAstara(true))
                } label: {
                    HStack(spacing: AstaraSpacing.xs) {
                        OracleSphereView(isThinking: false)
                            .frame(width: 32, height: 32)
                            .scaleEffect(0.35)
                        Text(String(localized: "ask_astara_btn"))
                            .font(AstaraTypography.labelMedium)
                            .foregroundStyle(AstaraColors.gold)
                    }
                    .padding(.horizontal, AstaraSpacing.md)
                    .padding(.vertical, AstaraSpacing.sm)
                    .background(AstaraColors.gold.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg))
                    .overlay(
                        RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg)
                            .stroke(AstaraColors.gold.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Time Travel button
                Button {
                    Haptics.selection()
                    store.send(.openTimeTravel(true))
                    store.send(.loadTimeTravelInsight)
                } label: {
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(AstaraColors.celestialTeal)
                        .frame(width: 44, height: 44)
                        .background(AstaraColors.celestialTeal.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
                        .overlay(
                            RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd)
                                .stroke(AstaraColors.celestialTeal.opacity(0.25), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Chapter VI: CONNECTIONS

    private var chapterConnections: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            ForEach(store.friendDynamics.prefix(2)) { item in
                HStack(alignment: .top, spacing: AstaraSpacing.sm) {
                    Text(item.friendSign.symbol).font(.system(size: 20))
                    VStack(alignment: .leading, spacing: AstaraSpacing.xxs) {
                        HStack {
                            Text(item.friendName)
                                .font(AstaraTypography.labelMedium)
                                .foregroundStyle(AstaraColors.textPrimary)
                            Spacer()
                            Text("%\(item.compatibility.overallScore)")
                                .font(.custom("CormorantGaramond-SemiBold", size: 18))
                                .foregroundStyle(AstaraColors.gold)
                        }
                        Text(item.insight)
                            .font(AstaraTypography.caption)
                            .foregroundStyle(AstaraColors.textSecondary)
                        Text(item.suggestedAction)
                            .font(AstaraTypography.caption)
                            .foregroundStyle(AstaraColors.goldLight)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(AstaraColors.textTertiary)
                        .padding(.top, 2)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Haptics.selection()
                    store.send(.selectTab(.compatibility))
                }
                if item.id != store.friendDynamics.prefix(2).last?.id {
                    Divider().overlay(AstaraColors.cardBorder)
                }
            }
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: AstaraSpacing.lg) {
            OrnamentalDivider(glyph: "✦", opacity: 0.25)
                .padding(.top, AstaraSpacing.xl)
            Text("Ad astra per aspera")
                .font(.custom("CormorantGaramond-Italic", size: 15))
                .foregroundStyle(AstaraColors.textTertiary.opacity(0.5))
                .italic()
        }
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        VStack(spacing: AstaraSpacing.md) {
            ZStack {
                Circle().fill(AstaraColors.gold.opacity(0.06)).frame(width: 72, height: 72)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(AstaraColors.gold.opacity(0.45))
            }
            Text(String(localized: "error_stars_unreachable"))
                .font(AstaraTypography.titleMedium)
                .foregroundStyle(AstaraColors.textPrimary)
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

    // MARK: - Helpers

    private func chapterDivider(number: String, title: String) -> some View {
        VStack(spacing: AstaraSpacing.sm) {
            OrnamentalDivider(opacity: 0.22)
            ChapterLabel(number: number, title: title)
        }
        .padding(.vertical, AstaraSpacing.lg)
        .padding(.horizontal, AstaraSpacing.lg)
    }

    private func microActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: AstaraSpacing.xxs) {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                Text(label).font(AstaraTypography.caption)
            }
            .foregroundStyle(AstaraColors.textTertiary)
            .padding(.horizontal, AstaraSpacing.sm)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.04))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func moodEmoji(_ value: Int) -> String {
        switch value {
        case 1: "😞"
        case 2: "😕"
        case 3: "😐"
        case 4: "🙂"
        default: "😄"
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return String(localized: "good_morning")
        case 12..<18: return String(localized: "good_afternoon")
        case 18..<22: return String(localized: "good_evening")
        default: return String(localized: "good_night")
        }
    }

    // MARK: - Share Card (screenshot-ready)

    private func dailyShareCard(caption: String) -> some View {
        ZStack {
            GradientBackground(ambient: .home)
            StarfieldView(starCount: 40).opacity(0.2)
            VStack(spacing: AstaraSpacing.lg) {
                Text("ASTARA")
                    .font(.custom("CormorantGaramond-Bold", size: 48))
                    .foregroundStyle(AstaraColors.gold)
                    .tracking(8)
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

    // MARK: - Ask Astara Sheet

    private var askAstaraSheet: some View {
        ZStack {
            GradientBackground(ambient: .home)
            StarfieldView(starCount: 40).opacity(0.25)

            if store.askQuotaRemaining == 0 && !store.isPremium {
                askQuotaExhaustedView
            } else {
                askAstaraContent
            }
        }
    }

    private var askSheetHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AstaraSpacing.xxs) {
                Text(String(localized: "ask_astara"))
                    .font(AstaraTypography.displayMedium)
                    .foregroundStyle(AstaraColors.textPrimary)
                Text(String(localized: "ask_astara_subtitle"))
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
                    .lineLimit(2)
            }
            Spacer()
            Button {
                store.send(.openAskAstara(false))
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AstaraColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "close_button"))
        }
    }

    private var askQuotaPill: some View {
        HStack(spacing: AstaraSpacing.xxs) {
            Image(systemName: store.isPremium ? "sparkles" : "sparkle")
                .font(.system(size: 10, weight: .medium))
            Text(store.isPremium
                 ? String(localized: "ask_quota_unlimited")
                 : "\(store.askQuotaRemaining) · \(String(localized: "ask_quota_remaining"))")
                .font(AstaraTypography.caption)
        }
        .foregroundStyle(store.isPremium ? AstaraColors.gold : AstaraColors.textSecondary)
        .padding(.horizontal, AstaraSpacing.sm)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(
                (store.isPremium ? AstaraColors.gold : AstaraColors.textSecondary)
                    .opacity(0.08)
            )
        )
        .overlay(
            Capsule().stroke(
                (store.isPremium ? AstaraColors.gold : AstaraColors.cardBorder)
                    .opacity(0.35),
                lineWidth: 1
            )
        )
    }

    private var askAstaraContent: some View {
        VStack(spacing: 0) {
            askSheetHeader
                .padding(.horizontal, AstaraSpacing.lg)
                .padding(.top, AstaraSpacing.md)

            HStack { askQuotaPill; Spacer() }
                .padding(.horizontal, AstaraSpacing.lg)
                .padding(.top, AstaraSpacing.sm)

            ScrollView(showsIndicators: false) {
                VStack(spacing: AstaraSpacing.lg) {
                    OracleSphereView(isThinking: store.isAskingAstara)
                        .frame(height: 180)
                        .padding(.top, AstaraSpacing.md)

                    if store.isAskingAstara {
                        askThinkingLabel
                            .transition(.opacity)
                    } else if let response = store.askResponse {
                        askAnswerCard(response)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        askSuggestions
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, AstaraSpacing.lg)
                .padding(.bottom, AstaraSpacing.md)
                .frame(maxWidth: .infinity)
                .animation(.easeInOut(duration: 0.25), value: store.isAskingAstara)
                .animation(.easeInOut(duration: 0.25), value: store.askResponse)
            }
            .frame(maxHeight: .infinity)

            askInputBar
                .padding(.horizontal, AstaraSpacing.lg)
                .padding(.top, AstaraSpacing.sm)
                .padding(.bottom, AstaraSpacing.md)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Rectangle()
                                .fill(AstaraColors.cardBorder)
                                .frame(height: 1),
                            alignment: .top
                        )
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var askThinkingLabel: some View {
        HStack(spacing: AstaraSpacing.xs) {
            Text(String(localized: "ask_thinking"))
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textSecondary)
            ThinkingDotsView()
        }
    }

    private func askAnswerCard(_ response: String) -> some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            HStack(spacing: AstaraSpacing.xxs) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 11, weight: .semibold))
                Text(String(localized: "ask_answer_label"))
                    .font(AstaraTypography.sectionMark)
                    .tracking(2)
                    .textCase(.uppercase)
            }
            .foregroundStyle(AstaraColors.gold)

            Text(response)
                .font(AstaraTypography.bodyLarge)
                .foregroundStyle(AstaraColors.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AstaraSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .astaraCard()
    }

    private var askSuggestions: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text(String(localized: "ask_empty_prompt"))
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, AstaraSpacing.xs)

            Text(String(localized: "ask_suggestions_title"))
                .font(AstaraTypography.sectionMark)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(AstaraColors.textTertiary)

            VStack(spacing: AstaraSpacing.xs) {
                askSuggestionChip(String(localized: "ask_suggested_love"))
                askSuggestionChip(String(localized: "ask_suggested_work"))
                askSuggestionChip(String(localized: "ask_suggested_today"))
            }
        }
    }

    private func askSuggestionChip(_ text: String) -> some View {
        Button {
            Haptics.selection()
            store.send(.setAskQuestionText(text))
        } label: {
            HStack {
                Text(text)
                    .font(AstaraTypography.bodyMedium)
                    .foregroundStyle(AstaraColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AstaraColors.gold.opacity(0.7))
            }
            .padding(.horizontal, AstaraSpacing.md)
            .padding(.vertical, AstaraSpacing.sm)
            .background(AstaraColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd)
                    .stroke(AstaraColors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var askInputBar: some View {
        let trimmed = store.askQuestionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let canSubmit = !trimmed.isEmpty && !store.isAskingAstara
        return HStack(alignment: .bottom, spacing: AstaraSpacing.sm) {
            TextField(
                String(localized: "ask_placeholder"),
                text: $store.askQuestionText.sending(\.setAskQuestionText),
                axis: .vertical
            )
            .lineLimit(1...4)
            .textFieldStyle(.plain)
            .font(AstaraTypography.bodyMedium)
            .foregroundStyle(AstaraColors.textPrimary)
            .tint(AstaraColors.gold)
            .padding(.horizontal, AstaraSpacing.md)
            .padding(.vertical, AstaraSpacing.sm)
            .background(AstaraColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg)
                    .stroke(AstaraColors.cardBorder, lineWidth: 1)
            )
            .disabled(store.isAskingAstara)
            .submitLabel(.send)
            .onSubmit {
                if canSubmit { store.send(.submitAskQuestion) }
            }

            Button {
                Haptics.medium()
                store.send(.submitAskQuestion)
            } label: {
                ZStack {
                    Circle()
                        .fill(canSubmit ? AstaraColors.gold : AstaraColors.gold.opacity(0.2))
                        .frame(width: 44, height: 44)
                    if store.isAskingAstara {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AstaraColors.backgroundDeep)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(
                                canSubmit ? AstaraColors.backgroundDeep : AstaraColors.textTertiary
                            )
                    }
                }
                .shadow(
                    color: canSubmit ? AstaraColors.gold.opacity(0.35) : .clear,
                    radius: 10
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .accessibilityLabel(String(localized: "ask_button"))
        }
    }

    private var askQuotaExhaustedView: some View {
        VStack(spacing: 0) {
            askSheetHeader
                .padding(.horizontal, AstaraSpacing.lg)
                .padding(.top, AstaraSpacing.md)

            Spacer()

            VStack(spacing: AstaraSpacing.lg) {
                OracleSphereView(isThinking: false)
                    .frame(height: 160)
                    .opacity(0.55)
                    .grayscale(0.7)
                Text(String(localized: "ask_quota_exhausted_title"))
                    .font(AstaraTypography.titleLarge)
                    .foregroundStyle(AstaraColors.textPrimary)
                    .multilineTextAlignment(.center)
                Text(String(localized: "ask_quota_exhausted_body"))
                    .font(AstaraTypography.bodyMedium)
                    .foregroundStyle(AstaraColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AstaraSpacing.lg)
                AstaraButton(title: String(localized: "go_premium"), style: .primary) {
                    store.send(.openAskAstara(false))
                    store.send(.profile(.setSubscriptionPresented(true)))
                }
                .frame(maxWidth: 280)
            }
            .padding(.horizontal, AstaraSpacing.lg)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Time Travel Sheet

    private var timeTravelSheet: some View {
        let now = Date()
        let minDate = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let maxDate = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now

        return ZStack {
            GradientBackground(ambient: .home)
            StarfieldView(starCount: 30).opacity(0.2)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AstaraSpacing.lg) {
                    timeTravelHeader
                    timeTravelDatePill

                    DatePicker(
                        String(localized: "time_travel_btn"),
                        selection: $store.timeTravelDate.sending(\.setTimeTravelDate),
                        in: minDate...maxDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(AstaraColors.gold)
                    .colorScheme(.dark)
                    .padding(AstaraSpacing.sm)
                    .background(AstaraColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg))
                    .overlay(
                        RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg)
                            .stroke(AstaraColors.cardBorder, lineWidth: 1)
                    )

                    if let insight = store.timeTravelInsight {
                        timeTravelInsightCard(insight)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(AstaraSpacing.lg)
                .animation(.easeInOut(duration: 0.25), value: store.timeTravelInsight)
            }
        }
    }

    private var timeTravelHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AstaraSpacing.xxs) {
                Text(String(localized: "time_travel_btn"))
                    .font(AstaraTypography.displayMedium)
                    .foregroundStyle(AstaraColors.textPrimary)
                Text(String(localized: "time_travel_subtitle"))
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }
            Spacer()
            Button {
                store.send(.openTimeTravel(false))
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AstaraColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "close_button"))
        }
    }

    private var timeTravelDatePill: some View {
        HStack(spacing: AstaraSpacing.xs) {
            Image(systemName: "sparkle")
                .font(.system(size: 10, weight: .medium))
            Text(AstaraDateFormatters.displayDate.string(from: store.timeTravelDate))
                .font(AstaraTypography.labelMedium)
            Text("·")
                .foregroundStyle(AstaraColors.textTertiary)
            Text(relativeDayString(for: store.timeTravelDate))
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
        }
        .foregroundStyle(AstaraColors.gold)
        .padding(.horizontal, AstaraSpacing.md)
        .padding(.vertical, 6)
        .background(Capsule().fill(AstaraColors.gold.opacity(0.08)))
        .overlay(Capsule().stroke(AstaraColors.gold.opacity(0.35), lineWidth: 1))
    }

    private func timeTravelInsightCard(_ insight: TimeTravelInsight) -> some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text(insight.title)
                .font(AstaraTypography.titleMedium)
                .foregroundStyle(AstaraColors.gold)

            Text(insight.summary)
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(AstaraColors.cardBorder)

            HStack(alignment: .top, spacing: AstaraSpacing.xs) {
                Image(systemName: "arrow.forward.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AstaraColors.gold)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "time_travel_action_label"))
                        .font(AstaraTypography.sectionMark)
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(AstaraColors.textTertiary)
                    Text(insight.action)
                        .font(AstaraTypography.bodyMedium)
                        .foregroundStyle(AstaraColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(AstaraSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .astaraCard()
    }

    private func relativeDayString(for date: Date) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTarget = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget).day ?? 0
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        if days == 0 {
            return formatter.localizedString(from: DateComponents(day: 0))
        }
        return formatter.localizedString(from: DateComponents(day: days))
    }
}

// MARK: - Thinking Dots

private struct ThinkingDotsView: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(AstaraColors.gold)
                    .frame(width: 5, height: 5)
                    .opacity(animate ? 1.0 : 0.25)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

// MARK: - Chapter entrance animation

private extension View {
    func chapterEntrance(appeared: Bool, delay: Double) -> some View {
        self
            .scaleEffect(appeared ? 1.0 : 0.96)
            .opacity(appeared ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.50).delay(delay), value: appeared)
    }
}
