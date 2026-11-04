import AppKit

// EclipseGlyph draws the menu bar icon: a bright ring around a dark disc, like a total eclipse.
enum EclipseGlyph {
    // size is the glyph's size in points, the height macOS gives a square status item image.
    static let size = NSSize(width: 18, height: 18)
    // ringOuter is the radius of the ring's outer edge, in points.
    static let ringOuter: CGFloat = 7.25
    // ringInner is the radius of the ring's inner edge, which is also the dark disc's edge.
    static let ringInner: CGFloat = 5.25
    // haloOuter is the radius where the faint halo outside the ring ends.
    static let haloOuter: CGFloat = 8.75
    // haloAlpha is the halo's opacity at the ring, fading to clear at haloOuter so it reads as glow.
    static let haloAlpha: CGFloat = 0.55

    // image returns the glyph as a template image, so macOS tints it to match the menu bar.
    static func image() -> NSImage {
        let image = NSImage(size: size, flipped: false) { rect in
            draw(in: rect)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Fuginaut"
        return image
    }

    // draw fills the halo and the ring in black, leaving the disc clear, centered in rect.
    static func draw(in rect: NSRect) {
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let glow = NSColor.black.withAlphaComponent(haloAlpha)
        NSGraphicsContext.saveGraphicsState()
        annulus(center: center, outer: haloOuter, inner: ringOuter).addClip()
        NSGradient(starting: glow, ending: .clear)?.draw(
            fromCenter: center, radius: ringOuter, toCenter: center, radius: haloOuter, options: []
        )
        NSGraphicsContext.restoreGraphicsState()
        NSColor.black.setFill()
        annulus(center: center, outer: ringOuter, inner: ringInner).fill()
    }

    // annulus returns the band between two circles around center.
    private static func annulus(center: NSPoint, outer: CGFloat, inner: CGFloat) -> NSBezierPath {
        let path = NSBezierPath(ovalIn: circle(center: center, radius: outer))
        path.append(NSBezierPath(ovalIn: circle(center: center, radius: inner)).reversed)
        path.windingRule = .evenOdd
        return path
    }

    // circle returns the square that bounds a circle.
    private static func circle(center: NSPoint, radius: CGFloat) -> NSRect {
        NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}
