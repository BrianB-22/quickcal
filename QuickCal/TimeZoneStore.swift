import Foundation
import Combine

struct ClockZone: Identifiable, Codable, Equatable {
    let id: UUID
    let identifier: String
    var label: String

    init(identifier: String, label: String) {
        self.id = UUID()
        self.identifier = identifier
        self.label = label
    }

    var timeZone: TimeZone {
        TimeZone(identifier: identifier) ?? .current
    }
}

final class TimeZoneStore: ObservableObject {
    private static let zonesKey  = "com.quickcal.clockZones"
    private static let pinnedKey = "com.quickcal.pinnedZoneId"

    @Published var zones: [ClockZone] = [] {
        didSet { save() }
    }

    @Published var pinnedZoneId: UUID? = nil {
        didSet {
            UserDefaults.standard.set(pinnedZoneId?.uuidString, forKey: Self.pinnedKey)
        }
    }

    var pinnedZone: ClockZone? {
        guard let id = pinnedZoneId else { return nil }
        return zones.first { $0.id == id }
    }

    init() {
        load()
    }

    func togglePin(_ zone: ClockZone) {
        pinnedZoneId = (zone.id == pinnedZoneId) ? nil : zone.id
    }

    func add(_ zone: ClockZone) {
        guard !zones.contains(where: { $0.identifier == zone.identifier }) else { return }
        zones.append(zone)
    }

    func remove(at offsets: IndexSet) {
        // Clear pin if the pinned zone is being removed
        for idx in offsets {
            if zones[idx].id == pinnedZoneId { pinnedZoneId = nil }
        }
        zones.remove(atOffsets: offsets)
    }

    func move(from source: IndexSet, to destination: Int) {
        zones.move(fromOffsets: source, toOffset: destination)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(zones) {
            UserDefaults.standard.set(data, forKey: Self.zonesKey)
        }
    }

    private static let defaultZones: [ClockZone] = [
        ClockZone(identifier: "America/New_York",  label: "New York"),
        ClockZone(identifier: "Europe/London",     label: "London"),
        ClockZone(identifier: "Europe/Paris",      label: "Paris"),
        ClockZone(identifier: "Asia/Singapore",     label: "Singapore"),
        ClockZone(identifier: "Asia/Kolkata",      label: "Mumbai"),
        ClockZone(identifier: "Asia/Tokyo",        label: "Tokyo"),
        ClockZone(identifier: "Australia/Sydney",  label: "Sydney"),
    ]

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Self.zonesKey),
           let saved = try? JSONDecoder().decode([ClockZone].self, from: data) {
            zones = saved
        } else if UserDefaults.standard.object(forKey: Self.zonesKey) == nil {
            // True first launch — key has never been written
            zones = Self.defaultZones
        }
        if let str = UserDefaults.standard.string(forKey: Self.pinnedKey) {
            pinnedZoneId = UUID(uuidString: str)
        }
    }

    // MARK: - Flag lookup

    static func flag(for identifier: String) -> String {
        let exact: [String: String] = [
            "Europe/London":        "🇬🇧",
            "Europe/Paris":         "🇫🇷",
            "Europe/Berlin":        "🇩🇪",
            "Europe/Warsaw":        "🇵🇱",
            "Europe/Rome":          "🇮🇹",
            "Europe/Madrid":        "🇪🇸",
            "Europe/Amsterdam":     "🇳🇱",
            "Europe/Brussels":      "🇧🇪",
            "Europe/Zurich":        "🇨🇭",
            "Europe/Stockholm":     "🇸🇪",
            "Europe/Oslo":          "🇳🇴",
            "Europe/Copenhagen":    "🇩🇰",
            "Europe/Helsinki":      "🇫🇮",
            "Europe/Athens":        "🇬🇷",
            "Europe/Lisbon":        "🇵🇹",
            "Europe/Moscow":        "🇷🇺",
            "Europe/Istanbul":      "🇹🇷",
            "Europe/Kiev":          "🇺🇦",
            "Asia/Kolkata":         "🇮🇳",
            "Asia/Tokyo":           "🇯🇵",
            "Asia/Shanghai":        "🇨🇳",
            "Asia/Singapore":       "🇸🇬",
            "Asia/Dubai":           "🇦🇪",
            "Asia/Seoul":           "🇰🇷",
            "Asia/Bangkok":         "🇹🇭",
            "Asia/Jakarta":         "🇮🇩",
            "Asia/Karachi":         "🇵🇰",
            "Asia/Dhaka":           "🇧🇩",
            "Asia/Tehran":          "🇮🇷",
            "Asia/Riyadh":          "🇸🇦",
            "Asia/Baghdad":         "🇮🇶",
            "Asia/Beirut":          "🇱🇧",
            "Asia/Jerusalem":       "🇮🇱",
            "Asia/Taipei":          "🇹🇼",
            "Asia/Kuala_Lumpur":    "🇲🇾",
            "Asia/Manila":          "🇵🇭",
            "Asia/Colombo":         "🇱🇰",
            "Asia/Kathmandu":       "🇳🇵",
            "Asia/Kabul":           "🇦🇫",
            "Australia/Sydney":     "🇦🇺",
            "Australia/Melbourne":  "🇦🇺",
            "Australia/Brisbane":   "🇦🇺",
            "Australia/Perth":      "🇦🇺",
            "Pacific/Auckland":     "🇳🇿",
            "Pacific/Honolulu":     "🇺🇸",
            "Pacific/Fiji":         "🇫🇯",
            "Pacific/Guam":         "🇬🇺",
            "America/Sao_Paulo":    "🇧🇷",
            "America/Mexico_City":  "🇲🇽",
            "America/Toronto":      "🇨🇦",
            "America/Vancouver":    "🇨🇦",
            "America/Winnipeg":     "🇨🇦",
            "America/Halifax":      "🇨🇦",
            "America/Buenos_Aires": "🇦🇷",
            "America/Santiago":     "🇨🇱",
            "America/Lima":         "🇵🇪",
            "America/Bogota":       "🇨🇴",
            "America/Caracas":      "🇻🇪",
            "Africa/Cairo":         "🇪🇬",
            "Africa/Johannesburg":  "🇿🇦",
            "Africa/Nairobi":       "🇰🇪",
            "Africa/Lagos":         "🇳🇬",
            "Africa/Casablanca":    "🇲🇦",
            "Africa/Accra":         "🇬🇭",
        ]
        if let flag = exact[identifier] { return flag }
        // Prefix fallbacks
        if identifier.hasPrefix("America/") { return "🇺🇸" }
        if identifier.hasPrefix("Europe/")  { return "🇪🇺" }
        if identifier.hasPrefix("Asia/")    { return "🌏" }
        if identifier.hasPrefix("Africa/")  { return "🌍" }
        if identifier.hasPrefix("Pacific/") { return "🌊" }
        return "🕐"
    }

    // MARK: - Suggestions

    static let suggestions: [(label: String, identifier: String)] = [
        ("London",        "Europe/London"),
        ("Paris",         "Europe/Paris"),
        ("Berlin",        "Europe/Berlin"),
        ("Dubai",         "Asia/Dubai"),
        ("Mumbai",        "Asia/Kolkata"),
        ("Kolkata",       "Asia/Kolkata"),
        ("Singapore",     "Asia/Singapore"),
        ("Tokyo",         "Asia/Tokyo"),
        ("Sydney",        "Australia/Sydney"),
        ("Auckland",      "Pacific/Auckland"),
        ("New York",      "America/New_York"),
        ("Chicago",       "America/Chicago"),
        ("Denver",        "America/Denver"),
        ("Los Angeles",   "America/Los_Angeles"),
        ("Anchorage",     "America/Anchorage"),
        ("Honolulu",      "Pacific/Honolulu"),
        ("São Paulo",     "America/Sao_Paulo"),
        ("Mexico City",   "America/Mexico_City"),
        ("Toronto",       "America/Toronto"),
        ("Vancouver",     "America/Vancouver"),
        ("Cairo",         "Africa/Cairo"),
        ("Johannesburg",  "Africa/Johannesburg"),
        ("Moscow",        "Europe/Moscow"),
        ("Seoul",         "Asia/Seoul"),
        ("Beijing",       "Asia/Shanghai"),
        ("Bangkok",       "Asia/Bangkok"),
        ("Jakarta",       "Asia/Jakarta"),
        ("Karachi",       "Asia/Karachi"),
        ("Dhaka",         "Asia/Dhaka"),
        ("Tehran",        "Asia/Tehran"),
        ("Istanbul",      "Europe/Istanbul"),
    ]
}
