//
//  SnoozeView.swift
//  Yomo
//
//  Screen 9: In-app snooze fallback when user taps notification
//

import SwiftUI
import FirebaseAuth

struct SnoozeView: View {
    let reminderId: String
    let reminderTitle: String
    let onDismiss: () -> Void

    @State private var snoozeMinutes: Double = 15
    @State private var isProcessing = false
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Dim overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Bottom sheet
            VStack(spacing: Spacing.lg) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.textTertiary)
                    .frame(width: 36, height: 5)
                    .padding(.top, Spacing.md)

                // Reminder title
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.brandBlue)

                    Text(reminderTitle)
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }

                // Snooze slider
                VStack(spacing: Spacing.sm) {
                    Text("Snooze for:")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)

                    Text("\(Int(snoozeMinutes)) min")
                        .font(.snoozeDisplay)
                        .foregroundColor(.brandBlue)
                        .monospacedDigit()

                    Slider(
                        value: $snoozeMinutes,
                        in: 1...60,
                        step: 1
                    )
                    .tint(.brandBlue)
                    .padding(.horizontal, Spacing.md)

                    HStack {
                        Text("1 min")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                        Spacer()
                        Text("60 min")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.horizontal, Spacing.md)
                }

                // Action buttons
                HStack(spacing: Spacing.md) {
                    // Snooze button
                    PrimaryButton(
                        "Snooze",
                        icon: "clock.arrow.circlepath",
                        isLoading: isProcessing
                    ) {
                        handleSnooze()
                    }

                    // Complete button
                    Button {
                        handleComplete()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Complete")
                                .font(.button)
                        }
                        .foregroundColor(.checkGold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(Color.goldBg)
                        )
                    }
                    .disabled(isProcessing)
                }

                Spacer().frame(height: Spacing.sm)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.xl)
                        .fill(Color.surface)

                    if appState.theme.usesGlassMaterial {
                        RoundedRectangle(cornerRadius: CornerRadius.xl)
                            .fill(.ultraThinMaterial)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private func handleSnooze() {
        isProcessing = true
        HapticManager.medium()

        Task {
            await NotificationService.shared.snoozeNotification(
                reminderId: reminderId,
                title: reminderTitle,
                minutes: Int(snoozeMinutes)
            )
            await MainActor.run {
                isProcessing = false
                onDismiss()
            }
        }
    }

    private var isLocalMode: Bool {
        Auth.auth().currentUser == nil
    }

    private func handleComplete() {
        isProcessing = true
        HapticManager.success()

        NotificationService.shared.cancelNotification(for: reminderId)

        if isLocalMode {
            if let reminder = LocalReminderStore.shared.findReminder(byId: reminderId) {
                LocalReminderStore.shared.completeReminder(reminder)
            }
            isProcessing = false
            onDismiss()
        } else {
            let service = ReminderService()
            Task {
                do {
                    let reminders = try await service.fetchReminders()
                    if let reminder = reminders.first(where: { $0.id == reminderId }) {
                        try await service.completeReminder(reminder)
                    }
                } catch {
                    // Error completing reminder
                }
                await MainActor.run {
                    isProcessing = false
                    onDismiss()
                }
            }
        }
    }
}
