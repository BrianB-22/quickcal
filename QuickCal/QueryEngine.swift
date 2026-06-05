import Foundation

// Rule-based natural language engine for time and calendar questions.
// All logic is local — no network calls.
enum QueryEngine {

    static func answer(_ input: String) -> String {
        let q = input.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return "" }

        if let a = answerTimeInPlace(q)        { return a }
        if let a = answerCurrentLocalTime(q)   { return a }
        if let a = answerDayOfWeek(q)          { return a }
        if let a = answerBusinessDays(q)       { return a }
        if let a = answerDaysUntil(q)          { return a }
        if let a = answerDaysSince(q)          { return a }
        if let a = answerDaysBetween(q)        { return a }
        if let a = answerWeekOfYear(q)         { return a }
        if let a = answerHolidayDate(q)        { return a }
        if let a = answerIsHoliday(q)          { return a }
        if let a = answerTodayDate(q)          { return a }

        return "I can answer questions like: \"what time is it in Tokyo\", \"what day is June 1 2027\", \"+15 business days from today\", \"how many days until Christmas\"."
    }

    // MARK: - Handlers

    private static func answerCurrentLocalTime(_ q: String) -> String? {
        guard q.contains("what time") && (q.contains("is it") || q.contains("now")) && !q.contains(" in ") else { return nil }
        return "It's \(formatTime(Date(), in: .current))  (\(localOffsetString()))."
    }

    private static func answerTodayDate(_ q: String) -> String? {
        let patterns = ["what day is today", "what is today", "today's date", "what date is today"]
        guard patterns.contains(where: { q.contains($0) }) else { return nil }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f.string(from: Date())
    }

    private static func answerTimeInPlace(_ q: String) -> String? {
        guard q.contains("time") else { return nil }
        guard let match = q.range(of: #"(?:in|at)\s+(.+?)(?:\s*\?|$)"#, options: .regularExpression) else { return nil }
        let tail = String(q[match]).replacingOccurrences(of: #"^(?:in|at)\s+"#, with: "", options: .regularExpression)
        guard let tz = resolveTimezone(from: tail) else { return nil }
        let now = Date()
        return "It's \(formatTime(now, in: tz)) in \(tz.localizedName(for: .standard, locale: .current) ?? tail.capitalized)  (\(offsetString(tz)))."
    }

    private static func answerDayOfWeek(_ q: String) -> String? {
        guard q.contains("day") && (q.contains("week") || q.contains("what day is")) else { return nil }
        guard let date = extractDate(from: q) else { return nil }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return "\(f.string(from: date))."
    }

    private static func answerBusinessDays(_ q: String) -> String? {
        // Matches: "+20 business days from today", "15 business days from March 5"
        // Also: "what is +20 business days from today"
        let pattern = #"([+-]?\d+)\s+business\s+days?\s+from\s+(.+?)(?:\s*\?|$)"#
        guard let match = q.range(of: pattern, options: .regularExpression) else { return nil }
        let text = String(q[match])

        let parts = text.components(separatedBy: " business day")
        guard let nStr = parts.first?.trimmingCharacters(in: .whitespaces),
              let n = Int(nStr.replacingOccurrences(of: "+", with: "")) else { return nil }

        let fromPart = parts.dropFirst().first?
            .replacingOccurrences(of: #"^s?\s+from\s+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces) ?? ""

        let start: Date
        if fromPart.isEmpty || fromPart == "today" {
            start = Calendar.current.startOfDay(for: Date())
        } else if let d = extractDate(from: fromPart) {
            start = d
        } else {
            return nil
        }

        let result = addBusinessDays(n, to: start)
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        let sign = n >= 0 ? "+" : ""
        return "\(sign)\(n) business days from \(f.string(from: start)) → \(f.string(from: result))."
    }

    private static func answerDaysUntil(_ q: String) -> String? {
        guard q.contains("until") || q.contains("till") || (q.contains("how many days") && q.contains("to ")) else { return nil }
        let tail = q
            .replacingOccurrences(of: "how many days until ", with: "")
            .replacingOccurrences(of: "how many days till ",  with: "")
            .replacingOccurrences(of: "how many days to ",    with: "")
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "?", with: "")

        if let date = resolveNamedDateOrParse(tail) {
            let days = calendarDaysBetween(Date(), and: date)
            if days == 0 { return "That's today!" }
            if days < 0 { return "That was \(-days) day\(plural(-days)) ago." }
            return "\(days) day\(plural(days)) until \(friendlyDate(date))."
        }
        return nil
    }

    private static func answerDaysSince(_ q: String) -> String? {
        guard q.contains("since") || q.contains("how long ago") || q.contains("days ago") else { return nil }
        let tail = q
            .replacingOccurrences(of: "how many days since ", with: "")
            .replacingOccurrences(of: "how long since ",      with: "")
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "?", with: "")

        if let date = resolveNamedDateOrParse(tail) {
            let days = calendarDaysBetween(date, and: Date())
            if days == 0 { return "That's today!" }
            if days < 0 { return "That's \(-days) day\(plural(-days)) from now." }
            return "\(days) day\(plural(days)) since \(friendlyDate(date))."
        }
        return nil
    }

    private static func answerDaysBetween(_ q: String) -> String? {
        guard q.contains("between") && q.contains("and") else { return nil }
        // "how many days between X and Y"
        guard let betweenRange = q.range(of: "between ") else { return nil }
        let afterBetween = String(q[betweenRange.upperBound...])
        let parts = afterBetween.components(separatedBy: " and ")
        guard parts.count >= 2 else { return nil }
        guard let d1 = resolveNamedDateOrParse(parts[0].trimmingCharacters(in: .whitespaces)),
              let d2 = resolveNamedDateOrParse(parts[1].replacingOccurrences(of: "?", with: "").trimmingCharacters(in: .whitespaces)) else { return nil }
        let days = abs(calendarDaysBetween(d1, and: d2))
        return "\(days) day\(plural(days)) between \(friendlyDate(d1)) and \(friendlyDate(d2))."
    }

    private static func answerWeekOfYear(_ q: String) -> String? {
        guard q.contains("week") && (q.contains("of the year") || q.contains("number") || q.contains("week is")) else { return nil }
        let date = extractDate(from: q) ?? Date()
        let week = Calendar.current.component(.weekOfYear, from: date)
        let f = DateFormatter(); f.dateFormat = "MMMM d, yyyy"
        return "Week \(week) of the year (\(f.string(from: date)))."
    }

    private static func answerHolidayDate(_ q: String) -> String? {
        guard q.contains("when is") || q.contains("what date is") else { return nil }
        let yearPattern = #"\b(20\d{2})\b"#
        let year: Int
        if let m = q.range(of: yearPattern, options: .regularExpression) {
            year = Int(q[m])!
        } else {
            year = Calendar.current.component(.year, from: Date())
        }
        let tail = q
            .replacingOccurrences(of: "when is ", with: "")
            .replacingOccurrences(of: "what date is ", with: "")
            .replacingOccurrences(of: #"\b20\d{2}\b"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "?", with: "")
            .trimmingCharacters(in: .whitespaces)

        if let date = HolidayData.date(forHolidayNamed: tail, year: year) {
            return "\(tail.capitalized) \(year): \(friendlyDate(date))."
        }
        return nil
    }

    private static func answerIsHoliday(_ q: String) -> String? {
        guard q.contains("is") && q.contains("holiday") else { return nil }
        let date = extractDate(from: q) ?? Date()
        if let name = HolidayData.holidayName(for: date) {
            return "\(friendlyDate(date)) is \(name)."
        }
        return "\(friendlyDate(date)) is not a US federal holiday."
    }

    // MARK: - Date parsing helpers

    private static func extractDate(from text: String) -> Date? {
        // Try common date formats
        let formats = [
            "MMMM d yyyy", "MMMM d, yyyy", "MMM d yyyy", "MMM d, yyyy",
            "MM/dd/yyyy", "MM-dd-yyyy", "yyyy-MM-dd",
            "MMMM d", "MMM d", "MM/dd"
        ]
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        for fmt in formats {
            f.dateFormat = fmt
            if let d = f.date(from: text) {
                // For formats without year, attach current or next year
                if !fmt.contains("yyyy") {
                    let cal = Calendar.current
                    var comps = cal.dateComponents([.month, .day], from: d)
                    comps.year = cal.component(.year, from: Date())
                    if let candidate = cal.date(from: comps), candidate < Date() {
                        comps.year! += 1
                    }
                    return cal.date(from: comps)
                }
                return d
            }
        }
        // Try natural language keywords
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        switch text.trimmingCharacters(in: .whitespaces) {
        case "today":    return today
        case "tomorrow": return cal.date(byAdding: .day, value: 1, to: today)
        case "yesterday":return cal.date(byAdding: .day, value: -1, to: today)
        default: break
        }
        return nil
    }

    private static func resolveNamedDateOrParse(_ text: String) -> Date? {
        let t = text.lowercased().trimmingCharacters(in: .whitespaces)
        let year = Calendar.current.component(.year, from: Date())
        // Try holiday name first
        if let d = HolidayData.date(forHolidayNamed: t, year: year) { return d }
        // Christmas / New Year shortcuts
        if t.contains("christmas") { return HolidayData.date(forHolidayNamed: "christmas", year: year) }
        if t.contains("new year")  { return HolidayData.date(forHolidayNamed: "new year", year: year) }
        return extractDate(from: t)
    }

    // MARK: - Timezone helpers

    private static let tzAliases: [String: String] = [
        "india": "Asia/Kolkata", "mumbai": "Asia/Kolkata", "delhi": "Asia/Kolkata",
        "kolkata": "Asia/Kolkata", "ist": "Asia/Kolkata",
        "tokyo": "Asia/Tokyo", "japan": "Asia/Tokyo",
        "beijing": "Asia/Shanghai", "shanghai": "Asia/Shanghai", "china": "Asia/Shanghai",
        "london": "Europe/London", "uk": "Europe/London", "england": "Europe/London",
        "paris": "Europe/Paris", "france": "Europe/Paris",
        "berlin": "Europe/Berlin", "germany": "Europe/Berlin",
        "dubai": "Asia/Dubai", "uae": "Asia/Dubai",
        "singapore": "Asia/Singapore",
        "sydney": "Australia/Sydney", "australia": "Australia/Sydney",
        "auckland": "Pacific/Auckland", "new zealand": "Pacific/Auckland",
        "new york": "America/New_York", "nyc": "America/New_York", "eastern": "America/New_York",
        "chicago": "America/Chicago", "central": "America/Chicago",
        "denver": "America/Denver", "mountain": "America/Denver",
        "los angeles": "America/Los_Angeles", "la": "America/Los_Angeles", "pacific": "America/Los_Angeles",
        "honolulu": "Pacific/Honolulu", "hawaii": "Pacific/Honolulu",
        "anchorage": "America/Anchorage", "alaska": "America/Anchorage",
        "toronto": "America/Toronto", "canada": "America/Toronto",
        "mexico city": "America/Mexico_City", "mexico": "America/Mexico_City",
        "moscow": "Europe/Moscow", "russia": "Europe/Moscow",
        "seoul": "Asia/Seoul", "korea": "Asia/Seoul",
        "bangkok": "Asia/Bangkok", "thailand": "Asia/Bangkok",
        "jakarta": "Asia/Jakarta", "indonesia": "Asia/Jakarta",
        "karachi": "Asia/Karachi", "pakistan": "Asia/Karachi",
        "dhaka": "Asia/Dhaka", "bangladesh": "Asia/Dhaka",
        "tehran": "Asia/Tehran", "iran": "Asia/Tehran",
        "istanbul": "Europe/Istanbul", "turkey": "Europe/Istanbul",
        "cairo": "Africa/Cairo", "egypt": "Africa/Cairo",
        "johannesburg": "Africa/Johannesburg", "south africa": "Africa/Johannesburg",
        "nairobi": "Africa/Nairobi", "kenya": "Africa/Nairobi",
        "sao paulo": "America/Sao_Paulo", "brazil": "America/Sao_Paulo",
    ]

    static func resolveTimezone(from text: String) -> TimeZone? {
        let t = text.lowercased().trimmingCharacters(in: .whitespaces)
        if let id = tzAliases[t] { return TimeZone(identifier: id) }
        // Try as a known TimeZone identifier directly
        if let tz = TimeZone(identifier: text) { return tz }
        // Partial match
        for (key, id) in tzAliases {
            if t.contains(key) || key.contains(t) {
                return TimeZone(identifier: id)
            }
        }
        // Try abbreviation
        if let tz = TimeZone(abbreviation: text.uppercased()) { return tz }
        return nil
    }

    // MARK: - Formatting helpers

    private static func formatTime(_ date: Date, in tz: TimeZone, use24Hour: Bool = false) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        return f.string(from: date)
    }

    private static func offsetString(_ tz: TimeZone) -> String {
        let seconds = tz.secondsFromGMT()
        let h = seconds / 3600
        let m = abs(seconds % 3600) / 60
        let sign = h >= 0 ? "+" : ""
        return m == 0 ? "UTC\(sign)\(h)" : "UTC\(sign)\(h):\(String(format: "%02d", m))"
    }

    private static func localOffsetString() -> String { offsetString(.current) }

    private static func friendlyDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f.string(from: date)
    }

    private static func calendarDaysBetween(_ from: Date, and to: Date) -> Int {
        let cal = Calendar.current
        let a = cal.startOfDay(for: from)
        let b = cal.startOfDay(for: to)
        return cal.dateComponents([.day], from: a, to: b).day ?? 0
    }

    private static func addBusinessDays(_ n: Int, to start: Date) -> Date {
        let cal = Calendar.current
        var date = cal.startOfDay(for: start)
        let step = n >= 0 ? 1 : -1
        var remaining = abs(n)
        while remaining > 0 {
            date = cal.date(byAdding: .day, value: step, to: date)!
            let weekday = cal.component(.weekday, from: date)
            if weekday != 1 && weekday != 7 { remaining -= 1 }
        }
        return date
    }

    private static func plural(_ n: Int) -> String { n == 1 ? "" : "s" }
}
