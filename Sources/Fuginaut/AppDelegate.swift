import AppKit
import SwiftUI

// AppDelegate starts Fuginaut and owns its long-lived objects.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // store holds the live settings.
    private let store = SettingsStore()
    // loginItem starts Fuginaut at login.
    private let loginItem = LoginItem()
    #if !FUGINAUT_STORE
        // updates checks GitHub for newer releases.
        private lazy var updates = UpdateMonitor(store: store)
    #endif
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
        #if FUGINAUT_STORE
            statusItem = StatusItemController(store: store) { [weak self] in
                self?.showSettings()
            }
        #else
            statusItem = StatusItemController(store: store, updates: updates) { [weak self] in
                self?.showSettings()
            }
            updates.start()
        #endif
    }

    // applicationShouldHandleReopen opens settings when Fuginaut is opened again, which is the way back in
    // when the menu bar icon is hidden.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    // showSettings opens the settings window and brings it to the front.
    private func showSettings() {
        if settingsWindow == nil {
            #if FUGINAUT_STORE
                let view = SettingsView(store: store, loginItem: loginItem)
            #else
                let view = SettingsView(store: store, loginItem: loginItem, updates: updates)
            #endif
            let host = NSHostingController(rootView: view)
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
