import Foundation
import SwiftUI
import ServiceManagement

enum HotkeyMode: String {
    case none
    case optionSpace
    case custom
}

final class SettingsStore: ObservableObject {
    @Published var use24Hour: Bool = false {
        didSet { UserDefaults.standard.set(use24Hour, forKey: "com.quickcal.use24Hour") }
    }

    @Published var showHolidays: Bool = true {
        didSet { UserDefaults.standard.set(showHolidays, forKey: "com.quickcal.showHolidays") }
    }

    @Published var launchAtLogin: Bool = false {
        didSet { applyLaunchAtLogin() }
    }

    @Published var hotkeyMode: HotkeyMode = .optionSpace {
        didSet { UserDefaults.standard.set(hotkeyMode.rawValue, forKey: "com.quickcal.hotkeyMode") }
    }

    @Published var customHotkeyKeyCode: UInt32 = 0 {
        didSet { UserDefaults.standard.set(Int(customHotkeyKeyCode), forKey: "com.quickcal.customHotkeyKeyCode") }
    }

    @Published var customHotkeyModifiers: UInt32 = 0 {
        didSet { UserDefaults.standard.set(Int(customHotkeyModifiers), forKey: "com.quickcal.customHotkeyModifiers") }
    }

    @Published var weekStartsOnMonday: Bool = false {
        didSet { UserDefaults.standard.set(weekStartsOnMonday, forKey: "com.quickcal.weekStartsOnMonday") }
    }

    @Published var showWeekNumbers: Bool = false {
        didSet { UserDefaults.standard.set(showWeekNumbers, forKey: "com.quickcal.showWeekNumbers") }
    }

    @Published var showLocalOffset: Bool = true {
        didSet { UserDefaults.standard.set(showLocalOffset, forKey: "com.quickcal.showLocalOffset") }
    }

    @Published var showRotatingPlaceholder: Bool = true {
        didSet { UserDefaults.standard.set(showRotatingPlaceholder, forKey: "com.quickcal.rotatingPlaceholder") }
    }

    @Published var enabledCountries: Set<HolidayCountry> = [.us] {
        didSet {
            let raw = enabledCountries.map { $0.rawValue }.joined(separator: ",")
            UserDefaults.standard.set(raw, forKey: "com.quickcal.enabledCountries")
        }
    }

    init() {
        if UserDefaults.standard.object(forKey: "com.quickcal.use24Hour") != nil {
            use24Hour = UserDefaults.standard.bool(forKey: "com.quickcal.use24Hour")
        }
        if UserDefaults.standard.object(forKey: "com.quickcal.showHolidays") != nil {
            showHolidays = UserDefaults.standard.bool(forKey: "com.quickcal.showHolidays")
        }
        if let raw = UserDefaults.standard.string(forKey: "com.quickcal.hotkeyMode"),
           let mode = HotkeyMode(rawValue: raw) {
            hotkeyMode = mode
        } else if UserDefaults.standard.object(forKey: "com.quickcal.globalHotkey") != nil {
            hotkeyMode = UserDefaults.standard.bool(forKey: "com.quickcal.globalHotkey") ? .optionSpace : .none
        }
        if UserDefaults.standard.object(forKey: "com.quickcal.customHotkeyKeyCode") != nil {
            customHotkeyKeyCode = UInt32(UserDefaults.standard.integer(forKey: "com.quickcal.customHotkeyKeyCode"))
            customHotkeyModifiers = UInt32(UserDefaults.standard.integer(forKey: "com.quickcal.customHotkeyModifiers"))
        }
        if UserDefaults.standard.object(forKey: "com.quickcal.weekStartsOnMonday") != nil {
            weekStartsOnMonday = UserDefaults.standard.bool(forKey: "com.quickcal.weekStartsOnMonday")
        }
        if UserDefaults.standard.object(forKey: "com.quickcal.showWeekNumbers") != nil {
            showWeekNumbers = UserDefaults.standard.bool(forKey: "com.quickcal.showWeekNumbers")
        }
        if UserDefaults.standard.object(forKey: "com.quickcal.showLocalOffset") != nil {
            showLocalOffset = UserDefaults.standard.bool(forKey: "com.quickcal.showLocalOffset")
        }
        if UserDefaults.standard.object(forKey: "com.quickcal.rotatingPlaceholder") != nil {
            showRotatingPlaceholder = UserDefaults.standard.bool(forKey: "com.quickcal.rotatingPlaceholder")
        }
        if let raw = UserDefaults.standard.string(forKey: "com.quickcal.enabledCountries") {
            let parsed = raw.split(separator: ",").compactMap { HolidayCountry(rawValue: String($0)) }
            if !parsed.isEmpty { enabledCountries = Set(parsed) }
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func applyLaunchAtLogin() {
        do {
            if launchAtLogin { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            print("Launch at login error: \(error)")
        }
    }
}
