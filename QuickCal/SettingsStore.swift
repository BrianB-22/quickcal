import Foundation
import SwiftUI
import ServiceManagement

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

    @Published var globalHotkeyEnabled: Bool = true {
        didSet { UserDefaults.standard.set(globalHotkeyEnabled, forKey: "com.quickcal.globalHotkey") }
    }

    @Published var weekStartsOnMonday: Bool = false {
        didSet { UserDefaults.standard.set(weekStartsOnMonday, forKey: "com.quickcal.weekStartsOnMonday") }
    }

    @Published var showWeekNumbers: Bool = false {
        didSet { UserDefaults.standard.set(showWeekNumbers, forKey: "com.quickcal.showWeekNumbers") }
    }

    @Published var showLocalOffset: Bool = false {
        didSet { UserDefaults.standard.set(showLocalOffset, forKey: "com.quickcal.showLocalOffset") }
    }

    @Published var enabledCountries: Set<HolidayCountry> = [.us, .uk, .france, .singapore, .india, .japan, .australia] {
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
        if UserDefaults.standard.object(forKey: "com.quickcal.globalHotkey") != nil {
            globalHotkeyEnabled = UserDefaults.standard.bool(forKey: "com.quickcal.globalHotkey")
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
