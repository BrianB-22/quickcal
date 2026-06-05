import SwiftUI
import Carbon

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
                    VStack(alignment: .leading, spacing: 8) {
                        row(icon: "keyboard.fill", title: "Global Hotkey",
                            detail: "Open QuickCal from any app without clicking the menu bar.")
                        Picker("", selection: $settings.hotkeyMode) {
                            Text("None").tag(HotkeyMode.none)
                            Text("⌥Space").tag(HotkeyMode.optionSpace)
                            Text("Custom").tag(HotkeyMode.custom)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        if settings.hotkeyMode == .custom {
                            HotkeyRecorder(keyCode: $settings.customHotkeyKeyCode,
                                           modifiers: $settings.customHotkeyModifiers)
                        }
                    }
                    .padding(.vertical, 4)
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
        .frame(width: 380, height: 650)
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

// MARK: - HotkeyRecorder

private struct HotkeyRecorder: View {
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: toggleRecording) {
            Text(isRecording ? "Press keys…" : displayString)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(isRecording ? Color.accentColor : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .frame(minWidth: 120)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(
                            isRecording ? Color.accentColor : Color.secondary.opacity(0.35),
                            lineWidth: isRecording ? 1.5 : 1
                        )
                        .background(RoundedRectangle(cornerRadius: 5)
                            .fill(Color(NSColor.controlBackgroundColor)))
                )
        }
        .buttonStyle(.plain)
    }

    private func toggleRecording() {
        if isRecording { stopRecording(); return }
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) { self.stopRecording(); return nil }
            let mods = self.carbonMods(from: event.modifierFlags)
            guard mods != 0 else { return event }
            self.keyCode = UInt32(event.keyCode)
            self.modifiers = mods
            self.stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    private func carbonMods(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var m: UInt32 = 0
        if flags.contains(.option)  { m |= UInt32(optionKey) }
        if flags.contains(.command) { m |= UInt32(cmdKey) }
        if flags.contains(.control) { m |= UInt32(controlKey) }
        if flags.contains(.shift)   { m |= UInt32(shiftKey) }
        return m
    }

    private var displayString: String {
        guard keyCode != 0 || modifiers != 0 else { return "Click to record" }
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey)  != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey)   != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey)     != 0 { s += "⌘" }
        s += keyLabel(for: keyCode)
        return s
    }

    private func keyLabel(for code: UInt32) -> String {
        let names: [UInt32: String] = [
            UInt32(kVK_Space): "Space",   UInt32(kVK_Return): "↩",
            UInt32(kVK_Tab): "⇥",         UInt32(kVK_Delete): "⌫",
            UInt32(kVK_F1): "F1",         UInt32(kVK_F2): "F2",
            UInt32(kVK_F3): "F3",         UInt32(kVK_F4): "F4",
            UInt32(kVK_F5): "F5",         UInt32(kVK_F6): "F6",
            UInt32(kVK_F7): "F7",         UInt32(kVK_F8): "F8",
            UInt32(kVK_F9): "F9",         UInt32(kVK_F10): "F10",
            UInt32(kVK_F11): "F11",       UInt32(kVK_F12): "F12",
            UInt32(kVK_ANSI_A): "A",      UInt32(kVK_ANSI_B): "B",
            UInt32(kVK_ANSI_C): "C",      UInt32(kVK_ANSI_D): "D",
            UInt32(kVK_ANSI_E): "E",      UInt32(kVK_ANSI_F): "F",
            UInt32(kVK_ANSI_G): "G",      UInt32(kVK_ANSI_H): "H",
            UInt32(kVK_ANSI_I): "I",      UInt32(kVK_ANSI_J): "J",
            UInt32(kVK_ANSI_K): "K",      UInt32(kVK_ANSI_L): "L",
            UInt32(kVK_ANSI_M): "M",      UInt32(kVK_ANSI_N): "N",
            UInt32(kVK_ANSI_O): "O",      UInt32(kVK_ANSI_P): "P",
            UInt32(kVK_ANSI_Q): "Q",      UInt32(kVK_ANSI_R): "R",
            UInt32(kVK_ANSI_S): "S",      UInt32(kVK_ANSI_T): "T",
            UInt32(kVK_ANSI_U): "U",      UInt32(kVK_ANSI_V): "V",
            UInt32(kVK_ANSI_W): "W",      UInt32(kVK_ANSI_X): "X",
            UInt32(kVK_ANSI_Y): "Y",      UInt32(kVK_ANSI_Z): "Z",
            UInt32(kVK_ANSI_0): "0",      UInt32(kVK_ANSI_1): "1",
            UInt32(kVK_ANSI_2): "2",      UInt32(kVK_ANSI_3): "3",
            UInt32(kVK_ANSI_4): "4",      UInt32(kVK_ANSI_5): "5",
            UInt32(kVK_ANSI_6): "6",      UInt32(kVK_ANSI_7): "7",
            UInt32(kVK_ANSI_8): "8",      UInt32(kVK_ANSI_9): "9",
        ]
        return names[code] ?? "Key(\(code))"
    }
}
