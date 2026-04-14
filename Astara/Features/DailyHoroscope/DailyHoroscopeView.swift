import SwiftUI
import ComposableArchitecture

struct DailyHoroscopeView: View {
    @Bindable var store: StoreOf<DailyHoroscopeFeature>

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Navigation header
                header
                    .padding(.horizontal, AstaraSpacing.lg)
                    .padding(.top, AstaraSpacing.md)
                    .padding(.bottom, AstaraSpacing.sm)

                // Sign selector carousel
                SignSelectorView(selectedSign: store.selectedSign) { sign in
                    Haptics.selection()
                    store.send(.selectSign(sign))
                }
                .padding(.bottom, AstaraSpacing.md)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AstaraSpacing.md) {
                        if store.isLoading {
                            ShimmerView()
                                .frame(height: 300)
                                .padding(.horizontal, AstaraSpacing.lg)
                        } else if let horoscope = store.currentHoroscope {
                            HoroscopeCardView(horoscope: horoscope)
                                .padding(.horizontal, AstaraSpacing.lg)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            emptyState
                        }

                        if let errorMessage = store.errorMessage {
                            Text(errorMessage)
                                .font(AstaraTypography.caption)
                                .foregroundStyle(AstaraColors.ember400)
                                .padding(.horizontal, AstaraSpacing.lg)
                        }

                        // Archive button
                        Button {
                            Haptics.selection()
                            store.send(.toggleArchive)
                        } label: {
                            HStack(spacing: AstaraSpacing.xs) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 14))
                                Text(String(localized: "view_archive"))
                                    .font(AstaraTypography.labelMedium)
                            }
                            .foregroundStyle(AstaraColors.textTertiary)
                            .padding(.vertical, AstaraSpacing.sm)
                        }
                        .padding(.top, AstaraSpacing.sm)
                    }
                    .padding(.bottom, AstaraSpacing.xxxl)
                    .animation(.easeInOut(duration: 0.25), value: store.selectedSign)
                }
                .refreshable {
                    Haptics.selection()
                    store.send(.refreshHoroscopes)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { store.showArchive },
            set: { if !$0 { store.send(.toggleArchive) } }
        )) {
            ArchiveView(sign: store.selectedSign)
        }
        .onAppear {
            store.send(.onAppear(userSign: store.selectedSign))
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "daily_horoscope"))
                    .font(AstaraTypography.displayMedium)
                    .foregroundStyle(AstaraColors.textPrimary)

                Text(todayFormatted)
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textTertiary)
            }

            Spacer()

            // Sun/moon phase indicator
            Image(systemName: "sun.max.fill")
                .font(.system(size: 28))
                .foregroundStyle(AstaraColors.gold)
        }
    }

    private var todayFormatted: String {
        AstaraDateFormatters.displayDate.string(from: Date())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AstaraSpacing.md) {
            Image(systemName: "moon.stars")
                .font(.system(size: 48))
                .foregroundStyle(AstaraColors.gold.opacity(0.3))

            Text(String(localized: "no_horoscope_available"))
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AstaraSpacing.xxxl)
    }
}

#Preview {
    DailyHoroscopeView(
        store: Store(initialState: DailyHoroscopeFeature.State(
            horoscopes: ZodiacSign.allCases.map { sign in
                DailyHoroscope(
                    sign: sign,
                    date: "2026-04-13",
                    text: "Bugün enerjin yüksek ve odaklanma gücün zirvedeyken fırsatları değerlendirmek için harika bir gün.",
                    energy: Int.random(in: 40...95),
                    theme: "Dönüşüm",
                    tip: "Sezgilerine güven.",
                    luckyNumber: 7,
                    luckyColor: "Mor"
                )
            },
            selectedSign: .pisces
        )) {
            DailyHoroscopeFeature()
        }
    )
}
