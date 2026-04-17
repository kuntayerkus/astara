import SwiftUI
import ComposableArchitecture

struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>
    /// Optional — passed by HomeView so the "Arkadaşlar" link can push the
    /// Friends feature. Older call-sites (previews, tests) can omit it.
    var friendsStore: StoreOf<FriendsFeature>? = nil
    #if DEBUG
    @State private var showDebugPanel = false
    #endif
    @State private var showFriends = false
    @State private var showClaimHandle = false

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

                    // Social section (v2 — Friend System)
                    if friendsStore != nil {
                        section(title: "Sosyal") {
                            socialSection
                        }
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
            .refreshable {
                Haptics.selection()
                store.send(.onAppear)
            }
        }
        .onAppear { store.send(.onAppear) }
        #if DEBUG
        .sheet(isPresented: $showDebugPanel) {
            DebugPanelView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        #endif
        .sheet(isPresented: Binding(
            get: { store.showSubscription },
            set: { store.send(.setSubscriptionPresented($0)) }
        )) {
            SubscriptionView(store: store)
        }
        .sheet(isPresented: Binding(
            get: { store.showEditBirthData },
            set: { if !$0 { store.send(.dismissEditBirthData) } }
        )) {
            EditBirthDataView(
                onSave: { store.send(.birthDataSaved) }
            )
        }
        .sheet(isPresented: $showFriends) {
            if let friendsStore {
                NavigationStack {
                    FriendsListView(store: friendsStore)
                }
            }
        }
        .sheet(isPresented: $showClaimHandle) {
            NavigationStack {
                ClaimHandleView()
            }
        }
    }

    private var socialSection: some View {
        VStack(spacing: AstaraSpacing.sm) {
            Button {
                showFriends = true
            } label: {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(AstaraColors.gold)
                    Text("Arkadaşlar")
                        .font(AstaraTypography.bodyLarge)
                        .foregroundStyle(AstaraColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AstaraColors.textTertiary)
                }
                .padding()
                .modifier(AstaraCardModifier())
            }
            .buttonStyle(.plain)

            Button {
                showClaimHandle = true
            } label: {
                HStack {
                    Image(systemName: "at")
                        .foregroundStyle(AstaraColors.gold)
                    Text("Kullanıcı Adı")
                        .font(AstaraTypography.bodyLarge)
                        .foregroundStyle(AstaraColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AstaraColors.textTertiary)
                }
                .padding()
                .modifier(AstaraCardModifier())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: AstaraSpacing.xxs) {
                Text(store.userName.isEmpty ? String(localized: "profile") : store.userName)
                    .font(AstaraTypography.displayMedium)
                    .foregroundStyle(AstaraColors.textPrimary)
                    #if DEBUG
                    .highPriorityGesture(
                        LongPressGesture(minimumDuration: 1.5)
                            .onEnded { _ in showDebugPanel = true }
                    )
                    #endif

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
        Button { store.send(.setSubscriptionPresented(true)) } label: {
            HStack(spacing: AstaraSpacing.md) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AstaraColors.gold)
                    .shadow(color: AstaraColors.gold.opacity(0.35), radius: 8, y: 2)

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
        .shadow(color: AstaraColors.gold.opacity(0.12), radius: 16, y: 8)
    }

    private var premiumActiveBadge: some View {
        HStack(spacing: AstaraSpacing.sm) {
            Image(systemName: "star.circle.fill")
                .foregroundStyle(AstaraColors.gold)
                .shadow(color: AstaraColors.gold.opacity(0.35), radius: 8, y: 2)
            Text(String(localized: "premium_active"))
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.gold)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AstaraColors.sage400)
        }
        .padding(AstaraSpacing.md)
        .background(
            LinearGradient(
                colors: [AstaraColors.gold.opacity(0.14), AstaraColors.cardBackground],
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

    // MARK: - Birth Data

    private var birthDataRow: some View {
        Button { store.send(.showEditBirthData) } label: {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "calendar")
                        .frame(width: 28)
                        .foregroundStyle(AstaraColors.gold)

                    Text(String(localized: "edit_birth_data"))
                        .font(AstaraTypography.bodyMedium)
                        .foregroundStyle(AstaraColors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(AstaraColors.textTertiary)
                }
                .padding(AstaraSpacing.md)

                Divider().background(AstaraColors.cardBorder)

                VStack(spacing: AstaraSpacing.xs) {
                    birthInfoRow(
                        icon: "birthday.cake",
                        label: String(localized: "birth_date"),
                        value: AstaraDateFormatters.longDate.string(from: store.birthDate)
                    )
                    if !store.birthTimeUnknown, let time = store.birthTime {
                        birthInfoRow(
                            icon: "clock",
                            label: String(localized: "birth_time"),
                            value: AstaraDateFormatters.timeOnly.string(from: time)
                        )
                    }
                    if !store.birthCity.isEmpty {
                        birthInfoRow(
                            icon: "mappin.circle",
                            label: String(localized: "birth_city"),
                            value: store.birthCity
                        )
                    }
                }
                .padding(.horizontal, AstaraSpacing.md)
                .padding(.vertical, AstaraSpacing.sm)
            }
        }
        .buttonStyle(.plain)
    }

    private func birthInfoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AstaraSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(AstaraColors.textTertiary)
                .frame(width: 20)

            Text(label)
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)

            Spacer()

            Text(value)
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textSecondary)
        }
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
            settingsRow(
                icon: "globe",
                title: String(localized: "language"),
                value: Locale.current.localizedString(forLanguageCode: "tr") ?? "Türkçe"
            )
            Divider().background(AstaraColors.cardBorder).padding(.leading, AstaraSpacing.xxl + AstaraSpacing.sm)
            settingsRow(icon: "envelope", title: String(localized: "contact"), value: "")
            Divider().background(AstaraColors.cardBorder).padding(.leading, AstaraSpacing.xxl + AstaraSpacing.sm)
            settingsRow(icon: "doc.text", title: String(localized: "privacy_policy"), value: "")
            Divider().background(AstaraColors.cardBorder).padding(.leading, AstaraSpacing.xxl + AstaraSpacing.sm)
            settingsRow(
                icon: "info.circle",
                title: String(localized: "app_version"),
                value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
            )
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
