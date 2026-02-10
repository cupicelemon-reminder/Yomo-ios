//
//  ReminderViewModel.swift
//  Yomo
//
//  View model for reminder list with real-time Firestore sync or local storage
//

import Foundation
import FirebaseAuth
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
    private let localStore = LocalReminderStore.shared
    private var listener: ListenerRegistration?
    private var hasStarted = false

    var isEmpty: Bool {
        reminders.isEmpty
    }

    /// Whether we're using local-only mode (dev login / free tier / no Firebase Auth)
    var isLocalMode: Bool {
        Auth.auth().currentUser == nil
    }

    func startListening() {
        guard !hasStarted else { return }
        hasStarted = true
        isLoading = true

        if isLocalMode {
            localStore.migrateIfNeeded()
            localStore.seedSampleRemindersIfNeeded()
            localStore.addChangeListener { [weak self] reminders in
                Task { @MainActor in
                    self?.reminders = reminders
                    self?.groupReminders(reminders)
                    self?.isLoading = false
                    NotificationService.shared.setBadgeCount(self?.overdueReminders.count ?? 0)
                    await NotificationService.shared.syncAllNotifications(reminders: reminders)
                }
            }
        } else {
            listener = service.listenToReminders { [weak self] reminders in
                Task { @MainActor in
                    self?.reminders = reminders
                    self?.groupReminders(reminders)
                    self?.isLoading = false
                    NotificationService.shared.setBadgeCount(self?.overdueReminders.count ?? 0)
                    await NotificationService.shared.syncAllNotifications(reminders: reminders)
                }
            }
        }
    }

    func stopListening() {
        hasStarted = false
        listener?.remove()
        listener = nil
        localStore.removeAllListeners()
    }

    func completeReminder(_ reminder: Reminder) {
        if isLocalMode {
            localStore.completeReminder(reminder)
            if let reminderId = reminder.id {
                NotificationService.shared.cancelNotification(for: reminderId)
            }
            HapticManager.success()
        } else {
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
    }

    func deleteReminder(_ reminder: Reminder) {
        if isLocalMode {
            localStore.deleteReminder(reminder)
            if let reminderId = reminder.id {
                NotificationService.shared.cancelNotification(for: reminderId)
            }
        } else {
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
    }

    private func groupReminders(_ reminders: [Reminder]) {
        let calendar = Calendar.current
        let now = Date()

        // Sort by displayDate ascending (closest to now first)
        let sorted = reminders.sorted { $0.displayDate < $1.displayDate }

        overdueReminders = sorted.filter { $0.isOverdue }

        todayReminders = sorted.filter { reminder in
            !reminder.isOverdue && calendar.isDateInToday(reminder.displayDate)
        }

        tomorrowReminders = sorted.filter { reminder in
            !reminder.isOverdue && calendar.isDateInTomorrow(reminder.displayDate)
        }

        thisWeekReminders = sorted.filter { reminder in
            guard !reminder.isOverdue,
                  !calendar.isDateInToday(reminder.displayDate),
                  !calendar.isDateInTomorrow(reminder.displayDate) else { return false }

            guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: now) else {
                return false
            }
            return reminder.displayDate > now && reminder.displayDate < weekEnd
        }

        laterReminders = sorted.filter { reminder in
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
