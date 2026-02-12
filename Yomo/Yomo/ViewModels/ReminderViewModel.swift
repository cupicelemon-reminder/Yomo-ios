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

    // Tracks when each overdue recurring reminder was first detected
    @Published var overdueRecurringFirstSeen: [String: Date] = [:]

    private let service = ReminderService()
    private let localStore = LocalReminderStore.shared
    private var listener: ListenerRegistration?
    private var hasStarted = false
    private var lastActiveReminderIds: Set<String> = []
    private var autoAdvanceTimer: AnyCancellable?

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

        // Start periodic auto-advance timer
        autoAdvanceTimer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.checkAutoAdvance()
                }
            }

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
        autoAdvanceTimer?.cancel()
        autoAdvanceTimer = nil
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

        // Track overdue recurring reminders for "Past Due" countdown
        updateOverdueRecurringTracking()
    }

    private func updateOverdueRecurringTracking() {
        let now = Date()

        // Find all overdue recurring reminder IDs
        let overdueRecurringIds = Set(overdueReminders.compactMap { reminder -> String? in
            guard let id = reminder.id,
                  let recurrence = reminder.recurrence,
                  recurrence.type != .none else {
                return nil
            }
            return id
        })

        // Add newly detected overdue recurring reminders
        for id in overdueRecurringIds where overdueRecurringFirstSeen[id] == nil {
            overdueRecurringFirstSeen[id] = now
        }

        // Clean up entries for reminders that are no longer overdue or no longer exist
        let allReminderIds = Set(reminders.compactMap { $0.id })
        for id in overdueRecurringFirstSeen.keys {
            if !overdueRecurringIds.contains(id) || !allReminderIds.contains(id) {
                overdueRecurringFirstSeen.removeValue(forKey: id)
            }
        }
    }

    private func checkAutoAdvance() {
        let now = Date()

        for (reminderId, firstSeen) in overdueRecurringFirstSeen {
            guard now.timeIntervalSince(firstSeen) >= 600 else { continue }

            guard let reminder = reminders.first(where: { $0.id == reminderId }),
                  let recurrence = reminder.recurrence,
                  recurrence.type != .none else {
                overdueRecurringFirstSeen.removeValue(forKey: reminderId)
                continue
            }

            // Auto-advance to next occurrence
            autoAdvanceReminder(reminder, recurrence: recurrence)
            overdueRecurringFirstSeen.removeValue(forKey: reminderId)
        }
    }

    private func autoAdvanceReminder(_ reminder: Reminder, recurrence: RecurrenceRule) {
        let unit: String = {
            switch recurrence.unit ?? .day {
            case .hour: return "hour"
            case .day: return "day"
            case .week: return "week"
            case .month: return "month"
            }
        }()

        let nextDate = AppDelegate.calculateNextDate(
            from: reminder.triggerDate.dateValue(),
            interval: recurrence.interval,
            unit: unit
        )

        if isLocalMode {
            localStore.advanceReminderToDate(reminderId: reminder.id ?? "", nextDate: nextDate)
        } else {
            guard let reminderId = reminder.id,
                  let userId = Auth.auth().currentUser?.uid else { return }

            let db = Firestore.firestore()
            let ref = db.collection("users").document(userId)
                .collection("reminders").document(reminderId)

            Task {
                try? await ref.updateData([
                    "triggerDate": Timestamp(date: nextDate),
                    "snoozedUntil": FieldValue.delete(),
                    "updatedAt": Timestamp(date: Date())
                ])
            }
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
