import AppKit

import FuginautCore

// Display is one connected screen as Fuginaut sees it.
@MainActor
struct Display {
    // id is the display number, which can change when displays reconnect.
    let id: CGDirectDisplayID
    // uuid stays the same for a display across reconnects and restarts.
    let uuid: String
    // name is the display's name as macOS shows it.
    let name: String
    // builtIn reports whether the display is a laptop's own screen.
    let builtIn: Bool
    // screen is the AppKit screen for the display.
    let screen: NSScreen

    // all returns every connected display.
    static func all() -> [Display] {
        NSScreen.screens.compactMap { screen in
            let key = NSDeviceDescriptionKey("NSScreenNumber")
            guard let id = screen.deviceDescription[key] as? CGDirectDisplayID else {
                return nil
            }
            let builtIn = CGDisplayIsBuiltin(id) != 0
            return Display(id: id, uuid: uuid(id), name: screen.localizedName, builtIn: builtIn, screen: screen)
        }
    }

    // shown returns the displays that show the clock under the given settings.
    static func shown(_ settings: Settings) -> [Display] {
        let displays = all()
        let external = displays.contains { !$0.builtIn }
        return displays.filter { settings.shows($0.uuid, builtIn: $0.builtIn, externalConnected: external) }
    }

    // uuid returns the display's stable UUID string, or its number when macOS has no UUID for it.
    private static func uuid(_ id: CGDirectDisplayID) -> String {
        guard let ref = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue(),
            let text = CFUUIDCreateString(nil, ref) as String?
        else {
            return String(id)
        }
        return text
    }

    // bar describes the display's menu bar. When the bar is hidden and fallback is true, it reports the
    // height the bar has when shown, so the clock can stay up.
    func bar(fallback: Bool) -> Bar {
        let frame = screen.frame
        var height = frame.maxY - screen.visibleFrame.maxY
        if height <= 0, fallback {
            height = max(screen.safeAreaInsets.top, NSStatusBar.system.thickness)
        }
        var notch: CGRect?
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            let minX = frame.minX + left.width
            let maxX = frame.maxX - right.width
            if maxX > minX {
                notch = CGRect(x: minX, y: frame.maxY - height, width: maxX - minX, height: height)
            }
        }
        return Bar(frame: frame, height: height, notch: notch)
    }
}
