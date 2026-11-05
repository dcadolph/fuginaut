import AppKit
import SwiftUI

// AstronautHeader is the band atop the settings window: the hourglass astronaut centered in a field of stars.
// It keeps its space black in light and dark mode because it is artwork, not chrome.
struct AstronautHeader: View {
    // astronaut is the hourglass astronaut on black, or nil to draw only the stars.
    var astronaut: NSImage?

    // height is the band's height.
    static let height: CGFloat = 132
    // artSide is the side of the square the astronaut art is drawn into.
    static let artSide: CGFloat = 180
    // clearing is the space around the band's center kept free of stars, so none shows through the visor.
    static let clearing = CGSize(width: 124, height: 132)
    // resource is the astronaut's file name in the app bundle's Resources.
    static let resource = "Astronaut"
    // starlight is the stars' color, the astronaut's suit cream.
    static let starlight = Color(red: 0.96, green: 0.92, blue: 0.82)
    // stars is the fixed star field, so the sky is the same every time the window opens.
    static let stars = Star.field(count: 90, seed: 0x00F0_9A07)

    // bundled loads the astronaut from the app bundle.
    static func bundled() -> NSImage? {
        Bundle.main.image(forResource: resource)
    }

    // body draws the stars on black with the astronaut screened over them, so the art's black drops away.
    var body: some View {
        ZStack {
            Color.black
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                for star in Self.stars {
                    let point = CGPoint(x: star.x * size.width, y: star.y * size.height)
                    if abs(point.x - center.x) < Self.clearing.width / 2
                        && abs(point.y - center.y) < Self.clearing.height / 2
                    {
                        continue
                    }
                    let dot = CGRect(
                        x: point.x - star.radius, y: point.y - star.radius, width: star.radius * 2,
                        height: star.radius * 2
                    )
                    context.fill(Path(ellipseIn: dot), with: .color(Self.starlight.opacity(star.brightness)))
                }
            }
            if let astronaut {
                Image(nsImage: astronaut)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: Self.artSide, height: Self.artSide)
                    .blendMode(.screen)
                    .accessibilityLabel("An astronaut with an eclipse in the visor, holding an hourglass")
            }
        }
        .frame(maxWidth: .infinity, minHeight: Self.height, maxHeight: Self.height)
        .clipped()
    }
}

// Star is one point of light in the header, placed as a fraction of the band's size.
struct Star {
    // x is the horizontal position, from 0 at the left edge to 1 at the right.
    var x: CGFloat
    // y is the vertical position, from 0 at the top to 1 at the bottom.
    var y: CGFloat
    // radius is the dot's radius in points.
    var radius: CGFloat
    // brightness is the dot's opacity.
    var brightness: Double

    // field scatters count stars from a fixed seed, mostly faint pinpricks with a few brighter ones.
    static func field(count: Int, seed: UInt64) -> [Star] {
        var state = seed
        func next() -> Double {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(state >> 11) / Double(UInt64(1) << 53)
        }
        return (0..<count).map { _ in
            let bright = next() < 0.12
            return Star(
                x: next(), y: next(), radius: bright ? 1.1 + next() * 0.5 : 0.4 + next() * 0.5,
                brightness: bright ? 0.85 : 0.25 + next() * 0.45
            )
        }
    }
}
