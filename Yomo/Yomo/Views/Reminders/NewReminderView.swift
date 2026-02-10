//
//  NewReminderView.swift
//  Yomo
//
//  Screen 6: Bottom sheet for creating new reminders with AI input
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NewReminderView: View {
    @Environment(\.dismiss) var dismiss
    @State private var naturalInput = ""
    @State private var title = ""
    @State private var date = Date()
    @State private var time = Date()
    @State private var notes = ""
    @State private var selectedRecurrence: RecurrenceType = .none
    @State private var isSaving = false
    @State private var isParsing = false
    @State private var errorMessage: String?
    @State private var showPaywall = false

    // Advanced recurrence state
    @State private var customInterval: Int = 1
    @State private var customUnit: RecurrenceUnit = .day
    @State private var customDaysOfWeek: [Int] = []
    @State private var customTimeRangeStart = Calendar.current.date(from: DateComponents(hour: 9)) ?? Date()
    @State private var customTimeRangeEnd = Calendar.current.date(from: DateComponents(hour: 18)) ?? Date()
    @State private var basedOnCompletion: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Drag handle
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.textTertiary)
                            .frame(width: 36, height: 5)
                        Spacer()
                    }
                    .padding(.top, Spacing.sm)

                    // AI Input
                    aiInputSection

                    // Divider
                    dividerSection

                    // Manual form
                    manualFormSection

                    if let error = errorMessage {
                        Text(error)
                            .font(.bodySmall)
                            .foregroundColor(.dangerRed)
                    }

                    PrimaryButton(
                        "Save Reminder",
                        icon: "checkmark",
                        isLoading: isSaving,
                        isDisabled: title.isEmpty
                    ) {
                        saveReminder()
                    }
                    .padding(.top, Spacing.sm)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.background)
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.brandBlue)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - AI Input Section

    private var aiInputSection: some View {
        VStack(spacing: Spacing.md) {
            GlassCard {
                TextField(
                    "Type naturally: 'Coffee tomorrow 10am'",
                    text: $naturalInput,
                    axis: .vertical
                )
                .font(.bodyRegular)
                .foregroundColor(.textPrimary)
                .lineLimit(1...3)
            }

            HStack {
                Spacer()
                PillButton(
                    isParsing ? "Parsing..." : "Parse",
                    isActive: true,
                    icon: "sparkles"
                ) {
                    parseInput()
                }
                .disabled(isParsing || naturalInput.isEmpty)
                Spacer()
            }
        }
    }

    // MARK: - Divider

    private var dividerSection: some View {
        HStack(spacing: Spacing.sm) {
            Rectangle()
                .fill(Color.dividerColor)
                .frame(height: 1)
            Text("or fill in manually")
                .font(.bodySmall)
                .foregroundColor(.textTertiary)
                .layoutPriority(1)
            Rectangle()
                .fill(Color.dividerColor)
                .frame(height: 1)
        }
    }

    // MARK: - Manual Form

    private var manualFormSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            FormField(
                label: "Title",
                placeholder: "Reminder title",
                text: $title
            )

            HStack(spacing: Spacing.md) {
                DateFormField(
                    label: "Date",
                    date: $date,
                    displayedComponents: [.date]
                )
                DateFormField(
                    label: "Time",
                    date: $time,
                    displayedComponents: [.hourAndMinute]
                )
            }

            FormField(
                label: "Notes",
                placeholder: "Add additional details...",
                text: $notes,
                axis: .vertical
            )

            // Recurrence selection
            recurrenceSection

            // Custom recurrence editor (Pro)
            if selectedRecurrence == .custom && AppState.shared.isPro {
                CustomRecurrenceEditor(
                    interval: $customInterval,
                    unit: $customUnit,
                    daysOfWeek: $customDaysOfWeek,
                    timeRangeStart: $customTimeRangeStart,
                    timeRangeEnd: $customTimeRangeEnd,
                    basedOnCompletion: $basedOnCompletion
                )
            }
        }
    }

    // MARK: - Recurrence

    private var recurrenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("REPEAT")
                .font(.caption)
                .foregroundColor(.textSecondary)
                .tracking(0.5)

            HStack(spacing: Spacing.sm) {
                PillButton("None", isActive: selectedRecurrence == .none) {
                    selectedRecurrence = .none
                }
                PillButton("Daily", isActive: selectedRecurrence == .daily) {
                    selectedRecurrence = .daily
                }
                PillButton("Weekly", isActive: selectedRecurrence == .weekly) {
                    selectedRecurrence = .weekly
                }
                PillButton("Custom", isActive: selectedRecurrence == .custom, icon: "sparkles") {
                    if AppState.shared.isPro {
                        selectedRecurrence = .custom
                    } else {
                        showPaywall = true
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func parseInput() {
        guard !naturalInput.isEmpty else { return }
        isParsing = true
        HapticManager.light()

        Task {
            let result = await AIParsingService.shared.parseNaturalLanguage(naturalInput)

            await MainActor.run {
                if let parsed = result {
                    title = parsed.title

                    if let parsedDate = parsed.date {
                        date = parsedDate
                    }

                    if let parsedTime = parsed.time {
                        time = parsedTime
                    }

                    switch parsed.recurrenceType {
                    case "daily": selectedRecurrence = .daily
                    case "weekly": selectedRecurrence = .weekly
                    case "custom": selectedRecurrence = .custom
                    default: selectedRecurrence = .none
                    }

                    if let days = parsed.daysOfWeek {
                        let dayMap = ["sun": 1, "mon": 2, "tue": 3, "wed": 4, "thu": 5, "fri": 6, "sat": 7]
                        customDaysOfWeek = days.compactMap { dayMap[$0.lowercased()] }
                    }

                    if let interval = parsed.recurrenceInterval {
                        customInterval = interval
                    }
                    if let unit = parsed.recurrenceUnit {
                        switch unit {
                        case "hour": customUnit = .hour
                        case "day": customUnit = .day
                        case "week": customUnit = .week
                        case "month": customUnit = .month
                        default: break
                        }
                    }
                }
                isParsing = false
                HapticManager.success()
            }
        }
    }

    private func saveReminder() {
        isSaving = true
        errorMessage = nil

        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        let triggerDate = calendar.date(from: combined) ?? date
        let recurrence = buildRecurrenceRule()

        let reminder = Reminder.new(
            title: title,
            triggerDate: triggerDate,
            notes: notes.isEmpty ? nil : notes,
            recurrence: recurrence
        )

        // Use local store if no Firebase Auth (dev login / free tier)
        if FirebaseAuth.Auth.auth().currentUser == nil {
            LocalReminderStore.shared.createReminder(reminder)
            HapticManager.success()
            dismiss()
        } else {
            Task {
                do {
                    let service = ReminderService()
                    try await service.createReminder(reminder)
                    HapticManager.success()
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }

    private func buildRecurrenceRule() -> RecurrenceRule? {
        switch selectedRecurrence {
        case .none:
            return nil
        case .daily:
            return .daily()
        case .weekly:
            return .weekly(on: customDaysOfWeek)
        case .custom:
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"

            return RecurrenceRule(
                type: .custom,
                interval: customInterval,
                unit: customUnit,
                daysOfWeek: customUnit == .week ? customDaysOfWeek : nil,
                timeRangeStart: customUnit == .hour ? formatter.string(from: customTimeRangeStart) : nil,
                timeRangeEnd: customUnit == .hour ? formatter.string(from: customTimeRangeEnd) : nil,
                basedOnCompletion: basedOnCompletion
            )
        }
    }
}
