//
//  ReminderCard.swift
//  Yomo
//
//  Glass card for individual reminder items in the list
//

import SwiftUI

struct ReminderCard: View {
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
        switch recurrence.type {
        case .daily: return "Every day"
        case .weekly:
            if let days = recurrence.daysOfWeek, !days.isEmpty {
                let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                let names = days.compactMap { $0 > 0 && $0 < dayNames.count ? dayNames[$0] : nil }
                return "Every \(names.joined(separator: ", "))"
            }
            return "Every week"
        case .custom: return "Custom"
        case .none: return nil
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
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.cardBorder, lineWidth: 1)
                    )
            )
            .glassCardShadow()
        }
        .buttonStyle(.plain)
    }
}
