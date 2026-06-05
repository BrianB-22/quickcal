import AppKit
import SwiftUI
import Combine
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!       // always square, anchors the popover
    private var clockStatusItem: NSStatusItem?  // appears only when a zone is pinned
    private var popover: NSPopover!
    let settings = SettingsStore()
    let tzStore = TimeZoneStore()
    private let hotkeyManager = HotkeyManager()
    private var cancellables = Set<AnyCancellable>()
    private var clockTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBarItem()
        setupPopover()

        hotkeyManager.onActivate = { [weak self] in self?.togglePopoverFromHotkey() }
        applyGlobalHotkey(settings.globalHotkeyEnabled)
        settings.$globalHotkeyEnabled
            .sink { [weak self] in self?.applyGlobalHotkey($0) }
            .store(in: &cancellables)

        // Use the value passed by the sink — @Published fires willSet so
        // tzStore.pinnedZoneId hasn't been written yet when the closure runs.
        tzStore.$pinnedZoneId
            .sink { [weak self] newId in self?.updateMenuBarClock(overridePinnedId: .some(newId)) }
            .store(in: &cancellables)
        tzStore.$zones
            .sink { [weak self] newZones in self?.updateMenuBarClock(zones: newZones) }
            .store(in: &cancellables)
        settings.$use24Hour
            .sink { [weak self] _ in self?.updateMenuBarClock() }
            .store(in: &cancellables)

        clockTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateMenuBarClock()
        }

        updateMenuBarClock()
    }

    // MARK: - Setup

    private func setupMenuBarItem() {
        // Icon item — always square so popover arrow always aligns correctly
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "calendar.badge.clock",
                               accessibilityDescription: "QuickCal")
        button.action = #selector(togglePopover(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 620, height: 560)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(settings)
                .environmentObject(tzStore)
        )
    }

    // MARK: - Menu bar clock

    // overridePinnedId: .some(x) = use x (may be nil for unpin); nil = read current value
    private func updateMenuBarClock(overridePinnedId: UUID?? = nil, zones: [ClockZone]? = nil) {
        let id   = overridePinnedId != nil ? overridePinnedId! : tzStore.pinnedZoneId
        let list = zones ?? tzStore.zones

        if let id, let zone = list.first(where: { $0.id == id }) {
            let f = DateFormatter()
            f.timeZone = zone.timeZone
            f.dateFormat = settings.use24Hour ? "HH:mm" : "h:mm a"
            let flag = TimeZoneStore.flag(for: zone.identifier)
            let title = "\(flag) \(f.string(from: Date()))"

            if clockStatusItem == nil {
                clockStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                clockStatusItem?.button?.action = #selector(togglePopover(_:))
                clockStatusItem?.button?.target = self
                clockStatusItem?.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
            }
            clockStatusItem?.button?.title = title
        } else {
            // Remove the clock item when nothing is pinned
            if let item = clockStatusItem {
                NSStatusBar.system.removeStatusItem(item)
                clockStatusItem = nil
            }
        }
    }

    // MARK: - Hotkey

    private func applyGlobalHotkey(_ enabled: Bool) {
        if enabled {
            hotkeyManager.register(keyCode: UInt32(kVK_Space),
                                   modifiers: UInt32(optionKey), id: 1)
        } else {
            hotkeyManager.unregister()
        }
    }

    private func togglePopoverFromHotkey() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem.button { showPopover(from: button) }
        }
    }

    // MARK: - Actions

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp { showContextMenu(); return }
        // Always anchor popover to the main icon item
        guard let button = statusItem.button else { return }
        if popover.isShown { popover.performClose(button) }
        else { showPopover(from: button) }
    }

    private func showPopover(from button: NSStatusBarButton) {
        if let popoverScreen = popover.contentViewController?.view.window?.screen,
           let buttonScreen = button.window?.screen,
           popoverScreen != buttonScreen {
            popover.performClose(nil)
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "About QuickCal", action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit QuickCal", action: #selector(quitApp), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func showAbout() { NSApp.orderFrontStandardAboutPanel(nil) }
    @objc private func quitApp()   { NSApp.terminate(nil) }
}
