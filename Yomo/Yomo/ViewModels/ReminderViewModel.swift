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
    private var lastActiveReminderIds: Set<String> = []

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
                    self?.cancelNotificationsForRemovedReminders(activeReminders: reminders)
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
                    self?.cancelNotificationsForRemovedReminders(activeReminders: reminders)
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
        lastActiveReminderIds = []
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

    private func cancelNotificationsForRemovedReminders(activeReminders: [Reminder]) {
        let newIds = Set(activeReminders.compactMap { $0.id })
        let removed = lastActiveReminderIds.subtracting(newIds)
        for id in removed {
            NotificationService.shared.cancelNotification(for: id)
        }
        lastActiveReminderIds = newIds
    }

    /// Process snooze/complete actions queued by the notification content extension.
    /// For local mode the shared UserDefaults is already updated; this handles Firebase sync.
    func processPendingExtensionActions() {
        // Always reload local data first (picks up extension writes for local mode)
        localStore.reloadFromDisk()

        let pendingActions = localStore.consumePendingExtensionActions()
        guard !pendingActions.isEmpty, !isLocalMode else { return }

        // Firebase mode — replay each action against Firestore
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        for action in pendingActions {
            let ref = db.collection("users").document(userId)
                .collection("reminders").document(action.reminderId)

            switch action.type {
            case "snooze":
                guard let snoozeDate = action.snoozeDate else { continue }
                Task {
                    try? await ref.updateData([
                        "snoozedUntil": Timestamp(date: snoozeDate),
                        "updatedAt": Timestamp(date: Date())
                    ])
                }
            case "complete":
                Task {
                    do {
                        let doc = try await ref.getDocument()
                        let recurrenceData = doc.data()?["recurrence"] as? [String: Any]
                        let recurrenceType = recurrenceData?["type"] as? String

                        if let recurrenceType, recurrenceType != "none" {
                            let triggerDate = (doc.data()?["triggerDate"] as? Timestamp)?.dateValue() ?? Date()
                            let interval = recurrenceData?["interval"] as? Int ?? 1
                            let unit = recurrenceData?["unit"] as? String ?? "day"
                            let nextDate = AppDelegate.calculateNextDate(
                                from: triggerDate, interval: interval, unit: unit
                            )
                            try await ref.updateData([
                                "triggerDate": Timestamp(date: nextDate),
                                "snoozedUntil": FieldValue.delete(),
                                "updatedAt": Timestamp(date: Date())
                            ])
                        } else {
                            try await ref.updateData([
                                "status": "completed",
                                "updatedAt": Timestamp(date: Date())
                            ])
                        }
                    } catch {
                        // Extension action sync failed silently
                    }
                }
            default:
                break
            }
        }
    }
}
