import AppKit

// StatusItemController owns the menu bar icon and its menu.
@MainActor
final class StatusItemController: NSObject {
    // item is the menu bar icon.
    private let item: NSStatusItem
    // openSettings opens the settings window.
    private let openSettings: () -> Void
    // updates checks for newer releases.
    private let updates: UpdateMonitor
    // updateItem checks for updates, or downloads one once a check finds it.
    private let updateItem = NSMenuItem(title: "", action: #selector(updateChosen), keyEquivalent: "")

    // init adds the icon and shows or hides it as the settings say.
    init(store: SettingsStore, updates: UpdateMonitor, openSettings: @escaping () -> Void) {
        self.openSettings = openSettings
        self.updates = updates
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        item.button?.image = EclipseGlyph.image()
        let menu = NSMenu()
        menu.autoenablesItems = false
        let settings = NSMenuItem(title: "Settings…", action: #selector(settingsChosen), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        updateItem.target = self
        menu.addItem(updateItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Fuginaut", action: #selector(NSApp.terminate), keyEquivalent: "q"))
        item.menu = menu
        item.isVisible = store.settings.showMenuIcon
        store.onChange { [weak self, weak store] in
            guard let store else {
                return
            }
            self?.item.isVisible = store.settings.showMenuIcon
        }
        refreshUpdateItem()
        updates.onChange { [weak self] in
            self?.refreshUpdateItem()
        }
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
