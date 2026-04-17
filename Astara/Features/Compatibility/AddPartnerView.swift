import SwiftUI
import ComposableArchitecture

/// Lightweight partner intake form. Mirrors the onboarding birth-data flow
/// (date + time-or-unknown + city search) but stays local — we don't need a
/// full TCA reducer for a one-shot modal.
struct AddPartnerView: View {
    let ownerUserId: UUID
    let onCancel: () -> Void
    let onSave: (PartnerDTO) -> Void

    @State private var name: String = ""
    @State private var birthDate: Date = Calendar.current.date(from: DateComponents(year: 1995, month: 3, day: 15)) ?? Date()
    @State private var birthTime: Date = Calendar.current.date(from: DateComponents(year: 1995, month: 3, day: 15, hour: 12, minute: 0)) ?? Date()
    @State private var birthTimeUnknown: Bool = false
    @State private var searchQuery: String = ""
    @State private var searchResults: [GeoCity] = []
    @State private var isSearching: Bool = false
    @State private var selectedCity: GeoCity?
    @State private var searchTask: Task<Void, Never>?

    @Dependency(\.geoService) private var geoService

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: AstaraSpacing.lg) {
                        header

                        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
                            sectionLabel(String(localized: "partner_name"))
                            AstaraTextField(
                                placeholder: String(localized: "partner_name_placeholder"),
                                text: $name
                            )
                        }

                        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
                            sectionLabel(String(localized: "birth_date"))
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(AstaraColors.gold)
                        }

                        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
                            sectionLabel(String(localized: "birth_time"))
                            Toggle(isOn: $birthTimeUnknown) {
                                Text(String(localized: "birth_time_unknown"))
                                    .font(AstaraTypography.bodyMedium)
                                    .foregroundStyle(AstaraColors.textSecondary)
                            }
                            .tint(AstaraColors.gold)

                            if !birthTimeUnknown {
                                DatePicker("", selection: $birthTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(AstaraColors.gold)
                            } else {
                                Text(String(localized: "birth_time_unknown_warning"))
                                    .font(AstaraTypography.caption)
                                    .foregroundStyle(AstaraColors.ember400)
                            }
                        }

                        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
                            sectionLabel(String(localized: "birth_city"))
                            AstaraTextField(
                                placeholder: String(localized: "search_city"),
                                text: $searchQuery
                            )
                            .onChange(of: searchQuery) { _, new in
                                debouncedSearch(new)
                            }

                            if isSearching {
                                HStack(spacing: AstaraSpacing.xs) {
                                    ProgressView().tint(AstaraColors.gold)
                                    Text(String(localized: "searching"))
                                        .font(AstaraTypography.bodySmall)
                                        .foregroundStyle(AstaraColors.textTertiary)
                                }
                            }

                            ForEach(searchResults) { city in
                                Button {
                                    selectedCity = city
                                    searchQuery = city.name
                                    searchResults = []
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(city.name)
                                                .foregroundStyle(AstaraColors.textPrimary)
                                            Text("\(city.country) \u{00B7} \(city.timezone)")
                                                .font(AstaraTypography.caption)
                                                .foregroundStyle(AstaraColors.textTertiary)
                                        }
                                        Spacer()
                                        if selectedCity?.id == city.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(AstaraColors.gold)
                                        }
                                    }
                                    .padding(.vertical, AstaraSpacing.xs)
                                }
                            }
                        }

                        Spacer(minLength: AstaraSpacing.xxl)
                    }
                    .padding(AstaraSpacing.lg)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { onCancel() }
                        .foregroundStyle(AstaraColors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) { save() }
                        .foregroundStyle(AstaraColors.gold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "add_partner").uppercased())
                .font(AstaraTypography.heroLabel)
                .foregroundStyle(AstaraColors.gold)
                .tracking(2)
            Text(String(localized: "add_partner_subtitle"))
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textTertiary)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AstaraTypography.caption)
            .tracking(1.5)
            .foregroundStyle(AstaraColors.textTertiary)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedCity != nil
    }

    private func save() {
        guard let city = selectedCity else { return }
        let dto = PartnerDTO(
            id: UUID(),
            ownerUserId: ownerUserId,
            name: name.trimmingCharacters(in: .whitespaces),
            birthDate: birthDate,
            birthTime: birthTimeUnknown ? nil : birthTime,
            birthTimeUnknown: birthTimeUnknown,
            birthCity: city.name,
            birthLatitude: city.latitude,
            birthLongitude: city.longitude,
            birthTimezone: city.timezone,
            lastSyncedAt: nil,
            source: "manual",
            createdAt: Date()
        )
        onSave(dto)
    }

    private func debouncedSearch(_ query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            searchResults = []
            return
        }
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            isSearching = true
            defer { isSearching = false }
            do {
                let results = try await geoService.searchCities(trimmed)
                if !Task.isCancelled {
                    searchResults = results
                }
            } catch {
                searchResults = []
            }
        }
    }
}
