import SwiftUI
import AppKit

struct CalendarView: View {
    @EnvironmentObject var settings: SettingsStore
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date?
    @Binding var rangeEnd: Date?
    @State private var hoveredHoliday: (label: String, color: Color)? = nil
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
            Divider().padding(.vertical, 4)
            dayOfWeekHeader
            calendarGrid
            holidayLabel
            Spacer(minLength: 0)
            Divider()
            if let start = selectedDate, let end = rangeEnd {
                RangeStatsView(start: start, end: end)
            } else {
                CalendarStatsView(date: selectedDate ?? Date())
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onKeyPress(.leftArrow)  { shiftMonth(-1); return .handled }
        .onKeyPress(.rightArrow) { shiftMonth(1);  return .handled }
        .onKeyPress(.space) {
            displayedMonth = Calendar.current.startOfMonth(for: Date())
            selectedDate   = Calendar.current.startOfDay(for: Date())
            rangeEnd       = nil
            return .handled
        }
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
                let isCurrentWeek = settings.highlightCurrentWeek
                    && row.days.contains { Calendar.current.isDateInToday($0) }
                HStack(spacing: 0) {
                    if settings.showWeekNumbers {
                        Text("\(row.weekNumber)")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .frame(width: weekNumberWidth, alignment: .trailing)
                            .padding(.trailing, 4)
                    }
                    ForEach(Array(row.days.enumerated()), id: \.offset) { _, date in
                        let inMonth = isSameMonth(date)
                        let dayHolidays: [Holiday] = {
                            guard inMonth else { return [] }
                            var h: [Holiday] = []
                            if settings.showHolidays {
                                h += HolidayData.holidays(for: date, countries: settings.enabledCountries)
                            }
                            if settings.showUSObservances {
                                h += HolidayData.observances(for: date)
                            }
                            if settings.showUSNoveltyDays {
                                h += HolidayData.noveltyDays(for: date)
                            }
                            return h
                        }()
                        let isRangeEndpoint = (selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false)
                            || (rangeEnd.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false)
                        DayCell(
                            date: date,
                            isCurrentMonth: inMonth,
                            isToday: Calendar.current.isDateInToday(date),
                            isSelected: isRangeEndpoint,
                            isCurrentWeek: isCurrentWeek,
                            isInRange: isStrictlyBetween(date, selectedDate, rangeEnd),
                            dotColor: dotColor(for: dayHolidays),
                            isObserved: dayHolidays.contains(where: { $0.isObserved }),
                            onHover: { hovering in
                                if hovering, let label = hoverLabel(for: dayHolidays) {
                                    let color = dotColor(for: dayHolidays) ?? .red
                                    hoveredHoliday = (label, color)
                                } else {
                                    hoveredHoliday = nil
                                }
                            }
                        )
                        .onTapGesture {
                            selectedDate = date
                            rangeEnd = nil
                            if !inMonth {
                                displayedMonth = Calendar.current.startOfMonth(for: date)
                            }
                        }
                        .overlay(RightClickCatcher {
                            guard selectedDate != nil else { return }
                            rangeEnd = date
                            if !inMonth {
                                displayedMonth = Calendar.current.startOfMonth(for: date)
                            }
                        })
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
        let days: [Date]
    }

    private var weekRows: [WeekRow] {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = settings.weekStartsOnMonday ? 2 : 1

        guard let monthInterval = cal.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstDay = monthInterval.start
        let lastDay  = cal.date(byAdding: .day, value: -1, to: monthInterval.end)!
        let daysInMonth = cal.component(.day, from: lastDay)

        let offset    = firstDayOffset(cal: cal, firstDay: firstDay)
        let totalRows = Int(ceil(Double(offset + daysInMonth) / 7.0))

        var flat: [Date] = []

        // Leading dates from previous month
        for i in 0 ..< offset {
            flat.append(cal.date(byAdding: .day, value: i - offset, to: firstDay)!)
        }
        // Current month
        for i in 0 ..< daysInMonth {
            flat.append(cal.date(byAdding: .day, value: i, to: firstDay)!)
        }
        // Trailing dates from next month
        var trailing = 0
        while flat.count < totalRows * 7 {
            flat.append(cal.date(byAdding: .day, value: trailing, to: monthInterval.end)!)
            trailing += 1
        }

        return (0 ..< totalRows).map { row in
            let slice  = Array(flat[(row * 7) ..< (row * 7 + 7)])
            let anchor = slice.first ?? firstDay
            let weekNum = cal.component(.weekOfYear, from: anchor)
            return WeekRow(weekNumber: weekNum, days: slice)
        }
    }

    private func isSameMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }

    private func isStrictlyBetween(_ date: Date, _ a: Date?, _ b: Date?) -> Bool {
        guard let a, let b else { return false }
        let cal = Calendar.current
        let d = cal.startOfDay(for: date)
        let lo = cal.startOfDay(for: min(a, b))
        let hi = cal.startOfDay(for: max(a, b))
        return d > lo && d < hi
    }

    private func shiftMonth(_ delta: Int) {
        if let d = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = d
        }
    }

    // Red = national/federal; yellow = US observance; purple = US novelty; teal = regional/varies
    private func dotColor(for holidays: [Holiday]) -> Color? {
        guard !holidays.isEmpty else { return nil }
        if holidays.contains(where: { $0.kind == .national })     { return .red }
        if holidays.contains(where: { $0.kind == .usObservance }) { return .yellow }
        if holidays.contains(where: { $0.kind == .usNovelty })    { return .purple }
        return .teal
    }

    private func hoverLabel(for holidays: [Holiday]) -> String? {
        guard !holidays.isEmpty else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return holidays.map { h in
            var parts = [h.country.flag, h.name]
            if h.isObserved { parts.append("(Observed \(fmt.string(from: h.date)))") }
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
    let isCurrentWeek: Bool
    let isInRange: Bool
    let dotColor: Color?     // nil = no holiday; .red = national; .teal = regional
    let isObserved: Bool
    let onHover: (Bool) -> Void

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var body: some View {
        ZStack {
            if isCurrentWeek {
                Rectangle().fill(Color.accentColor.opacity(0.16))
            }
            if isInRange {
                Rectangle().fill(Color.accentColor.opacity(0.22))
            }
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

// MARK: - Right-click catcher

/// A transparent overlay that only intercepts the right mouse button — every
/// other event (left click, hover) falls through to the SwiftUI content
/// beneath it untouched, since `hitTest` only claims the point while an
/// actual right-click event is being dispatched.
private struct RightClickCatcher: NSViewRepresentable {
    let onRightClick: () -> Void

    func makeNSView(context: Context) -> PassthroughView {
        let view = PassthroughView()
        view.onRightClick = onRightClick
        return view
    }

    func updateNSView(_ nsView: PassthroughView, context: Context) {
        nsView.onRightClick = onRightClick
    }

    final class PassthroughView: NSView {
        var onRightClick: (() -> Void)?

        override func hitTest(_ point: NSPoint) -> NSView? {
            guard let event = NSApp.currentEvent,
                  event.type == .rightMouseDown || event.type == .rightMouseUp else { return nil }
            return super.hitTest(point)
        }

        override func rightMouseDown(with event: NSEvent) {
            onRightClick?()
        }
    }
}
