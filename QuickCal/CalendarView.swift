import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var settings: SettingsStore
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date?
    @State private var hoveredHoliday: (label: String, color: Color)? = nil

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
            Divider().padding(.vertical, 4)
            dayOfWeekHeader
            calendarGrid
            holidayLabel
            Spacer(minLength: 0)
            Divider()
            CalendarStatsView(date: selectedDate ?? Date())
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Month header

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Text(monthTitle)
                .font(.system(size: 15, weight: .semibold))

            Spacer()

            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Day-of-week header

    private var dayOfWeekHeader: some View {
        HStack(spacing: 0) {
            if settings.showWeekNumbers {
                weekNumberGutterSpacer
            }
            ForEach(orderedDayLabels, id: \.self) { label in
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
            }
        }
    }

    // MARK: - Calendar grid

    private var calendarGrid: some View {
        VStack(spacing: 2) {
            ForEach(Array(weekRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    if settings.showWeekNumbers {
                        Text("\(row.weekNumber)")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .frame(width: weekNumberWidth, alignment: .trailing)
                            .padding(.trailing, 4)
                    }
                    ForEach(Array(row.days.enumerated()), id: \.offset) { _, date in
                        if let date {
                            let dayHolidays = settings.showHolidays
                                ? HolidayData.holidays(for: date, countries: settings.enabledCountries)
                                : []
                            DayCell(
                                date: date,
                                isCurrentMonth: isSameMonth(date),
                                isToday: Calendar.current.isDateInToday(date),
                                isSelected: selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false,
                                dotColor: dotColor(for: dayHolidays),
                                isObserved: dayHolidays.contains(where: { $0.isObserved }),
                                onHover: { hovering in
                                    if hovering, let label = hoverLabel(for: dayHolidays) {
                                        let color = dotColor(for: dayHolidays) ?? .orange
                                        hoveredHoliday = (label, color)
                                    } else {
                                        hoveredHoliday = nil
                                    }
                                }
                            )
                            .onTapGesture { selectedDate = date }
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Holiday label

    private var holidayLabel: some View {
        HStack(spacing: 5) {
            if let hovered = hoveredHoliday {
                Circle()
                    .fill(hovered.color)
                    .frame(width: 7, height: 7)
                Text(hovered.label)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text(" ").font(.system(size: 13))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
        .animation(.easeInOut(duration: 0.12), value: hoveredHoliday?.label)
    }

    // MARK: - Helpers

    private var weekNumberWidth: CGFloat { 24 }

    private var weekNumberGutterSpacer: some View {
        Color.clear.frame(width: weekNumberWidth + 4, height: 1)
    }

    private var orderedDayLabels: [String] {
        let all = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
        if settings.weekStartsOnMonday {
            return Array(all.dropFirst()) + [all[0]]
        }
        return all
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonth)
    }

    // Returns the offset of the first day within a week row (0-based)
    private func firstDayOffset(cal: Calendar, firstDay: Date) -> Int {
        let weekday = cal.component(.weekday, from: firstDay) // 1=Sun … 7=Sat
        if settings.weekStartsOnMonday {
            return (weekday - 2 + 7) % 7  // Mon=0 … Sun=6
        } else {
            return weekday - 1             // Sun=0 … Sat=6
        }
    }

    private struct WeekRow {
        let weekNumber: Int
        let days: [Date?]
    }

    private var weekRows: [WeekRow] {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = settings.weekStartsOnMonday ? 2 : 1

        guard let monthInterval = cal.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstDay = monthInterval.start
        let lastDay = cal.date(byAdding: .day, value: -1, to: monthInterval.end)!
        let daysInMonth = cal.component(.day, from: lastDay)

        let offset = firstDayOffset(cal: cal, firstDay: firstDay)
        let totalRows = Int(ceil(Double(offset + daysInMonth) / 7.0))

        var flat: [Date?] = Array(repeating: nil, count: offset)
        for i in 0 ..< daysInMonth {
            flat.append(cal.date(byAdding: .day, value: i, to: firstDay))
        }
        while flat.count < totalRows * 7 { flat.append(nil) }

        return (0 ..< totalRows).map { row in
            let slice = Array(flat[(row * 7) ..< (row * 7 + 7)])
            let anchor = slice.compactMap { $0 }.first ?? firstDay
            let weekNum = cal.component(.weekOfYear, from: anchor)
            return WeekRow(weekNumber: weekNum, days: slice)
        }
    }

    private func isSameMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }

    private func shiftMonth(_ delta: Int) {
        if let d = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = d
        }
    }

    // Orange = national/federal; teal = regional/observance varies
    private func dotColor(for holidays: [Holiday]) -> Color? {
        guard !holidays.isEmpty else { return nil }
        return holidays.contains(where: { $0.kind == .national }) ? .orange : .teal
    }

    private func hoverLabel(for holidays: [Holiday]) -> String? {
        guard !holidays.isEmpty else { return nil }
        return holidays.map { h in
            var parts = [h.country.flag, h.name]
            if h.isObserved { parts.append("(Observed)") }
            parts.append("·")
            parts.append(h.kind.label)
            return parts.joined(separator: "  ")
        }.joined(separator: "\n")
    }
}

// MARK: - DayCell

private struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let dotColor: Color?     // nil = no holiday; .orange = national; .teal = regional
    let isObserved: Bool
    let onHover: (Bool) -> Void

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var body: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 6).fill(Color.accentColor)
            } else if isToday {
                RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.15))
            }

            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.system(size: 13, weight: isToday ? .bold : .regular))
                    .foregroundStyle(
                        isSelected    ? .white :
                        isToday       ? Color.accentColor :
                        isCurrentMonth ? Color.primary : Color.secondary.opacity(0.4)
                    )

                if let base = dotColor {
                    let color = isSelected ? Color.white.opacity(0.85) : base
                    // Hollow ring = observed shift; filled = actual date
                    Circle()
                        .strokeBorder(color, lineWidth: isObserved ? 1.5 : 0)
                        .background(Circle().fill(isObserved ? Color.clear : color))
                        .frame(width: 5, height: 5)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .contentShape(Rectangle())
        .onHover { hovering in
            if dotColor != nil { onHover(hovering) }
        }
    }
}
