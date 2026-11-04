import Foundation
import Observation

import FuginautCore

// SettingsStore persists Settings in user defaults and tells listeners when they change.
@MainActor
@Observable
final class SettingsStore {
    // settings is the live configuration. Every change is saved and announced immediately.
    var settings: Settings {
        didSet {
            guard settings != oldValue else {
                return
            }
            save()
            for listener in listeners {
                listener()
            }
        }
    }

    // listeners run after every change, in the order they were added.
    @ObservationIgnored private var listeners: [@MainActor () -> Void] = []

    // key is the user defaults key holding the encoded settings.
    private static let key = "settings"

    // init loads saved settings, or the defaults when none are saved or they fail to decode.
    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
            let saved = try? JSONDecoder().decode(Settings.self, from: data)
        {
            settings = saved
        } else {
            settings = Settings()
        }
    }

    // onChange adds a listener that runs after every change.
    func onChange(_ listener: @escaping @MainActor () -> Void) {
        listeners.append(listener)
    }

    // reset restores the defaults.
    func reset() {
        settings = Settings()
    }

    // save writes the settings to user defaults.
    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
