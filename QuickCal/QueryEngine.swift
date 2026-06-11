import Foundation

// Rule-based natural language engine for time and calendar questions.
// All logic is local — no network calls.
enum QueryEngine {

    static func answer(_ input: String) -> String {
        let q = normalize(input)
        guard !q.isEmpty else { return "" }

        if let a = answerTimeConversion(q)        { return a }
        if let a = answerTimeInPlace(q)          { return a }
        if let a = answerCurrentLocalTime(q)   { return a }
        if let a = answerDayOfWeek(q)          { return a }
        if let a = answerBusinessDays(q)       { return a }
        if let a = answerBizDaysInPeriod(q)    { return a }
        if let a = answerBizDaysBetween(q)     { return a }
        if let a = answerDateArithmetic(q)     { return a }
        if let a = answerAge(q)                { return a }
        if let a = answerDurationBetween(q)    { return a }
        if let a = answerDaysInMonth(q)        { return a }
        if let a = answerDaysLeftInPeriod(q)   { return a }
        if let a = answerMonthAnchor(q)        { return a }
        if let a = answerNthWeekdayInMonth(q)  { return a }
        if let a = answerQuarterBoundary(q)    { return a }
        if let a = answerWeeksUntil(q)         { return a }
        if let a = answerDaysUntil(q)          { return a }
        if let a = answerDaysSince(q)          { return a }
        if let a = answerDaysBetween(q)        { return a }
        if let a = answerWeekOfYear(q)         { return a }
        if let a = answerQuarter(q)            { return a }
        if let a = answerLeapYear(q)           { return a }
        if let a = answerHolidayDate(q)        { return a }
        if let a = answerIsHoliday(q)          { return a }
        if let a = answerTodayDate(q)          { return a }

        return "Try here: \"time in Tokyo\", \"convert 3pm EST to London time\", \"next Friday\", \"+15 business days from today\", \"days until Christmas\", \"is 2028 a leap year\", \"what quarter is it\"."
    }

    // MARK: - Normalization

    private static func normalize(_ input: String) -> String {
        var q = input.lowercased().trimmingCharacters(in: .whitespaces)
        let contractions: [(String, String)] = [
            ("what's", "what is"), ("when's", "when is"), ("how's", "how is"),
            ("it's", "it is"), ("there's", "there is"), ("that's", "that is"),
            ("where's", "where is"), ("who's", "who is"), ("don't", "do not"),
            ("doesn't", "does not"), ("isn't", "is not"), ("aren't", "are not"),
        ]
        for (c, e) in contractions { q = q.replacingOccurrences(of: c, with: e) }
        q = q.replacingOccurrences(of: "?", with: "")
              .replacingOccurrences(of: "  ", with: " ")
              .trimmingCharacters(in: .whitespaces)
        return q
    }

    // MARK: - Handlers

    private static func answerTimeConversion(_ q: String) -> String? {
        // "convert 3pm EST to London time", "what is 9am Tokyo in New York", "3:30pm Paris to Sydney"
        let pattern = #"(?:convert\s+|what\s+is\s+)?(\d{1,2}(?::\d{2})?\s*(?:am|pm))\s+(.+?)\s+(?:to|in)\s+(.+?)(?:\s+time)?$"#
        guard let re = try? NSRegularExpression(pattern: pattern),
              let match = re.firstMatch(in: q, range: NSRange(q.startIndex..., in: q)) else { return nil }
        func g(_ i: Int) -> String {
            guard let r = Range(match.range(at: i), in: q) else { return "" }
            return String(q[r]).trimmingCharacters(in: .whitespaces)
        }
        let timeStr = g(1); let fromPlace = g(2); let toPlace = g(3)
        guard let fromTZ = resolveTimezone(from: fromPlace),
              let toTZ   = resolveTimezone(from: toPlace),
              let inputDate = parseTimeOfDay(timeStr, in: fromTZ) else { return nil }
        let fromName = fromTZ.localizedName(for: .standard, locale: .current) ?? fromPlace.capitalized
        let toName   = toTZ.localizedName(for: .standard,   locale: .current) ?? toPlace.capitalized
        return "\(formatTime(inputDate, in: fromTZ)) \(fromName) = \(formatTime(inputDate, in: toTZ)) \(toName)."
    }

    private static func parseTimeOfDay(_ timeStr: String, in tz: TimeZone) -> Date? {
        let t = timeStr.lowercased().replacingOccurrences(of: " ", with: "")
        let isPM = t.hasSuffix("pm"); let isAM = t.hasSuffix("am")
        let digits = t.replacingOccurrences(of: "am", with: "").replacingOccurrences(of: "pm", with: "")
        var hour: Int; var minute = 0
        if digits.contains(":") {
            let parts = digits.split(separator: ":").map(String.init)
            guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
            hour = h; minute = m
        } else {
            guard let h = Int(digits) else { return nil }
            hour = h
        }
        if isPM && hour != 12 { hour += 12 }
        if isAM && hour == 12 { hour = 0 }
        guard hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 else { return nil }
        let cal = Calendar.current
        var comps = DateComponents()
        comps.timeZone = tz
        comps.year = cal.component(.year, from: Date()); comps.month = cal.component(.month, from: Date())
        comps.day  = cal.component(.day,  from: Date()); comps.hour = hour; comps.minute = minute; comps.second = 0
        return cal.date(from: comps)
    }

    private static func answerCurrentLocalTime(_ q: String) -> String? {
        let triggers = ["what time is it", "what is the time", "what time is it now",
                        "current time", "time now", "local time"]
        guard triggers.contains(where: { q.contains($0) }) && !q.contains(" in ") else { return nil }
        return "It's \(formatTime(Date(), in: .current))  (\(offsetString(.current)))."
    }

    private static func answerTodayDate(_ q: String) -> String? {
        let triggers = ["what day is today", "what is today", "today's date",
                        "what date is today", "what is the date", "what day is it"]
        guard triggers.contains(where: { q.contains($0) }) else { return nil }
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d, yyyy"
        return f.string(from: Date())
    }

    private static func answerTimeInPlace(_ q: String) -> String? {
        // "what time is it in X", "time in X", "X time", "what time in X"
        let patterns = [
            #"(?:what\s+)?time\s+(?:is\s+it\s+)?in\s+(.+)$"#,
            #"(.+?)\s+time$"#,
            #"(?:what\s+)?time\s+in\s+(.+)$"#,
        ]
        for pattern in patterns {
            if let match = q.range(of: pattern, options: .regularExpression) {
                let full = String(q[match])
                // Extract the captured group (city name)
                let nsr = NSRegularExpression.escapedPattern(for: "")
                _ = nsr
                if let r = full.range(of: pattern, options: .regularExpression) {
                    let str = full[r]
                    let nsRange = NSRange(str.startIndex..., in: String(str))
                    if let re = try? NSRegularExpression(pattern: pattern),
                       let m = re.firstMatch(in: String(str), range: nsRange) {
                        let g = m.range(at: 1)
                        if let range = Range(g, in: String(str)) {
                            let place = String(str[range]).trimmingCharacters(in: .whitespaces)
                            if let tz = resolveTimezone(from: place) {
                                let name = tz.localizedName(for: .standard, locale: .current) ?? place.capitalized
                                return "It's \(formatTime(Date(), in: tz)) in \(name)  (\(offsetString(tz)))."
                            }
                        }
                    }
                }
            }
        }
        // Simpler fallback: look for "in <place>" when query mentions time
        if q.contains("time") || q.contains("clock"),
           let inRange = q.range(of: #"\bin\s+(\w[\w\s]*)$"#, options: .regularExpression) {
            let tail = String(q[inRange])
                .replacingOccurrences(of: #"^in\s+"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            if let tz = resolveTimezone(from: tail) {
                let name = tz.localizedName(for: .standard, locale: .current) ?? tail.capitalized
                return "It's \(formatTime(Date(), in: tz)) in \(name)  (\(offsetString(tz)))."
            }
        }
        return nil
    }

    private static func answerDayOfWeek(_ q: String) -> String? {
        let triggers = ["what day is", "what day of the week is", "day of the week",
                        "what day does", "what day will", "what day was"]
        guard triggers.contains(where: { q.contains($0) }) else { return nil }
        guard let date = extractDate(from: q) else { return nil }
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d, yyyy"
        return "\(f.string(from: date))."
    }

    private static func answerBusinessDays(_ q: String) -> String? {
        let pattern = #"([+-]?\d+)\s+business\s+days?\s+from\s+(.+)$"#
        guard let match = q.range(of: pattern, options: .regularExpression) else { return nil }
        let text = String(q[match])
        let parts = text.components(separatedBy: " business day")
        guard let nStr = parts.first?.trimmingCharacters(in: .whitespaces),
              let n = Int(nStr.replacingOccurrences(of: "+", with: "")) else { return nil }
        let fromPart = (parts.dropFirst().first ?? "")
            .replacingOccurrences(of: #"^s?\s+from\s+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        let start: Date
        if fromPart.isEmpty || fromPart == "today" || fromPart == "now" {
            start = Calendar.current.startOfDay(for: Date())
        } else if let d = extractDate(from: fromPart) {
            start = d
        } else { return nil }
        let result = addBusinessDays(n, to: start)
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d, yyyy"
        let sign = n >= 0 ? "+" : ""
        return "\(sign)\(n) business days from \(f.string(from: start)) → \(f.string(from: result))."
    }

    private static func answerWeeksUntil(_ q: String) -> String? {
        guard q.contains("weeks until") || q.contains("weeks till") ||
              q.contains("weeks to ") || q.contains("how many weeks") else { return nil }
        let tail = q
            .replacingOccurrences(of: "how many weeks until ", with: "")
            .replacingOccurrences(of: "how many weeks till ",  with: "")
            .replacingOccurrences(of: "how many weeks to ",    with: "")
            .replacingOccurrences(of: "how many weeks until",  with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let date = resolveNamedDateOrParse(tail) else { return nil }
        let days = calendarDaysBetween(Date(), and: date)
        if days == 0 { return "That's today!" }
        if days < 0  { return "That was \(abs(days)) day\(plural(abs(days))) ago." }
        let weeks = days / 7; let rem = days % 7
        let daysPart = rem > 0 ? " and \(rem) day\(plural(rem))" : ""
        return "\(weeks) week\(plural(weeks))\(daysPart) until \(friendlyDate(date))."
    }

    private static func answerDaysUntil(_ q: String) -> String? {
        guard q.contains("until") || q.contains("till") ||
              (q.contains("how many days") && q.contains("to ")) ||
              q.contains("days until") || q.contains("days to ") else { return nil }
        let tail = q
            .replacingOccurrences(of: "how many days until ", with: "")
            .replacingOccurrences(of: "how many days till ",  with: "")
            .replacingOccurrences(of: "how many days to ",    with: "")
            .replacingOccurrences(of: "days until ",          with: "")
            .replacingOccurrences(of: "until ",               with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let date = resolveNamedDateOrParse(tail) else { return nil }
        let days = calendarDaysBetween(Date(), and: date)
        if days == 0 { return "That's today!" }
        if days < 0  { return "That was \(-days) day\(plural(-days)) ago." }
        return "\(days) day\(plural(days)) until \(friendlyDate(date))."
    }

    private static func answerDaysSince(_ q: String) -> String? {
        guard q.contains("since") || q.contains("how long ago") || q.contains("days ago") ||
              q.contains("days since") else { return nil }
        let tail = q
            .replacingOccurrences(of: "how many days since ", with: "")
            .replacingOccurrences(of: "how long since ",      with: "")
            .replacingOccurrences(of: "days since ",          with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let date = resolveNamedDateOrParse(tail) else { return nil }
        let days = calendarDaysBetween(date, and: Date())
        if days == 0 { return "That's today!" }
        if days < 0  { return "That's \(-days) day\(plural(-days)) from now." }
        return "\(days) day\(plural(days)) since \(friendlyDate(date))."
    }

    private static func answerDaysBetween(_ q: String) -> String? {
        guard q.contains("between") && q.contains("and") else { return nil }
        guard let betweenRange = q.range(of: "between ") else { return nil }
        let afterBetween = String(q[betweenRange.upperBound...])
        let parts = afterBetween.components(separatedBy: " and ")
        guard parts.count >= 2,
              let d1 = resolveNamedDateOrParse(parts[0].trimmingCharacters(in: .whitespaces)),
              let d2 = resolveNamedDateOrParse(parts[1].trimmingCharacters(in: .whitespaces)) else { return nil }
        let days = abs(calendarDaysBetween(d1, and: d2))
        return "\(days) day\(plural(days)) between \(friendlyDate(d1)) and \(friendlyDate(d2))."
    }

    private static func answerWeekOfYear(_ q: String) -> String? {
        guard q.contains("week") && (q.contains("of the year") || q.contains("number") ||
              q.contains("week is") || q.contains("week of")) else { return nil }
        let date = extractDate(from: q) ?? Date()
        let week = Calendar.current.component(.weekOfYear, from: date)
        let f = DateFormatter(); f.dateFormat = "MMMM d, yyyy"
        return "Week \(week) of the year (\(f.string(from: date)))."
    }

    private static func answerQuarter(_ q: String) -> String? {
        guard q.contains("quarter") else { return nil }
        let date = extractDate(from: q) ?? Date()
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let year  = cal.component(.year,  from: date)
        let q2 = (month - 1) / 3 + 1
        let names = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        let s = (q2 - 1) * 3
        return "Q\(q2) \(year) (\(names[s]) – \(names[s + 2]))."
    }

    private static func answerLeapYear(_ q: String) -> String? {
        guard q.contains("leap year") else { return nil }
        let year: Int
        if let m = q.range(of: #"\b(20\d{2}|19\d{2})\b"#, options: .regularExpression) {
            year = Int(q[m])!
        } else {
            year = Calendar.current.component(.year, from: Date())
        }
        let isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
        return isLeap
            ? "\(year) is a leap year — February has 29 days."
            : "\(year) is not a leap year — February has 28 days."
    }

    private static func answerHolidayDate(_ q: String) -> String? {
        guard q.contains("when is") || q.contains("what date is") ||
              q.contains("when does") else { return nil }
        let year: Int
        if let m = q.range(of: #"\b(20\d{2})\b"#, options: .regularExpression) {
            year = Int(q[m])!
        } else {
            year = Calendar.current.component(.year, from: Date())
        }
        let tail = q
            .replacingOccurrences(of: "when is ", with: "")
            .replacingOccurrences(of: "what date is ", with: "")
            .replacingOccurrences(of: "when does ", with: "")
            .replacingOccurrences(of: #"\b20\d{2}\b"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        if let date = HolidayData.date(forHolidayNamed: tail, year: year) {
            return "\(tail.capitalized) \(year): \(friendlyDate(date))."
        }
        if let date = HolidayData.date(forObservanceNamed: tail, year: year) {
            return "\(tail.capitalized) \(year): \(friendlyDate(date))."
        }
        if let date = HolidayData.date(forNoveltyDayNamed: tail, year: year) {
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

    // MARK: - Calendar math handlers

    // "90 days from March 15", "today + 45 days", "June 1 minus 3 weeks", "add 2 months to today"
    private static func answerDateArithmetic(_ q: String) -> String? {
        // Pattern: <date> + / plus / minus / - <N> days/weeks/months
        let addPat = #"(.+?)\s*(?:\+|plus|and)\s*(\d+)\s*(day|days|week|weeks|month|months|year|years)"#
        let subPat = #"(.+?)\s*(?:-|minus)\s*(\d+)\s*(day|days|week|weeks|month|months|year|years)"#
        // Pattern: <N> days/weeks/months from/after <date>
        let fromPat = #"(\d+)\s*(day|days|week|weeks|month|months|year|years)\s+(?:from|after|after)\s+(.+)$"#
        // Pattern: add/subtract N unit to/from date
        let verbPat = #"(?:add|subtract)\s+(\d+)\s*(day|days|week|weeks|month|months|year|years)\s+(?:to|from)\s+(.+)$"#

        func applyOffset(_ base: Date, n: Int, unit: String) -> Date {
            let cal = Calendar.current
            switch unit {
            case "day", "days":     return cal.date(byAdding: .day,   value: n, to: base)!
            case "week", "weeks":   return cal.date(byAdding: .day,   value: n * 7, to: base)!
            case "month", "months": return cal.date(byAdding: .month, value: n, to: base)!
            case "year", "years":   return cal.date(byAdding: .year,  value: n, to: base)!
            default: return base
            }
        }

        // "N unit from date"
        if let m = q.range(of: fromPat, options: .regularExpression) {
            let parts = String(q[m]).components(separatedBy: " ")
            if let n = Int(parts[0]), parts.count >= 4 {
                let unit = parts[1]
                let dateStr = parts.dropFirst(3).joined(separator: " ")
                if let base = resolveNamedDateOrParse(dateStr) {
                    return "\(friendlyDate(applyOffset(base, n: n, unit: unit)))."
                }
            }
        }

        // "add/subtract N unit to/from date"
        if let m = q.range(of: verbPat, options: .regularExpression) {
            let s = String(q[m])
            let adding = s.hasPrefix("add")
            let parts = s.components(separatedBy: " ")
            if parts.count >= 4, let n = Int(parts[1]) {
                let unit = parts[2]
                let dateStr = parts.dropFirst(4).joined(separator: " ")
                if let base = resolveNamedDateOrParse(dateStr) {
                    return "\(friendlyDate(applyOffset(base, n: adding ? n : -n, unit: unit)))."
                }
            }
        }

        // "date + N unit" or "date - N unit"
        for (pat, sign) in [(addPat, 1), (subPat, -1)] {
            if let m = q.range(of: pat, options: .regularExpression) {
                let s = String(q[m])
                if let re = try? NSRegularExpression(pattern: pat),
                   let match = re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) {
                    func g(_ i: Int) -> String {
                        let r = match.range(at: i)
                        return Range(r, in: s).map { String(s[$0]) } ?? ""
                    }
                    let dateStr = g(1).trimmingCharacters(in: .whitespaces)
                    let nStr = g(2); let unit = g(3)
                    if let base = resolveNamedDateOrParse(dateStr), let n = Int(nStr) {
                        return "\(friendlyDate(applyOffset(base, n: sign * n, unit: unit)))."
                    }
                }
            }
        }
        return nil
    }

    // "how old is someone born June 5 1990", "age of someone born in 1985"
    private static func answerAge(_ q: String) -> String? {
        guard q.contains("born") || (q.contains("old") && q.contains("since")) ||
              q.contains("how many years since") else { return nil }
        guard let birth = extractDate(from: q) else { return nil }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: birth, to: Date())
        guard let years = comps.year, let months = comps.month, let days = comps.day else { return nil }
        if years < 0 { return "That date is in the future." }
        var parts: [String] = []
        if years  > 0 { parts.append("\(years) year\(plural(years))") }
        if months > 0 { parts.append("\(months) month\(plural(months))") }
        if days   > 0 && years < 5 { parts.append("\(days) day\(plural(days))") }
        return parts.isEmpty ? "Less than a day." : parts.joined(separator: ", ") + " old."
    }

    // "how long between Jan 1 and Oct 15", "duration from X to Y"
    private static func answerDurationBetween(_ q: String) -> String? {
        guard (q.contains("how long") || q.contains("duration") || q.contains("time between")) &&
              (q.contains("between") || q.contains(" from ") || q.contains(" and ")) else { return nil }
        // Already handled day-count in answerDaysBetween; this gives years/months/days breakdown
        var d1: Date?, d2: Date?
        if q.contains("between"), let r = q.range(of: "between ") {
            let after = String(q[r.upperBound...])
            let parts = after.components(separatedBy: " and ")
            if parts.count >= 2 {
                d1 = resolveNamedDateOrParse(parts[0].trimmingCharacters(in: .whitespaces))
                d2 = resolveNamedDateOrParse(parts[1].trimmingCharacters(in: .whitespaces))
            }
        } else if q.contains(" from ") && q.contains(" to ") {
            if let fr = q.range(of: " from "), let tr = q.range(of: " to ") {
                d1 = resolveNamedDateOrParse(String(q[fr.upperBound..<tr.lowerBound]))
                d2 = resolveNamedDateOrParse(String(q[tr.upperBound...]))
            }
        }
        guard let a = d1, let b = d2 else { return nil }
        let (start, end) = a < b ? (a, b) : (b, a)
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: start, to: end)
        guard let y = comps.year, let mo = comps.month, let d = comps.day else { return nil }
        var parts: [String] = []
        if y  > 0 { parts.append("\(y) year\(plural(y))") }
        if mo > 0 { parts.append("\(mo) month\(plural(mo))") }
        if d  > 0 { parts.append("\(d) day\(plural(d))") }
        let total = abs(calendarDaysBetween(a, and: b))
        let breakdown = parts.isEmpty ? "0 days" : parts.joined(separator: ", ")
        return "\(breakdown)  (\(total) day\(plural(total)) total)."
    }

    // "how many days in February 2028", "days in March"
    private static func answerDaysInMonth(_ q: String) -> String? {
        guard (q.contains("days in") || q.contains("how many days") && q.contains("in")) &&
              !q.contains("until") && !q.contains("since") && !q.contains("left") else { return nil }
        let months = ["january":1,"february":2,"march":3,"april":4,"may":5,"june":6,
                      "july":7,"august":8,"september":9,"october":10,"november":11,"december":12,
                      "jan":1,"feb":2,"mar":3,"apr":4,"jun":6,"jul":7,"aug":8,
                      "sep":9,"oct":10,"nov":11,"dec":12]
        var month: Int? = nil
        var year = Calendar.current.component(.year, from: Date())
        for (name, num) in months { if q.contains(name) { month = num; break } }
        if let m = q.range(of: #"\b(20\d{2})\b"#, options: .regularExpression) { year = Int(q[m])! }
        guard let mo = month else { return nil }
        let cal = Calendar(identifier: .gregorian)
        let comps = DateComponents(year: year, month: mo, day: 1)
        guard let date = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: date) else { return nil }
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return "\(f.string(from: date)) has \(range.count) days."
    }

    // "days left in June", "days left in the year", "days left in Q2", "business days left in month"
    private static func answerDaysLeftInPeriod(_ q: String) -> String? {
        guard q.contains("left") || q.contains("remaining") else { return nil }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Business days left in month
        if q.contains("business") && (q.contains("month") || q.contains("this month")) {
            let year  = cal.component(.year,  from: today)
            let month = cal.component(.month, from: today)
            let nextMonthStart = cal.date(from: DateComponents(year: year, month: month + 1, day: 1))!
            let endOfMonth = cal.date(byAdding: .day, value: -1, to: nextMonthStart)!
            var count = 0; var cursor = today
            while cursor <= endOfMonth {
                let wd = cal.component(.weekday, from: cursor)
                if wd != 1 && wd != 7 { count += 1 }
                cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
            }
            let f = DateFormatter(); f.dateFormat = "MMMM"
            return "\(count) business day\(plural(count)) left in \(f.string(from: today))."
        }

        // Days left in year
        if q.contains("year") {
            let year = cal.component(.year, from: today)
            let endOfYear = cal.date(from: DateComponents(year: year, month: 12, day: 31))!
            let days = abs(calendarDaysBetween(today, and: endOfYear))
            return "\(days) day\(plural(days)) left in \(year)."
        }

        // Days left in quarter
        if q.contains("quarter") {
            let month = cal.component(.month, from: today)
            let year  = cal.component(.year,  from: today)
            let qNum  = (month - 1) / 3 + 1
            let endMonth = qNum * 3
            let endOfQ = cal.date(from: DateComponents(year: year, month: endMonth + 1, day: 0))!
            let days = abs(calendarDaysBetween(today, and: endOfQ))
            return "\(days) day\(plural(days)) left in Q\(qNum) \(year)."
        }

        // Days left in a specific month
        let months = ["january":1,"february":2,"march":3,"april":4,"may":5,"june":6,
                      "july":7,"august":8,"september":9,"october":10,"november":11,"december":12,
                      "jan":1,"feb":2,"mar":3,"apr":4,"jun":6,"jul":7,"aug":8,
                      "sep":9,"oct":10,"nov":11,"dec":12]
        for (name, num) in months {
            if q.contains(name) {
                let year = cal.component(.year, from: today)
                let endOfM = cal.date(from: DateComponents(year: year, month: num + 1, day: 0))!
                let start  = q.contains("this") ? today :
                             cal.date(from: DateComponents(year: year, month: num, day: 1))!
                let days = abs(calendarDaysBetween(start, and: endOfM))
                let f = DateFormatter(); f.dateFormat = "MMMM"
                return "\(days) day\(plural(days)) left in \(f.string(from: endOfM))."
            }
        }

        // "days left in the month" / "days left this month"
        if q.contains("month") {
            let year  = cal.component(.year,  from: today)
            let month = cal.component(.month, from: today)
            let endOfM = cal.date(from: DateComponents(year: year, month: month + 1, day: 0))!
            let days = abs(calendarDaysBetween(today, and: endOfM))
            let f = DateFormatter(); f.dateFormat = "MMMM"
            return "\(days) day\(plural(days)) left in \(f.string(from: today))."
        }

        return nil
    }

    // "what day does August start on", "what day does December end on"
    private static func answerMonthAnchor(_ q: String) -> String? {
        guard (q.contains("start") || q.contains("begin") || q.contains("end") ||
               q.contains("first day") || q.contains("last day")) else { return nil }
        let months = ["january":1,"february":2,"march":3,"april":4,"may":5,"june":6,
                      "july":7,"august":8,"september":9,"october":10,"november":11,"december":12,
                      "jan":1,"feb":2,"mar":3,"apr":4,"jun":6,"jul":7,"aug":8,
                      "sep":9,"oct":10,"nov":11,"dec":12]
        var month: Int? = nil
        var year = Calendar.current.component(.year, from: Date())
        for (name, num) in months { if q.contains(name) { month = num; break } }
        if let m = q.range(of: #"\b(20\d{2})\b"#, options: .regularExpression) { year = Int(q[m])! }
        guard let mo = month else { return nil }
        let cal = Calendar(identifier: .gregorian)
        let isEnd = q.contains("end") || q.contains("last")
        let day: Int
        if isEnd {
            let nextStart = cal.date(from: DateComponents(year: year, month: mo + 1, day: 1))!
            day = cal.dateComponents([.day], from: cal.date(from: DateComponents(year: year, month: mo, day: 1))!,
                                     to: nextStart).day!
        } else { day = 1 }
        let date = cal.date(from: DateComponents(year: year, month: mo, day: day))!
        return "\(friendlyDate(date))."
    }

    // "first Monday in October 2027", "last Friday of November", "third Tuesday in August"
    private static func answerNthWeekdayInMonth(_ q: String) -> String? {
        let ordinals = ["first":1,"second":2,"third":3,"fourth":4,"fifth":5,"last":-1]
        let weekdays = ["sunday":1,"monday":2,"tuesday":3,"wednesday":4,
                        "thursday":5,"friday":6,"saturday":7]
        let months   = ["january":1,"february":2,"march":3,"april":4,"may":5,"june":6,
                        "july":7,"august":8,"september":9,"october":10,"november":11,"december":12,
                        "jan":1,"feb":2,"mar":3,"apr":4,"jun":6,"jul":7,"aug":8,
                        "sep":9,"oct":10,"nov":11,"dec":12]
        var ordinal: Int? = nil; var weekday: Int? = nil; var month: Int? = nil
        var year = Calendar.current.component(.year, from: Date())
        for (k, v) in ordinals { if q.contains(k) { ordinal = v; break } }
        for (k, v) in weekdays { if q.contains(k) { weekday = v; break } }
        for (k, v) in months   { if q.contains(k) { month   = v; break } }
        if let m = q.range(of: #"\b(20\d{2})\b"#, options: .regularExpression) { year = Int(q[m])! }
        guard let ord = ordinal, let wd = weekday, let mo = month else { return nil }
        let cal = Calendar(identifier: .gregorian)
        if ord == -1 {
            // Last occurrence: start from end of month
            let nextStart = cal.date(from: DateComponents(year: year, month: mo + 1, day: 1))!
            var date = cal.date(byAdding: .day, value: -1, to: nextStart)!
            while cal.component(.weekday, from: date) != wd {
                date = cal.date(byAdding: .day, value: -1, to: date)!
            }
            return "\(friendlyDate(date))."
        } else {
            let firstDay = cal.date(from: DateComponents(year: year, month: mo, day: 1))!
            let firstWD  = cal.component(.weekday, from: firstDay)
            let offset   = (wd - firstWD + 7) % 7 + (ord - 1) * 7
            let date     = cal.date(byAdding: .day, value: offset, to: firstDay)!
            // Verify still in same month
            guard cal.component(.month, from: date) == mo else { return "No \(ord)th occurrence in that month." }
            return "\(friendlyDate(date))."
        }
    }

    // "when does Q3 start", "when does Q2 end", "how many days left in Q2"
    private static func answerQuarterBoundary(_ q: String) -> String? {
        guard q.contains("q1") || q.contains("q2") || q.contains("q3") || q.contains("q4") else { return nil }
        guard q.contains("start") || q.contains("begin") || q.contains("end") else { return nil }
        let qNum: Int
        if q.contains("q1") { qNum = 1 } else if q.contains("q2") { qNum = 2 }
        else if q.contains("q3") { qNum = 3 } else { qNum = 4 }
        let cal = Calendar(identifier: .gregorian)
        var year = Calendar.current.component(.year, from: Date())
        if let m = q.range(of: #"\b(20\d{2})\b"#, options: .regularExpression) { year = Int(q[m])! }
        let startMonth = (qNum - 1) * 3 + 1
        let isEnd = q.contains("end")
        let date: Date
        if isEnd {
            date = cal.date(from: DateComponents(year: year, month: qNum * 3 + 1, day: 0))!
        } else {
            date = cal.date(from: DateComponents(year: year, month: startMonth, day: 1))!
        }
        return "Q\(qNum) \(year) \(isEnd ? "ends" : "starts") on \(friendlyDate(date))."
    }

    // "how many business days in July", "business days in Q3"
    private static func answerBizDaysInPeriod(_ q: String) -> String? {
        guard q.contains("business day") && (q.contains("in ") || q.contains("during")) &&
              !q.contains("from") && !q.contains("left") else { return nil }
        let cal = Calendar(identifier: .gregorian)
        var year = Calendar.current.component(.year, from: Date())
        if let m = q.range(of: #"\b(20\d{2})\b"#, options: .regularExpression) { year = Int(q[m])! }

        var start: Date? = nil; var end: Date? = nil

        // Quarter
        for qn in 1...4 {
            if q.contains("q\(qn)") {
                let sm = (qn - 1) * 3 + 1
                start = cal.date(from: DateComponents(year: year, month: sm, day: 1))!
                end   = cal.date(from: DateComponents(year: year, month: qn * 3 + 1, day: 0))!
            }
        }

        // Month name
        if start == nil {
            let months = ["january":1,"february":2,"march":3,"april":4,"may":5,"june":6,
                          "july":7,"august":8,"september":9,"october":10,"november":11,"december":12,
                          "jan":1,"feb":2,"mar":3,"apr":4,"jun":6,"jul":7,"aug":8,
                          "sep":9,"oct":10,"nov":11,"dec":12]
            for (name, num) in months {
                if q.contains(name) {
                    start = cal.date(from: DateComponents(year: year, month: num, day: 1))!
                    end   = cal.date(from: DateComponents(year: year, month: num + 1, day: 0))!
                    break
                }
            }
        }

        guard let s = start, let e = end else { return nil }
        var count = 0; var cursor = cal.startOfDay(for: s)
        while cursor <= e {
            let wd = cal.component(.weekday, from: cursor)
            if wd != 1 && wd != 7 { count += 1 }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
        }
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return "\(count) business day\(plural(count)) in \(f.string(from: s))."
    }

    // "business days between March 1 and April 15"
    private static func answerBizDaysBetween(_ q: String) -> String? {
        guard q.contains("business day") && q.contains("between") && q.contains("and") else { return nil }
        guard let r = q.range(of: "between ") else { return nil }
        let parts = String(q[r.upperBound...]).components(separatedBy: " and ")
        guard parts.count >= 2,
              let d1 = resolveNamedDateOrParse(parts[0].trimmingCharacters(in: .whitespaces)),
              let d2 = resolveNamedDateOrParse(parts[1].trimmingCharacters(in: .whitespaces)) else { return nil }
        let (start, end) = d1 < d2 ? (d1, d2) : (d2, d1)
        let cal = Calendar(identifier: .gregorian)
        var count = 0; var cursor = cal.startOfDay(for: start)
        while cursor <= cal.startOfDay(for: end) {
            let wd = cal.component(.weekday, from: cursor)
            if wd != 1 && wd != 7 { count += 1 }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
        }
        return "\(count) business day\(plural(count)) between \(friendlyDate(d1)) and \(friendlyDate(d2))."
    }

    // MARK: - Date parsing

    private static let weekdayNumbers: [String: Int] = [
        "sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
        "thursday": 5, "friday": 6, "saturday": 7,
        "sun": 1, "mon": 2, "tue": 3, "wed": 4, "thu": 5, "fri": 6, "sat": 7,
    ]

    private static func nextWeekday(_ target: Int, from base: Date, includeToday: Bool) -> Date {
        let cal = Calendar.current
        var date = cal.startOfDay(for: base)
        if !includeToday { date = cal.date(byAdding: .day, value: 1, to: date)! }
        for _ in 0..<8 {
            if cal.component(.weekday, from: date) == target { return date }
            date = cal.date(byAdding: .day, value: 1, to: date)!
        }
        return date
    }

    private static func previousWeekday(_ target: Int, from base: Date) -> Date {
        let cal = Calendar.current
        var date = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: base))!
        for _ in 0..<8 {
            if cal.component(.weekday, from: date) == target { return date }
            date = cal.date(byAdding: .day, value: -1, to: date)!
        }
        return date
    }

    private static func extractDate(from text: String) -> Date? {
        let t = text.trimmingCharacters(in: .whitespaces).lowercased()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Natural language keywords
        switch t {
        case "today", "now":           return today
        case "tomorrow":               return cal.date(byAdding: .day, value: 1, to: today)
        case "yesterday":              return cal.date(byAdding: .day, value: -1, to: today)
        case "next week":              return cal.date(byAdding: .day, value: 7, to: today)
        case "last week":              return cal.date(byAdding: .day, value: -7, to: today)
        case "next month":             return cal.date(byAdding: .month, value: 1, to: today)
        case "next year":              return cal.date(byAdding: .year, value: 1, to: today)
        case "end of year", "new year's eve": return cal.date(from: DateComponents(
                                           year: cal.component(.year, from: today), month: 12, day: 31))
        default: break
        }

        // "next <weekday>", "last <weekday>", "this <weekday>"
        for prefix in ["next ", "this coming ", "this "] {
            if t.hasPrefix(prefix) {
                let rest = String(t.dropFirst(prefix.count))
                if let wd = weekdayNumbers[rest] {
                    return nextWeekday(wd, from: today, includeToday: prefix == "this ")
                }
            }
        }
        if t.hasPrefix("last ") || t.hasPrefix("past ") {
            let rest = String(t.dropFirst(5))
            if let wd = weekdayNumbers[rest] { return previousWeekday(wd, from: today) }
        }
        // Bare weekday name → next occurrence
        if let wd = weekdayNumbers[t] { return nextWeekday(wd, from: today, includeToday: false) }

        // "in N days/weeks/months"
        if let m = t.range(of: #"^in (\d+) (day|days|week|weeks|month|months|year|years)$"#,
                           options: .regularExpression) {
            let parts = String(t[m]).components(separatedBy: " ")
            if parts.count >= 3, let n = Int(parts[1]) {
                switch parts[2] {
                case "day",   "days":   return cal.date(byAdding: .day,   value: n,      to: today)
                case "week",  "weeks":  return cal.date(byAdding: .day,   value: n * 7,  to: today)
                case "month", "months": return cal.date(byAdding: .month, value: n,      to: today)
                case "year",  "years":  return cal.date(byAdding: .year,  value: n,      to: today)
                default: break
                }
            }
        }

        // "N days/weeks from now/today"
        if let m = t.range(of: #"^(\d+) (day|days|week|weeks) (?:from now|from today|from here)$"#,
                           options: .regularExpression) {
            let parts = String(t[m]).components(separatedBy: " ")
            if let n = Int(parts[0]) {
                let unit = parts[1]
                if unit.hasPrefix("day")  { return cal.date(byAdding: .day, value: n,     to: today) }
                if unit.hasPrefix("week") { return cal.date(byAdding: .day, value: n * 7, to: today) }
            }
        }

        // Standard date formats
        let formats = [
            "MMMM d yyyy", "MMMM d, yyyy", "MMM d yyyy", "MMM d, yyyy",
            "MM/dd/yyyy", "MM-dd-yyyy", "yyyy-MM-dd", "d MMMM yyyy",
            "MMMM d", "MMM d", "MM/dd", "MMMM yyyy",
        ]
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US")
        for fmt in formats {
            f.dateFormat = fmt
            if let d = f.date(from: text) {
                if !fmt.contains("yyyy") {
                    var comps = cal.dateComponents([.month, .day], from: d)
                    comps.year = cal.component(.year, from: Date())
                    if let candidate = cal.date(from: comps), candidate < today { comps.year! += 1 }
                    return cal.date(from: comps)
                }
                return d
            }
        }
        return nil
    }

    private static func resolveNamedDateOrParse(_ text: String) -> Date? {
        let t = text.lowercased().trimmingCharacters(in: .whitespaces)
        let year = Calendar.current.component(.year, from: Date())
        if let d = HolidayData.date(forHolidayNamed: t, year: year)    { return d }
        if let d = HolidayData.date(forObservanceNamed: t, year: year) { return d }
        if let d = HolidayData.date(forNoveltyDayNamed: t, year: year) { return d }
        if t.contains("christmas")   { return HolidayData.date(forHolidayNamed: "christmas",   year: year) }
        if t.contains("new year")    { return HolidayData.date(forHolidayNamed: "new year",    year: year) }
        if t.contains("thanksgiving"){ return HolidayData.date(forHolidayNamed: "thanksgiving", year: year) }
        if t.contains("independence"){ return HolidayData.date(forHolidayNamed: "independence", year: year) }
        if t.contains("memorial")    { return HolidayData.date(forHolidayNamed: "memorial",    year: year) }
        if t.contains("labor")       { return HolidayData.date(forHolidayNamed: "labor",       year: year) }
        return extractDate(from: t)
    }

    // MARK: - Timezone helpers

    private static let tzAliases: [String: String] = [
        // North America
        "new york": "America/New_York",  "nyc": "America/New_York",
        "eastern": "America/New_York",   "est": "America/New_York",  "edt": "America/New_York",
        "boston": "America/New_York",    "dc": "America/New_York",   "washington": "America/New_York",
        "miami": "America/New_York",     "atlanta": "America/New_York", "philly": "America/New_York",
        "philadelphia": "America/New_York",
        "chicago": "America/Chicago",    "central": "America/Chicago", "cst": "America/Chicago",
        "dallas": "America/Chicago",     "houston": "America/Chicago",
        "denver": "America/Denver",      "mountain": "America/Denver", "mst": "America/Denver",
        "phoenix": "America/Phoenix",
        "los angeles": "America/Los_Angeles", "la": "America/Los_Angeles",
        "san francisco": "America/Los_Angeles", "sf": "America/Los_Angeles",
        "seattle": "America/Los_Angeles", "portland": "America/Los_Angeles",
        "pacific": "America/Los_Angeles", "pst": "America/Los_Angeles", "pdt": "America/Los_Angeles",
        "las vegas": "America/Los_Angeles",
        "anchorage": "America/Anchorage", "alaska": "America/Anchorage",
        "honolulu": "Pacific/Honolulu",   "hawaii": "Pacific/Honolulu",
        "toronto": "America/Toronto",     "ottawa": "America/Toronto",
        "vancouver": "America/Vancouver", "calgary": "America/Edmonton",
        "montreal": "America/Toronto",
        "mexico city": "America/Mexico_City", "mexico": "America/Mexico_City",
        // South America
        "sao paulo": "America/Sao_Paulo", "brazil": "America/Sao_Paulo",
        "buenos aires": "America/Argentina/Buenos_Aires", "argentina": "America/Argentina/Buenos_Aires",
        "santiago": "America/Santiago",   "chile": "America/Santiago",
        "lima": "America/Lima",           "peru": "America/Lima",
        "bogota": "America/Bogota",       "colombia": "America/Bogota",
        // Europe
        "london": "Europe/London",        "uk": "Europe/London",   "england": "Europe/London",
        "gmt": "Europe/London",
        "paris": "Europe/Paris",          "france": "Europe/Paris",
        "berlin": "Europe/Berlin",        "germany": "Europe/Berlin",
        "warsaw": "Europe/Warsaw",        "poland": "Europe/Warsaw",
        "rome": "Europe/Rome",            "italy": "Europe/Rome",   "milan": "Europe/Rome",
        "madrid": "Europe/Madrid",        "spain": "Europe/Madrid", "barcelona": "Europe/Madrid",
        "amsterdam": "Europe/Amsterdam",  "netherlands": "Europe/Amsterdam",
        "brussels": "Europe/Brussels",    "belgium": "Europe/Brussels",
        "zurich": "Europe/Zurich",        "switzerland": "Europe/Zurich",
        "stockholm": "Europe/Stockholm",  "sweden": "Europe/Stockholm",
        "oslo": "Europe/Oslo",            "norway": "Europe/Oslo",
        "copenhagen": "Europe/Copenhagen","denmark": "Europe/Copenhagen",
        "helsinki": "Europe/Helsinki",    "finland": "Europe/Helsinki",
        "athens": "Europe/Athens",        "greece": "Europe/Athens",
        "lisbon": "Europe/Lisbon",        "portugal": "Europe/Lisbon",
        "moscow": "Europe/Moscow",        "russia": "Europe/Moscow",
        "istanbul": "Europe/Istanbul",    "turkey": "Europe/Istanbul",
        "kyiv": "Europe/Kyiv",            "ukraine": "Europe/Kyiv",  "kiev": "Europe/Kyiv",
        "bucharest": "Europe/Bucharest",  "romania": "Europe/Bucharest",
        "vienna": "Europe/Vienna",        "austria": "Europe/Vienna",
        "prague": "Europe/Prague",        "czech": "Europe/Prague",
        "budapest": "Europe/Budapest",    "hungary": "Europe/Budapest",
        // Middle East & Africa
        "dubai": "Asia/Dubai",            "uae": "Asia/Dubai",
        "abu dhabi": "Asia/Dubai",
        "riyadh": "Asia/Riyadh",          "saudi arabia": "Asia/Riyadh",
        "baghdad": "Asia/Baghdad",        "iraq": "Asia/Baghdad",
        "beirut": "Asia/Beirut",          "lebanon": "Asia/Beirut",
        "tel aviv": "Asia/Jerusalem",     "jerusalem": "Asia/Jerusalem", "israel": "Asia/Jerusalem",
        "tehran": "Asia/Tehran",          "iran": "Asia/Tehran",
        "cairo": "Africa/Cairo",          "egypt": "Africa/Cairo",
        "johannesburg": "Africa/Johannesburg", "south africa": "Africa/Johannesburg",
        "nairobi": "Africa/Nairobi",      "kenya": "Africa/Nairobi",
        "lagos": "Africa/Lagos",          "nigeria": "Africa/Lagos",
        "accra": "Africa/Accra",          "ghana": "Africa/Accra",
        "casablanca": "Africa/Casablanca","morocco": "Africa/Casablanca",
        // Asia
        "india": "Asia/Kolkata",          "mumbai": "Asia/Kolkata",  "delhi": "Asia/Kolkata",
        "kolkata": "Asia/Kolkata",        "bangalore": "Asia/Kolkata", "ist": "Asia/Kolkata",
        "chennai": "Asia/Kolkata",        "hyderabad": "Asia/Kolkata",
        "karachi": "Asia/Karachi",        "pakistan": "Asia/Karachi",
        "dhaka": "Asia/Dhaka",            "bangladesh": "Asia/Dhaka",
        "kathmandu": "Asia/Kathmandu",    "nepal": "Asia/Kathmandu",
        "colombo": "Asia/Colombo",        "sri lanka": "Asia/Colombo",
        "kabul": "Asia/Kabul",            "afghanistan": "Asia/Kabul",
        "tashkent": "Asia/Tashkent",      "uzbekistan": "Asia/Tashkent",
        "almaty": "Asia/Almaty",          "kazakhstan": "Asia/Almaty",
        "beijing": "Asia/Shanghai",       "shanghai": "Asia/Shanghai",
        "china": "Asia/Shanghai",         "cst_china": "Asia/Shanghai",
        "hong kong": "Asia/Hong_Kong",    "hk": "Asia/Hong_Kong",
        "taipei": "Asia/Taipei",          "taiwan": "Asia/Taipei",
        "tokyo": "Asia/Tokyo",            "japan": "Asia/Tokyo",     "jst": "Asia/Tokyo",
        "osaka": "Asia/Tokyo",
        "seoul": "Asia/Seoul",            "korea": "Asia/Seoul",     "south korea": "Asia/Seoul",
        "singapore": "Asia/Singapore",
        "kuala lumpur": "Asia/Kuala_Lumpur", "malaysia": "Asia/Kuala_Lumpur", "kl": "Asia/Kuala_Lumpur",
        "jakarta": "Asia/Jakarta",        "indonesia": "Asia/Jakarta",
        "bangkok": "Asia/Bangkok",        "thailand": "Asia/Bangkok",
        "ho chi minh": "Asia/Ho_Chi_Minh","vietnam": "Asia/Ho_Chi_Minh", "hanoi": "Asia/Ho_Chi_Minh",
        "manila": "Asia/Manila",          "philippines": "Asia/Manila",
        "yangon": "Asia/Rangoon",         "myanmar": "Asia/Rangoon",
        // Pacific
        "sydney": "Australia/Sydney",     "australia": "Australia/Sydney",
        "melbourne": "Australia/Melbourne","brisbane": "Australia/Brisbane",
        "perth": "Australia/Perth",
        "auckland": "Pacific/Auckland",   "new zealand": "Pacific/Auckland",
        "fiji": "Pacific/Fiji",
    ]

    static func resolveTimezone(from text: String) -> TimeZone? {
        let t = text.lowercased().trimmingCharacters(in: .whitespaces)
        if let id = tzAliases[t]      { return TimeZone(identifier: id) }
        if let tz = TimeZone(identifier: text) { return tz }
        if let tz = TimeZone(abbreviation: t.uppercased()) { return tz }
        // Partial match — longest key first to avoid "la" matching "colombia"
        let sorted = tzAliases.keys.sorted { $0.count > $1.count }
        for key in sorted {
            if t == key || t.hasPrefix(key + " ") || t.hasSuffix(" " + key) { return TimeZone(identifier: tzAliases[key]!) }
        }
        return nil
    }

    // MARK: - Formatting

    private static func formatTime(_ date: Date, in tz: TimeZone) -> String {
        let f = DateFormatter(); f.timeZone = tz; f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private static func offsetString(_ tz: TimeZone) -> String {
        let s = tz.secondsFromGMT()
        let h = s / 3600; let m = abs(s % 3600) / 60
        let sign = h >= 0 ? "+" : "−"
        return m == 0 ? "\(sign)\(abs(h))" : "\(sign)\(abs(h)):\(String(format: "%02d", m))"
    }

    private static func friendlyDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d, yyyy"
        return f.string(from: date)
    }

    private static func calendarDaysBetween(_ from: Date, and to: Date) -> Int {
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: from),
                                          to:   cal.startOfDay(for: to)).day ?? 0
    }

    private static func addBusinessDays(_ n: Int, to start: Date) -> Date {
        let cal = Calendar.current
        var date = cal.startOfDay(for: start)
        let step = n >= 0 ? 1 : -1
        var remaining = abs(n)
        while remaining > 0 {
            date = cal.date(byAdding: .day, value: step, to: date)!
            let wd = cal.component(.weekday, from: date)
            if wd != 1 && wd != 7 { remaining -= 1 }
        }
        return date
    }

    private static func plural(_ n: Int) -> String { n == 1 ? "" : "s" }
}
