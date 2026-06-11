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

    @Published var showUSObservances: Bool = false {
        didSet { UserDefaults.standard.set(showUSObservances, forKey: "com.quickcal.showUSObservances") }
    }

    @Published var showUSNoveltyDays: Bool = false {
        didSet { UserDefaults.standard.set(showUSNoveltyDays, forKey: "com.quickcal.showUSNoveltyDays") }
    }

    @Published var availableVersion: String? = nil
    @Published var updateURL: URL? = nil

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
        if UserDefaults.standard.object(forKey: "com.quickcal.showUSObservances") != nil {
            showUSObservances = UserDefaults.standard.bool(forKey: "com.quickcal.showUSObservances")
        }
        if UserDefaults.standard.object(forKey: "com.quickcal.showUSNoveltyDays") != nil {
            showUSNoveltyDays = UserDefaults.standard.bool(forKey: "com.quickcal.showUSNoveltyDays")
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

    func checkForUpdates() {
        guard let url = URL(string: "https://api.github.com/repos/BrianB-22/quickcal/releases/latest") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self,
                  let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String,
                  let htmlString = json["html_url"] as? String,
                  let releaseURL = URL(string: htmlString) else { return }
            let remote = tag.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
            guard self.isNewer(remote, than: current) else { return }
            DispatchQueue.main.async {
                self.availableVersion = remote
                self.updateURL = releaseURL
            }
        }.resume()
    }

    private func isNewer(_ remote: String, than current: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let c = current.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, c.count) {
            let rv = i < r.count ? r[i] : 0
            let cv = i < c.count ? c[i] : 0
            if rv != cv { return rv > cv }
        }
        return false
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
