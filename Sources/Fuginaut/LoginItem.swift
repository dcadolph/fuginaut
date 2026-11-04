import Foundation
import Observation
import ServiceManagement

// LoginItem registers Fuginaut to start at login and reports the system's view of that registration.
@MainActor
@Observable
final class LoginItem {
    // status is the registration state last read from the system.
    private(set) var status: SMAppService.Status
    // lastError describes the most recent failed change, or nil after a success.
    private(set) var lastError: String?

    // service is the login item for the app bundle itself.
    @ObservationIgnored private let service = SMAppService.mainApp
    // configuredKey is the user defaults key set once the first-launch registration has run.
    private static let configuredKey = "loginItemConfigured"

    // init reads the current status.
    init() {
        status = service.status
    }

    // isEnabled reports whether Fuginaut will start at login.
    var isEnabled: Bool {
        status == .enabled
    }

    // needsApproval reports whether the user must allow the login item in System Settings.
    var needsApproval: Bool {
        status == .requiresApproval
    }

    // configureOnFirstLaunch turns launch at login on the first time the app runs from Applications. Builds
    // run from anywhere else are never registered, and later launches leave the user's choice alone.
    func configureOnFirstLaunch() {
        let defaults = UserDefaults.standard
        let installed = Bundle.main.bundleURL.path.hasPrefix("/Applications/")
        if installed, !defaults.bool(forKey: Self.configuredKey) {
            setEnabled(true)
            defaults.set(true, forKey: Self.configuredKey)
        }
        refresh()
    }

    // setEnabled registers or unregisters the login item.
    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }

    // refresh rereads the status from the system.
    func refresh() {
        status = service.status
    }
}
