import CoreGraphics
import Testing

@testable import FuginautCore

// screen is a 3440 by 1440 ultrawide at the origin with a 24 point bar.
let screen = Bar(frame: CGRect(x: 0, y: 0, width: 3440, height: 1440), height: 24)

// notched is a 1512 by 982 laptop screen with a 200 point notch in the middle of a 32 point bar.
let notched = Bar(
    frame: CGRect(x: 0, y: 0, width: 1512, height: 982), height: 32,
    notch: CGRect(x: 656, y: 950, width: 200, height: 32)
)

// PlacementCase is one panel placement expectation.
struct PlacementCase: Sendable, CustomTestStringConvertible {
    // Name labels the case.
    let name: String
    // Bar is the display's menu bar.
    let bar: Bar
    // Text is the text size.
    let text: CGSize
    // Anchor is where the clock sits.
    let anchor: Anchor
    // Offset nudges the clock right.
    let offset: CGFloat
    // WantFrame is the expected panel frame, or nil when the panel should hide.
    let wantFrame: CGRect?

    // testDescription labels the case in test output.
    var testDescription: String { name }
}

// placementCases covers both anchors, nudges, edges, the notch, tall text, and a hidden bar.
let placementCases: [PlacementCase] = [
    PlacementCase( // Test 0: Centered on an ultrawide.
        name: "center", bar: screen, text: CGSize(width: 184, height: 16), anchor: .center, offset: 0,
        wantFrame: CGRect(x: 1620, y: 1416, width: 200, height: 24)
    ),
    PlacementCase( // Test 1: Left edge.
        name: "left", bar: screen, text: CGSize(width: 184, height: 16), anchor: .left, offset: 0,
        wantFrame: CGRect(x: 0, y: 1416, width: 200, height: 24)
    ),
    PlacementCase( // Test 2: Nudged right of center.
        name: "nudge right", bar: screen, text: CGSize(width: 184, height: 16), anchor: .center, offset: 100,
        wantFrame: CGRect(x: 1720, y: 1416, width: 200, height: 24)
    ),
    PlacementCase( // Test 3: Nudged left past the edge stays on screen.
        name: "clamp left", bar: screen, text: CGSize(width: 184, height: 16), anchor: .left, offset: -50,
        wantFrame: CGRect(x: 0, y: 1416, width: 200, height: 24)
    ),
    PlacementCase( // Test 4: Nudged right past the edge stays on screen.
        name: "clamp right", bar: screen, text: CGSize(width: 184, height: 16), anchor: .center, offset: 5000,
        wantFrame: CGRect(x: 3240, y: 1416, width: 200, height: 24)
    ),
    PlacementCase( // Test 5: Fractional text width rounds up.
        name: "round up", bar: screen, text: CGSize(width: 183.2, height: 15.4), anchor: .left, offset: 0,
        wantFrame: CGRect(x: 0, y: 1416, width: 200, height: 24)
    ),
    PlacementCase( // Test 6: Tall text grows the panel down from the top.
        name: "tall", bar: screen, text: CGSize(width: 384, height: 48), anchor: .left, offset: 0,
        wantFrame: CGRect(x: 0, y: 1392, width: 400, height: 48)
    ),
    PlacementCase( // Test 7: Centered under a notch moves right of it.
        name: "notch center", bar: notched, text: CGSize(width: 184, height: 16), anchor: .center, offset: 0,
        wantFrame: CGRect(x: 856, y: 950, width: 200, height: 32)
    ),
    PlacementCase( // Test 8: Overlapping the notch's left side moves left of it.
        name: "notch left", bar: notched, text: CGSize(width: 184, height: 16), anchor: .left, offset: 500,
        wantFrame: CGRect(x: 456, y: 950, width: 200, height: 32)
    ),
    PlacementCase( // Test 9: Touching the notch edge does not move.
        name: "notch edge", bar: notched, text: CGSize(width: 184, height: 16), anchor: .left, offset: 456,
        wantFrame: CGRect(x: 456, y: 950, width: 200, height: 32)
    ),
    PlacementCase( // Test 10: Hidden bar hides the panel.
        name: "hidden", bar: Bar(frame: screen.frame, height: 0), text: CGSize(width: 184, height: 16),
        anchor: .center, offset: 0, wantFrame: nil
    ),
    PlacementCase( // Test 11: Second display to the right of the first.
        name: "second display", bar: Bar(frame: CGRect(x: 3440, y: 0, width: 1920, height: 1080), height: 24),
        text: CGSize(width: 184, height: 16), anchor: .center, offset: 0,
        wantFrame: CGRect(x: 4300, y: 1056, width: 200, height: 24)
    ),
]

// testFrame checks each placement.
@Test(arguments: placementCases)
func testFrame(test: PlacementCase) {
    let got = Placement.frame(bar: test.bar, text: test.text, anchor: test.anchor, offset: test.offset)
    #expect(got == test.wantFrame)
}

// testTextY checks centering in the bar and filling a taller panel.
@Test(arguments: [
    (CGFloat(24), CGFloat(16), CGFloat(4)), // Test 0: Centered.
    (CGFloat(24), CGFloat(24), CGFloat(0)), // Test 1: Exact fit.
    (CGFloat(24), CGFloat(48), CGFloat(0)), // Test 2: Taller than the bar.
])
func testTextY(barHeight: CGFloat, textHeight: CGFloat, wantY: CGFloat) {
    let got: CGFloat = Placement.textY(barHeight: barHeight, textHeight: textHeight)
    #expect(got == wantY)
}
