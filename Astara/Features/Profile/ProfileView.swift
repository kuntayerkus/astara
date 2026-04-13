import SwiftUI
import ComposableArchitecture

struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AstaraSpacing.lg) {
                    header
                        .padding(.horizontal, AstaraSpacing.lg)
                        .padding(.top, AstaraSpacing.md)

                    // Premium banner
                    if !store.isPremium {
                        premiumBanner
                            .padding(.horizontal, AstaraSpacing.lg)
                    } else {
                        premiumActiveBadge
                            .padding(.horizontal, AstaraSpacing.lg)
                    }

                    // Birth data section
                    section(title: String(localized: "birth_data")) {
                        birthDataRow
                    }

                    // Notifications section
                    section(title: String(localized: "notifications")) {
                        notificationsSection
                    }

                    // App section
                    section(title: String(localized: "app_settings")) {
                        appSection
                    }

                    Spacer(minLength: AstaraSpacing.xxxl)
                }
                .padding(.bottom, AstaraSpacing.xxxl)
            }
        }
        .onAppear { store.send(.onAppear) }
        .sheet(isPresented: Binding(
            get: { store.showSubscription },
            set: { if !$0 { store.send(.toggleSubscription) } }
        )) {
            SubscriptionView(isPremium: store.isPremium)
        }
        .sheet(isPresented: Binding(
            get: { store.showEditBirthData },
            set: { if !$0 { store.send(.toggleEditBirthData) } }
        )) {
            EditBirthDataView()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: AstaraSpacing.xxs) {
                Text(store.userName.isEmpty ? String(localized: "profile") : store.userName)
                    .font(AstaraTypography.displayMedium)
                    .foregroundStyle(AstaraColors.textPrimary)

                if !store.birthCity.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11))
                        Text(store.birthCity)
                            .font(AstaraTypography.bodySmall)
                    }
                    .foregroundStyle(AstaraColors.textTertiary)
                }
            }

            Spacer()

            // Avatar placeholder
            Circle()
                .fill(AstaraColors.gold.opacity(0.15))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AstaraColors.gold.opacity(0.5))
                )
        }
    }

    // MARK: - Premium

    private var premiumBanner: some View {
        Button { store.send(.toggleSubscription) } label: {
            HStack(spacing: AstaraSpacing.md) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AstaraColors.gold)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "upgrade_to_premium"))
                        .font(AstaraTypography.labelLarge)
                        .foregroundStyle(AstaraColors.textPrimary)

                    Text(String(localized: "premium_teaser"))
                        .font(AstaraTypography.caption)
                        .foregroundStyle(AstaraColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(AstaraColors.textTertiary)
            }
            .padding(AstaraSpacing.md)
            .background(
                LinearGradient(
                    colors: [AstaraColors.gold.opacity(0.12), AstaraColors.goldDark.opacity(0.06)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg)
                    .stroke(AstaraColors.gold.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var premiumActiveBadge: some View {
        HStack(spacing: AstaraSpacing.sm) {
            Image(systemName: "star.circle.fill")
                .foregroundStyle(AstaraColors.gold)
            Text(String(localized: "premium_active"))
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.gold)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AstaraColors.sage400)
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    // MARK: - Birth Data

    private var birthDataRow: some View {
        Button { store.send(.toggleEditBirthData) } label: {
            HStack {
                Image(systemName: "calendar")
                    .frame(width: 28)
                    .foregroundStyle(AstaraColors.gold)

                Text(String(localized: "edit_birth_data"))
                    .font(AstaraTypography.bodyMedium)
                    .foregroundStyle(AstaraColors.textPrimary)

                Spacer()

                Text(store.birthDate, style: .date)
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textTertiary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(AstaraColors.textTertiary)
            }
            .padding(AstaraSpacing.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "bell.fill")
                    .frame(width: 28)
                    .foregroundStyle(AstaraColors.gold)

                Text(String(localized: "daily_notifications"))
                    .font(AstaraTypography.bodyMedium)
                    .foregroundStyle(AstaraColors.textPrimary)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { store.notificationsEnabled },
                    set: { store.send(.toggleNotifications($0)) }
                ))
                .tint(AstaraColors.gold)
                .labelsHidden()
            }
            .padding(AstaraSpacing.md)

            if store.notificationsEnabled {
                Divider().background(AstaraColors.cardBorder)

                HStack {
                    Image(systemName: "clock")
                        .frame(width: 28)
                        .foregroundStyle(AstaraColors.textTertiary)

                    Text(String(localized: "notification_time"))
                        .font(AstaraTypography.bodyMedium)
                        .foregroundStyle(AstaraColors.textPrimary)

                    Spacer()

                    Stepper(
                        "\(store.dailyNotificationHour):00",
                        value: Binding(
                            get: { store.dailyNotificationHour },
                            set: { store.send(.setDailyNotificationHour($0)) }
                        ),
                        in: 7...22
                    )
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textSecondary)
                }
                .padding(AstaraSpacing.md)
            }
        }
    }

    // MARK: - App Section

    private var appSection: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "globe", title: String(localized: "language"), value: "Türkçe")
            Divider().background(AstaraColors.cardBorder).padding(.leading, AstaraSpacing.xxl + AstaraSpacing.sm)
            settingsRow(icon: "envelope", title: String(localized: "contact"), value: "")
            Divider().background(AstaraColors.cardBorder).padding(.leading, AstaraSpacing.xxl + AstaraSpacing.sm)
            settingsRow(icon: "doc.text", title: String(localized: "privacy_policy"), value: "")
        }
    }

    private func settingsRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(AstaraColors.textTertiary)

            Text(title)
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textPrimary)

            Spacer()

            if !value.isEmpty {
                Text(value)
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(AstaraColors.textTertiary)
        }
        .padding(AstaraSpacing.md)
    }

    // MARK: - Section Wrapper

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.xs) {
            Text(title.uppercased())
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
                .tracking(1)
                .padding(.horizontal, AstaraSpacing.lg)

            VStack(spacing: 0) {
                content()
            }
            .astaraCard()
            .padding(.horizontal, AstaraSpacing.lg)
        }
    }
}

#Preview {
    ProfileView(
        store: Store(initialState: ProfileFeature.State(
            userName: "Ayşe",
            birthCity: "İstanbul",
            isPremium: false
        )) {
            ProfileFeature()
        }
    )
}
