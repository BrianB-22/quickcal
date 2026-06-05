import SwiftUI

struct WorldClockView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var tzStore: TimeZoneStore
    @State private var showAddZone = false
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            LocalTimePanel(now: now, use24Hour: settings.use24Hour)

            Divider().padding(.vertical, 4)

            List {
                ForEach(Array(tzStore.zones.enumerated()), id: \.element.id) { idx, zone in
                    ZonePanel(
                        zone: zone,
                        now: now,
                        use24Hour: settings.use24Hour,
                        onRename: { newLabel in tzStore.zones[idx].label = newLabel },
                        onDelete: { tzStore.zones.remove(at: idx) }
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                    .listRowSeparator(.hidden)
                }
                .onMove { tzStore.move(from: $0, to: $1) }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            Divider().padding(.vertical, 4)

            Button { showAddZone = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill").foregroundStyle(.tint)
                    Text("Add Time Zone")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .onReceive(timer) { now = $0 }
        .sheet(isPresented: $showAddZone) {
            AddZoneSheet().environmentObject(tzStore)
        }
    }
}

// MARK: - Local time panel

private struct LocalTimePanel: View {
    let now: Date
    let use24Hour: Bool

    private var flag: String? {
        let f = TimeZoneStore.flag(for: TimeZone.current.identifier)
        let noFlag = ["🌏", "🌍", "🌎", "🌊", "🕐"]
        return noFlag.contains(f) ? nil : f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if let flag {
                    Text(flag)
                        .font(.system(size: 16))
                        .alignmentGuide(.firstTextBaseline) { d in d[.bottom] - 1 }
                }
                Text(timeString)
                    .font(.system(size: 26, weight: .light, design: .monospaced))
                if !use24Hour {
                    Text(ampm)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .alignmentGuide(.firstTextBaseline) { d in d[.bottom] - 2 }
                }
            }
            HStack(spacing: 4) {
                Text(localZoneName).font(.system(size: 13)).foregroundStyle(.secondary)
                Text("(Local)").font(.system(size: 12)).foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private var timeString: String {
        let f = DateFormatter(); f.dateFormat = use24Hour ? "HH:mm:ss" : "h:mm:ss"
        return f.string(from: now)
    }
    private var ampm: String {
        let f = DateFormatter(); f.dateFormat = "a"; return f.string(from: now)
    }
    private var localZoneName: String {
        TimeZone.current.localizedName(for: .generic, locale: .current) ?? TimeZone.current.identifier
    }
}

// MARK: - Zone panel

private struct ZonePanel: View {
    let zone: ClockZone
    let now: Date
    let use24Hour: Bool
    let onRename: (String) -> Void
    let onDelete: () -> Void

    @EnvironmentObject var tzStore: TimeZoneStore
    @EnvironmentObject var settings: SettingsStore
    @State private var isHovering = false
    @State private var showEdit = false
    @State private var editLabel = ""

    private var isPinned: Bool { tzStore.pinnedZoneId == zone.id }

    private var flag: String? {
        let f = TimeZoneStore.flag(for: zone.identifier)
        // Only show actual country flags — skip globe/clock fallbacks
        let noFlag = ["🌏", "🌍", "🌎", "🌊", "🕐"]
        return noFlag.contains(f) ? nil : f
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Time + label
            VStack(alignment: .leading, spacing: 2) {
                // Row 1: flag + time + AM/PM + offset
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let flag {
                        Text(flag)
                            .font(.system(size: 13))
                            .alignmentGuide(.firstTextBaseline) { d in d[.bottom] - 1 }
                    }
                    Text(timeString)
                        .font(.system(size: 18, weight: .light, design: .monospaced))
                        .lineLimit(1)
                    if !use24Hour {
                        Text(ampm)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .alignmentGuide(.firstTextBaseline) { d in d[.bottom] - 2 }
                    }
                    Spacer(minLength: 4)
                    Text(offsetLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .fixedSize()
                }
                // Row 2: city name + date — full width, city truncates if long
                HStack(spacing: 6) {
                    Text(zone.label)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(dateString)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            // Pin button — always present, accent when pinned
            Button { tzStore.togglePin(zone) } label: {
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 12))
                    .foregroundStyle(
                        isPinned
                            ? AnyShapeStyle(.tint)
                            : (isHovering ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tertiary.opacity(0.4)))
                    )
            }
            .buttonStyle(.plain)
            .padding(.leading, 6)
            .help(isPinned ? "Unpin from menu bar" : "Pin to menu bar")

            // Info button — always present, brightens on hover
            Button {
                editLabel = zone.label
                showEdit = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(isHovering ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tertiary.opacity(0.4)))
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
            .popover(isPresented: $showEdit, arrowEdge: .trailing) {
                EditZonePopover(
                    label: $editLabel,
                    identifier: zone.identifier,
                    onDone: {
                        let trimmed = editLabel.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty { onRename(trimmed) }
                        showEdit = false
                    },
                    onDelete: {
                        showEdit = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { onDelete() }
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }

    private var timeString: String {
        let f = DateFormatter(); f.timeZone = zone.timeZone
        f.dateFormat = use24Hour ? "HH:mm" : "h:mm"
        return f.string(from: now)
    }
    private var ampm: String {
        let f = DateFormatter(); f.timeZone = zone.timeZone
        f.dateFormat = "a"; return f.string(from: now)
    }
    private var dateString: String {
        let f = DateFormatter(); f.timeZone = zone.timeZone
        f.dateFormat = "EEE, MMM d"; return f.string(from: now)
    }
    private var offsetLabel: String {
        if settings.showLocalOffset {
            let diff = zone.timeZone.secondsFromGMT() - TimeZone.current.secondsFromGMT()
            let h = diff / 3600
            let m = abs(diff % 3600) / 60
            let sign = diff >= 0 ? "+" : "−"
            if diff == 0 { return "same" }
            return m == 0 ? "\(sign)\(abs(h))h" : "\(sign)\(abs(h)):\(String(format: "%02d", m))h"
        } else {
            let s = zone.timeZone.secondsFromGMT()
            let h = s / 3600; let m = abs(s % 3600) / 60
            let sign = h >= 0 ? "+" : "−"
            return m == 0 ? "\(sign)\(abs(h))" : "\(sign)\(abs(h)):\(String(format: "%02d", m))"
        }
    }
}

// MARK: - Edit zone popover

private struct EditZonePopover: View {
    @Binding var label: String
    let identifier: String
    let onDone: () -> Void
    let onDelete: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Edit Zone")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("Name", text: $label)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))
                .focused($focused)
                .onSubmit { onDone() }

            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text(identifier)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .textSelection(.enabled)
            }

            HStack {
                Button(role: .destructive) { onDelete() } label: {
                    Label("Remove", systemImage: "trash")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)

                Spacer()

                Button("Done") { onDone() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(14)
        .frame(width: 190)
        .onAppear { focused = true }
    }
}

// MARK: - Add zone sheet

struct AddZoneSheet: View {
    @EnvironmentObject var tzStore: TimeZoneStore
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    // Suggestions that match the search query
    private var matchedSuggestions: [(label: String, identifier: String)] {
        if searchText.isEmpty { return TimeZoneStore.suggestions }
        let q = searchText.lowercased()
        return TimeZoneStore.suggestions.filter {
            $0.label.lowercased().contains(q) || $0.identifier.lowercased().contains(q)
        }
    }

    // IANA identifiers that weren't in the suggestions list
    private var ianaResults: [(label: String, identifier: String)] {
        guard !searchText.isEmpty else { return [] }
        let q = searchText.lowercased()
        let suggestionIds = Set(TimeZoneStore.suggestions.map { $0.identifier })
        return TimeZone.knownTimeZoneIdentifiers
            .filter { !suggestionIds.contains($0) }
            .compactMap { id -> (label: String, identifier: String)? in
                let label = prettyLabel(for: id)
                guard label.lowercased().contains(q) || id.lowercased().contains(q) else { return nil }
                return (label: label, identifier: id)
            }
            .sorted { $0.label < $1.label }
            .prefix(40)
            .map { $0 }
    }

    private func prettyLabel(for identifier: String) -> String {
        guard let last = identifier.split(separator: "/").last else { return identifier }
        return last.replacingOccurrences(of: "_", with: " ")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "globe").foregroundStyle(.tint).font(.title3)
                Text("Add Time Zone").font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary).font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            Divider()

            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search cities or time zones…", text: $searchText).textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal, 16).padding(.vertical, 10)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    // Suggestions section
                    if !matchedSuggestions.isEmpty {
                        if !searchText.isEmpty && !ianaResults.isEmpty {
                            sectionHeader("Suggested")
                        }
                        ForEach(matchedSuggestions, id: \.identifier) { item in
                            zoneRow(item)
                            Divider().padding(.leading, 16)
                        }
                    }

                    // IANA fallthrough section
                    if !ianaResults.isEmpty {
                        sectionHeader("All Time Zones")
                        ForEach(ianaResults, id: \.identifier) { item in
                            zoneRow(item)
                            Divider().padding(.leading, 16)
                        }
                    }

                    // Empty state
                    if matchedSuggestions.isEmpty && ianaResults.isEmpty && !searchText.isEmpty {
                        Text("No results for \"\(searchText)\"")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    }
                }
            }
        }
        .frame(width: 340, height: 440)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 2)
    }

    private func zoneRow(_ item: (label: String, identifier: String)) -> some View {
        Button {
            tzStore.add(ClockZone(identifier: item.identifier, label: item.label))
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label).font(.system(size: 13)).foregroundStyle(.primary)
                    Text(item.identifier).font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                Text(currentTime(for: item.identifier))
                    .font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            tzStore.zones.contains(where: { $0.identifier == item.identifier })
            ? Color.accentColor.opacity(0.08) : Color.clear
        )
    }

    private func currentTime(for identifier: String) -> String {
        guard let tz = TimeZone(identifier: identifier) else { return "" }
        let f = DateFormatter(); f.timeZone = tz; f.dateFormat = "h:mm a"
        return f.string(from: Date())
    }
}
