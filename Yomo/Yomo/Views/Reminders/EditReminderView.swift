//
//  EditReminderView.swift
//  Yomo
//
//  Screen 7: Bottom sheet for editing existing reminders
//

import SwiftUI
import FirebaseFirestore

struct EditReminderView: View {
    @Environment(\.dismiss) var dismiss
    let reminder: Reminder
    @State private var title: String
    @State private var date: Date
    @State private var time: Date
    @State private var notes: String
    @State private var selectedRecurrence: RecurrenceType
    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String?
    @State private var showPaywall = false

    // Advanced recurrence state
    @State private var customInterval: Int
    @State private var customUnit: RecurrenceUnit
    @State private var customDaysOfWeek: [Int]
    @State private var customTimeRangeStart: Date
    @State private var customTimeRangeEnd: Date
    @State private var basedOnCompletion: Bool

    init(reminder: Reminder) {
        self.reminder = reminder
        _title = State(initialValue: reminder.title)
        _date = State(initialValue: reminder.triggerDate.dateValue())
        _time = State(initialValue: reminder.triggerDate.dateValue())
        _notes = State(initialValue: reminder.notes ?? "")
        _selectedRecurrence = State(initialValue: reminder.recurrence?.type ?? .none)
        _customInterval = State(initialValue: reminder.recurrence?.interval ?? 1)
        _customUnit = State(initialValue: reminder.recurrence?.unit ?? .day)
        _customDaysOfWeek = State(initialValue: reminder.recurrence?.daysOfWeek ?? [])

        let calendar = Calendar.current
        if let startStr = reminder.recurrence?.timeRangeStart {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            _customTimeRangeStart = State(initialValue: formatter.date(from: startStr) ?? calendar.date(from: DateComponents(hour: 9))!)
        } else {
            _customTimeRangeStart = State(initialValue: calendar.date(from: DateComponents(hour: 9)) ?? Date())
        }
        if let endStr = reminder.recurrence?.timeRangeEnd {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            _customTimeRangeEnd = State(initialValue: formatter.date(from: endStr) ?? calendar.date(from: DateComponents(hour: 18))!)
        } else {
            _customTimeRangeEnd = State(initialValue: calendar.date(from: DateComponents(hour: 18)) ?? Date())
        }

        _basedOnCompletion = State(initialValue: reminder.recurrence?.basedOnCompletion ?? false)
    }

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

                    // Form
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

                        // Repeat pills
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

                        // Custom recurrence editor
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

                    if let error = errorMessage {
                        Text(error)
                            .font(.bodySmall)
                            .foregroundColor(.dangerRed)
                    }

                    PrimaryButton(
                        "Save Changes",
                        icon: "checkmark",
                        isLoading: isSaving,
                        isDisabled: title.isEmpty
                    ) {
                        saveChanges()
                    }
                    .padding(.top, Spacing.sm)

                    // Delete button
                    HStack {
                        Spacer()
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete Reminder")
                                .font(.bodyRegular)
                                .foregroundColor(.dangerRed)
                        }
                        Spacer()
                    }
                    .padding(.top, Spacing.sm)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.background)
            .navigationTitle("Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.brandBlue)
                }
            }
            .alert("Delete Reminder?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { deleteReminder() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func saveChanges() {
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

        let updated = Reminder(
            id: reminder.id,
            title: title,
            notes: notes.isEmpty ? nil : notes,
            triggerDate: Timestamp(date: triggerDate),
            recurrence: recurrence,
            status: reminder.status,
            snoozedUntil: nil,
            createdAt: reminder.createdAt,
            updatedAt: Timestamp(date: Date())
        )

        Task {
            do {
                let service = ReminderService()
                try await service.updateReminder(updated)
                HapticManager.success()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }

    private func deleteReminder() {
        Task {
            do {
                let service = ReminderService()
                try await service.deleteReminder(reminder)
                if let reminderId = reminder.id {
                    NotificationService.shared.cancelNotification(for: reminderId)
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
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

// MARK: - Make Reminder identifiable for sheet binding

extension Reminder: @retroactive Hashable {
    static func == (lhs: Reminder, rhs: Reminder) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
