//
//  Reminder.swift
//  Yomo
//
//  Core reminder data model matching Firestore schema
//

import Foundation
import FirebaseFirestore

struct Reminder: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var notes: String?
    var triggerDate: Timestamp
    var recurrence: RecurrenceRule?
    var status: ReminderStatus
    var snoozedUntil: Timestamp?
    var createdAt: Timestamp
    var updatedAt: Timestamp

    enum ReminderStatus: String, Codable {
        case active
        case completed
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case notes
        case triggerDate
        case recurrence
        case status
        case snoozedUntil
        case createdAt
        case updatedAt
    }

    // Computed properties
    var isOverdue: Bool {
        guard status == .active else { return false }
        return triggerDate.dateValue() < Date()
    }

    var displayDate: Date {
        snoozedUntil?.dateValue() ?? triggerDate.dateValue()
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(displayDate)
    }

    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(displayDate)
    }

    var isThisWeek: Bool {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return false
        }
        return displayDate >= weekStart && displayDate < weekEnd
    }
}

struct RecurrenceRule: Codable {
    var type: RecurrenceType
    var interval: Int // e.g., every 2 days, every 3 hours
    var unit: RecurrenceUnit?
    var daysOfWeek: [Int]? // 1=Sunday, 2=Monday, etc.
    var timeRangeStart: String? // HH:mm format
    var timeRangeEnd: String? // HH:mm format
    var basedOnCompletion: Bool

    enum RecurrenceType: String, Codable {
        case none
        case daily
        case weekly
        case custom
    }

    enum RecurrenceUnit: String, Codable {
        case hour
        case day
        case week
        case month
    }

    // Default initializer for simple cases
    static func daily() -> RecurrenceRule {
        RecurrenceRule(
            type: .daily,
            interval: 1,
            unit: .day,
            daysOfWeek: nil,
            timeRangeStart: nil,
            timeRangeEnd: nil,
            basedOnCompletion: false
        )
    }

    static func weekly(on days: [Int]) -> RecurrenceRule {
        RecurrenceRule(
            type: .weekly,
            interval: 1,
            unit: .week,
            daysOfWeek: days,
            timeRangeStart: nil,
            timeRangeEnd: nil,
            basedOnCompletion: false
        )
    }
}

// MARK: - Helper for creating new reminders
extension Reminder {
    static func new(title: String, triggerDate: Date, notes: String? = nil, recurrence: RecurrenceRule? = nil) -> Reminder {
        let now = Timestamp(date: Date())
        return Reminder(
            id: nil,
            title: title,
            notes: notes,
            triggerDate: Timestamp(date: triggerDate),
            recurrence: recurrence,
            status: .active,
            snoozedUntil: nil,
            createdAt: now,
            updatedAt: now
        )
    }
}
