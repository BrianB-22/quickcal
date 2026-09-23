import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var tzStore: TimeZoneStore
    @EnvironmentObject var calendarStore: CalendarStore
    @State private var showSettings = false
    var isDetached: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            HStack(alignment: .top, spacing: 0) {
                // Left: Calendar
                CalendarView(displayedMonth: $calendarStore.displayedMonth, selectedDate: $calendarStore.selectedDate, rangeEnd: $calendarStore.rangeEnd)
                    .frame(width: 360)
                    .environmentObject(settings)

                Divider()

                // Right: World Clock
                WorldClockView()
                    .frame(width: 240)
                    .environmentObject(settings)
                    .environmentObject(tzStore)
            }
            .frame(maxHeight: .infinity)

            // Bottom: Q&A
            QueryView().environmentObject(settings)

        }
        .frame(
            minWidth: isDetached ? 560 : 620, idealWidth: 620, maxWidth: isDetached ? .infinity : 620,
            minHeight: isDetached ? 480 : 560, idealHeight: 560, maxHeight: isDetached ? .infinity : 560
        )
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(settings)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(.tint)
                .font(.system(size: 15, weight: .medium))

            Text("QuickCal")
                .font(.system(size: 14, weight: .semibold))

            // Today shortcut
            Button("Today") {
                calendarStore.resetToToday()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(NSColor.controlBackgroundColor))
            )

            Spacer()

            // 12/24h toggle
            Toggle(isOn: $settings.use24Hour) {
                Text(settings.use24Hour ? "24h" : "12h")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .toggleStyle(.button)
            .controlSize(.small)
            .help("Toggle 12/24-hour time")

            // UTC / local offset toggle
            Toggle(isOn: $settings.showLocalOffset) {
                Text(settings.showLocalOffset ? "Local" : "UTC")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .toggleStyle(.button)
            .controlSize(.small)
            .help("Toggle UTC offset vs offset from local time")

            if !isDetached {
                Button {
                    NotificationCenter.default.post(name: .quickCalDetach, object: nil)
                } label: {
                    Image(systemName: "macwindow")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open in a Window")
            }

            Button { showSettings = true } label: {
                Image(systemName: "gear")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Calendar extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps)!
    }
}
