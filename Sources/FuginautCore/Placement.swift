import CoreGraphics

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

    // frame returns the panel frame for text of the given size, centered on the bar and moved right by
    // offset, or nil when the bar is hidden. The panel hangs from the top of the display and grows below the
    // bar when the text is taller than the bar. It slides past the notch toward whichever side needs the
    // shorter move and stays on the display.
    public static func frame(bar: Bar, text: CGSize, offset: CGFloat) -> CGRect? {
        guard bar.height > 0 else {
            return nil
        }
        let width = ceil(text.width) + padding * 2
        let height = max(bar.height, ceil(text.height))
        var x = bar.frame.midX - width / 2 + offset
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

    // pillInset is the space the pill leaves at each end of the panel.
    public static let pillInset: CGFloat = 2
    // pillOverhang is how far the pill reaches above and below the text.
    public static let pillOverhang: CGFloat = 1

    // pill returns the capsule's frame behind text inside a panel: nearly the panel's full width, a little
    // taller than the text, and never outside the panel.
    public static func pill(panel: CGRect, text: CGRect) -> CGRect {
        let minY = max(panel.minY, text.minY - pillOverhang)
        let maxY = min(panel.maxY, text.maxY + pillOverhang)
        return CGRect(
            x: panel.minX + pillInset, y: minY, width: max(0, panel.width - pillInset * 2), height: max(0, maxY - minY)
        )
    }
}
