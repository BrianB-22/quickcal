import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "gear")
                    .foregroundStyle(.tint)
                    .font(.title3)
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            Form {
                Section("General") {
                    Toggle(isOn: $settings.launchAtLogin) {
                        row(icon: "power", title: "Launch at Login",
                            detail: "Open QuickCal automatically when you log in.")
                    }
                    Toggle(isOn: $settings.globalHotkeyEnabled) {
                        row(icon: "keyboard.fill", title: "Global Hotkey (⌥Space)",
                            detail: "Open QuickCal from any app without clicking the menu bar.")
                    }
                }

                Section("Calendar") {
                    Toggle(isOn: $settings.showHolidays) {
                        row(icon: "calendar.badge.exclamationmark", title: "Show Holidays",
                            detail: "Highlight holidays on the calendar grid.")
                    }

                    if settings.showHolidays {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(HolidayCountry.allCases, id: \.self) { country in
                                countryRow(country)
                            }
                        }
                        .padding(.leading, 30)

                        dotLegend
                            .padding(.leading, 30)
                            .padding(.top, 6)

                        Text("Dates are best-effort. Regional and proclaimed holidays not included. Lunar/Islamic dates hardcoded through 2030.")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 30)
                            .padding(.top, 4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Toggle(isOn: $settings.weekStartsOnMonday) {
                        row(icon: "calendar", title: "Week Starts on Monday",
                            detail: "Show Monday as the first column instead of Sunday.")
                    }
                    Toggle(isOn: $settings.showWeekNumbers) {
                        row(icon: "number", title: "Show Week Numbers",
                            detail: "Display ISO week numbers in the left gutter of the calendar.")
                    }
                }

                Section("Clock") {
                    Toggle(isOn: $settings.use24Hour) {
                        row(icon: "clock", title: "24-Hour Time",
                            detail: "Display times in 24-hour (military) format.")
                    }
                    Toggle(isOn: $settings.showLocalOffset) {
                        row(icon: "arrow.left.arrow.right", title: "Show Offset from Local Time",
                            detail: "Display ±Nh instead of UTC±N next to each time zone.")
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            VStack(spacing: 3) {
                HStack(spacing: 4) {
                    Text("QuickCal v1.0")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Text("·")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Link("dejatechsolutions.com",
                         destination: URL(string: "https://dejatechsolutions.com")!)
                        .font(.system(size: 11))
                        .foregroundStyle(.tint)
                }
                Text("© \(currentYear) Dejatech Solutions. All rights reserved.")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 10)
        }
        .frame(width: 380, height: 620)
    }

    private var currentYear: String {
        "\(Calendar.current.component(.year, from: Date()))"
    }

    // MARK: - Dot legend

    private var dotLegend: some View {
        VStack(alignment: .leading, spacing: 5) {
            Divider().padding(.trailing, 30).padding(.bottom, 2)

            legendRow(dot: filledDot(.orange),      label: "National / Federal holiday")
            legendRow(dot: filledDot(.teal),         label: "Observance varies by region")
            legendRow(dot: hollowDot(.orange),       label: "Observed date (weekend shift)")
        }
    }

    private func legendRow(dot: some View, label: String) -> some View {
        HStack(spacing: 8) {
            dot
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private func filledDot(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }

    private func hollowDot(_ color: Color) -> some View {
        Circle()
            .strokeBorder(color, lineWidth: 1.5)
            .frame(width: 8, height: 8)
    }

    // MARK: - Country row

    private func countryRow(_ country: HolidayCountry) -> some View {
        let isOn = settings.enabledCountries.contains(country)
        return Button {
            if isOn { settings.enabledCountries.remove(country) }
            else     { settings.enabledCountries.insert(country) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .font(.system(size: 14))
                Text(country.flag + "  " + country.displayName)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Generic row

    private func row(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
