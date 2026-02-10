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

    private init() {}

    // MARK: - CRUD

    func allActiveReminders() -> [Reminder] {
        loadReminders().filter { $0.status == .active }
    }

    func createReminder(_ reminder: Reminder) {
        var reminders = loadReminders()
        var newReminder = reminder
        if newReminder.id == nil {
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

    // MARK: - Listener simulation

    func addChangeListener(_ callback: @escaping ([Reminder]) -> Void) {
        changeCallbacks.append(callback)
        callback(allActiveReminders())
    }

    func removeAllListeners() {
        changeCallbacks.removeAll()
    }

    // MARK: - Sample reminders for first launch

    func seedSampleRemindersIfNeeded() {
        let seededKey = "yomo_samples_seeded"
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }

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

        UserDefaults.standard.set(true, forKey: seededKey)
    }

    // MARK: - Persistence

    private func loadReminders() -> [Reminder] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode([Reminder].self, from: data)) ?? []
    }

    private func saveReminders(_ reminders: [Reminder]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(reminders) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func notifyChange() {
        let active = allActiveReminders()
        for callback in changeCallbacks {
            callback(active)
        }
    }

    // MARK: - Recurrence calculation (same as ReminderService)

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
