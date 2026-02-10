//
//  CustomRecurrenceEditor.swift
//  Yomo
//
//  Advanced recurrence editor for Pro users
//

import SwiftUI

struct CustomRecurrenceEditor: View {
    @Binding var interval: Int
    @Binding var unit: RecurrenceUnit
    @Binding var daysOfWeek: [Int]
    @Binding var timeRangeStart: Date
    @Binding var timeRangeEnd: Date
    @Binding var basedOnCompletion: Bool

    let units: [RecurrenceUnit] = [.hour, .day, .week, .month]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Row 1: Every N [unit]
            frequencyRow

            // Row 2: Conditional UI based on unit
            conditionalRow

            // Row 3: Completion-based toggle
            completionToggle
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.brandBlueBg.opacity(0.5))
        )
    }

    // MARK: - Frequency Row

    private var frequencyRow: some View {
        HStack(spacing: Spacing.sm) {
            Text("Every")
                .font(.bodyRegular)
                .foregroundColor(.textPrimary)

            // Interval stepper
            HStack(spacing: Spacing.xs) {
                Button {
                    if interval > 1 { interval -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.brandBlue)
                }

                Text("\(interval)")
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)
                    .frame(minWidth: 24)
                    .monospacedDigit()

                Button {
                    if interval < 99 { interval += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.brandBlue)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.surface)
            )

            // Unit picker
            Menu {
                ForEach(units, id: \.self) { u in
                    Button(u.displayName(plural: interval > 1)) {
                        unit = u
                    }
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text(unit.displayName(plural: interval > 1))
                        .font(.bodyRegular)
                        .foregroundColor(.brandBlue)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.brandBlue)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs + 2)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.surface)
                )
            }
        }
    }

    // MARK: - Conditional Row

    @ViewBuilder
    private var conditionalRow: some View {
        switch unit {
        case .hour:
            timeRangeRow

        case .week:
            dayOfWeekRow

        case .day, .month:
            EmptyView()
        }
    }

    private var timeRangeRow: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Active hours")
                .font(.caption)
                .foregroundColor(.textSecondary)
                .tracking(0.5)

            HStack(spacing: Spacing.sm) {
                Text("From")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)

                DatePicker("", selection: $timeRangeStart, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()

                Text("to")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)

                DatePicker("", selection: $timeRangeEnd, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
        }
    }

    private var dayOfWeekRow: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("ON DAYS")
                .font(.caption)
                .foregroundColor(.textSecondary)
                .tracking(0.5)

            HStack(spacing: Spacing.xs) {
                ForEach(1...7, id: \.self) { day in
                    let isSelected = daysOfWeek.contains(day)
                    Button {
                        if isSelected {
                            daysOfWeek = daysOfWeek.filter { $0 != day }
                        } else {
                            daysOfWeek = (daysOfWeek + [day]).sorted()
                        }
                    } label: {
                        Text(dayAbbreviation(day))
                            .font(.caption)
                            .foregroundColor(isSelected ? .white : .brandBlue)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.brandBlue : Color.surface)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Completion Toggle

    private var completionToggle: some View {
        HStack {
            Toggle(isOn: $basedOnCompletion) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Repeat from completion")
                        .font(.bodySmall)
                        .foregroundColor(.textPrimary)

                    if basedOnCompletion {
                        Text("Next reminder \(interval) \(unit.displayName(plural: interval > 1)) after you complete")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .brandBlue))
        }
    }

    // MARK: - Helpers

    private func dayAbbreviation(_ day: Int) -> String {
        // 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
        let abbreviations = ["", "S", "M", "T", "W", "T", "F", "S"]
        return day > 0 && day < abbreviations.count ? abbreviations[day] : ""
    }
}

// MARK: - RecurrenceUnit Display Extension

extension RecurrenceUnit {
    func displayName(plural: Bool) -> String {
        switch self {
        case .hour: return plural ? "hours" : "hour"
        case .day: return plural ? "days" : "day"
        case .week: return plural ? "weeks" : "week"
        case .month: return plural ? "months" : "month"
        }
    }
}
