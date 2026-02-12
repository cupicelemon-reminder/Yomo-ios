//
//  NewReminderView.swift
//  Yomo
//
//  Screen 6: Bottom sheet for creating new reminders with AI input
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Speech
import AVFoundation

struct NewReminderView: View {
    @Environment(\.dismiss) var dismiss
    @State private var naturalInput = ""
    @State private var title = ""
    @State private var date = Date()
    @State private var time = Date()
    @State private var notes = ""
    @State private var selectedRecurrence: RecurrenceType = .none
    @State private var isSaving = false
    @State private var isParsing = false
    @State private var errorMessage: String?
    @State private var showPaywall = false
    @State private var debouncedAIParseTask: Task<Void, Never>?

    // Advanced recurrence state
    @State private var customInterval: Int = 1
    @State private var customUnit: RecurrenceUnit = .day
    @State private var customDaysOfWeek: [Int] = []
    @State private var customTimeRangeStart = Calendar.current.date(from: DateComponents(hour: 9)) ?? Date()
    @State private var customTimeRangeEnd = Calendar.current.date(from: DateComponents(hour: 18)) ?? Date()
    @State private var basedOnCompletion: Bool = false
    @StateObject private var speechTranscriber = SpeechTranscriber()
    @State private var isVoicePrefillActive = false
    @State private var shouldParseOnVoiceStop = false
    @State private var isHoldingParse = false
    @State private var holdToTalkWorkItem: DispatchWorkItem?
    @State private var showSpeechPermissionAlert = false
    @State private var speechPermissionMessage: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Drag handle
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.textTertiary)
                            .frame(width: 36, height: 5)
                        Spacer()
                    }
                    .padding(.top, Spacing.sm)

                    // AI Input
                    aiInputSection

                    // Divider
                    dividerSection

                    // Manual form
                    manualFormSection

                    if let error = errorMessage {
                        Text(error)
                            .font(.bodySmall)
                            .foregroundColor(.dangerRed)
                    }

                    PrimaryButton(
                        "Save Reminder",
                        icon: "checkmark",
                        isLoading: isSaving,
                        isDisabled: title.isEmpty
                    ) {
                        saveReminder()
                    }
                    .padding(.top, Spacing.sm)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.background)
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.brandBlue)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onChange(of: naturalInput) { newValue in
            // Live typing updates should not fight voice prefilling.
            guard !isVoicePrefillActive else { return }

            // Immediate local parse keeps UI responsive.
            let local = AIParsingService.shared.parseLocally(newValue)
            applyParsedReminder(local)

            // Debounced AI parse (best effort). This is intentionally quiet (no spinner).
            debouncedAIParseTask?.cancel()
            let snapshot = newValue
            debouncedAIParseTask = Task {
                try? await Task.sleep(nanoseconds: 900_000_000)
                guard !Task.isCancelled else { return }

                let trimmed = snapshot.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 4 else { return }

                let parsed = await AIParsingService.shared.parseNaturalLanguage(trimmed)
                    ?? AIParsingService.shared.parseLocally(trimmed)

                await MainActor.run {
                    // Apply only if the user hasn't changed the input since the task started.
                    guard naturalInput == snapshot else { return }
                    guard !isVoicePrefillActive else { return }
                    applyParsedReminder(parsed)
                }
            }
        }
        .onChange(of: speechTranscriber.transcript) { newValue in
            if isVoicePrefillActive {
                naturalInput = newValue
            }
        }
        .onChange(of: speechTranscriber.isRecording) { isRecording in
            // When recording stops (manual release, silence auto-stop, or recognizer final),
            // parse exactly once if this recording session requested it.
            guard !isRecording else { return }

            if shouldParseOnVoiceStop {
                shouldParseOnVoiceStop = false
                isVoicePrefillActive = false
                UsageLimitService.shared.recordVoiceUse()

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
            debouncedAIParseTask?.cancel()
            debouncedAIParseTask = nil
            speechTranscriber.stopTranscribing()
        }
        .alert("Voice Input", isPresented: $showSpeechPermissionAlert) {
            Button("OK") {}
        } message: {
            Text(speechPermissionMessage)
        }
    }

    // MARK: - AI Input Section

    private var aiInputSection: some View {
        VStack(spacing: Spacing.md) {
            GlassCard {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    TextField(
                        "Type or speak: 'Coffee tomorrow 10am'",
                        text: $naturalInput,
                        axis: .vertical
                    )
                    .font(.bodyRegular)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1...3)
                }
            }

            if speechTranscriber.isRecording {
                Text("Listening...")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }

            HStack {
                Spacer()
                holdToTalkParseButton
                Spacer()
            }

            Text("Tip: tap to parse. Press and hold to talk, release to stop and parse.")
                .font(.bodySmall)
                .foregroundColor(.textTertiary)

            if !AppState.shared.isPro {
                usageLimitIndicator
            }
        }
    }

    private var usageLimitIndicator: some View {
        let limits = UsageLimitService.shared
        let parsesLeft = limits.remainingParseUses
        let voiceLeft = limits.remainingVoiceUses
        return Text("\(parsesLeft) parse\(parsesLeft == 1 ? "" : "s") · \(voiceLeft) voice left today")
            .font(.bodySmall)
            .foregroundColor(.textTertiary)
    }

    private var holdToTalkParseButton: some View {
        let trimmed = naturalInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let canTapParse = !isParsing && !trimmed.isEmpty

        let title: String = if speechTranscriber.isRecording {
            "Release to Stop"
        } else if isParsing {
            "Parsing..."
        } else {
            "Parse"
        }

        let icon: String = speechTranscriber.isRecording ? "waveform" : "mic.fill"
        let fill: Color = speechTranscriber.isRecording ? .dangerRed : .brandBlue

        return HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
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
        .scaleEffect(isHoldingParse && !speechTranscriber.isRecording ? 0.92 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHoldingParse)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(speechTranscriber.isRecording ? "Stop voice input" : "Parse")
        .accessibilityHint("Tap to parse typed text. Press and hold to speak, release to stop and parse.")
    }

    // MARK: - Divider

    private var dividerSection: some View {
        HStack(spacing: Spacing.sm) {
            Rectangle()
                .fill(Color.dividerColor)
                .frame(height: 1)
            Text("or fill in manually")
                .font(.bodySmall)
                .foregroundColor(.textTertiary)
                .layoutPriority(1)
            Rectangle()
                .fill(Color.dividerColor)
                .frame(height: 1)
        }
    }

    // MARK: - Manual Form

    private var manualFormSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            FormField(
                label: "Title",
                placeholder: "Reminder title",
                text: $title
            )

            HStack(spacing: Spacing.md) {
                DateFormField(
                    label: "Date",
                    date: $date,
                    displayedComponents: [.date]
                )
                DateFormField(
                    label: "Time",
                    date: $time,
                    displayedComponents: [.hourAndMinute]
                )
            }

            FormField(
                label: "Notes",
                placeholder: "Add additional details...",
                text: $notes,
                axis: .vertical
            )

            // Recurrence selection
            recurrenceSection

            // Custom recurrence editor (Pro)
            if selectedRecurrence == .custom && AppState.shared.isPro {
                CustomRecurrenceEditor(
                    interval: $customInterval,
                    unit: $customUnit,
                    daysOfWeek: $customDaysOfWeek,
                    timeRangeStart: $customTimeRangeStart,
                    timeRangeEnd: $customTimeRangeEnd,
                    basedOnCompletion: $basedOnCompletion
                )
            }
        }
    }

    // MARK: - Recurrence

    private var recurrenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("REPEAT")
                .font(.caption)
                .foregroundColor(.textSecondary)
                .tracking(0.5)

            HStack(spacing: Spacing.sm) {
                PillButton("None", isActive: selectedRecurrence == .none) {
                    selectedRecurrence = .none
                }
                PillButton("Daily", isActive: selectedRecurrence == .daily) {
                    selectedRecurrence = .daily
                }
                PillButton("Weekly", isActive: selectedRecurrence == .weekly) {
                    selectedRecurrence = .weekly
                }
                PillButton("Custom", isActive: selectedRecurrence == .custom, icon: "sparkles") {
                    if AppState.shared.isPro {
                        selectedRecurrence = .custom
                    } else {
                        showPaywall = true
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func startVoiceFromHoldIfNeeded() {
        guard isHoldingParse else { return }
        guard !speechTranscriber.isRecording else { return }

        if !UsageLimitService.shared.canUseVoice(isPro: AppState.shared.isPro) {
            showPaywall = true
            return
        }

        HapticManager.light()
        debouncedAIParseTask?.cancel()
        debouncedAIParseTask = nil

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

        if !UsageLimitService.shared.canUseTextParse(isPro: AppState.shared.isPro) {
            showPaywall = true
            return
        }

        isParsing = true
        HapticManager.light()
        UsageLimitService.shared.recordTextParseUse()

        debouncedAIParseTask?.cancel()
        debouncedAIParseTask = nil

        Task {
            let result = await AIParsingService.shared.parseNaturalLanguage(trimmed)

            await MainActor.run {
                if let parsed = result {
                    applyParsedReminder(parsed)
                }
                isParsing = false
                HapticManager.success()
            }
        }
    }

    private func applyParsedReminder(_ parsed: ParsedReminder) {
        title = parsed.title

        if let parsedDate = parsed.date {
            date = parsedDate
        }

        if let parsedTime = parsed.time {
            time = parsedTime
        }

        switch parsed.recurrenceType {
        case "daily": selectedRecurrence = .daily
        case "weekly": selectedRecurrence = .weekly
        case "custom": selectedRecurrence = .custom
        default: selectedRecurrence = .none
        }

        if let days = parsed.daysOfWeek {
            let dayMap = ["sun": 1, "mon": 2, "tue": 3, "wed": 4, "thu": 5, "fri": 6, "sat": 7]
            customDaysOfWeek = days.compactMap { dayMap[$0.lowercased()] }
        }

        if let interval = parsed.recurrenceInterval {
            customInterval = interval
        }
        if let unit = parsed.recurrenceUnit {
            switch unit {
            case "hour": customUnit = .hour
            case "day": customUnit = .day
            case "week": customUnit = .week
            case "month": customUnit = .month
            default: break
            }
        }
    }

    private func saveReminder() {
        isSaving = true
        errorMessage = nil

        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        let triggerDate = calendar.date(from: combined) ?? date
        let recurrence = buildRecurrenceRule()

        let reminder = Reminder.new(
            title: title,
            triggerDate: triggerDate,
            notes: notes.isEmpty ? nil : notes,
            recurrence: recurrence
        )

        // Use local store if no Firebase Auth (dev login / free tier)
        if FirebaseAuth.Auth.auth().currentUser == nil {
            LocalReminderStore.shared.createReminder(reminder)
            HapticManager.success()
            dismiss()
        } else {
            Task {
                do {
                    let service = ReminderService()
                    try await service.createReminder(reminder)
                    HapticManager.success()
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }

    private func buildRecurrenceRule() -> RecurrenceRule? {
        switch selectedRecurrence {
        case .none:
            return nil
        case .daily:
            return .daily()
        case .weekly:
            return .weekly(on: customDaysOfWeek)
        case .custom:
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"

            return RecurrenceRule(
                type: .custom,
                interval: customInterval,
                unit: customUnit,
                daysOfWeek: customUnit == .week ? customDaysOfWeek : nil,
                timeRangeStart: customUnit == .hour ? formatter.string(from: customTimeRangeStart) : nil,
                timeRangeEnd: customUnit == .hour ? formatter.string(from: customTimeRangeEnd) : nil,
                basedOnCompletion: basedOnCompletion
            )
        }
    }
}

@MainActor
final class SpeechTranscriber: NSObject, ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false

    private let recognizer = SFSpeechRecognizer(locale: Locale.current)
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceWorkItem: DispatchWorkItem?
    private let silenceTimeout: TimeInterval = 1.4

    private(set) var lastErrorMessage: String?

    func requestPermissionsIfNeeded() async -> Bool {
        // Speech recognition permission
        let speechStatus: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            lastErrorMessage = "Speech recognition permission is required to use voice input."
            return false
        }

        // Microphone permission
        let micGranted: Bool = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        guard micGranted else {
            lastErrorMessage = "Microphone permission is required to use voice input."
            return false
        }

        lastErrorMessage = nil
        return true
    }

    func startTranscribing() {
        guard !isRecording else { return }
        guard let recognizer else {
            lastErrorMessage = "Speech recognition is not available on this device."
            return
        }

        transcript = ""
        lastErrorMessage = nil
        isRecording = true
        silenceWorkItem?.cancel()
        silenceWorkItem = nil

        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            lastErrorMessage = "Unable to start audio session."
            stopTranscribing()
            return
        }

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            lastErrorMessage = "Unable to start recording."
            stopTranscribing()
            return
        }

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    self.resetSilenceAutoStop()
                }

                if error != nil || (result?.isFinal ?? false) {
                    self.stopTranscribing()
                }
            }
        }
    }

    func stopTranscribing() {
        guard isRecording else { return }

        silenceWorkItem?.cancel()
        silenceWorkItem = nil

        isRecording = false

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()

        task?.cancel()
        task = nil
        request = nil
        audioEngine = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func resetSilenceAutoStop() {
        silenceWorkItem?.cancel()

        let snapshot = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !snapshot.isEmpty else { return }

        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.isRecording else { return }

            let current = self.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard current == snapshot else { return }

            self.stopTranscribing()
        }

        silenceWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + silenceTimeout, execute: item)
    }
}
