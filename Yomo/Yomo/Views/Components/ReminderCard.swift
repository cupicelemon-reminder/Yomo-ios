//
//  ReminderCard.swift
//  Yomo
//
//  Glass card for individual reminder items in the list
//

import SwiftUI

struct ReminderCard: View {
    @EnvironmentObject private var appState: AppState
    let reminder: Reminder
    var onTap: (() -> Void)? = nil

    private var statusColor: Color {
        if reminder.isOverdue { return .dangerRed }
        return .brandBlue
    }

    private var timeText: String {
        let formatter = DateFormatter()
        if reminder.isOverdue && !Calendar.current.isDateInToday(reminder.displayDate) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: reminder.displayDate)
        }
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: reminder.displayDate)
    }

    private var recurrenceText: String? {
        guard let recurrence = reminder.recurrence, recurrence.type != .none else {
            return nil
        }

        let suffix = recurrence.basedOnCompletion ? " (from completion)" : ""

        switch recurrence.type {
        case .daily:
            let base = recurrence.interval <= 1 ? "Every day" : "Every \(recurrence.interval) days"
            return base + suffix
        case .weekly:
            if let days = recurrence.daysOfWeek, !days.isEmpty {
                let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                let names = days.compactMap { $0 > 0 && $0 < dayNames.count ? dayNames[$0] : nil }
                let prefix = recurrence.interval <= 1 ? "Every" : "Every \(recurrence.interval) weeks on"
                return "\(prefix) \(names.joined(separator: ", "))" + suffix
            }
            let base = recurrence.interval <= 1 ? "Every week" : "Every \(recurrence.interval) weeks"
            return base + suffix
        case .custom:
            guard let unit = recurrence.unit else { return "Custom" + suffix }
            let interval = recurrence.interval
            let base: String
            switch unit {
            case .hour:
                let text = interval <= 1 ? "Every hour" : "Every \(interval) hours"
                if let start = recurrence.timeRangeStart, let end = recurrence.timeRangeEnd {
                    base = "\(text) (\(start)\u{2013}\(end))"
                } else {
                    base = text
                }
            case .day:
                base = interval <= 1 ? "Every day" : "Every \(interval) days"
            case .week:
                if let days = recurrence.daysOfWeek, !days.isEmpty {
                    let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                    let names = days.compactMap { $0 > 0 && $0 < dayNames.count ? dayNames[$0] : nil }
                    let prefix = interval <= 1 ? "Every" : "Every \(interval) weeks on"
                    base = "\(prefix) \(names.joined(separator: ", "))"
                } else {
                    base = interval <= 1 ? "Every week" : "Every \(interval) weeks"
                }
            case .month:
                base = interval <= 1 ? "Every month" : "Every \(interval) months"
            }
            return base + suffix
        case .none:
            return nil
        }
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: Spacing.md) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(reminder.title)
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)

                    if let recurrenceText = recurrenceText {
                        Text(recurrenceText)
                            .font(.bodySmall)
                            .foregroundColor(.brandBlue)
                    }
                }

                Spacer()

                Text(timeText)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            .padding(Spacing.md)
            .liquidGlassBackground(isGlass: appState.theme.usesGlassMaterial)
        }
        .buttonStyle(.plain)
    }
}
