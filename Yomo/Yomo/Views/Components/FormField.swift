//
//  FormField.swift
//  Yomo
//
//  Labeled form input field matching design spec
//

import SwiftUI

struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label.uppercased())
                .font(.caption)
                .foregroundColor(.textSecondary)
                .tracking(0.5)

            TextField(placeholder, text: $text, axis: axis)
                .font(.bodyRegular)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm + 2)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm + 2)
                        .fill(Color.brandBlueBg)
                )
        }
    }
}

struct DateFormField: View {
    let label: String
    @Binding var date: Date
    var displayedComponents: DatePicker.Components = [.date]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label.uppercased())
                .font(.caption)
                .foregroundColor(.textSecondary)
                .tracking(0.5)

            DatePicker("", selection: $date, displayedComponents: displayedComponents)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm + 2)
                        .fill(Color.brandBlueBg)
                )
        }
    }
}
