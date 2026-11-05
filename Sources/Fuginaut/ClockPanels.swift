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
    // openSettings opens the settings window when a clock is clicked.
    private let openSettings: () -> Void

    // init starts the clock and follows display, space, and settings changes.
    init(store: SettingsStore, openSettings: @escaping () -> Void) {
        self.store = store
        self.openSettings = openSettings
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
        for display in Display.shown(settings) {
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
        let panel = ClockPanel(onClick: openSettings)
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
    // pill draws the capsule behind the text when the backing is a pill.
    private let pill = PillView()
    // settings is the look last applied.
    private var settings = Settings()

    // init builds the panel at status bar level on every space. onClick runs when the clock is clicked.
    init(onClick: @escaping () -> Void) {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .statusBar
        isReleasedWhenClosed = false
        let content = ClickView(onClick: onClick)
        content.addSubview(pill)
        content.addSubview(label)
        contentView = content
    }

    // canBecomeKey keeps the panel from ever taking keyboard focus.
    override var canBecomeKey: Bool {
        false
    }

    // apply sets the font, color, backing, and full screen behavior from the settings.
    func apply(_ settings: Settings) {
        self.settings = settings
        label.font = ClockLook.font(settings)
        label.textColor = ClockLook.dynamicText(settings)
        if settings.backing == .shadow {
            let shadow = NSShadow()
            shadow.shadowBlurRadius = ClockLook.shadowBlur
            shadow.shadowOffset = .zero
            shadow.shadowColor = ClockLook.dynamicBacking(settings, automaticAlpha: ClockLook.shadowAlpha)
            label.shadow = shadow
        } else {
            label.shadow = nil
        }
        pill.color = ClockLook.dynamicBacking(settings, automaticAlpha: ClockLook.pillAlpha)
        pill.isHidden = settings.backing != .pill
        ignoresMouseEvents = !settings.clickOpensSettings
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
        guard let frame = Placement.frame(bar: bar, text: size, offset: settings.offset) else {
            orderOut(nil)
            return
        }
        setFrame(frame, display: false)
        let y = Placement.textY(barHeight: bar.height, textHeight: size.height)
        label.frame.origin = NSPoint(x: Placement.padding, y: y)
        pill.frame = Placement.pill(panel: CGRect(origin: .zero, size: frame.size), text: label.frame)
        orderFrontRegardless()
    }
}

// PillView fills its bounds with a capsule, resolving its color against the current appearance.
final class PillView: NSView {
    // color fills the capsule.
    var color: NSColor = .clear {
        didSet {
            needsDisplay = true
        }
    }

    // wantsUpdateLayer draws through updateLayer instead of draw.
    override var wantsUpdateLayer: Bool {
        true
    }

    // init builds a layer backed view.
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    // init is not supported, since the view is only built in code.
    required init?(coder: NSCoder) {
        nil
    }

    // updateLayer sets the capsule's color and rounding for the current appearance and size.
    override func updateLayer() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = color.cgColor
        }
        layer?.cornerRadius = bounds.height / 2
    }

    // layout keeps the rounding a capsule as the size changes.
    override func layout() {
        super.layout()
        needsDisplay = true
    }
}

// ClickView is the clock panel's content. It takes every click inside the panel, including the first one
// while another app is active, and reports it.
final class ClickView: NSView {
    // onClick runs on each click.
    private let onClick: () -> Void

    // init builds the view with the click handler.
    init(onClick: @escaping () -> Void) {
        self.onClick = onClick
        super.init(frame: .zero)
    }

    // init is not supported, since the view is only built in code.
    required init?(coder: NSCoder) {
        nil
    }

    // hitTest claims every point inside the view, so the text and pill never take the click.
    override func hitTest(_ point: NSPoint) -> NSView? {
        frame.contains(point) ? self : nil
    }

    // acceptsFirstMouse lets the first click act without first activating Fuginaut.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    // mouseUp reports the click once the button is released.
    override func mouseUp(with event: NSEvent) {
        onClick()
    }
}
