import AppKit

import FuginautCore

// ClockPanels keeps one clock panel over the menu bar of every display that shows the clock.
@MainActor
final class ClockPanels: NSObject {
    // store holds the live settings.
    private let store: SettingsStore
    // panels holds one panel per display, keyed by display number.
    private var panels: [CGDirectDisplayID: ClockPanel] = [:]
    // formatter turns the current time into clock text for the current style.
    private var formatter: ClockFormatter
    // text is the clock text currently shown.
    private var text = ""
    // timer fires on each whole second.
    private var timer: Timer?

    // init starts the clock and follows display, space, and settings changes.
    init(store: SettingsStore) {
        self.store = store
        formatter = ClockFormatter(style: store.settings.style)
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(layout), name: NSApplication.didChangeScreenParametersNotification, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(layout), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil
        )
        store.onChange { [weak self] in
            self?.settingsChanged()
        }
        startTimer()
        text = formatter.string(Date())
        layout()
    }

    // startTimer schedules a tick at the start of every second, so seconds turn over on time.
    private func startTimer() {
        let next = Date(timeIntervalSinceReferenceDate: floor(Date.timeIntervalSinceReferenceDate) + 1)
        let timer = Timer(fire: next, interval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        timer.tolerance = 0.05
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    // tick refreshes the text and lays the panels out again only when the text changed.
    private func tick() {
        let now = formatter.string(Date())
        if now != text {
            text = now
            layout()
        }
    }

    // settingsChanged rebuilds the formatter, restyles every panel, and lays them out again.
    private func settingsChanged() {
        formatter = ClockFormatter(style: store.settings.style)
        text = formatter.string(Date())
        for panel in panels.values {
            panel.apply(store.settings)
        }
        layout()
    }

    // layout places a panel over every display that shows the clock and removes the rest.
    @objc private func layout() {
        let settings = store.settings
        var seen = Set<CGDirectDisplayID>()
        for display in Display.all() where !settings.hiddenDisplays.contains(display.uuid) {
            seen.insert(display.id)
            let panel = panels[display.id] ?? makePanel(display.id)
            panel.show(text: text, bar: display.bar(fallback: settings.showWhenBarHidden), settings: settings)
        }
        for (id, panel) in panels where !seen.contains(id) {
            panel.orderOut(nil)
            panels[id] = nil
        }
    }

    // makePanel builds and records a styled panel for a display.
    private func makePanel(_ id: CGDirectDisplayID) -> ClockPanel {
        let panel = ClockPanel()
        panel.apply(store.settings)
        panels[id] = panel
        return panel
    }
}

// ClockPanel is a clear panel that ignores the mouse and holds the clock text.
@MainActor
final class ClockPanel: NSPanel {
    // label draws the clock text.
    private let label = NSTextField(labelWithString: "")

    // init builds the panel at status bar level on every space.
    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .statusBar
        isReleasedWhenClosed = false
        let content = NSView()
        content.addSubview(label)
        contentView = content
    }

    // canBecomeKey keeps the panel from ever taking keyboard focus.
    override var canBecomeKey: Bool {
        false
    }

    // apply sets the font, color, and full screen behavior from the settings.
    func apply(_ settings: Settings) {
        label.font = .monospacedDigitSystemFont(ofSize: settings.fontSize, weight: Self.weight(settings.weight))
        if let c = settings.color {
            label.textColor = NSColor(srgbRed: c.red, green: c.green, blue: c.blue, alpha: c.alpha)
        } else {
            label.textColor = .labelColor
        }
        var behavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        if settings.showWhenBarHidden {
            behavior.insert(.fullScreenAuxiliary)
        }
        collectionBehavior = behavior
    }

    // show sets the text and places the panel on the bar, or hides it when the bar is hidden.
    func show(text: String, bar: Bar, settings: Settings) {
        label.stringValue = text
        label.sizeToFit()
        let size = label.frame.size
        let anchor = settings.anchor
        guard let frame = Placement.frame(bar: bar, text: size, anchor: anchor, offset: settings.offset) else {
            orderOut(nil)
            return
        }
        setFrame(frame, display: false)
        let y = Placement.textY(barHeight: bar.height, textHeight: size.height)
        label.frame.origin = NSPoint(x: Placement.padding, y: y)
        orderFrontRegardless()
    }

    // weight maps a settings weight to a font weight.
    private static func weight(_ w: Weight) -> NSFont.Weight {
        switch w {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        }
    }
}
