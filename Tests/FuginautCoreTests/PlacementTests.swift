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
    // Offset nudges the clock right of center.
    let offset: CGFloat
    // WantFrame is the expected panel frame, or nil when the panel should hide.
    let wantFrame: CGRect?

    // testDescription labels the case in test output.
    var testDescription: String { name }
}

// placementCases covers centering, nudges, edges, the notch, tall text, and a hidden bar.
let placementCases: [PlacementCase] = [
    PlacementCase(  // Test 0: Centered on an ultrawide.
        name: "center", bar: screen, text: CGSize(width: 184, height: 16), offset: 0,
        wantFrame: CGRect(x: 1620, y: 1416, width: 200, height: 24)
    ),
    PlacementCase(  // Test 1: Nudged left of center.
        name: "nudge left", bar: screen, text: CGSize(width: 184, height: 16), offset: -100,
        wantFrame: CGRect(x: 1520, y: 1416, width: 200, height: 24)
    ),
    PlacementCase(  // Test 2: Nudged right of center.
        name: "nudge right", bar: screen, text: CGSize(width: 184, height: 16), offset: 100,
        wantFrame: CGRect(x: 1720, y: 1416, width: 200, height: 24)
    ),
    PlacementCase(  // Test 3: Nudged left past the edge stays on screen.
        name: "clamp left", bar: screen, text: CGSize(width: 184, height: 16), offset: -5000,
        wantFrame: CGRect(x: 0, y: 1416, width: 200, height: 24)
    ),
    PlacementCase(  // Test 4: Nudged right past the edge stays on screen.
        name: "clamp right", bar: screen, text: CGSize(width: 184, height: 16), offset: 5000,
        wantFrame: CGRect(x: 3240, y: 1416, width: 200, height: 24)
    ),
    PlacementCase(  // Test 5: Fractional text width rounds up.
        name: "round up", bar: screen, text: CGSize(width: 183.2, height: 15.4), offset: 0,
        wantFrame: CGRect(x: 1620, y: 1416, width: 200, height: 24)
    ),
    PlacementCase(  // Test 6: Tall text grows the panel down from the top.
        name: "tall", bar: screen, text: CGSize(width: 384, height: 48), offset: 0,
        wantFrame: CGRect(x: 1520, y: 1392, width: 400, height: 48)
    ),
    PlacementCase(  // Test 7: Centered under a notch moves right of it.
        name: "notch center", bar: notched, text: CGSize(width: 184, height: 16), offset: 0,
        wantFrame: CGRect(x: 856, y: 950, width: 200, height: 32)
    ),
    PlacementCase(  // Test 8: Overlapping the notch's left side moves left of it.
        name: "notch left", bar: notched, text: CGSize(width: 184, height: 16), offset: -156,
        wantFrame: CGRect(x: 456, y: 950, width: 200, height: 32)
    ),
    PlacementCase(  // Test 9: Touching the notch edge does not move.
        name: "notch edge", bar: notched, text: CGSize(width: 184, height: 16), offset: -200,
        wantFrame: CGRect(x: 456, y: 950, width: 200, height: 32)
    ),
    PlacementCase(  // Test 10: Hidden bar hides the panel.
        name: "hidden", bar: Bar(frame: screen.frame, height: 0), text: CGSize(width: 184, height: 16),
        offset: 0, wantFrame: nil
    ),
    PlacementCase(  // Test 11: Second display to the right of the first.
        name: "second display", bar: Bar(frame: CGRect(x: 3440, y: 0, width: 1920, height: 1080), height: 24),
        text: CGSize(width: 184, height: 16), offset: 0,
        wantFrame: CGRect(x: 4300, y: 1056, width: 200, height: 24)
    ),
]

// testFrame checks each placement.
@Test(arguments: placementCases)
func testFrame(test: PlacementCase) {
    let got = Placement.frame(bar: test.bar, text: test.text, offset: test.offset)
    #expect(got == test.wantFrame)
}

// testTextY checks centering in the bar and filling a taller panel.
@Test(arguments: [
    (CGFloat(24), CGFloat(16), CGFloat(4)),  // Test 0: Centered.
    (CGFloat(24), CGFloat(24), CGFloat(0)),  // Test 1: Exact fit.
    (CGFloat(24), CGFloat(48), CGFloat(0)),  // Test 2: Taller than the bar.
])
func testTextY(barHeight: CGFloat, textHeight: CGFloat, wantY: CGFloat) {
    let got: CGFloat = Placement.textY(barHeight: barHeight, textHeight: textHeight)
    #expect(got == wantY)
}

// testPill checks the capsule behind the text, including text that fills the panel.
@Test(arguments: [
    (  // Test 0: Text centered in the bar.
        CGRect(x: 0, y: 0, width: 200, height: 24), CGRect(x: 8, y: 4, width: 184, height: 16),
        CGRect(x: 2, y: 3, width: 196, height: 18)
    ),
    (  // Test 1: Text as tall as the panel stays inside it.
        CGRect(x: 0, y: 0, width: 200, height: 24), CGRect(x: 8, y: 0, width: 184, height: 24),
        CGRect(x: 2, y: 0, width: 196, height: 24)
    ),
    (  // Test 2: Panel narrower than the insets has no width.
        CGRect(x: 0, y: 0, width: 3, height: 24), CGRect(x: 0, y: 4, width: 0, height: 16),
        CGRect(x: 2, y: 3, width: 0, height: 18)
    ),
])
func testPill(panel: CGRect, text: CGRect, wantPill: CGRect) {
    #expect(Placement.pill(panel: panel, text: text) == wantPill)
}
