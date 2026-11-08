import AppKit
import Observation

import FuginautCore

// UpdateStatus is where the last update check stands.
enum UpdateStatus: Equatable {
    // unchecked is no check run yet this launch.
    case unchecked
    // unavailable is a build without a release version, which never checks.
    case unavailable
    // checking is a check under way.
    case checking
    // upToDate is a check at the given time that found nothing newer.
    case upToDate(Date)
    // available is a newer release.
    case available(Release)
    // failed is a check that could not reach or read GitHub, with the reason.
    case failed(String)
}

// UpdateMonitor checks GitHub for a newer release on a schedule and on request, and announces each new
// release once.
@MainActor
@Observable
final class UpdateMonitor {
    // status is where the last check stands.
    private(set) var status: UpdateStatus

    // current is the running version, or nil for a development build.
    @ObservationIgnored let current: ReleaseVersion?
    // store holds the check updates switch.
    @ObservationIgnored private let store: SettingsStore
    // fetcher sends the release request.
    @ObservationIgnored private let fetcher: any Fetcher
    // launched is when the monitor was made, which delays the first check.
    @ObservationIgnored private let launched = Date()
    // lastChecked is when the last automatic or manual check finished.
    @ObservationIgnored private var lastChecked: Date?
    // timer looks for a due check once a minute.
    @ObservationIgnored private var timer: Timer?
    // listeners run after every status change.
    @ObservationIgnored private var listeners: [@MainActor () -> Void] = []

    // announcedKey is the user defaults key holding the last version announced in an alert.
    private static let announcedKey = "announcedVersion"
    // brewCommand upgrades a Homebrew install.
    static let brewCommand = "brew upgrade --cask fuginaut"

    // init builds a monitor for the running bundle's version.
    init(store: SettingsStore, version: String = SettingsView.version, fetcher: any Fetcher = URLSessionFetcher()) {
        self.store = store
        self.fetcher = fetcher
        current = ReleaseVersion(version)
        status = current == nil ? .unavailable : .unchecked
    }

    // init builds a monitor that holds status and never checks, for stills.
    init(fixture status: UpdateStatus, store: SettingsStore) {
        self.store = store
        fetcher = FetcherFunc { _ in (Data(), 0) }
        current = ReleaseVersion("0.0.0")
        self.status = status
    }

    // start begins the automatic checks.
    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
    }

    // onChange adds a listener that runs after every status change.
    func onChange(_ listener: @escaping @MainActor () -> Void) {
        listeners.append(listener)
    }

    // tick runs an automatic check when one is on and due, and announces a release not announced before.
    func tick() {
        guard store.settings.checkUpdates, status != .checking,
            UpdateSchedule.isDue(lastChecked: lastChecked, launched: launched, now: Date())
        else {
            return
        }
        Task {
            if case .available(let release) = await check(), Self.announced != release.version.description {
                Self.announced = release.version.description
                announce(release)
            }
        }
    }

    // checkNow runs a check on request and reports the result in an alert.
    func checkNow() {
        Task {
            let result = await check()
            switch result {
            case .available(let release):
                Self.announced = release.version.description
                announce(release)
            case .upToDate:
                alert("Fuginaut is up to date.", "Version \(current?.description ?? "") is the newest release.")
            case .failed(let reason):
                alert("Couldn't check for updates.", reason)
            case .unchecked, .unavailable, .checking:
                break
            }
        }
    }

    // check asks GitHub for a newer release and records the result.
    @discardableResult
    func check() async -> UpdateStatus {
        guard let current, status != .checking else {
            return status
        }
        set(.checking)
        let checker = UpdateChecker(fetcher: fetcher, current: current)
        let next: UpdateStatus
        do {
            next = try await checker.check().map { .available($0) } ?? .upToDate(Date())
        } catch UpdateError.server(let code) {
            next = .failed("GitHub answered with status \(code). Try again later.")
        } catch UpdateError.decode {
            next = .failed("GitHub sent a response Fuginaut couldn't read.")
        } catch {
            next = .failed(error.localizedDescription)
        }
        lastChecked = Date()
        set(next)
        return next
    }

    // openRelease opens the release page of an available update.
    func openRelease() {
        guard case .available(let release) = status else {
            return
        }
        NSWorkspace.shared.open(release.page)
    }

    // announce tells the user about a newer release and offers its page.
    private func announce(_ release: Release) {
        let alert = NSAlert()
        alert.messageText = "Fuginaut \(release.version) is available."
        alert.informativeText =
            "You have \(current?.description ?? "an older version"). Download it from GitHub, or run "
            + "\(Self.brewCommand) in Terminal."
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")
        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(release.page)
        }
    }

    // alert shows a message with an OK button.
    private func alert(_ message: String, _ detail: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        NSApp.activate()
        alert.runModal()
    }

    // set moves to status and tells listeners.
    private func set(_ next: UpdateStatus) {
        status = next
        for listener in listeners {
            listener()
        }
    }

    // announced is the last version announced in an alert, so each release is announced once.
    private static var announced: String? {
        get { UserDefaults.standard.string(forKey: announcedKey) }
        set { UserDefaults.standard.set(newValue, forKey: announcedKey) }
    }
}
