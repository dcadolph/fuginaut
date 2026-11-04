import AppKit
import SwiftUI

import FuginautCore

// SettingsView is the settings window's content. Every change applies to the clock right away.
struct SettingsView: View {
    // store holds the live settings.
    @Bindable var store: SettingsStore
    // loginItem starts Fuginaut at login.
    var loginItem: LoginItem

    // zones lists every time zone identifier for the second time picker.
    private static let zones = TimeZone.knownTimeZoneIdentifiers.sorted()

    // body lays out the settings form.
    var body: some View {
        Form {
            position
            look
            time
            general
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }

    // position holds the anchor, offset, and display choices.
    private var position: some View {
        Section("Position") {
            Picker("Place", selection: $store.settings.anchor) {
                Text("Center").tag(Anchor.center)
                Text("Left").tag(Anchor.left)
            }
            .pickerStyle(.segmented)
            LabeledContent("Nudge") {
                HStack {
                    Slider(value: $store.settings.offset, in: Settings.offsets, step: 1)
                    Text("\(Int(store.settings.offset)) pt")
                        .monospacedDigit()
                        .frame(width: 56, alignment: .trailing)
                    Button("Reset") {
                        store.settings.offset = 0
                    }
                    .disabled(store.settings.offset == 0)
                }
            }
            ForEach(Display.all(), id: \.uuid) { display in
                Toggle(display.name, isOn: shown(display.uuid))
            }
        }
    }

    // look holds the size, weight, and color choices.
    private var look: some View {
        Section("Look") {
            LabeledContent("Size") {
                HStack {
                    Slider(value: $store.settings.fontSize, in: Settings.fontSizes, step: 1)
                    Text("\(Int(store.settings.fontSize)) pt")
                        .monospacedDigit()
                        .frame(width: 56, alignment: .trailing)
                }
            }
            Picker("Weight", selection: $store.settings.weight) {
                Text("Regular").tag(Weight.regular)
                Text("Medium").tag(Weight.medium)
                Text("Semibold").tag(Weight.semibold)
                Text("Bold").tag(Weight.bold)
            }
            Toggle("Match the menu bar's text color", isOn: matchSystem)
            if store.settings.color != nil {
                ColorPicker("Color", selection: color, supportsOpacity: true)
            }
        }
    }

    // time holds what the clock text shows.
    private var time: some View {
        Section("Time") {
            Toggle("24-hour time", isOn: $store.settings.style.use24Hour)
            Toggle("Seconds", isOn: $store.settings.style.showSeconds)
            Toggle("Weekday", isOn: $store.settings.style.showWeekday)
            Toggle("Date", isOn: $store.settings.style.showDate)
            Picker("Second time zone", selection: $store.settings.style.secondZone) {
                Text("None").tag("")
                ForEach(Self.zones, id: \.self) { zone in
                    Text(zone.replacingOccurrences(of: "_", with: " ")).tag(zone)
                }
            }
            if !store.settings.style.secondZone.isEmpty {
                TextField("Label", text: $store.settings.style.secondZoneLabel, prompt: Text("Zone abbreviation"))
            }
        }
    }

    // general holds visibility, login, and reset.
    private var general: some View {
        Section {
            Toggle("Show when the menu bar is hidden", isOn: $store.settings.showWhenBarHidden)
            Toggle("Show menu bar icon", isOn: $store.settings.showMenuIcon)
            Toggle("Open at login", isOn: openAtLogin)
            if loginItem.needsApproval {
                Text("Allow Fuginaut in System Settings, under General, then Login Items.")
                    .foregroundStyle(.secondary)
            }
            if let error = loginItem.lastError {
                Text(error)
                    .foregroundStyle(.red)
            }
            HStack {
                Button("Restore Defaults") {
                    store.reset()
                }
                Spacer()
                Button("Quit Fuginaut") {
                    NSApp.terminate(nil)
                }
            }
        } footer: {
            if !store.settings.showMenuIcon {
                Text("To get back here with the icon hidden, open Fuginaut again from Applications or Spotlight.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // shown binds a display's toggle to whether its UUID is absent from the hidden set.
    private func shown(_ uuid: String) -> Binding<Bool> {
        Binding {
            !store.settings.hiddenDisplays.contains(uuid)
        } set: { on in
            if on {
                store.settings.hiddenDisplays.remove(uuid)
            } else {
                store.settings.hiddenDisplays.insert(uuid)
            }
        }
    }

    // matchSystem binds the toggle to whether the color follows the system.
    private var matchSystem: Binding<Bool> {
        Binding {
            store.settings.color == nil
        } set: { on in
            store.settings.color = on ? nil : RGBA(red: 1, green: 1, blue: 1)
        }
    }

    // color binds the color picker to the stored sRGB color.
    private var color: Binding<Color> {
        Binding {
            let c = store.settings.color ?? RGBA(red: 1, green: 1, blue: 1)
            return Color(.sRGB, red: c.red, green: c.green, blue: c.blue, opacity: c.alpha)
        } set: { picked in
            guard let c = NSColor(picked).usingColorSpace(.sRGB) else {
                return
            }
            store.settings.color = RGBA(
                red: c.redComponent, green: c.greenComponent, blue: c.blueComponent, alpha: c.alphaComponent
            )
        }
    }

    // openAtLogin binds the toggle to the login item registration.
    private var openAtLogin: Binding<Bool> {
        Binding {
            loginItem.isEnabled || loginItem.needsApproval
        } set: { on in
            loginItem.setEnabled(on)
        }
    }
}
