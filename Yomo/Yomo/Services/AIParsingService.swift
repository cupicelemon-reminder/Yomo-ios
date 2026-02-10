//
//  AIParsingService.swift
//  Yomo
//
//  AI-powered natural language reminder parsing using Claude or OpenAI
//

import Foundation

struct ParsedReminder {
    let title: String
    let date: Date?
    let time: Date?
    let recurrenceType: String
    let recurrenceInterval: Int?
    let recurrenceUnit: String?
    let daysOfWeek: [String]?
}

final class AIParsingService {
    static let shared = AIParsingService()

    private init() {}

    // MARK: - Parse Input

    func parseNaturalLanguage(_ input: String) async -> ParsedReminder? {
        let now = Date()

        // Handle relative time phrases locally for reliability (e.g. "after 10min", "in 2 hours").
        // We'll still use the AI to extract title/recurrence, but we override the computed time.
        let relativeMatch = RelativeTimeParser.match(in: input, now: now)
        let normalizedInput = relativeMatch?.cleanedInput ?? input

        // Priority: OpenRouter > Claude direct > OpenAI direct > local fallback
        let parsed: ParsedReminder? = if !Constants.openRouterAPIKey.isEmpty {
            await parseWithOpenRouter(normalizedInput)
        } else if !Constants.claudeAPIKey.isEmpty {
            await parseWithClaude(normalizedInput)
        } else if !Constants.openaiAPIKey.isEmpty {
            await parseWithOpenAI(normalizedInput)
        } else {
            parseLocally(normalizedInput)
        }

        guard let relativeMatch else { return parsed }

        let target = relativeMatch.targetDate
        let base = parsed ?? parseLocally(normalizedInput)

        // Apply the relative time as an absolute date/time to drive the UI Date+Time pickers.
        return ParsedReminder(
            title: base.title,
            date: target,
            time: target,
            recurrenceType: base.recurrenceType,
            recurrenceInterval: base.recurrenceInterval,
            recurrenceUnit: base.recurrenceUnit,
            daysOfWeek: base.daysOfWeek
        )
    }

    // MARK: - OpenRouter API (primary)

    private func parseWithOpenRouter(_ input: String) async -> ParsedReminder? {
        let prompt = buildPrompt(input)

        var request = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(Constants.openRouterAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Yomo/1.0", forHTTPHeaderField: "X-Title")

        let body: [String: Any] = [
            "model": "google/gemini-2.0-flash-001",
            "max_tokens": 256,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return parseLocally(input)
            }

            // OpenRouter uses OpenAI-compatible response format
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String,
               let jsonData = content.data(using: .utf8) {
                return parseJSONResponse(jsonData)
            }

            return parseLocally(input)
        } catch {
            return parseLocally(input)
        }
    }

    // MARK: - Claude API

    private func parseWithClaude(_ input: String) async -> ParsedReminder? {
        let prompt = buildPrompt(input)

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.addValue(Constants.claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 256,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return parseLocally(input)
            }

            return parseAPIResponse(data)
        } catch {
            return parseLocally(input)
        }
    }

    // MARK: - OpenAI API

    private func parseWithOpenAI(_ input: String) async -> ParsedReminder? {
        let prompt = buildPrompt(input)

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(Constants.openaiAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "max_tokens": 256,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return parseLocally(input)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String,
               let jsonData = content.data(using: .utf8) {
                return parseJSONResponse(jsonData)
            }

            return parseLocally(input)
        } catch {
            return parseLocally(input)
        }
    }

    // MARK: - Build Prompt

    private func buildPrompt(_ input: String) -> String {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let todayName = dayNames[dayOfWeek]
        let now = Date()
        let nowTime = ISO8601DateFormatter().string(from: now)

        return """
        Today is \(today) (\(todayName)). The current time is \(nowTime). Extract reminder details from the user input. \
        If the user specifies a relative time (for example: "after 10min", "in 2 hours", "10 minutes later"), compute the absolute date/time relative to now. \
        Return ONLY valid JSON with no extra text:
        {
          "title": "string",
          "date": "YYYY-MM-DD or null",
          "time": "HH:mm or null",
          "recurrence_type": "none" | "daily" | "weekly" | "custom",
          "recurrence_interval": number or null,
          "recurrence_unit": "hour" | "day" | "week" | "month" or null,
          "days_of_week": ["mon","tue",...] or null
        }
        Input: "\(input)"
        """
    }

    // MARK: - Parse API Response

    private func parseAPIResponse(_ data: Data) -> ParsedReminder? {
        // Claude response format: { "content": [{ "text": "..." }] }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String,
              let jsonData = text.data(using: .utf8) else {
            return nil
        }

        return parseJSONResponse(jsonData)
    }

    private func parseJSONResponse(_ data: Data) -> ParsedReminder? {
        // Try to extract JSON from the text (in case there's surrounding text)
        guard let text = String(data: data, encoding: .utf8) else { return nil }

        let jsonString: String
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            jsonString = String(text[startIndex...endIndex])
        } else {
            jsonString = text
        }

        guard let cleanData = jsonString.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: cleanData) as? [String: Any] else {
            return nil
        }

        let title = parsed["title"] as? String ?? ""
        let dateString = parsed["date"] as? String
        let timeString = parsed["time"] as? String
        let recurrenceType = parsed["recurrence_type"] as? String ?? "none"
        let recurrenceInterval = parsed["recurrence_interval"] as? Int
        let recurrenceUnit = parsed["recurrence_unit"] as? String
        let daysOfWeek = parsed["days_of_week"] as? [String]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateString.flatMap { dateFormatter.date(from: $0) }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let time = timeString.flatMap { timeFormatter.date(from: $0) }

        return ParsedReminder(
            title: title,
            date: date,
            time: time,
            recurrenceType: recurrenceType,
            recurrenceInterval: recurrenceInterval,
            recurrenceUnit: recurrenceUnit,
            daysOfWeek: daysOfWeek
        )
    }

    // MARK: - Local Fallback Parser

    func parseLocally(_ input: String) -> ParsedReminder {
        // Relative time support (e.g. "after 10min", "10 minutes later", "10分钟后")
        let now = Date()
        if let relativeMatch = RelativeTimeParser.match(in: input, now: now) {
            let fallback = parseLocally(relativeMatch.cleanedInput)
            return ParsedReminder(
                title: fallback.title,
                date: relativeMatch.targetDate,
                time: relativeMatch.targetDate,
                recurrenceType: fallback.recurrenceType,
                recurrenceInterval: fallback.recurrenceInterval,
                recurrenceUnit: fallback.recurrenceUnit,
                daysOfWeek: fallback.daysOfWeek
            )
        }

        let words = input.components(separatedBy: .whitespaces)
        let lowercased = input.lowercased()

        // Extract time patterns like "3pm", "10:30am", "15:00"
        var extractedTime: Date?
        let timeFormatter = DateFormatter()

        let timePatterns = [
            "\\d{1,2}:\\d{2}\\s*(am|pm)",
            "\\d{1,2}\\s*(am|pm)",
            "\\d{1,2}:\\d{2}"
        ]

        for pattern in timePatterns {
            if let range = lowercased.range(of: pattern, options: .regularExpression) {
                let match = String(lowercased[range])
                for format in ["h:mm a", "h a", "HH:mm", "h:mma", "ha"] {
                    timeFormatter.dateFormat = format
                    if let time = timeFormatter.date(from: match) {
                        extractedTime = time
                        break
                    }
                }
                if extractedTime != nil { break }
            }
        }

        // Extract date references
        var extractedDate: Date?
        let calendar = Calendar.current

        if lowercased.contains("tomorrow") {
            extractedDate = calendar.date(byAdding: .day, value: 1, to: Date())
        } else if lowercased.contains("today") {
            extractedDate = Date()
        } else if lowercased.contains("next week") {
            extractedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: Date())
        } else {
            // Check for day names
            let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
            for (index, dayName) in dayNames.enumerated() {
                if lowercased.contains(dayName) {
                    let targetDay = index + 1 // Calendar weekday is 1-based
                    let currentDay = calendar.component(.weekday, from: Date())
                    var daysAhead = targetDay - currentDay
                    if daysAhead <= 0 { daysAhead += 7 }
                    extractedDate = calendar.date(byAdding: .day, value: daysAhead, to: Date())
                    break
                }
            }
        }

        // Detect recurrence
        var recurrenceType = "none"
        var daysOfWeek: [String]?

        if lowercased.contains("every day") || lowercased.contains("daily") {
            recurrenceType = "daily"
        } else if lowercased.contains("every week") || lowercased.contains("weekly") {
            recurrenceType = "weekly"
        } else if lowercased.contains("every") {
            // Check for "every [day name]"
            let dayAbbrevs = [
                ("monday", "mon"), ("tuesday", "tue"), ("wednesday", "wed"),
                ("thursday", "thu"), ("friday", "fri"), ("saturday", "sat"), ("sunday", "sun")
            ]
            var foundDays: [String] = []
            for (fullName, abbrev) in dayAbbrevs {
                if lowercased.contains(fullName) {
                    foundDays.append(abbrev)
                }
            }
            if !foundDays.isEmpty {
                recurrenceType = "weekly"
                daysOfWeek = foundDays
            }
        }

        // Build title by removing date/time/recurrence words
        let stopWords = Set([
            "at", "on", "every", "tomorrow", "today", "next", "week",
            "am", "pm",
            // relative time
            "after", "in", "later", "from", "now",
            "sec", "secs", "second", "seconds", "s",
            "min", "mins", "minute", "minutes", "m",
            "hr", "hrs", "hour", "hours", "h",
            "day", "days", "d",
            "week", "weeks", "w",
            // recurrence
            "daily", "weekly",
            // filler
            "remind", "me", "to", "the",
            "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
        ])

        let titleWords = words.filter { word in
            let lower = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            if stopWords.contains(lower) { return false }
            // Remove time patterns
            if lower.range(of: "\\d{1,2}(:\\d{2})?(am|pm)?", options: .regularExpression) != nil {
                return false
            }
            return true
        }

        let title = titleWords.isEmpty
            ? input.prefix(50).capitalized
            : titleWords.joined(separator: " ").capitalized

        return ParsedReminder(
            title: String(title.prefix(100)),
            date: extractedDate,
            time: extractedTime,
            recurrenceType: recurrenceType,
            recurrenceInterval: nil,
            recurrenceUnit: nil,
            daysOfWeek: daysOfWeek
        )
    }
}

// MARK: - Relative Time Parsing

private struct RelativeTimeMatch {
    let cleanedInput: String
    let targetDate: Date
}

private enum RelativeTimeParser {
    static func match(in input: String, now: Date) -> RelativeTimeMatch? {
        let lowered = input.lowercased()

        // English examples:
        // - "after 10min", "in 2 hours", "10 minutes later", "in an hour"
        // Chinese examples:
        // - "10分钟后", "2小时后", "1天后"

        let numberToken = "(?:\\d+(?:\\.\\d+)?|a|an|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|couple|half|quarter)"

        let patterns: [(regex: String, numberGroup: Int, unitGroup: Int)] = [
            // "in half an hour", "after quarter hour"
            ("\\b(?:after|in)\\s+(half|quarter)\\s+(?:a\\s+|an\\s+)?(h|hr|hrs|hour|hours)\\b", 1, 2),
            ("\\b(?:after|in)\\s+(" + numberToken + ")\\s*(s|sec|secs|second|seconds|m|min|mins|minute|minutes|h|hr|hrs|hour|hours|d|day|days|w|week|weeks)\\b", 1, 2),
            ("\\b(" + numberToken + ")\\s*(s|sec|secs|second|seconds|m|min|mins|minute|minutes|h|hr|hrs|hour|hours|d|day|days|w|week|weeks)\\s*(?:from\\s+now|later)\\b", 1, 2),
            // Chinese
            ("(?:再|过|等)?\\s*([0-9]+(?:\\.[0-9]+)?|[零一二三四五六七八九十两半]+)\\s*(秒|分钟|分|min|mins|minute|minutes|小时|时|h|hr|hrs|hour|hours|天|日|d|day|days|周|星期|w|week|weeks)\\s*(?:后|之后|以后)", 1, 2)
        ]

        for p in patterns {
            if let m = firstMatch(pattern: p.regex, in: lowered) {
                let numberRaw = m.group(p.numberGroup) ?? ""
                let unitRaw = m.group(p.unitGroup) ?? ""
                guard let value = parseNumberValue(numberRaw),
                      let multiplier = parseUnitMultiplier(unitRaw) else {
                    continue
                }

                let seconds = TimeInterval(value) * multiplier
                let target = now.addingTimeInterval(seconds)

                let cleaned = removeSubstring(input, range: m.rangeInOriginal)
                return RelativeTimeMatch(cleanedInput: cleaned, targetDate: target)
            }
        }

        // Also support compact formats like "in10min" or "after10m" (no whitespace).
        // We'll only check if the string contains the keyword to avoid false positives.
        if lowered.contains("in") || lowered.contains("after") {
            let compact = "(?:in|after)\\s*(\\d+(?:\\.\\d+)?)\\s*(m|min|mins|minute|minutes|h|hr|hrs|hour|hours|s|sec|secs|second|seconds|d|day|days|w|week|weeks)\\b"
            if let m = firstMatch(pattern: compact, in: lowered),
               let numberRaw = m.group(1),
               let unitRaw = m.group(2),
               let value = Double(numberRaw),
               let multiplier = parseUnitMultiplier(unitRaw) {
                let target = now.addingTimeInterval(TimeInterval(value) * multiplier)
                let cleaned = removeSubstring(input, range: m.rangeInOriginal)
                return RelativeTimeMatch(cleanedInput: cleaned, targetDate: target)
            }
        }

        return nil
    }

    // MARK: - Helpers

    private static func parseNumberValue(_ token: String) -> Double? {
        if let v = Double(token) { return v }

        switch token {
        case "a", "an": return 1
        case "one": return 1
        case "two": return 2
        case "three": return 3
        case "four": return 4
        case "five": return 5
        case "six": return 6
        case "seven": return 7
        case "eight": return 8
        case "nine": return 9
        case "ten": return 10
        case "eleven": return 11
        case "twelve": return 12
        case "thirteen": return 13
        case "fourteen": return 14
        case "fifteen": return 15
        case "sixteen": return 16
        case "seventeen": return 17
        case "eighteen": return 18
        case "nineteen": return 19
        case "twenty": return 20
        case "thirty": return 30
        case "forty": return 40
        case "fifty": return 50
        case "sixty": return 60
        case "seventy": return 70
        case "eighty": return 80
        case "ninety": return 90
        case "couple": return 2
        case "half": return 0.5
        case "quarter": return 0.25
        default:
            return parseChineseNumeral(token)
        }
    }

    private static func parseChineseNumeral(_ token: String) -> Double? {
        if token == "半" { return 0.5 }

        let digits: [Character: Int] = [
            "零": 0,
            "一": 1,
            "二": 2,
            "两": 2,
            "三": 3,
            "四": 4,
            "五": 5,
            "六": 6,
            "七": 7,
            "八": 8,
            "九": 9
        ]

        // Handle 1..99 with '十'
        if token == "十" { return 10 }
        if token.contains("十") {
            let parts = token.split(separator: "十", omittingEmptySubsequences: false)
            let tensPart = parts.first.map(String.init) ?? ""
            let onesPart = parts.count > 1 ? String(parts[1]) : ""

            let tens: Int = if tensPart.isEmpty {
                1
            } else if let c = tensPart.first, let d = digits[c] {
                d
            } else {
                0
            }

            let ones: Int = if onesPart.isEmpty {
                0
            } else if let c = onesPart.first, let d = digits[c] {
                d
            } else {
                0
            }

            return Double(tens * 10 + ones)
        }

        if token.count == 1, let c = token.first, let d = digits[c] {
            return Double(d)
        }

        return nil
    }

    private static func parseUnitMultiplier(_ token: String) -> TimeInterval? {
        switch token {
        case "s", "sec", "secs", "second", "seconds", "秒":
            return 1
        case "m", "min", "mins", "minute", "minutes", "分", "分钟":
            return 60
        case "h", "hr", "hrs", "hour", "hours", "时", "小时":
            return 60 * 60
        case "d", "day", "days", "日", "天":
            return 60 * 60 * 24
        case "w", "week", "weeks", "周", "星期":
            return 60 * 60 * 24 * 7
        default:
            return nil
        }
    }

    private static func removeSubstring(_ input: String, range: Range<String.Index>) -> String {
        var s = input
        s.removeSubrange(range)
        // Collapse extra whitespace.
        let collapsed = s
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return collapsed
    }

    private struct Match {
        let rangeInOriginal: Range<String.Index>
        let groups: [String]

        func group(_ i: Int) -> String? {
            guard i >= 0, i < groups.count else { return nil }
            return groups[i]
        }
    }

    private static func firstMatch(pattern: String, in lowered: String) -> Match? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let ns = lowered as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let result = regex.firstMatch(in: lowered, options: [], range: range) else { return nil }

        // Map NSRange back to original string indices by applying the same ranges to the lowered string.
        // Since lowered is derived 1:1 from input (only case-changes), indices align.
        guard let swiftRange = Range(result.range, in: lowered) else { return nil }

        var groups: [String] = Array(repeating: "", count: result.numberOfRanges)
        for i in 0..<result.numberOfRanges {
            let r = result.range(at: i)
            if r.location != NSNotFound, let rr = Range(r, in: lowered) {
                groups[i] = String(lowered[rr])
            }
        }

        return Match(rangeInOriginal: swiftRange, groups: groups)
    }
}
