import SwiftUI
import ComposableArchitecture

struct BirthDataInputView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                Button {
                    store.send(.previousStep)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(AstaraColors.gold)
                        .padding(AstaraSpacing.sm)
                }
                Spacer()

                // Step indicator
                Text(stepIndicator)
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)

                Spacer()
                // Spacer for symmetry
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, AstaraSpacing.md)

            ScrollView {
                VStack(spacing: AstaraSpacing.xl) {
                    switch store.currentStep {
                    case .birthDate:
                        birthDateSection
                    case .birthTime:
                        birthTimeSection
                    case .birthCity:
                        birthCitySection
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, AstaraSpacing.lg)
                .padding(.top, AstaraSpacing.xl)
            }

            Spacer()

            // Next button
            AstaraButton(
                title: String(localized: "continue"),
                style: .primary,
                isDisabled: !canContinue
            ) {
                store.send(.nextStep)
            }
            .padding(.horizontal, AstaraSpacing.lg)
            .padding(.bottom, AstaraSpacing.xxl)
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: String {
        switch store.currentStep {
        case .birthDate: "1/3"
        case .birthTime: "2/3"
        case .birthCity: "3/3"
        default: ""
        }
    }

    // MARK: - Can Continue

    private var canContinue: Bool {
        switch store.currentStep {
        case .birthDate: true
        case .birthTime: true
        case .birthCity: store.selectedCity != nil
        default: true
        }
    }

    // MARK: - Birth Date Section

    private var birthDateSection: some View {
        VStack(spacing: AstaraSpacing.lg) {
            Text(String(localized: "when_were_you_born"))
                .font(AstaraTypography.displayMedium)
                .foregroundStyle(AstaraColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "birth_date_subtitle"))
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textSecondary)
                .multilineTextAlignment(.center)

            DatePicker(
                "",
                selection: $store.birthDate.sending(\.setBirthDate),
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .tint(AstaraColors.gold)
        }
    }

    // MARK: - Birth Time Section

    private var birthTimeSection: some View {
        VStack(spacing: AstaraSpacing.lg) {
            Text(String(localized: "what_time"))
                .font(AstaraTypography.displayMedium)
                .foregroundStyle(AstaraColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "birth_time_subtitle"))
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textSecondary)
                .multilineTextAlignment(.center)

            if !store.birthTimeUnknown {
                DatePicker(
                    "",
                    selection: $store.birthTime.sending(\.setBirthTime),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .tint(AstaraColors.gold)
            }

            // "I don't know" toggle
            Button {
                store.send(.toggleBirthTimeUnknown)
            } label: {
                HStack(spacing: AstaraSpacing.xs) {
                    Image(systemName: store.birthTimeUnknown ? "checkmark.square.fill" : "square")
                        .foregroundStyle(AstaraColors.gold)
                    Text(String(localized: "dont_know_birth_time"))
                        .font(AstaraTypography.bodyMedium)
                        .foregroundStyle(AstaraColors.textSecondary)
                }
            }

            if store.birthTimeUnknown {
                HStack(spacing: AstaraSpacing.xs) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(AstaraColors.ember400)
                        .font(.system(size: 14))
                    Text(String(localized: "unknown_time_warning"))
                        .font(AstaraTypography.caption)
                        .foregroundStyle(AstaraColors.ember400)
                }
                .padding(AstaraSpacing.sm)
                .astaraCard(cornerRadius: AstaraSpacing.cornerRadiusSm)
            }
        }
    }

    // MARK: - Birth City Section

    private var birthCitySection: some View {
        VStack(spacing: AstaraSpacing.lg) {
            Text(String(localized: "where_were_you_born"))
                .font(AstaraTypography.displayMedium)
                .foregroundStyle(AstaraColors.textPrimary)
                .multilineTextAlignment(.center)

            AstaraTextField(
                placeholder: String(localized: "search_city"),
                text: $store.searchQuery.sending(\.setSearchQuery)
            )

            if store.isSearching {
                ProgressView()
                    .tint(AstaraColors.gold)
            }

            if let error = store.searchError {
                HStack(spacing: AstaraSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 13))
                    Text(error)
                        .font(AstaraTypography.bodySmall)
                }
                .foregroundStyle(AstaraColors.ember400)
            }

            if !store.searchResults.isEmpty {
                LazyVStack(spacing: 0) {
                    ForEach(store.searchResults) { city in
                        Button {
                            store.send(.selectCity(city))
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.name)
                                        .font(AstaraTypography.bodyLarge)
                                        .foregroundStyle(AstaraColors.textPrimary)
                                    Text(city.country)
                                        .font(AstaraTypography.caption)
                                        .foregroundStyle(AstaraColors.textTertiary)
                                }
                                Spacer()
                                if store.selectedCity?.id == city.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AstaraColors.gold)
                                }
                            }
                            .padding(.horizontal, AstaraSpacing.md)
                            .padding(.vertical, AstaraSpacing.sm)
                        }
                        if city.id != store.searchResults.last?.id {
                            Divider().background(AstaraColors.cardBorder)
                        }
                    }
                }
                .astaraCard()
            } else if !store.isSearching && store.searchQuery.count >= 2 && store.searchError == nil && store.selectedCity == nil {
                Text(String(localized: "no_results"))
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textTertiary)
            }
        }
    }
}

#Preview("Birth Date") {
    ZStack {
        GradientBackground()
        BirthDataInputView(
            store: Store(initialState: OnboardingFeature.State(currentStep: .birthDate)) {
                OnboardingFeature()
            }
        )
    }
}

#Preview("Birth City") {
    ZStack {
        GradientBackground()
        BirthDataInputView(
            store: Store(initialState: OnboardingFeature.State(currentStep: .birthCity)) {
                OnboardingFeature()
            }
        )
    }
}
