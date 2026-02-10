//
//  PillButton.swift
//  Yomo
//
//  Pill-shaped toggle button for recurrence selection
//

import SwiftUI

struct PillButton: View {
    let title: String
    let isActive: Bool
    let icon: String?
    let action: () -> Void

    init(
        _ title: String,
        isActive: Bool = false,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isActive = isActive
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(.pillLabel)
            }
            .foregroundColor(isActive ? .white : .brandBlue)
            .padding(.horizontal, Spacing.md)
            .frame(height: 36)
            .background(
                Capsule()
                    .fill(isActive ? Color.brandBlue : Color.brandBlueBg)
            )
        }
    }
}
