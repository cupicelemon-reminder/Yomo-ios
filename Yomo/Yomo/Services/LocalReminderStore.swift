//
//  LocalReminderStore.swift
//  Yomo
//
//  Local-only reminder storage for free/dev accounts (no Firestore sync)
//

import Foundation
import FirebaseFirestore

final class LocalReminderStore {
    static let shared = LocalReminderStore()

    private let storageKey = "yomo_local_reminders"
    private var changeCallbacks: [([Reminder]) -> Void] = []

    /// Shared App Group container so the notification content extension can also read/write
    private let defaults: UserDefaults

    private init() {
        defaults = UserDefaults(suiteName: Constants.appGroupId) ?? UserDefaults.standard
    }

    // MARK: - DTO for JSON serialization
    // Firebase Timestamp and @DocumentID don't work with JSONEncoder/JSONDecoder,
    // so we convert to/from plain types for persistence.

    private struct ReminderDTO: Codable {
        var id: String
        var title: String
        var notes: String?
        var triggerDate: Double
        var recurrenceType: String?
        var recurrenceInterval: Int?
        var recurrenceUnit: String?
        var recurrenceDaysOfWeek: [Int]?
        var recurrenceTimeRangeStart: String?
        var recurrenceTimeRangeEnd: String?
        var recurrenceBasedOnCompletion: Bool?
        var status: String
        var snoozedUntil: Double?
        var createdAt: Double
        var updatedAt: Double

        init(from reminder: Reminder) {
            self.id = reminder.id ?? UUID().uuidString
            self.title = reminder.title
            self.notes = reminder.notes
            self.triggerDate = reminder.triggerDate.dateValue().timeIntervalSince1970
            self.status = reminder.status.rawValue
            self.snoozedUntil = reminder.snoozedUntil?.dateValue().timeIntervalSince1970
            self.createdAt = reminder.createdAt.dateValue().timeIntervalSince1970
            self.updatedAt = reminder.updatedAt.dateValue().timeIntervalSince1970

            if let recurrence = reminder.recurrence {
                self.recurrenceType = recurrence.type.rawValue
                self.recurrenceInterval = recurrence.interval
                self.recurrenceUnit = recurrence.unit?.rawValue
                self.recurrenceDaysOfWeek = recurrence.daysOfWeek
                self.recurrenceTimeRangeStart = recurrence.timeRangeStart
                self.recurrenceTimeRangeEnd = recurrence.timeRangeEnd
                self.recurrenceBasedOnCompletion = recurrence.basedOnCompletion
            }
        }

        func toReminder() -> Reminder {
            var recurrence: RecurrenceRule?
            if let typeStr = recurrenceType,
               let type = RecurrenceType(rawValue: typeStr),
               type != .none {
                recurrence = RecurrenceRule(
                    type: type,
                    interval: recurrenceInterval ?? 1,
                    unit: recurrenceUnit.flatMap { RecurrenceUnit(rawValue: $0) },
                    daysOfWeek: recurrenceDaysOfWeek,
                    timeRangeStart: recurrenceTimeRangeStart,
                    timeRangeEnd: recurrenceTimeRangeEnd,
                    basedOnCompletion: recurrenceBasedOnCompletion ?? false
                )
            }

            return Reminder(
                id: id,
                title: title,
                notes: notes,
                triggerDate: Timestamp(date: Date(timeIntervalSince1970: triggerDate)),
                recurrence: recurrence,
                status: Reminder.ReminderStatus(rawValue: status) ?? .active,
                snoozedUntil: snoozedUntil.map { Timestamp(date: Date(timeIntervalSince1970: $0)) },
                createdAt: Timestamp(date: Date(timeIntervalSince1970: createdAt)),
                updatedAt: Timestamp(date: Date(timeIntervalSince1970: updatedAt))
            )
        }
    }

    // MARK: - CRUD

    func allActiveReminders() -> [Reminder] {
        loadReminders().filter { $0.status == .active }
    }

    func createReminder(_ reminder: Reminder) {
        var reminders = loadReminders()
        let newReminder: Reminder
        if reminder.id == nil {
            newReminder = Reminder(
                id: UUID().uuidString,
                title: reminder.title,
                notes: reminder.notes,
                triggerDate: reminder.triggerDate,
                recurrence: reminder.recurrence,
                status: reminder.status,
                snoozedUntil: reminder.snoozedUntil,
                createdAt: reminder.createdAt,
                updatedAt: reminder.updatedAt
            )
        } else {
            newReminder = reminder
        }
        reminders.append(newReminder)
        saveReminders(reminders)
        notifyChange()
    }

    func updateReminder(_ reminder: Reminder) {
        var reminders = loadReminders()
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
            saveReminders(reminders)
            notifyChange()
        }
    }

    func completeReminder(_ reminder: Reminder) {
        var reminders = loadReminders()
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            if let recurrence = reminder.recurrence, recurrence.type != .none {
                let nextDate = calculateNextDate(
                    from: reminder.triggerDate.dateValue(),
                    recurrence: recurrence
                )
                reminders[index] = Reminder(
                    id: reminder.id,
                    title: reminder.title,
                    notes: reminder.notes,
                    triggerDate: Timestamp(date: nextDate),
                    recurrence: reminder.recurrence,
                    status: .active,
                    snoozedUntil: nil,
                    createdAt: reminder.createdAt,
                    updatedAt: Timestamp(date: Date())
                )
            } else {
                reminders[index] = Reminder(
                    id: reminder.id,
                    title: reminder.title,
                    notes: reminder.notes,
                    triggerDate: reminder.triggerDate,
                    recurrence: reminder.recurrence,
                    status: .completed,
                    snoozedUntil: reminder.snoozedUntil,
                    createdAt: reminder.createdAt,
                    updatedAt: Timestamp(date: Date())
                )
            }
            saveReminders(reminders)
            notifyChange()
        }
    }

    func deleteReminder(_ reminder: Reminder) {
        var reminders = loadReminders()
        reminders.removeAll { $0.id == reminder.id }
        saveReminders(reminders)
        notifyChange()
    }

    /// Find a reminder by ID (for notification action handling in local mode)
    func findReminder(byId id: String) -> Reminder? {
        loadReminders().first { $0.id == id }
    }

    /// Update the snoozedUntil field for a local reminder
    func snoozeReminder(id: String, until date: Date) {
        var reminders = loadReminders()
        if let index = reminders.firstIndex(where: { $0.id == id }) {
            let r = reminders[index]
            reminders[index] = Reminder(
                id: r.id,
                title: r.title,
                notes: r.notes,
                triggerDate: r.triggerDate,
                recurrence: r.recurrence,
                status: r.status,
                snoozedUntil: Timestamp(date: date),
                createdAt: r.createdAt,
                updatedAt: Timestamp(date: Date())
            )
            saveReminders(reminders)
            notifyChange()
        }
    }

    // MARK: - Listener simulation

    func addChangeListener(_ callback: @escaping ([Reminder]) -> Void) {
        changeCallbacks.append(callback)
        callback(allActiveReminders())
    }

    func removeAllListeners() {
        changeCallbacks.removeAll()
    }

    /// Re-read data from App Group storage and notify listeners.
    /// Call this when returning to foreground, since the notification extension
    /// may have snoozed/completed reminders while the app was in background.
    func reloadFromDisk() {
        notifyChange()
    }

    // MARK: - Data migration

    /// Migrates from UserDefaults.standard to App Group, and clears corrupted pre-DTO data
    func migrateIfNeeded() {
        let migrationKey = "yomo_appgroup_migration_v2"
        guard !defaults.bool(forKey: migrationKey) else { return }

        // Move valid DTO data from standard to App Group (if any exists from v1 migration)
        if let existingData = UserDefaults.standard.data(forKey: storageKey),
           let _ = try? JSONDecoder().decode([ReminderDTO].self, from: existingData) {
            defaults.set(existingData, forKey: storageKey)
            UserDefaults.standard.removeObject(forKey: storageKey)
        } else {
            // Clear any corrupted data
            defaults.removeObject(forKey: storageKey)
            UserDefaults.standard.removeObject(forKey: storageKey)
        }

        defaults.removeObject(forKey: "yomo_samples_seeded")
        UserDefaults.standard.removeObject(forKey: "yomo_samples_seeded")
        defaults.set(true, forKey: migrationKey)
    }

    // MARK: - Sample reminders for first launch

    func seedSampleRemindersIfNeeded() {
        let seededKey = "yomo_samples_seeded"
        guard !defaults.bool(forKey: seededKey) else { return }

        let calendar = Calendar.current
        let now = Date()

        let samples = [
            Reminder.new(
                title: "Welcome to Yomo! Tap me to complete",
                triggerDate: now
            ),
            Reminder.new(
                title: "Swipe left on a reminder to delete it",
                triggerDate: calendar.date(byAdding: .hour, value: 1, to: now) ?? now
            ),
            Reminder.new(
                title: "Try the + button to create your own",
                triggerDate: calendar.date(byAdding: .day, value: 1, to: now) ?? now
            ),
        ]

        for sample in samples {
            createReminder(sample)
        }

        defaults.set(true, forKey: seededKey)
    }

    // MARK: - Persistence (using DTO to avoid Firebase type issues)

    private func loadReminders() -> [Reminder] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }
        let decoder = JSONDecoder()
        guard let dtos = try? decoder.decode([ReminderDTO].self, from: data) else {
            return []
        }
        return dtos.map { $0.toReminder() }
    }

    private func saveReminders(_ reminders: [Reminder]) {
        let dtos = reminders.map { ReminderDTO(from: $0) }
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(dtos) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func notifyChange() {
        let active = allActiveReminders()
        for callback in changeCallbacks {
            callback(active)
        }
    }

    // MARK: - Recurrence calculation

    private func calculateNextDate(from date: Date, recurrence: RecurrenceRule) -> Date {
        let calendar = Calendar.current
        let now = Date()
        var nextDate = date

        switch recurrence.type {
        case .daily:
            while nextDate <= now {
                nextDate = calendar.date(byAdding: .day, value: recurrence.interval, to: nextDate) ?? nextDate
            }
        case .weekly:
            while nextDate <= now {
                nextDate = calendar.date(byAdding: .weekOfYear, value: recurrence.interval, to: nextDate) ?? nextDate
            }
        case .custom:
            if let unit = recurrence.unit {
                let component: Calendar.Component = {
                    switch unit {
                    case .hour: return .hour
                    case .day: return .day
                    case .week: return .weekOfYear
                    case .month: return .month
                    }
                }()
                while nextDate <= now {
                    nextDate = calendar.date(byAdding: component, value: recurrence.interval, to: nextDate) ?? nextDate
                }
            }
        case .none:
            break
        }

        return nextDate
    }
}
