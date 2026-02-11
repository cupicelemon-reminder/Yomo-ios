//
//  UsageLimitService.swift
//  Yomo
//
//  Tracks daily AI usage limits for free users.
//  Pro users have unlimited access.
//

import Foundation

final class UsageLimitService {
    static let shared = UsageLimitService()

    private let voiceKey = "usageLimit_voiceUses"
    private let parseKey = "usageLimit_parseUses"
    private let dateKey = "usageLimit_lastResetDate"

    private let maxFreeVoice = 1
    private let maxFreeParse = 3

    private let defaults = UserDefaults.standard

    private init() {
        resetIfNewDay()
    }

    // MARK: - Public API

    var voiceUsesToday: Int {
        resetIfNewDay()
        return defaults.integer(forKey: voiceKey)
    }

    var textParseUsesToday: Int {
        resetIfNewDay()
        return defaults.integer(forKey: parseKey)
    }

    var remainingVoiceUses: Int {
        max(0, maxFreeVoice - voiceUsesToday)
    }

    var remainingParseUses: Int {
        max(0, maxFreeParse - textParseUsesToday)
    }

    func canUseVoice(isPro: Bool) -> Bool {
        if isPro { return true }
        resetIfNewDay()
        return defaults.integer(forKey: voiceKey) < maxFreeVoice
    }

    func canUseTextParse(isPro: Bool) -> Bool {
        if isPro { return true }
        resetIfNewDay()
        return defaults.integer(forKey: parseKey) < maxFreeParse
    }

    func recordVoiceUse() {
        resetIfNewDay()
        let current = defaults.integer(forKey: voiceKey)
        defaults.set(current + 1, forKey: voiceKey)
    }

    func recordTextParseUse() {
        resetIfNewDay()
        let current = defaults.integer(forKey: parseKey)
        defaults.set(current + 1, forKey: parseKey)
    }

    // MARK: - Private

    private func resetIfNewDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastReset = defaults.object(forKey: dateKey) as? Date {
            let lastDay = calendar.startOfDay(for: lastReset)
            if lastDay >= today { return }
        }

        defaults.set(0, forKey: voiceKey)
        defaults.set(0, forKey: parseKey)
        defaults.set(today, forKey: dateKey)
    }
}
