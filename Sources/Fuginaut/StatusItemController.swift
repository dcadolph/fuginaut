import AppKit

// StatusItemController owns the menu bar icon: amber while the clock is on and tinted like the bar while it is
// off. A click switches the clock, and a right-click or control-click opens the menu.
@MainActor
final class StatusItemController: NSObject {
    // item is the menu bar icon.
    private let item: NSStatusItem
    // store holds the live settings.
    private let store: SettingsStore
    // openSettings opens the settings window.
    private let openSettings: () -> Void
    // updates checks for newer releases.
    private let updates: UpdateMonitor
    // menu opens on a right-click.
    private let menu = NSMenu()
    // clockItem switches the clock from the menu.
    private let clockItem = NSMenuItem(title: "", action: #selector(toggleClock), keyEquivalent: "")
    // updateItem checks for updates, or downloads one once a check finds it.
    private let updateItem = NSMenuItem(title: "", action: #selector(updateChosen), keyEquivalent: "")
    // lit is the state the icon was last drawn in, or nil before the first draw.
    private var lit: Bool?

    // init adds the icon and keeps it in step with the settings and the update check.
    init(store: SettingsStore, updates: UpdateMonitor, openSettings: @escaping () -> Void) {
        self.store = store
        self.openSettings = openSettings
        self.updates = updates
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        item.button?.target = self
        item.button?.action = #selector(clicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        menu.autoenablesItems = false
        clockItem.target = self
        menu.addItem(clockItem)
        let settings = NSMenuItem(title: "Settings…", action: #selector(settingsChosen), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        updateItem.target = self
        menu.addItem(updateItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Fuginaut", action: #selector(NSApp.terminate), keyEquivalent: "q"))
        refresh()
        store.onChange { [weak self] in
            self?.refresh()
        }
        refreshUpdateItem()
        updates.onChange { [weak self] in
            self?.refreshUpdateItem()
        }
    }

    // refresh shows or hides the icon and draws it for the clock's state.
    private func refresh() {
        item.isVisible = store.settings.showMenuIcon
        let on = store.settings.clockEnabled
        guard on != lit else {
            return
        }
        lit = on
        item.button?.image = EclipseGlyph.image(lit: on)
        item.button?.toolTip = "Click to turn the clock \(on ? "off" : "on"). Right-click for the menu."
        clockItem.title = on ? "Turn Clock Off" : "Turn Clock On"
    }

    // refreshUpdateItem titles the update item for the latest check.
    private func refreshUpdateItem() {
        switch updates.status {
        case .available(let release):
            updateItem.title = "Download Fuginaut \(release.version)…"
            updateItem.isEnabled = true
        case .checking:
            updateItem.title = "Checking for Updates…"
            updateItem.isEnabled = false
        case .unavailable:
            updateItem.title = "Check for Updates…"
            updateItem.isEnabled = false
        case .unchecked, .upToDate, .failed:
            updateItem.title = "Check for Updates…"
            updateItem.isEnabled = true
        }
    }

    // clicked opens the menu on a right-click or control-click and switches the clock on any other click.
    @objc private func clicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            item.menu = menu
            item.button?.performClick(nil)
            item.menu = nil
        } else {
            toggleClock()
        }
    }

    // toggleClock turns the clock on or off.
    @objc private func toggleClock() {
        store.settings.clockEnabled.toggle()
    }

    // updateChosen opens an available release, or checks for one.
    @objc private func updateChosen() {
        if case .available = updates.status {
            updates.openRelease()
        } else {
            updates.checkNow()
        }
    }

    // settingsChosen opens the settings window.
    @objc private func settingsChosen() {
        openSettings()
    }
}
