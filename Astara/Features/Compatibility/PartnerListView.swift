import SwiftUI
import ComposableArchitecture

/// Full list of user-saved partners with entry into the ``SynastryDetailView``.
/// Rendered as a subsection inside ``CompatibilityView``.
struct PartnerListView: View {
    @Bindable var store: StoreOf<CompatibilityFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.md) {
            header

            if store.partners.isEmpty {
                emptyState
            } else {
                VStack(spacing: AstaraSpacing.sm) {
                    ForEach(store.partners) { partner in
                        partnerRow(partner)
                    }
                }
            }
        }
        .padding(.horizontal, AstaraSpacing.lg)
        .sheet(isPresented: Binding(
            get: { store.showAddPartner },
            set: { store.send(.showAddPartner($0)) }
        )) {
            AddPartnerView(
                ownerUserId: store.userId ?? UUID(),
                onCancel: { store.send(.showAddPartner(false)) },
                onSave: { dto in store.send(.addPartner(dto)) }
            )
        }
        .sheet(item: Binding(
            get: { store.selectedPartner },
            set: { store.send(.selectPartner($0)) }
        )) { partner in
            SynastryDetailView(
                partner: partner,
                synastry: store.synastry,
                isLoading: store.isLoadingSynastry,
                errorMessage: store.synastryError,
                onClose: { store.send(.selectPartner(nil)) },
                onDelete: {
                    store.send(.deletePartner(partner.id))
                    store.send(.selectPartner(nil))
                }
            )
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "partners_title").uppercased())
                    .font(AstaraTypography.heroLabel)
                    .tracking(2)
                    .foregroundStyle(AstaraColors.gold)

                Text(String(localized: "partners_subtitle"))
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }
            Spacer()
            Button {
                store.send(.showAddPartner(true))
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AstaraColors.gold)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AstaraSpacing.sm) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 32))
                .foregroundStyle(AstaraColors.textTertiary)

            Text(String(localized: "partners_empty_title"))
                .font(AstaraTypography.titleMedium)
                .foregroundStyle(AstaraColors.textPrimary)

            Text(String(localized: "partners_empty_body"))
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                store.send(.showAddPartner(true))
            } label: {
                Text(String(localized: "partners_empty_cta"))
                    .font(AstaraTypography.labelMedium)
                    .foregroundStyle(AstaraColors.gold)
                    .padding(.horizontal, AstaraSpacing.md)
                    .padding(.vertical, AstaraSpacing.xs)
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(AstaraColors.gold.opacity(0.6), lineWidth: 1)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AstaraSpacing.lg)
        .astaraCard()
    }

    private func partnerRow(_ partner: PartnerDTO) -> some View {
        Button {
            store.send(.selectPartner(partner))
        } label: {
            HStack(spacing: AstaraSpacing.md) {
                // Sign badge
                Text(partner.approximateSunSign.symbol)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(AstaraColors.gold)
                    .frame(width: 44, height: 44)
                    .background(AstaraColors.cardBackground)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(partner.name)
                        .font(AstaraTypography.titleMedium)
                        .foregroundStyle(AstaraColors.textPrimary)
                    HStack(spacing: AstaraSpacing.xs) {
                        Text(partner.approximateSunSign.localizedName)
                            .font(AstaraTypography.caption)
                            .foregroundStyle(AstaraColors.textTertiary)
                        if partner.birthTimeUnknown {
                            Text("\u{00B7}")
                                .foregroundStyle(AstaraColors.textTertiary)
                            Text(String(localized: "partners_time_unknown_badge"))
                                .font(AstaraTypography.caption)
                                .foregroundStyle(AstaraColors.ember400)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(AstaraColors.textTertiary)
            }
            .padding(AstaraSpacing.md)
            .microCard()
        }
    }
}
