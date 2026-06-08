import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var tzStore: TimeZoneStore
    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDate: Date? = nil
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            HStack(alignment: .top, spacing: 0) {
                // Left: Calendar
                CalendarView(displayedMonth: $displayedMonth, selectedDate: $selectedDate)
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
        .frame(width: 620, height: 560)
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("com.quickcal.didOpen"))) { _ in
            displayedMonth = Calendar.current.startOfMonth(for: Date())
            selectedDate   = nil
        }
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
                let today = Calendar.current.startOfMonth(for: Date())
                displayedMonth = today
                selectedDate = Calendar.current.startOfDay(for: Date())
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
