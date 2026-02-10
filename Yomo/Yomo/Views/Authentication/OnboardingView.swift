//
//  OnboardingView.swift
//  Yomo
//
//  Screen 2: Set your first reminder with AI parse
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var naturalInput = ""
    @State private var parsedTitle = ""
    @State private var parsedDate = ""
    @State private var parsedTime = ""
    @State private var parsedRecurrence = ""
    @State private var showParsed = false
    @State private var isSaving = false
    var onComplete: () -> Void
    var onSkip: () -> Void

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(alignment: .leading, spacing: 0) {
                // Back button
                Button(action: onSkip) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .padding(.leading, Spacing.md)

                // Header
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Let's set your first reminder.")
                        .font(.titleLarge)
                        .foregroundColor(.textPrimary)

                    Text("Just type what to remember.")
                        .font(.bodyRegular)
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

                Spacer().frame(height: Spacing.xl)

                // AI input card
                GlassCard {
                    TextField(
                        "Water plants every Tuesday at 3pm",
                        text: $naturalInput,
                        axis: .vertical
                    )
                    .font(.bodyRegular)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2...4)
                }
                .padding(.horizontal, Spacing.lg)

                // Parse button
                HStack {
                    Spacer()
                    PillButton("Parse Reminder", isActive: true, icon: "sparkles") {
                        parseReminder()
                    }
                    Spacer()
                }
                .padding(.top, Spacing.md)

                // Parsed result
                if showParsed {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Nice! Here's what I got:")
                            .font(.bodyRegular)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, Spacing.lg)

                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                HStack(spacing: Spacing.sm) {
                                    Text("📝")
                                    Text(parsedTitle)
                                        .font(.titleSmall)
                                        .foregroundColor(.textPrimary)
                                }

                                HStack(spacing: Spacing.lg) {
                                    HStack(spacing: Spacing.sm) {
                                        Text("📅")
                                        Text(parsedDate)
                                            .font(.bodyRegular)
                                            .foregroundColor(.textPrimary)
                                    }
                                    HStack(spacing: Spacing.sm) {
                                        Text("🕐")
                                        Text(parsedTime)
                                            .font(.bodyRegular)
                                            .foregroundColor(.textPrimary)
                                    }
                                }

                                if !parsedRecurrence.isEmpty {
                                    HStack(spacing: Spacing.sm) {
                                        Text("🔁")
                                        Text(parsedRecurrence)
                                            .font(.bodyRegular)
                                            .foregroundColor(.brandBlue)
                                    }
                                }

                                Text("Tap any field to adjust.")
                                    .font(.bodySmall)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.top, Spacing.lg)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                // Save button
                if showParsed {
                    PrimaryButton(
                        "Save my first reminder",
                        icon: "checkmark",
                        isLoading: isSaving
                    ) {
                        saveFirstReminder()
                    }
                    .padding(.horizontal, Spacing.lg)
                    .transition(.opacity)
                }

                // Skip
                HStack {
                    Spacer()
                    Button {
                        onSkip()
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Text("Skip for now")
                                .font(.bodyRegular)
                                .foregroundColor(.textSecondary)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, Spacing.lg)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showParsed)
    }

    private func parseReminder() {
        guard !naturalInput.isEmpty else { return }
        // Simple local parse for MVP (AI integration in Day 6)
        parsedTitle = extractTitle(from: naturalInput)
        parsedDate = extractDate(from: naturalInput)
        parsedTime = extractTime(from: naturalInput)
        parsedRecurrence = extractRecurrence(from: naturalInput)

        withAnimation {
            showParsed = true
        }
    }

    private func saveFirstReminder() {
        isSaving = true
        // Create and save reminder via service
        let triggerDate = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Date()
        ) ?? Date()

        let reminder = Reminder.new(
            title: parsedTitle.isEmpty ? naturalInput : parsedTitle,
            triggerDate: triggerDate
        )

        Task {
            do {
                let service = ReminderService()
                try await service.createReminder(reminder)
                onComplete()
            } catch {
                isSaving = false
            }
        }
    }

    // MARK: - Simple parsers (placeholder until AI Day 6)
    private func extractTitle(from text: String) -> String {
        let words = text.components(separatedBy: " ")
        let stopWords = ["every", "at", "on", "tomorrow", "today", "daily", "weekly", "am", "pm"]
        let titleWords = words.filter { word in
            !stopWords.contains(word.lowercased()) &&
            !word.contains(":") &&
            Int(word) == nil
        }
        return titleWords.prefix(5).joined(separator: " ").capitalized
    }

    private func extractDate(from text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("tomorrow") { return "Tomorrow" }
        if lower.contains("today") { return "Today" }
        let dayNames = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        for day in dayNames {
            if lower.contains(day) { return day.capitalized }
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }

    private func extractTime(from text: String) -> String {
        let pattern = #"(\d{1,2}):?(\d{2})?\s*(am|pm|AM|PM)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            return String(text[Range(match.range, in: text)!]).uppercased()
        }
        let numberPattern = #"(\d{1,2})\s*(am|pm|AM|PM)"#
        if let regex = try? NSRegularExpression(pattern: numberPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            let matched = String(text[Range(match.range, in: text)!])
            return matched.uppercased()
        }
        return "3:00 PM"
    }

    private func extractRecurrence(from text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("every day") || lower.contains("daily") { return "Every day" }
        if lower.contains("every week") || lower.contains("weekly") { return "Every week" }
        let dayNames = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        for day in dayNames {
            if lower.contains("every \(day)") { return "Every \(day.capitalized)" }
        }
        return ""
    }
}
