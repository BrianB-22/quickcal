import Foundation

// MARK: - Types

enum HolidayKind {
    case national   // Federally mandated, universally observed — orange dot
    case regional   // State/cultural/observance varies — teal dot

    var label: String {
        switch self {
        case .national: return "Federal Holiday"
        case .regional: return "Observance Varies"
        }
    }
}

enum HolidayCountry: String, CaseIterable, Codable {
    case us          = "US"
    case india       = "India"
    case uk          = "UK"
    case canada      = "Canada"
    case australia   = "Australia"
    case france      = "France"
    case germany     = "Germany"
    case italy       = "Italy"
    case japan       = "Japan"
    case brazil      = "Brazil"
    case mexico      = "Mexico"
    case netherlands = "Netherlands"
    case poland      = "Poland"
    case singapore   = "Singapore"
    case southKorea  = "SouthKorea"
    case spain       = "Spain"

    var displayName: String {
        switch self {
        case .us:          return "United States"
        case .india:       return "India"
        case .uk:          return "United Kingdom"
        case .canada:      return "Canada"
        case .australia:   return "Australia"
        case .france:      return "France"
        case .germany:     return "Germany"
        case .italy:       return "Italy"
        case .japan:       return "Japan"
        case .brazil:      return "Brazil"
        case .mexico:      return "Mexico"
        case .netherlands: return "Netherlands"
        case .poland:      return "Poland"
        case .singapore:   return "Singapore"
        case .southKorea:  return "South Korea"
        case .spain:       return "Spain"
        }
    }

    var flag: String {
        switch self {
        case .us:          return "🇺🇸"
        case .india:       return "🇮🇳"
        case .uk:          return "🇬🇧"
        case .canada:      return "🇨🇦"
        case .australia:   return "🇦🇺"
        case .france:      return "🇫🇷"
        case .germany:     return "🇩🇪"
        case .italy:       return "🇮🇹"
        case .japan:       return "🇯🇵"
        case .brazil:      return "🇧🇷"
        case .mexico:      return "🇲🇽"
        case .netherlands: return "🇳🇱"
        case .poland:      return "🇵🇱"
        case .singapore:   return "🇸🇬"
        case .southKorea:  return "🇰🇷"
        case .spain:       return "🇪🇸"
        }
    }
}

struct Holiday: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let observedDate: Date?
    let kind: HolidayKind
    let country: HolidayCountry

    var displayDate: Date { observedDate ?? date }
    var isObserved: Bool  { observedDate != nil }
}

// MARK: - HolidayData

enum HolidayData {

    // MARK: Public API

    static func holidays(for year: Int, countries: Set<HolidayCountry>) -> [Holiday] {
        countries.flatMap { holidays(for: year, country: $0) }
    }

    static func holidays(for date: Date, countries: Set<HolidayCountry>) -> [Holiday] {
        let cal = Calendar(identifier: .gregorian)
        let year = cal.component(.year, from: date)
        // Also check prior year for Dec 31 observed cases
        return [year - 1, year].flatMap { y in
            holidays(for: y, countries: countries).filter {
                cal.isDate($0.displayDate, inSameDayAs: date)
            }
        }
    }

    // US-only helpers kept for QueryEngine
    static func holidayName(for date: Date) -> String? {
        holidays(for: date, countries: [.us]).first?.name
    }

    static func isHoliday(_ date: Date) -> Bool {
        !holidays(for: date, countries: [.us]).isEmpty
    }

    static func holiday(for date: Date) -> Holiday? {
        holidays(for: date, countries: [.us]).first
    }

    static func date(forHolidayNamed name: String, year: Int) -> Date? {
        let lower = name.lowercased()
        return holidays(for: year, country: .us)
            .first { $0.name.lowercased().contains(lower) }?.date
    }

    // MARK: - Per-country

    private static func holidays(for year: Int, country: HolidayCountry) -> [Holiday] {
        switch country {
        case .us:          return usHolidays(year)
        case .india:       return indiaHolidays(year)
        case .uk:          return ukHolidays(year)
        case .canada:      return canadaHolidays(year)
        case .australia:   return australiaHolidays(year)
        case .france:      return franceHolidays(year)
        case .germany:     return germanyHolidays(year)
        case .italy:       return italyHolidays(year)
        case .japan:       return japanHolidays(year)
        case .brazil:      return brazilHolidays(year)
        case .mexico:      return mexicoHolidays(year)
        case .netherlands: return netherlandsHolidays(year)
        case .poland:      return polandHolidays(year)
        case .singapore:   return singaporeHolidays(year)
        case .southKorea:  return southKoreaHolidays(year)
        case .spain:       return spainHolidays(year)
        }
    }

    // MARK: - Shared helpers

    private static func cal() -> Calendar { Calendar(identifier: .gregorian) }

    private static func fixed(year: Int, month: Int, day: Int) -> Date {
        cal().date(from: DateComponents(year: year, month: month, day: day))!
    }

    private static func nthWeekday(_ weekday: Int, nth: Int, month: Int, year: Int) -> Date {
        let c = cal()
        let first = fixed(year: year, month: month, day: 1)
        let firstWD = c.component(.weekday, from: first)
        let offset = (weekday - firstWD + 7) % 7 + (nth - 1) * 7
        return c.date(byAdding: .day, value: offset, to: first)!
    }

    private static func lastWeekday(_ weekday: Int, month: Int, year: Int) -> Date {
        let c = cal()
        let range = c.range(of: .day, in: .month, for: fixed(year: year, month: month, day: 1))!
        let last = fixed(year: year, month: month, day: range.upperBound - 1)
        let lastWD = c.component(.weekday, from: last)
        let offset = (lastWD - weekday + 7) % 7
        return c.date(byAdding: .day, value: -offset, to: last)!
    }

    // Sat → Fri, Sun → Mon (for fixed-date holidays only)
    private static func observed(_ date: Date) -> Date? {
        let weekday = cal().component(.weekday, from: date)
        if weekday == 7 { return cal().date(byAdding: .day, value: -1, to: date) }
        if weekday == 1 { return cal().date(byAdding: .day, value:  1, to: date) }
        return nil
    }

    private static func h(_ name: String, date: Date, kind: HolidayKind,
                           country: HolidayCountry, shift: Bool = false) -> Holiday {
        Holiday(name: name, date: date,
                observedDate: shift ? observed(date) : nil,
                kind: kind, country: country)
    }

    // Anonymous Gregorian algorithm for Easter Sunday
    static func easter(year: Int) -> Date {
        let a = year % 19, b = year / 100, c = year % 100
        let d = b / 4,     e = b % 4,     f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let hh = (19 * a + b - d - g + 15) % 30
        let i = c / 4,     k = c % 4
        let l = (32 + 2 * e + 2 * i - hh - k) % 7
        let m = (a + 11 * hh + 22 * l) / 451
        let month = (hh + l - 7 * m + 114) / 31
        let day   = ((hh + l - 7 * m + 114) % 31) + 1
        return fixed(year: year, month: month, day: day)
    }

    private static func easterOffset(_ offset: Int, year: Int) -> Date {
        cal().date(byAdding: .day, value: offset, to: easter(year: year))!
    }

    // MARK: - United States

    private static func usHolidays(_ year: Int) -> [Holiday] {
        [
            h("New Year's Day",   date: fixed(year: year, month: 1, day: 1),                         kind: .national, country: .us, shift: true),
            h("MLK Day",          date: nthWeekday(2, nth: 3, month: 1, year: year),                  kind: .national, country: .us),
            h("Presidents' Day",  date: nthWeekday(2, nth: 3, month: 2, year: year),                  kind: .national, country: .us),
            h("Memorial Day",     date: lastWeekday(2, month: 5, year: year),                         kind: .national, country: .us),
            h("Juneteenth",       date: fixed(year: year, month: 6, day: 19),                         kind: .national, country: .us, shift: true),
            h("Independence Day", date: fixed(year: year, month: 7, day: 4),                          kind: .national, country: .us, shift: true),
            h("Labor Day",        date: nthWeekday(2, nth: 1, month: 9, year: year),                  kind: .national, country: .us),
            h("Columbus Day",     date: nthWeekday(2, nth: 2, month: 10, year: year),                 kind: .regional, country: .us),
            h("Veterans Day",     date: fixed(year: year, month: 11, day: 11),                        kind: .national, country: .us, shift: true),
            h("Thanksgiving",     date: nthWeekday(5, nth: 4, month: 11, year: year),                 kind: .national, country: .us),
            h("Christmas Day",    date: fixed(year: year, month: 12, day: 25),                        kind: .national, country: .us, shift: true),
        ]
    }

    // MARK: - United Kingdom (England & Wales)

    private static func ukHolidays(_ year: Int) -> [Holiday] {
        // Early May: 1st Monday in May (except some years moved for special occasions — use rule)
        let earlyMay = nthWeekday(2, nth: 1, month: 5, year: year)
        let springBH = lastWeekday(2, month: 5, year: year)
        let summerBH = lastWeekday(2, month: 8, year: year)
        return [
            h("New Year's Day",       date: fixed(year: year, month: 1, day: 1),    kind: .national, country: .uk, shift: true),
            h("Good Friday",          date: easterOffset(-2, year: year),            kind: .national, country: .uk),
            h("Easter Monday",        date: easterOffset( 1, year: year),            kind: .national, country: .uk),
            h("Early May Bank Holiday", date: earlyMay,                             kind: .national, country: .uk),
            h("Spring Bank Holiday",  date: springBH,                               kind: .national, country: .uk),
            h("Summer Bank Holiday",  date: summerBH,                               kind: .national, country: .uk),
            h("Christmas Day",        date: fixed(year: year, month: 12, day: 25),  kind: .national, country: .uk, shift: true),
            h("Boxing Day",           date: fixed(year: year, month: 12, day: 26),  kind: .national, country: .uk, shift: true),
        ]
    }

    // MARK: - Canada

    private static func canadaHolidays(_ year: Int) -> [Holiday] {
        // Victoria Day: last Monday on or before May 24
        let may24 = fixed(year: year, month: 5, day: 24)
        let may24WD = cal().component(.weekday, from: may24) // 1=Sun,2=Mon…
        let victoriaOffset = -(may24WD == 2 ? 0 : (may24WD - 2 + 7) % 7)
        let victoriaDay = cal().date(byAdding: .day, value: victoriaOffset, to: may24)!

        return [
            h("New Year's Day",   date: fixed(year: year, month: 1,  day: 1),  kind: .national, country: .canada, shift: true),
            h("Good Friday",      date: easterOffset(-2, year: year),           kind: .national, country: .canada),
            h("Easter Monday",    date: easterOffset( 1, year: year),           kind: .regional, country: .canada),
            h("Victoria Day",     date: victoriaDay,                            kind: .national, country: .canada),
            h("Canada Day",       date: fixed(year: year, month: 7,  day: 1),  kind: .national, country: .canada, shift: true),
            h("Civic Holiday",    date: nthWeekday(2, nth: 1, month: 8, year: year), kind: .regional, country: .canada),
            h("Labour Day",       date: nthWeekday(2, nth: 1, month: 9, year: year), kind: .national, country: .canada),
            h("Thanksgiving",     date: nthWeekday(2, nth: 2, month: 10, year: year), kind: .national, country: .canada),
            h("Remembrance Day",  date: fixed(year: year, month: 11, day: 11), kind: .national, country: .canada),
            h("Christmas Day",    date: fixed(year: year, month: 12, day: 25), kind: .national, country: .canada, shift: true),
            h("Boxing Day",       date: fixed(year: year, month: 12, day: 26), kind: .regional, country: .canada, shift: true),
        ]
    }

    // MARK: - Australia (national; state holidays marked regional)

    private static func australiaHolidays(_ year: Int) -> [Holiday] {
        [
            h("New Year's Day",  date: fixed(year: year, month: 1,  day: 1),  kind: .national, country: .australia, shift: true),
            h("Australia Day",   date: fixed(year: year, month: 1,  day: 26), kind: .national, country: .australia, shift: true),
            h("Good Friday",     date: easterOffset(-2, year: year),           kind: .national, country: .australia),
            h("Easter Saturday", date: easterOffset(-1, year: year),           kind: .regional, country: .australia),
            h("Easter Monday",   date: easterOffset( 1, year: year),           kind: .national, country: .australia),
            h("Anzac Day",       date: fixed(year: year, month: 4,  day: 25), kind: .national, country: .australia),
            h("Christmas Day",   date: fixed(year: year, month: 12, day: 25), kind: .national, country: .australia, shift: true),
            h("Boxing Day",      date: fixed(year: year, month: 12, day: 26), kind: .national, country: .australia, shift: true),
        ]
    }

    // MARK: - Germany

    private static func germanyHolidays(_ year: Int) -> [Holiday] {
        [
            h("New Year's Day",    date: fixed(year: year, month: 1, day: 1),  kind: .national, country: .germany),
            h("Epiphany",          date: fixed(year: year, month: 1, day: 6),  kind: .regional, country: .germany),
            h("Good Friday",       date: easterOffset(-2, year: year),          kind: .national, country: .germany),
            h("Easter Monday",     date: easterOffset( 1, year: year),          kind: .national, country: .germany),
            h("Labour Day",        date: fixed(year: year, month: 5, day: 1),  kind: .national, country: .germany),
            h("Ascension Day",     date: easterOffset(39, year: year),          kind: .national, country: .germany),
            h("Whit Monday",       date: easterOffset(50, year: year),          kind: .national, country: .germany),
            h("Corpus Christi",    date: easterOffset(60, year: year),          kind: .regional, country: .germany),
            h("Assumption Day",    date: fixed(year: year, month: 8, day: 15), kind: .regional, country: .germany),
            h("German Unity Day",  date: fixed(year: year, month: 10, day: 3), kind: .national, country: .germany),
            h("All Saints' Day",   date: fixed(year: year, month: 11, day: 1), kind: .regional, country: .germany),
            h("Christmas Day",     date: fixed(year: year, month: 12, day: 25), kind: .national, country: .germany),
            h("St. Stephen's Day", date: fixed(year: year, month: 12, day: 26), kind: .national, country: .germany),
        ]
    }

    // MARK: - India
    // Fixed national holidays are always accurate.
    // Lunar/Islamic holidays are hardcoded 2023-2030; outside that range only fixed holidays show.

    private static let indiaLunar: [Int: [(name: String, month: Int, day: Int, kind: HolidayKind)]] = [
        2023: [
            ("Holi",          3,  8, .regional),
            ("Eid al-Fitr",   4, 21, .regional),
            ("Eid al-Adha",   6, 28, .regional),
            ("Dussehra",     10, 24, .regional),
            ("Diwali",       11, 12, .regional),
        ],
        2024: [
            ("Holi",          3, 25, .regional),
            ("Eid al-Fitr",   4, 10, .regional),
            ("Eid al-Adha",   6, 17, .regional),
            ("Dussehra",     10, 12, .regional),
            ("Diwali",       11,  1, .regional),
        ],
        2025: [
            ("Holi",          3, 14, .regional),
            ("Eid al-Fitr",   3, 30, .regional),
            ("Eid al-Adha",   6,  7, .regional),
            ("Dussehra",     10,  2, .regional),
            ("Diwali",       10, 20, .regional),
        ],
        2026: [
            ("Holi",          3,  3, .regional),
            ("Eid al-Fitr",   3, 20, .regional),
            ("Eid al-Adha",   5, 27, .regional),
            ("Dussehra",     10, 20, .regional),
            ("Diwali",       11,  8, .regional),
        ],
        2027: [
            ("Holi",          3, 22, .regional),
            ("Eid al-Fitr",   3,  9, .regional),
            ("Eid al-Adha",   5, 16, .regional),
            ("Dussehra",     10, 10, .regional),
            ("Diwali",       10, 29, .regional),
        ],
        2028: [
            ("Holi",          3, 11, .regional),
            ("Eid al-Fitr",   2, 26, .regional),
            ("Eid al-Adha",   5,  5, .regional),
            ("Dussehra",      9, 28, .regional),
            ("Diwali",       10, 17, .regional),
        ],
        2029: [
            ("Holi",          3,  1, .regional),
            ("Eid al-Fitr",   2, 14, .regional),
            ("Eid al-Adha",   4, 24, .regional),
            ("Dussehra",     10, 17, .regional),
            ("Diwali",       11,  5, .regional),
        ],
        2030: [
            ("Holi",          3, 19, .regional),
            ("Eid al-Fitr",   2,  3, .regional),
            ("Eid al-Adha",   4, 14, .regional),
            ("Dussehra",     10,  7, .regional),
            ("Diwali",       10, 25, .regional),
        ],
    ]

    private static func indiaHolidays(_ year: Int) -> [Holiday] {
        var result: [Holiday] = [
            h("Republic Day",      date: fixed(year: year, month: 1,  day: 26), kind: .national, country: .india),
            h("Good Friday",       date: easterOffset(-2, year: year),           kind: .regional, country: .india),
            h("Independence Day",  date: fixed(year: year, month: 8,  day: 15), kind: .national, country: .india),
            h("Gandhi Jayanti",    date: fixed(year: year, month: 10, day: 2),  kind: .national, country: .india),
            h("Christmas Day",     date: fixed(year: year, month: 12, day: 25), kind: .regional, country: .india),
        ]
        if let lunar = indiaLunar[year] {
            for entry in lunar {
                result.append(h(entry.name,
                                date: fixed(year: year, month: entry.month, day: entry.day),
                                kind: entry.kind, country: .india))
            }
        }
        return result
    }

    // MARK: - France

    private static func franceHolidays(_ year: Int) -> [Holiday] {
        [
            h("New Year's Day",      date: fixed(year: year, month: 1,  day: 1),  kind: .national, country: .france),
            h("Easter Monday",       date: easterOffset(1,  year: year),           kind: .national, country: .france),
            h("Labour Day",          date: fixed(year: year, month: 5,  day: 1),  kind: .national, country: .france),
            h("Victory in Europe Day", date: fixed(year: year, month: 5, day: 8), kind: .national, country: .france),
            h("Ascension Day",       date: easterOffset(39, year: year),           kind: .national, country: .france),
            h("Whit Monday",         date: easterOffset(50, year: year),           kind: .national, country: .france),
            h("Bastille Day",        date: fixed(year: year, month: 7,  day: 14), kind: .national, country: .france),
            h("Assumption of Mary",  date: fixed(year: year, month: 8,  day: 15), kind: .national, country: .france),
            h("All Saints' Day",     date: fixed(year: year, month: 11, day: 1),  kind: .national, country: .france),
            h("Armistice Day",       date: fixed(year: year, month: 11, day: 11), kind: .national, country: .france),
            h("Christmas Day",       date: fixed(year: year, month: 12, day: 25), kind: .national, country: .france),
        ]
    }

    // MARK: - Poland

    private static func polandHolidays(_ year: Int) -> [Holiday] {
        [
            h("New Year's Day",      date: fixed(year: year, month: 1,  day: 1),  kind: .national, country: .poland),
            h("Epiphany",            date: fixed(year: year, month: 1,  day: 6),  kind: .national, country: .poland),
            h("Easter Sunday",       date: easter(year: year),                    kind: .national, country: .poland),
            h("Easter Monday",       date: easterOffset(1,  year: year),           kind: .national, country: .poland),
            h("Labour Day",          date: fixed(year: year, month: 5,  day: 1),  kind: .national, country: .poland),
            h("Constitution Day",    date: fixed(year: year, month: 5,  day: 3),  kind: .national, country: .poland),
            h("Pentecost Sunday",    date: easterOffset(49, year: year),           kind: .national, country: .poland),
            h("Corpus Christi",      date: easterOffset(60, year: year),           kind: .national, country: .poland),
            h("Assumption of Mary",  date: fixed(year: year, month: 8,  day: 15), kind: .national, country: .poland),
            h("All Saints' Day",     date: fixed(year: year, month: 11, day: 1),  kind: .national, country: .poland),
            h("Independence Day",    date: fixed(year: year, month: 11, day: 11), kind: .national, country: .poland),
            h("Christmas Day",       date: fixed(year: year, month: 12, day: 25), kind: .national, country: .poland),
            h("St. Stephen's Day",   date: fixed(year: year, month: 12, day: 26), kind: .national, country: .poland),
        ]
    }

    // MARK: - Italy

    private static func italyHolidays(_ year: Int) -> [Holiday] {
        [
            h("New Year's Day",        date: fixed(year: year, month: 1,  day: 1),  kind: .national, country: .italy),
            h("Epiphany",              date: fixed(year: year, month: 1,  day: 6),  kind: .national, country: .italy),
            h("Easter Sunday",         date: easter(year: year),                    kind: .national, country: .italy),
            h("Easter Monday",         date: easterOffset(1,  year: year),           kind: .national, country: .italy),
            h("Liberation Day",        date: fixed(year: year, month: 4,  day: 25), kind: .national, country: .italy),
            h("Labour Day",            date: fixed(year: year, month: 5,  day: 1),  kind: .national, country: .italy),
            h("Republic Day",          date: fixed(year: year, month: 6,  day: 2),  kind: .national, country: .italy),
            h("Assumption of Mary",    date: fixed(year: year, month: 8,  day: 15), kind: .national, country: .italy),
            h("All Saints' Day",       date: fixed(year: year, month: 11, day: 1),  kind: .national, country: .italy),
            h("Immaculate Conception", date: fixed(year: year, month: 12, day: 8),  kind: .national, country: .italy),
            h("Christmas Day",         date: fixed(year: year, month: 12, day: 25), kind: .national, country: .italy),
            h("St. Stephen's Day",     date: fixed(year: year, month: 12, day: 26), kind: .national, country: .italy),
        ]
    }

    // MARK: - Spain

    private static func spainHolidays(_ year: Int) -> [Holiday] {
        [
            h("New Year's Day",        date: fixed(year: year, month: 1,  day: 1),  kind: .national, country: .spain),
            h("Epiphany",              date: fixed(year: year, month: 1,  day: 6),  kind: .national, country: .spain),
            h("Good Friday",           date: easterOffset(-2, year: year),           kind: .national, country: .spain),
            h("Labour Day",            date: fixed(year: year, month: 5,  day: 1),  kind: .national, country: .spain),
            h("Assumption of Mary",    date: fixed(year: year, month: 8,  day: 15), kind: .national, country: .spain),
            h("National Day of Spain", date: fixed(year: year, month: 10, day: 12), kind: .national, country: .spain),
            h("All Saints' Day",       date: fixed(year: year, month: 11, day: 1),  kind: .national, country: .spain),
            h("Constitution Day",      date: fixed(year: year, month: 12, day: 6),  kind: .national, country: .spain),
            h("Immaculate Conception", date: fixed(year: year, month: 12, day: 8),  kind: .national, country: .spain),
            h("Christmas Day",         date: fixed(year: year, month: 12, day: 25), kind: .national, country: .spain),
        ]
    }

    // MARK: - Netherlands

    private static func netherlandsHolidays(_ year: Int) -> [Holiday] {
        // King's Day: Apr 27, shifts to Apr 26 when Apr 27 falls on Sunday
        let apr27    = fixed(year: year, month: 4, day: 27)
        let kingsDay = cal().component(.weekday, from: apr27) == 1
            ? cal().date(byAdding: .day, value: -1, to: apr27)! : apr27
        return [
            h("New Year's Day",    date: fixed(year: year, month: 1,  day: 1),  kind: .national, country: .netherlands),
            h("Good Friday",       date: easterOffset(-2, year: year),           kind: .regional, country: .netherlands),
            h("Easter Sunday",     date: easter(year: year),                    kind: .regional, country: .netherlands),
            h("Easter Monday",     date: easterOffset( 1, year: year),           kind: .national, country: .netherlands),
            h("King's Day",        date: kingsDay,                              kind: .national, country: .netherlands),
            h("Liberation Day",    date: fixed(year: year, month: 5,  day: 5),  kind: .national, country: .netherlands),
            h("Ascension Day",     date: easterOffset(39, year: year),           kind: .national, country: .netherlands),
            h("Whit Sunday",       date: easterOffset(49, year: year),           kind: .regional, country: .netherlands),
            h("Whit Monday",       date: easterOffset(50, year: year),           kind: .national, country: .netherlands),
            h("Christmas Day",     date: fixed(year: year, month: 12, day: 25), kind: .national, country: .netherlands),
            h("St. Stephen's Day", date: fixed(year: year, month: 12, day: 26), kind: .national, country: .netherlands),
        ]
    }

    // MARK: - Brazil

    private static func brazilHolidays(_ year: Int) -> [Holiday] {
        [
            h("New Year's Day",          date: fixed(year: year, month: 1,  day: 1),  kind: .national, country: .brazil),
            h("Carnival",                date: easterOffset(-47, year: year),          kind: .regional, country: .brazil),
            h("Good Friday",             date: easterOffset(-2,  year: year),          kind: .national, country: .brazil),
            h("Tiradentes Day",          date: fixed(year: year, month: 4,  day: 21), kind: .national, country: .brazil),
            h("Labour Day",              date: fixed(year: year, month: 5,  day: 1),  kind: .national, country: .brazil),
            h("Corpus Christi",          date: easterOffset(60,  year: year),          kind: .regional, country: .brazil),
            h("Independence Day",        date: fixed(year: year, month: 9,  day: 7),  kind: .national, country: .brazil),
            h("Our Lady of Aparecida",   date: fixed(year: year, month: 10, day: 12), kind: .national, country: .brazil),
            h("All Souls' Day",          date: fixed(year: year, month: 11, day: 2),  kind: .national, country: .brazil),
            h("Republic Day",            date: fixed(year: year, month: 11, day: 15), kind: .national, country: .brazil),
            h("Black Consciousness Day", date: fixed(year: year, month: 11, day: 20), kind: .national, country: .brazil),
            h("Christmas Day",           date: fixed(year: year, month: 12, day: 25), kind: .national, country: .brazil),
        ]
    }

    // MARK: - Mexico

    private static func mexicoHolidays(_ year: Int) -> [Holiday] {
        [
            h("New Year's Day",    date: fixed(year: year, month: 1,  day: 1),                  kind: .national, country: .mexico),
            h("Constitution Day",  date: nthWeekday(2, nth: 1, month: 2,  year: year),          kind: .national, country: .mexico),
            h("Benito Juárez Day", date: nthWeekday(2, nth: 3, month: 3,  year: year),          kind: .national, country: .mexico),
            h("Good Friday",       date: easterOffset(-2, year: year),                           kind: .regional, country: .mexico),
            h("Labour Day",        date: fixed(year: year, month: 5,  day: 1),                  kind: .national, country: .mexico),
            h("Independence Day",  date: fixed(year: year, month: 9,  day: 16),                 kind: .national, country: .mexico),
            h("Revolution Day",    date: nthWeekday(2, nth: 3, month: 11, year: year),          kind: .national, country: .mexico),
            h("Christmas Day",     date: fixed(year: year, month: 12, day: 25),                 kind: .national, country: .mexico),
        ]
    }

    // MARK: - Japan
    // Vernal and Autumnal Equinox dates vary by year (astronomical calculation).
    // Hardcoded 2023–2030; defaults to Mar 20 / Sep 23 outside that range.
    // Note: substitute holidays (振替休日, Sun → next Mon) are not computed.

    private static let japanVernalEquinox: [Int: (Int, Int)] = [
        2023: (3, 21), 2024: (3, 20), 2025: (3, 20), 2026: (3, 20),
        2027: (3, 20), 2028: (3, 19), 2029: (3, 20), 2030: (3, 20),
    ]
    private static let japanAutumnalEquinox: [Int: (Int, Int)] = [
        2023: (9, 23), 2024: (9, 22), 2025: (9, 23), 2026: (9, 23),
        2027: (9, 23), 2028: (9, 22), 2029: (9, 23), 2030: (9, 23),
    ]

    private static func japanHolidays(_ year: Int) -> [Holiday] {
        let vernal   = japanVernalEquinox[year]   ?? (3, 20)
        let autumnal = japanAutumnalEquinox[year] ?? (9, 23)
        return [
            h("New Year's Day",           date: fixed(year: year, month: 1, day: 1),                   kind: .national, country: .japan),
            h("Coming of Age Day",        date: nthWeekday(2, nth: 2, month: 1,  year: year),          kind: .national, country: .japan),
            h("National Foundation Day",  date: fixed(year: year, month: 2, day: 11),                  kind: .national, country: .japan),
            h("Emperor's Birthday",       date: fixed(year: year, month: 2, day: 23),                  kind: .national, country: .japan),
            h("Vernal Equinox Day",       date: fixed(year: year, month: vernal.0,   day: vernal.1),   kind: .national, country: .japan),
            h("Showa Day",                date: fixed(year: year, month: 4, day: 29),                  kind: .national, country: .japan),
            h("Constitution Day",         date: fixed(year: year, month: 5, day: 3),                   kind: .national, country: .japan),
            h("Greenery Day",             date: fixed(year: year, month: 5, day: 4),                   kind: .national, country: .japan),
            h("Children's Day",           date: fixed(year: year, month: 5, day: 5),                   kind: .national, country: .japan),
            h("Marine Day",               date: nthWeekday(2, nth: 3, month: 7,  year: year),          kind: .national, country: .japan),
            h("Mountain Day",             date: fixed(year: year, month: 8, day: 11),                  kind: .national, country: .japan),
            h("Respect for the Aged Day", date: nthWeekday(2, nth: 3, month: 9,  year: year),          kind: .national, country: .japan),
            h("Autumnal Equinox Day",     date: fixed(year: year, month: autumnal.0, day: autumnal.1), kind: .national, country: .japan),
            h("Sports Day",               date: nthWeekday(2, nth: 2, month: 10, year: year),          kind: .national, country: .japan),
            h("Culture Day",              date: fixed(year: year, month: 11, day: 3),                  kind: .national, country: .japan),
            h("Labor Thanksgiving Day",   date: fixed(year: year, month: 11, day: 23),                 kind: .national, country: .japan),
        ]
    }

    // MARK: - Singapore
    // Fixed holidays are always accurate.
    // Lunar/Islamic holidays hardcoded 2023–2030.

    private static let singaporeLunar: [Int: [(name: String, month: Int, day: Int)]] = [
        2023: [("Chinese New Year", 1, 22), ("Chinese New Year", 1, 23), ("Vesak Day", 6, 2),
               ("Hari Raya Puasa", 4, 21), ("Hari Raya Haji", 6, 28), ("Deepavali", 11, 13)],
        2024: [("Chinese New Year", 2, 10), ("Chinese New Year", 2, 11), ("Vesak Day", 5, 22),
               ("Hari Raya Puasa", 4, 10), ("Hari Raya Haji", 6, 17), ("Deepavali", 10, 31)],
        2025: [("Chinese New Year", 1, 29), ("Chinese New Year", 1, 30), ("Vesak Day", 5, 12),
               ("Hari Raya Puasa", 3, 30), ("Hari Raya Haji", 6,  6), ("Deepavali", 10, 20)],
        2026: [("Chinese New Year", 2, 17), ("Chinese New Year", 2, 18), ("Vesak Day", 5, 31),
               ("Hari Raya Puasa", 3, 20), ("Hari Raya Haji", 5, 27), ("Deepavali", 11,  8)],
        2027: [("Chinese New Year", 2,  6), ("Chinese New Year", 2,  7), ("Vesak Day", 5, 20),
               ("Hari Raya Puasa", 3,  9), ("Hari Raya Haji", 5, 16), ("Deepavali", 10, 28)],
        2028: [("Chinese New Year", 1, 26), ("Chinese New Year", 1, 27), ("Vesak Day", 5,  8),
               ("Hari Raya Puasa", 2, 26), ("Hari Raya Haji", 5,  5), ("Deepavali", 10, 17)],
    ]

    private static func singaporeHolidays(_ year: Int) -> [Holiday] {
        var result: [Holiday] = [
            h("New Year's Day", date: fixed(year: year, month: 1,  day: 1),  kind: .national, country: .singapore),
            h("Good Friday",    date: easterOffset(-2, year: year),           kind: .national, country: .singapore),
            h("Labour Day",     date: fixed(year: year, month: 5,  day: 1),  kind: .national, country: .singapore),
            h("National Day",   date: fixed(year: year, month: 8,  day: 9),  kind: .national, country: .singapore),
            h("Christmas Day",  date: fixed(year: year, month: 12, day: 25), kind: .national, country: .singapore),
        ]
        if let lunar = singaporeLunar[year] {
            for entry in lunar {
                result.append(h(entry.name,
                                date: fixed(year: year, month: entry.month, day: entry.day),
                                kind: .national, country: .singapore))
            }
        }
        return result
    }

    // MARK: - South Korea
    // Seollal (Lunar New Year, 3 days) and Chuseok (3 days) are lunar-based.
    // Buddha's Birthday is also lunar. All hardcoded 2023–2030.

    private static let koreaLunar: [Int: [(name: String, month: Int, day: Int)]] = [
        2023: [
            ("Seollal Eve",    1, 21), ("Seollal",         1, 22), ("Seollal Holiday", 1, 23),
            ("Buddha's Birthday", 5, 27),
            ("Chuseok Eve",    9, 28), ("Chuseok",         9, 29), ("Chuseok Holiday", 9, 30),
        ],
        2024: [
            ("Seollal Eve",    2,  9), ("Seollal",         2, 10), ("Seollal Holiday", 2, 12),
            ("Buddha's Birthday", 5, 15),
            ("Chuseok Eve",    9, 16), ("Chuseok",         9, 17), ("Chuseok Holiday", 9, 18),
        ],
        2025: [
            ("Seollal Eve",    1, 28), ("Seollal",         1, 29), ("Seollal Holiday", 1, 30),
            ("Buddha's Birthday", 5,  5),
            ("Chuseok Eve",   10,  5), ("Chuseok",        10,  6), ("Chuseok Holiday",10,  7),
        ],
        2026: [
            ("Seollal Eve",    2, 16), ("Seollal",         2, 17), ("Seollal Holiday", 2, 18),
            ("Buddha's Birthday", 5, 24),
            ("Chuseok Eve",    9, 24), ("Chuseok",         9, 25), ("Chuseok Holiday", 9, 26),
        ],
        2027: [
            ("Seollal Eve",    2,  5), ("Seollal",         2,  6), ("Seollal Holiday", 2,  7),
            ("Buddha's Birthday", 5, 13),
            ("Chuseok Eve",   10, 14), ("Chuseok",        10, 15), ("Chuseok Holiday",10, 16),
        ],
        2028: [
            ("Seollal Eve",    1, 25), ("Seollal",         1, 26), ("Seollal Holiday", 1, 27),
            ("Buddha's Birthday", 5,  2),
            ("Chuseok Eve",   10,  2), ("Chuseok",        10,  3), ("Chuseok Holiday",10,  4),
        ],
    ]

    private static func southKoreaHolidays(_ year: Int) -> [Holiday] {
        var result: [Holiday] = [
            h("New Year's Day",         date: fixed(year: year, month: 1,  day: 1),  kind: .national, country: .southKorea),
            h("Independence Movement Day", date: fixed(year: year, month: 3, day: 1), kind: .national, country: .southKorea),
            h("Children's Day",         date: fixed(year: year, month: 5,  day: 5),  kind: .national, country: .southKorea),
            h("Memorial Day",           date: fixed(year: year, month: 6,  day: 6),  kind: .national, country: .southKorea),
            h("Liberation Day",         date: fixed(year: year, month: 8,  day: 15), kind: .national, country: .southKorea),
            h("National Foundation Day",date: fixed(year: year, month: 10, day: 3),  kind: .national, country: .southKorea),
            h("Hangeul Day",            date: fixed(year: year, month: 10, day: 9),  kind: .national, country: .southKorea),
            h("Christmas Day",          date: fixed(year: year, month: 12, day: 25), kind: .national, country: .southKorea),
        ]
        if let lunar = koreaLunar[year] {
            for entry in lunar {
                result.append(h(entry.name,
                                date: fixed(year: year, month: entry.month, day: entry.day),
                                kind: .national, country: .southKorea))
            }
        }
        return result
    }
}
