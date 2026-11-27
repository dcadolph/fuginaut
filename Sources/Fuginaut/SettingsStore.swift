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

    #if !FUGINAUT_STORE
        // theme is the theme color drawn over the user's colors, or nil to draw them as chosen. It is remembered
        // under its own key and never saved into settings, so clearing it puts back exactly what the user had.
        var theme: ThemeColor? {
            didSet {
                guard theme != oldValue else {
                    return
                }
                saveTheme()
                for listener in listeners {
                    listener()
                }
            }
        }
    #endif

    // drawn is what the clock draws: the settings with the theme color over them, when one is held.
    var drawn: Settings {
        #if FUGINAUT_STORE
            settings
        #else
            settings.drawn(with: theme)
        #endif
    }

    // listeners run after every change, in the order they were added.
    @ObservationIgnored private var listeners: [@MainActor () -> Void] = []

    // persists saves changes to user defaults. Fixture stores used for stills never save.
    @ObservationIgnored private let persists: Bool

    // key is the user defaults key holding the encoded settings.
    private static let key = "settings"
    #if !FUGINAUT_STORE
        // themeKey is the user defaults key holding the theme color's message.
        private static let themeKey = "themeColor"
    #endif

    // init loads saved settings, or the defaults when none are saved or they fail to decode.
    init() {
        persists = true
        if let data = UserDefaults.standard.data(forKey: Self.key),
            let saved = try? JSONDecoder().decode(Settings.self, from: data)
        {
            settings = saved
        } else {
            settings = Settings.fitting(.current)
        }
        #if !FUGINAUT_STORE
            theme = ThemeMessage(UserDefaults.standard.string(forKey: Self.themeKey) ?? "").updating(nil)
        #endif
    }

    // init builds a store that holds settings in memory only.
    init(fixture: Settings) {
        persists = false
        settings = fixture
    }

    // onChange adds a listener that runs after every change.
    func onChange(_ listener: @escaping @MainActor () -> Void) {
        listeners.append(listener)
    }

    // reset restores the defaults.
    func reset() {
        settings = Settings.fitting(.current)
    }

    // save writes the settings to user defaults.
    private func save() {
        guard persists else {
            return
        }
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    #if !FUGINAUT_STORE
        // saveTheme remembers the theme color across a relaunch, or forgets it once cleared.
        private func saveTheme() {
            guard persists else {
                return
            }
            if let theme {
                UserDefaults.standard.set(theme.message, forKey: Self.themeKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.themeKey)
            }
        }
    #endif
}
