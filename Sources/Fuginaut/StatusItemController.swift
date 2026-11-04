import AppKit

// StatusItemController owns the menu bar icon and its menu.
@MainActor
final class StatusItemController: NSObject {
    // item is the menu bar icon.
    private let item: NSStatusItem
    // openSettings opens the settings window.
    private let openSettings: () -> Void

    // init adds the icon and shows or hides it as the settings say.
    init(store: SettingsStore, openSettings: @escaping () -> Void) {
        self.openSettings = openSettings
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        let image = NSImage(systemSymbolName: "hourglass", accessibilityDescription: "Fuginaut")
        image?.isTemplate = true
        item.button?.image = image
        let menu = NSMenu()
        let settings = NSMenuItem(title: "Settings…", action: #selector(settingsChosen), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
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
    }

    // settingsChosen opens the settings window.
    @objc private func settingsChosen() {
        openSettings()
    }
}
