//
//  OnboardingView.swift
//  Yomo
//
//  Screen 2: Set your first reminder with AI parse + voice input
//

import SwiftUI
import FirebaseAuth

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var naturalInput = ""
    @State private var parsedTitle = ""
    @State private var parsedDate: Date?
    @State private var parsedTime: Date?
    @State private var parsedDateDisplay = ""
    @State private var parsedTimeDisplay = ""
    @State private var parsedRecurrence = ""
    @State private var parsedRecurrenceType = ""
    @State private var parsedRecurrenceInterval: Int?
    @State private var parsedRecurrenceUnit: String?
    @State private var parsedDaysOfWeek: [String]?
    @State private var showParsed = false
    @State private var isSaving = false
    @State private var isParsing = false

    // Voice input
    @StateObject private var speechTranscriber = SpeechTranscriber()
    @State private var isVoicePrefillActive = false
    @State private var shouldParseOnVoiceStop = false
    @State private var isHoldingParse = false
    @State private var holdToTalkWorkItem: DispatchWorkItem?
    @State private var showSpeechPermissionAlert = false
    @State private var speechPermissionMessage = ""

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

                    Text("Type or speak what to remember.")
                        .font(.bodyRegular)
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

                Spacer().frame(height: Spacing.xl)

                // AI input card
                GlassCard {
                    TextField(
                        "Coffee tomorrow 10am",
                        text: $naturalInput,
                        axis: .vertical
                    )
                    .font(.bodyRegular)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1...4)
                }
                .padding(.horizontal, Spacing.lg)

                // Listening indicator
                if speechTranscriber.isRecording {
                    Text("Listening...")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.xs)
                }

                // Hold-to-talk parse button
                HStack {
                    Spacer()
                    holdToTalkParseButton
                    Spacer()
                }
                .padding(.top, Spacing.md)

                Text("Tip: tap to parse. Press and hold to talk, release to stop and parse.")
                    .font(.bodySmall)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.xs)

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
                                    Image(systemName: "text.alignleft")
                                        .foregroundColor(.brandBlue)
                                    Text(parsedTitle)
                                        .font(.titleSmall)
                                        .foregroundColor(.textPrimary)
                                }

                                HStack(spacing: Spacing.lg) {
                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.brandBlue)
                                        Text(parsedDateDisplay)
                                            .font(.bodyRegular)
                                            .foregroundColor(.textPrimary)
                                    }
                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: "clock")
                                            .foregroundColor(.brandBlue)
                                        Text(parsedTimeDisplay)
                                            .font(.bodyRegular)
                                            .foregroundColor(.textPrimary)
                                    }
                                }

                                if !parsedRecurrence.isEmpty {
                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .foregroundColor(.brandBlue)
                                        Text(parsedRecurrence)
                                            .font(.bodyRegular)
                                            .foregroundColor(.brandBlue)
                                    }
                                }
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
        .onChange(of: speechTranscriber.transcript) { newValue in
            if isVoicePrefillActive {
                naturalInput = newValue
            }
        }
        .onChange(of: speechTranscriber.isRecording) { isRecording in
            guard !isRecording else { return }

            if shouldParseOnVoiceStop {
                shouldParseOnVoiceStop = false
                isVoicePrefillActive = false

                let trimmed = naturalInput.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    parseInput()
                }
            } else {
                isVoicePrefillActive = false
            }
        }
        .onDisappear {
            isVoicePrefillActive = false
            shouldParseOnVoiceStop = false
            holdToTalkWorkItem?.cancel()
            holdToTalkWorkItem = nil
            speechTranscriber.stopTranscribing()
        }
        .alert("Voice Input", isPresented: $showSpeechPermissionAlert) {
            Button("OK") {}
        } message: {
            Text(speechPermissionMessage)
        }
    }

    // MARK: - Hold-to-Talk Parse Button

    private var holdToTalkParseButton: some View {
        let trimmed = naturalInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let canTapParse = !isParsing && !trimmed.isEmpty

        let buttonTitle: String = if speechTranscriber.isRecording {
            "Release to Stop"
        } else if isParsing {
            "Parsing..."
        } else {
            "Parse"
        }

        let icon: String = speechTranscriber.isRecording ? "waveform" : "sparkles"
        let fill: Color = speechTranscriber.isRecording ? .dangerRed : .brandBlue

        return HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(buttonTitle)
                .font(.pillLabel)
        }
        .foregroundColor(.white)
        .padding(.horizontal, Spacing.md)
        .frame(height: 36)
        .background(
            Capsule()
                .fill(fill)
        )
        .opacity((canTapParse || speechTranscriber.isRecording) ? 1 : 0.55)
        .contentShape(Capsule())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !speechTranscriber.isRecording else { return }
                    guard holdToTalkWorkItem == nil else { return }

                    isHoldingParse = true
                    let work = DispatchWorkItem { startVoiceFromHoldIfNeeded() }
                    holdToTalkWorkItem = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
                }
                .onEnded { _ in
                    let wasRecording = speechTranscriber.isRecording
                    isHoldingParse = false

                    holdToTalkWorkItem?.cancel()
                    holdToTalkWorkItem = nil

                    if wasRecording {
                        speechTranscriber.stopTranscribing()
                    } else if canTapParse {
                        parseInput()
                    }
                }
        )
        .accessibilityLabel(speechTranscriber.isRecording ? "Stop voice input" : "Parse")
        .accessibilityHint("Tap to parse typed text. Press and hold to speak.")
    }

    // MARK: - Actions

    private func startVoiceFromHoldIfNeeded() {
        guard isHoldingParse else { return }
        guard !speechTranscriber.isRecording else { return }

        HapticManager.light()

        Task {
            let ok = await speechTranscriber.requestPermissionsIfNeeded()
            guard ok else {
                await MainActor.run {
                    speechPermissionMessage = speechTranscriber.lastErrorMessage
                        ?? "Please allow Microphone and Speech Recognition permissions in Settings."
                    showSpeechPermissionAlert = true
                }
                return
            }

            await MainActor.run {
                shouldParseOnVoiceStop = true
                isVoicePrefillActive = true
                speechTranscriber.startTranscribing()
            }
        }
    }

    private func parseInput() {
        let trimmed = naturalInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isParsing = true
        HapticManager.light()

        Task {
            let result = await AIParsingService.shared.parseNaturalLanguage(trimmed)
                ?? AIParsingService.shared.parseLocally(trimmed)

            await MainActor.run {
                applyParsedResult(result)
                isParsing = false
                HapticManager.success()
            }
        }
    }

    private func applyParsedResult(_ parsed: ParsedReminder) {
        parsedTitle = parsed.title
        parsedDate = parsed.date
        parsedTime = parsed.time

        // Date display
        if let d = parsed.date {
            let calendar = Calendar.current
            if calendar.isDateInToday(d) {
                parsedDateDisplay = "Today"
            } else if calendar.isDateInTomorrow(d) {
                parsedDateDisplay = "Tomorrow"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                parsedDateDisplay = formatter.string(from: d)
            }
        } else {
            parsedDateDisplay = "Tomorrow"
        }

        // Time display
        if let t = parsed.time {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            parsedTimeDisplay = formatter.string(from: t)
        } else {
            parsedTimeDisplay = "3:00 PM"
        }

        // Recurrence
        parsedRecurrenceType = parsed.recurrenceType
        parsedRecurrenceInterval = parsed.recurrenceInterval
        parsedRecurrenceUnit = parsed.recurrenceUnit
        parsedDaysOfWeek = parsed.daysOfWeek

        switch parsed.recurrenceType {
        case "daily": parsedRecurrence = "Every day"
        case "weekly":
            if let days = parsed.daysOfWeek, !days.isEmpty {
                parsedRecurrence = "Every \(days.map { $0.capitalized }.joined(separator: ", "))"
            } else {
                parsedRecurrence = "Every week"
            }
        case "custom":
            if let interval = parsed.recurrenceInterval, let unit = parsed.recurrenceUnit {
                parsedRecurrence = interval == 1 ? "Every \(unit)" : "Every \(interval) \(unit)s"
            } else {
                parsedRecurrence = "Custom"
            }
        default:
            parsedRecurrence = ""
        }

        withAnimation {
            showParsed = true
        }
    }

    private func saveFirstReminder() {
        isSaving = true

        let calendar = Calendar.current
        let baseDate = parsedDate ?? calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let baseTime = parsedTime ?? calendar.date(from: DateComponents(hour: 15)) ?? Date()

        let dateComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: baseTime)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        let triggerDate = calendar.date(from: combined) ?? baseDate
        let recurrence = buildRecurrenceRule()

        let reminder = Reminder.new(
            title: parsedTitle.isEmpty ? naturalInput : parsedTitle,
            triggerDate: triggerDate,
            recurrence: recurrence
        )

        // Use local store if no Firebase Auth
        if Auth.auth().currentUser == nil {
            LocalReminderStore.shared.createReminder(reminder)
            HapticManager.success()
            onComplete()
        } else {
            Task {
                do {
                    let service = ReminderService()
                    try await service.createReminder(reminder)
                    HapticManager.success()
                    onComplete()
                } catch {
                    isSaving = false
                }
            }
        }
    }

    private func buildRecurrenceRule() -> RecurrenceRule? {
        switch parsedRecurrenceType {
        case "daily":
            return .daily()
        case "weekly":
            let dayMap = ["sun": 1, "mon": 2, "tue": 3, "wed": 4, "thu": 5, "fri": 6, "sat": 7]
            let days = parsedDaysOfWeek?.compactMap { dayMap[$0.lowercased()] } ?? []
            return .weekly(on: days)
        case "custom":
            let interval = parsedRecurrenceInterval ?? 1
            let unit: RecurrenceRule.RecurrenceUnit
            switch parsedRecurrenceUnit {
            case "hour": unit = .hour
            case "week": unit = .week
            case "month": unit = .month
            default: unit = .day
            }
            return RecurrenceRule(
                type: .custom,
                interval: interval,
                unit: unit,
                daysOfWeek: nil,
                timeRangeStart: nil,
                timeRangeEnd: nil,
                basedOnCompletion: false
            )
        default:
            return nil
        }
    }
}
