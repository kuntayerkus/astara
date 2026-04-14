import SwiftUI
import SwiftData

struct EditBirthDataView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var onSave: (() -> Void)?

    @State private var birthDate = Date()
    @State private var birthTime = Date()
    @State private var birthCity = ""
    @State private var timeUnknown = false
    @State private var isSaving = false

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(AstaraColors.cardBorder)
                    .frame(width: 40, height: 5)
                    .padding(.top, AstaraSpacing.md)
                    .padding(.bottom, AstaraSpacing.lg)

                // Header
                HStack {
                    Text(String(localized: "edit_birth_data"))
                        .font(AstaraTypography.titleLarge)
                        .foregroundStyle(AstaraColors.textPrimary)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AstaraColors.textTertiary)
                    }
                }
                .padding(.horizontal, AstaraSpacing.lg)
                .padding(.bottom, AstaraSpacing.lg)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AstaraSpacing.lg) {
                        // Date
                        VStack(alignment: .leading, spacing: AstaraSpacing.xs) {
                            Text(String(localized: "when_were_you_born"))
                                .font(AstaraTypography.labelLarge)
                                .foregroundStyle(AstaraColors.textPrimary)

                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        .padding(AstaraSpacing.md)
                        .astaraCard()

                        // Time
                        VStack(alignment: .leading, spacing: AstaraSpacing.xs) {
                            Text(String(localized: "what_time"))
                                .font(AstaraTypography.labelLarge)
                                .foregroundStyle(AstaraColors.textPrimary)

                            if !timeUnknown {
                                DatePicker("", selection: $birthTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.wheel)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }

                            Toggle(isOn: $timeUnknown) {
                                Text(String(localized: "dont_know_birth_time"))
                                    .font(AstaraTypography.bodySmall)
                                    .foregroundStyle(AstaraColors.textSecondary)
                            }
                            .tint(AstaraColors.gold)
                        }
                        .padding(AstaraSpacing.md)
                        .astaraCard()

                        AstaraButton(title: String(localized: "save_changes"), style: .primary) {
                            saveChanges()
                        }
                        .disabled(isSaving)
                    }
                    .padding(.horizontal, AstaraSpacing.lg)
                    .padding(.bottom, AstaraSpacing.xxxl)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear { loadExistingData() }
    }

    // MARK: - SwiftData

    private func loadExistingData() {
        let descriptor = FetchDescriptor<User>()
        guard let user = (try? modelContext.fetch(descriptor))?.first else { return }
        birthDate = user.birthDate
        birthTime = user.birthTime ?? Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
        birthCity = user.birthCity
        timeUnknown = user.birthTimeUnknown
    }

    private func saveChanges() {
        isSaving = true
        let descriptor = FetchDescriptor<User>()
        guard let user = (try? modelContext.fetch(descriptor))?.first else {
            isSaving = false
            return
        }
        user.birthDate = birthDate
        user.birthTime = timeUnknown ? nil : birthTime
        user.birthTimeUnknown = timeUnknown
        try? modelContext.save()
        isSaving = false
        onSave?()
        dismiss()
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            EditBirthDataView()
        }
}
