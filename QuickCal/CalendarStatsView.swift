import SwiftUI

// MARK: - Moon phase

private enum MoonPhase {
    // Returns 0.0 (new moon) → approaching 1.0 (next new moon)
    static func illumination(for date: Date) -> Double {
        // Reference new moon: Jan 6, 2000, 18:14 UTC
        let ref = Date(timeIntervalSince1970: 947182440.0)
        let cycle = 29.53059
        var age = (date.timeIntervalSince(ref) / 86400).truncatingRemainder(dividingBy: cycle)
        if age < 0 { age += cycle }
        return age / cycle
    }

    static func name(_ p: Double) -> String {
        switch p {
        case 0.0..<0.033:  return "New Moon"
        case 0.033..<0.25: return "Waxing Crescent"
        case 0.25..<0.283: return "First Quarter"
        case 0.283..<0.5:  return "Waxing Gibbous"
        case 0.5..<0.533:  return "Full Moon"
        case 0.533..<0.75: return "Waning Gibbous"
        case 0.75..<0.783: return "Last Quarter"
        default:           return "Waning Crescent"
        }
    }

    static func symbol(_ p: Double) -> String {
        switch p {
        case 0.0..<0.033:  return "moonphase.new.moon"
        case 0.033..<0.25: return "moonphase.waxing.crescent"
        case 0.25..<0.283: return "moonphase.first.quarter"
        case 0.283..<0.5:  return "moonphase.waxing.gibbous"
        case 0.5..<0.533:  return "moonphase.full.moon"
        case 0.533..<0.75: return "moonphase.waning.gibbous"
        case 0.75..<0.783: return "moonphase.last.quarter"
        default:           return "moonphase.waning.crescent"
        }
    }
}

// MARK: - Season

private struct SeasonInfo {
    let name: String
    let emoji: String
    let day: Int
    let total: Int

    static func from(_ date: Date) -> SeasonInfo {
        let cal = Calendar(identifier: .gregorian)
        let year  = cal.component(.year,  from: date)
        let month = cal.component(.month, from: date)

        let name: String; let emoji: String
        let startMonth: Int; let startYear: Int
        switch month {
        case 3, 4, 5:   name = "Spring"; emoji = "🌸"; startMonth = 3;  startYear = year
        case 6, 7, 8:   name = "Summer"; emoji = "☀️"; startMonth = 6;  startYear = year
        case 9, 10, 11: name = "Autumn"; emoji = "🍂"; startMonth = 9;  startYear = year
        case 12:        name = "Winter"; emoji = "❄️"; startMonth = 12; startYear = year
        default:        name = "Winter"; emoji = "❄️"; startMonth = 12; startYear = year - 1
        }

        let start = cal.date(from: DateComponents(year: startYear, month: startMonth, day: 1))!
        let end   = cal.date(byAdding: .month, value: 3, to: start)!
        let total = cal.dateComponents([.day], from: start, to: end).day!
        let day   = cal.dateComponents([.day], from: start, to: cal.startOfDay(for: date)).day! + 1
        return SeasonInfo(name: name, emoji: emoji, day: max(1, day), total: total)
    }
}

// MARK: - CalendarStatsView

struct CalendarStatsView: View {
    let date: Date
    private let cal = Calendar(identifier: .gregorian)

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    // Moon
    private var moonP:      Double { MoonPhase.illumination(for: date) }
    private var moonName:   String { MoonPhase.name(moonP) }
    private var moonSymbol: String { MoonPhase.symbol(moonP) }

    // Season
    private var season: SeasonInfo { SeasonInfo.from(date) }

    // Year
    private var year: Int        { cal.component(.year, from: date) }
    private var dayOfYear: Int   { cal.ordinality(of: .day, in: .year, for: date) ?? 1 }
    private var daysInYear: Int  {
        let s = cal.date(from: DateComponents(year: year,     month: 1, day: 1))!
        let e = cal.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        return cal.dateComponents([.day], from: s, to: e).day!
    }
    private var daysLeft: Int    { daysInYear - dayOfYear }
    private var yearPct: Double  { Double(dayOfYear) / Double(daysInYear) }
    private var weekNum: Int     { cal.component(.weekOfYear, from: date) }

    // Month
    private var monthAbbrev: String {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f.string(from: date)
    }
    private var bizDaysLeft: Int {
        let month = cal.component(.month, from: date)
        let monthStart = cal.date(from: DateComponents(year: year, month: month, day: 1))!
        let nextMonth  = cal.date(byAdding: .month, value: 1, to: monthStart)!
        let endOfMonth = cal.date(byAdding: .day, value: -1, to: nextMonth)!
        var count = 0
        var cursor = cal.startOfDay(for: date)
        while cursor <= endOfMonth {
            let wd = cal.component(.weekday, from: cursor)
            if wd != 1 && wd != 7 { count += 1 }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
        }
        return count
    }

    private var dateLabelText: String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // "Selected date" chip — only when not today
            if !isToday {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                    Text(dateLabelText)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            // Moon phase + Season
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Image(systemName: moonSymbol)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    Text(moonName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(season.emoji) \(season.name)  ·  Day \(season.day) of \(season.total)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // Year progress bar
            HStack(spacing: 6) {
                Text(String(year))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(width: 34, alignment: .leading)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.secondary.opacity(0.15))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor.opacity(0.5))
                            .frame(width: max(4, geo.size.width * yearPct))
                    }
                }
                .frame(height: 4)

                Text("\(Int(yearPct * 100))%")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(width: 32, alignment: .trailing)
            }

            // Day stats strip
            HStack(spacing: 0) {
                chip("Day \(dayOfYear)")
                sep
                chip("Mo \(cal.component(.month, from: date))")
                sep
                chip("Wk \(weekNum)")
                sep
                chip("\(daysLeft) days left in \(year)")
                sep
                chip("\(bizDaysLeft) biz days in \(monthAbbrev)")
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 10)
    }

    private func chip(_ text: String) -> some View {
        Text(text).font(.system(size: 10)).foregroundStyle(.tertiary)
    }

    private var sep: some View {
        Text("  ·  ").font(.system(size: 10)).foregroundStyle(Color.secondary.opacity(0.3))
    }
}
