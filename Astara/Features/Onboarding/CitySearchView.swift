import SwiftUI
import ComposableArchitecture

struct CitySearchView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(spacing: AstaraSpacing.md) {
            AstaraTextField(
                placeholder: String(localized: "search_city"),
                text: $store.searchQuery.sending(\.setSearchQuery)
            )

            if store.isSearching {
                HStack(spacing: AstaraSpacing.xs) {
                    ProgressView()
                        .tint(AstaraColors.gold)
                    Text(String(localized: "searching"))
                        .font(AstaraTypography.bodySmall)
                        .foregroundStyle(AstaraColors.textTertiary)
                }
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.searchResults) { city in
                        cityRow(city)
                        if city.id != store.searchResults.last?.id {
                            Divider()
                                .background(AstaraColors.cardBorder)
                        }
                    }
                }
            }
        }
    }

    private func cityRow(_ city: GeoCity) -> some View {
        Button {
            store.send(.selectCity(city))
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(city.name)
                        .font(AstaraTypography.bodyLarge)
                        .foregroundStyle(AstaraColors.textPrimary)

                    Text("\(city.country) \u{00B7} \(city.timezone)")
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
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        CitySearchView(
            store: Store(
                initialState: OnboardingFeature.State(
                    searchQuery: "Ist",
                    searchResults: [
                        GeoCity(name: "Istanbul", country: "Turkey", latitude: 41.0082, longitude: 28.9784, timezone: "Europe/Istanbul"),
                    ]
                )
            ) {
                OnboardingFeature()
            }
        )
        .padding()
    }
}
