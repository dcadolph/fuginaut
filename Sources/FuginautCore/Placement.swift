import CoreGraphics

// Anchor names where the clock sits along the menu bar.
public enum Anchor: String, Codable, CaseIterable, Sendable {
    case center
    case left
}

// Bar describes one display's menu bar in global screen coordinates, with the origin at the bottom left.
public struct Bar: Equatable, Sendable {
    // frame is the display's full frame.
    public var frame: CGRect
    // height is the menu bar's height, or zero when the bar is hidden.
    public var height: CGFloat
    // notch is the camera housing's frame, or nil on displays without one.
    public var notch: CGRect?

    // init builds a Bar from its parts.
    public init(frame: CGRect, height: CGFloat, notch: CGRect? = nil) {
        self.frame = frame
        self.height = height
        self.notch = notch
    }
}

// Placement computes where the clock panel and its text go.
public enum Placement {
    // padding is the space on each side of the text inside the panel.
    public static let padding: CGFloat = 8

    // frame returns the panel frame for text of the given size, or nil when the bar is hidden. The panel
    // hangs from the top of the display and grows below the bar when the text is taller than the bar. It
    // slides past the notch toward whichever side needs the shorter move and stays on the display.
    public static func frame(bar: Bar, text: CGSize, anchor: Anchor, offset: CGFloat) -> CGRect? {
        guard bar.height > 0 else {
            return nil
        }
        let width = ceil(text.width) + padding * 2
        let height = max(bar.height, ceil(text.height))
        var x: CGFloat
        switch anchor {
        case .center:
            x = bar.frame.midX - width / 2 + offset
        case .left:
            x = bar.frame.minX + offset
        }
        if let notch = bar.notch, x < notch.maxX, x + width > notch.minX {
            let right = notch.maxX - x
            let left = x + width - notch.minX
            x = right <= left ? notch.maxX : notch.minX - width
        }
        x = max(bar.frame.minX, min(x, bar.frame.maxX - width))
        return CGRect(x: x, y: bar.frame.maxY - height, width: width, height: height)
    }

    // textY returns the text's distance from the bottom of the panel. Text that fits is centered in the bar,
    // and taller text fills the panel from the bottom.
    public static func textY(barHeight: CGFloat, textHeight: CGFloat) -> CGFloat {
        max(0, (barHeight - textHeight) / 2)
    }
}
