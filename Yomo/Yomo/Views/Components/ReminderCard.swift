//
//  ReminderCard.swift
//  Yomo
//
//  Glass card for individual reminder items in the list
//

import SwiftUI

struct ReminderCard: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var viewModel: ReminderViewModel
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

    private var isOverdueRecurring: Bool {
        guard reminder.isOverdue,
              let recurrence = reminder.recurrence,
              recurrence.type != .none else {
            return false
        }
        return true
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

                    if isOverdueRecurring {
                        pastDueLabel
                    } else if let recurrenceText = recurrenceText {
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

    private var pastDueLabel: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = pastDueCountdownText(now: context.date)
            HStack(spacing: Spacing.xs) {
                Text("Past Due")
                    .font(.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.dangerRed)

                if let remaining {
                    Text("· \(remaining)")
                        .font(.bodySmall)
                        .foregroundColor(.dangerRed.opacity(0.7))
                }
            }
        }
    }

    private func pastDueCountdownText(now: Date) -> String? {
        guard let reminderId = reminder.id,
              let firstSeen = viewModel.overdueRecurringFirstSeen[reminderId] else {
            return nil
        }

        let autoAdvanceAt = firstSeen.addingTimeInterval(600) // 10 minutes
        let remaining = autoAdvanceAt.timeIntervalSince(now)

        guard remaining > 0 else { return nil }

        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return "\(minutes)m \(seconds)s"
    }
}
