//
//  ReminderService.swift
//  Yomo
//
//  Firestore CRUD service for reminders with real-time listeners
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class ReminderService {
    private let db = Firestore.firestore()

    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    private var remindersRef: CollectionReference? {
        guard let userId = userId else { return nil }
        return db.collection("users").document(userId).collection("reminders")
    }

    // MARK: - Create
    func createReminder(_ reminder: Reminder) async throws {
        guard let ref = remindersRef else {
            throw ReminderError.notAuthenticated
        }

        let data: [String: Any] = [
            "title": reminder.title,
            "notes": reminder.notes ?? "",
            "triggerDate": reminder.triggerDate,
            "recurrence": encodeRecurrence(reminder.recurrence),
            "status": reminder.status.rawValue,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]

        try await ref.addDocument(data: data)
    }

    // MARK: - Read
    func fetchReminders() async throws -> [Reminder] {
        guard let ref = remindersRef else {
            throw ReminderError.notAuthenticated
        }

        let snapshot = try await ref
            .whereField("status", isEqualTo: ReminderStatus.active.rawValue)
            .order(by: "triggerDate", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            decodeReminder(from: doc)
        }
    }

    // MARK: - Real-time listener
    func listenToReminders(
        onChange: @escaping ([Reminder]) -> Void
    ) -> ListenerRegistration? {
        guard let ref = remindersRef else { return nil }

        return ref
            .whereField("status", isEqualTo: ReminderStatus.active.rawValue)
            .order(by: "triggerDate", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let reminders = documents.compactMap { doc in
                    self.decodeReminder(from: doc)
                }
                onChange(reminders)
            }
    }

    // MARK: - Update
    func updateReminder(_ reminder: Reminder) async throws {
        guard let ref = remindersRef, let id = reminder.id else {
            throw ReminderError.notAuthenticated
        }

        var data: [String: Any] = [
            "title": reminder.title,
            "notes": reminder.notes ?? "",
            "triggerDate": reminder.triggerDate,
            "recurrence": encodeRecurrence(reminder.recurrence),
            "status": reminder.status.rawValue,
            "updatedAt": Timestamp(date: Date())
        ]

        if let snoozedUntil = reminder.snoozedUntil {
            data["snoozedUntil"] = snoozedUntil
        }

        try await ref.document(id).updateData(data)
    }

    // MARK: - Complete
    func completeReminder(_ reminder: Reminder) async throws {
        guard let ref = remindersRef, let id = reminder.id else {
            throw ReminderError.notAuthenticated
        }

        // If recurring, create next occurrence instead of completing
        if let recurrence = reminder.recurrence, recurrence.type != .none {
            let nextDate = calculateNextDate(
                from: reminder.triggerDate.dateValue(),
                recurrence: recurrence
            )
            try await ref.document(id).updateData([
                "triggerDate": Timestamp(date: nextDate),
                "snoozedUntil": FieldValue.delete(),
                "updatedAt": Timestamp(date: Date())
            ])
        } else {
            try await ref.document(id).updateData([
                "status": ReminderStatus.completed.rawValue,
                "updatedAt": Timestamp(date: Date())
            ])
        }
    }

    // MARK: - Delete
    func deleteReminder(_ reminder: Reminder) async throws {
        guard let ref = remindersRef, let id = reminder.id else {
            throw ReminderError.notAuthenticated
        }

        try await ref.document(id).delete()
    }

    // MARK: - Helpers
    private func encodeRecurrence(_ rule: RecurrenceRule?) -> [String: Any] {
        guard let rule = rule else {
            return ["type": "none"]
        }
        var data: [String: Any] = [
            "type": rule.type.rawValue,
            "interval": rule.interval,
            "basedOnCompletion": rule.basedOnCompletion
        ]
        if let unit = rule.unit { data["unit"] = unit.rawValue }
        if let days = rule.daysOfWeek { data["daysOfWeek"] = days }
        return data
    }

    private func decodeReminder(from doc: QueryDocumentSnapshot) -> Reminder? {
        let data = doc.data()
        guard let title = data["title"] as? String,
              let triggerDate = data["triggerDate"] as? Timestamp,
              let statusRaw = data["status"] as? String,
              let status = ReminderStatus(rawValue: statusRaw) else {
            return nil
        }

        let recurrenceData = data["recurrence"] as? [String: Any]
        let recurrence = decodeRecurrenceRule(from: recurrenceData)

        return Reminder(
            id: doc.documentID,
            title: title,
            notes: data["notes"] as? String,
            triggerDate: triggerDate,
            recurrence: recurrence,
            status: status,
            snoozedUntil: data["snoozedUntil"] as? Timestamp,
            createdAt: data["createdAt"] as? Timestamp ?? Timestamp(date: Date()),
            updatedAt: data["updatedAt"] as? Timestamp ?? Timestamp(date: Date())
        )
    }

    private func decodeRecurrenceRule(from data: [String: Any]?) -> RecurrenceRule? {
        guard let data = data,
              let typeRaw = data["type"] as? String,
              let type = RecurrenceType(rawValue: typeRaw),
              type != .none else {
            return nil
        }

        return RecurrenceRule(
            type: type,
            interval: data["interval"] as? Int ?? 1,
            unit: (data["unit"] as? String).flatMap { RecurrenceUnit(rawValue: $0) },
            daysOfWeek: data["daysOfWeek"] as? [Int],
            timeRangeStart: data["timeRangeStart"] as? String,
            timeRangeEnd: data["timeRangeEnd"] as? String,
            basedOnCompletion: data["basedOnCompletion"] as? Bool ?? false
        )
    }

    private func calculateNextDate(from date: Date, recurrence: RecurrenceRule) -> Date {
        let calendar = Calendar.current
        let now = Date()
        var nextDate = date

        switch recurrence.type {
        case .daily:
            let interval = recurrence.interval
            while nextDate <= now {
                nextDate = calendar.date(byAdding: .day, value: interval, to: nextDate) ?? nextDate
            }
        case .weekly:
            let interval = recurrence.interval
            while nextDate <= now {
                nextDate = calendar.date(byAdding: .weekOfYear, value: interval, to: nextDate) ?? nextDate
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

// MARK: - Errors
enum ReminderError: LocalizedError {
    case notAuthenticated
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to manage reminders"
        case .invalidData:
            return "Invalid reminder data"
        }
    }
}

// MARK: - Type aliases for cleaner imports
typealias ReminderStatus = Reminder.ReminderStatus
typealias RecurrenceType = RecurrenceRule.RecurrenceType
typealias RecurrenceUnit = RecurrenceRule.RecurrenceUnit
