//
//  ReminderViewModel.swift
//  Yomo
//
//  View model for reminder list with real-time Firestore sync
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class ReminderViewModel: ObservableObject {
    @Published var reminders: [Reminder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Grouped sections
    @Published var overdueReminders: [Reminder] = []
    @Published var todayReminders: [Reminder] = []
    @Published var tomorrowReminders: [Reminder] = []
    @Published var thisWeekReminders: [Reminder] = []
    @Published var laterReminders: [Reminder] = []

    private let service = ReminderService()
    private var listener: ListenerRegistration?

    var isEmpty: Bool {
        reminders.isEmpty
    }

    func startListening() {
        isLoading = true
        listener = service.listenToReminders { [weak self] reminders in
            Task { @MainActor in
                self?.reminders = reminders
                self?.groupReminders(reminders)
                self?.isLoading = false

                // Sync notifications with current reminders
                await NotificationService.shared.syncAllNotifications(reminders: reminders)
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func completeReminder(_ reminder: Reminder) {
        Task {
            do {
                try await service.completeReminder(reminder)
                if let reminderId = reminder.id {
                    NotificationService.shared.cancelNotification(for: reminderId)
                }
                HapticManager.success()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteReminder(_ reminder: Reminder) {
        Task {
            do {
                try await service.deleteReminder(reminder)
                if let reminderId = reminder.id {
                    NotificationService.shared.cancelNotification(for: reminderId)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func groupReminders(_ reminders: [Reminder]) {
        let calendar = Calendar.current
        let now = Date()

        overdueReminders = reminders.filter { $0.isOverdue }

        todayReminders = reminders.filter { reminder in
            !reminder.isOverdue && calendar.isDateInToday(reminder.displayDate)
        }

        tomorrowReminders = reminders.filter { reminder in
            !reminder.isOverdue && calendar.isDateInTomorrow(reminder.displayDate)
        }

        thisWeekReminders = reminders.filter { reminder in
            guard !reminder.isOverdue,
                  !calendar.isDateInToday(reminder.displayDate),
                  !calendar.isDateInTomorrow(reminder.displayDate) else { return false }

            guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: now) else {
                return false
            }
            return reminder.displayDate > now && reminder.displayDate < weekEnd
        }

        laterReminders = reminders.filter { reminder in
            guard !reminder.isOverdue,
                  !calendar.isDateInToday(reminder.displayDate),
                  !calendar.isDateInTomorrow(reminder.displayDate) else { return false }

            guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: now) else {
                return false
            }
            return reminder.displayDate >= weekEnd
        }
    }
}
