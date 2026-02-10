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
        // Try Claude API first, fall back to OpenAI, then local parsing
        if !Constants.claudeAPIKey.isEmpty {
            return await parseWithClaude(input)
        } else if !Constants.openaiAPIKey.isEmpty {
            return await parseWithOpenAI(input)
        } else {
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

            // Extract content from OpenAI response
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

        return """
        Today is \(today) (\(todayName)). Extract reminder details from the user input. \
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
            "am", "pm", "daily", "weekly", "remind", "me", "to", "the",
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
