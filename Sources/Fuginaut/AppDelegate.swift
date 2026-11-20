import AppKit
import SwiftUI

#if !FUGINAUT_STORE
    import FuginautCore
#endif

// AppDelegate starts Fuginaut and owns its long-lived objects.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // store holds the live settings.
    private let store = SettingsStore()
    // loginItem starts Fuginaut at login.
    private let loginItem = LoginItem()
    // clock draws the clock on every display.
    private var clock: ClockPanels?
    // statusItem is the menu bar icon that opens settings.
    private var statusItem: StatusItemController?
    // settingsWindow is created on first open and reused.
    private var settingsWindow: NSWindow?

    // applicationDidFinishLaunching draws the clock and adds the menu bar icon.
    func applicationDidFinishLaunching(_ notification: Notification) {
        loginItem.configureOnFirstLaunch()
        clock = ClockPanels(store: store) { [weak self] in
            self?.showSettings()
        }
        statusItem = StatusItemController(store: store) { [weak self] in
            self?.showSettings()
        }
        #if !FUGINAUT_STORE
            DistributedNotificationCenter.default().addObserver(
                self, selector: #selector(themeColorChanged), name: Notification.Name(ThemeColor.notificationName),
                object: nil, suspensionBehavior: .deliverImmediately
            )
        #endif
    }

    #if !FUGINAUT_STORE
        // themeColorChanged takes a theme color from a Mac-wide theme switch, or clears it on an empty message.
        // Delivery is immediate, since a menu bar app is almost never the active app.
        @objc private func themeColorChanged(_ notification: Notification) {
            store.theme = ThemeMessage(notification.object as? String ?? "").updating(store.theme)
        }
    #endif

    // applicationShouldHandleReopen opens settings when Fuginaut is opened again, which is the way back in
    // when the menu bar icon is hidden.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    // showSettings opens the settings window and brings it to the front.
    private func showSettings() {
        if settingsWindow == nil {
            let host = NSHostingController(rootView: SettingsView(store: store, loginItem: loginItem))
            let window = NSWindow(contentViewController: host)
            window.title = "Fuginaut Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        loginItem.refresh()
        NSApp.activate()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
