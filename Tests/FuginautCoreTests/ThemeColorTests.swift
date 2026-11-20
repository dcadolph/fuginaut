import Testing

@testable import FuginautCore

// ThemeMessageCase is one theme message expectation.
struct ThemeMessageCase: Sendable, CustomTestStringConvertible {
    // Name labels the case.
    let name: String
    // Message is the notification's object string.
    let message: String
    // WantMessage is what the message should ask for.
    let wantMessage: ThemeMessage

    // testDescription labels the case in test output.
    var testDescription: String { name }
}

// purple is a theme text color.
let purple = RGBA(red: 167.0 / 255, green: 123.0 / 255, blue: 230.0 / 255)
// black is a theme backing color.
let black = RGBA(red: 0, green: 0, blue: 0)

// themeMessageCases covers text only, text and backing, clear, and junk.
let themeMessageCases: [ThemeMessageCase] = [
    ThemeMessageCase(name: "text", message: "#A77BE6", wantMessage: .set(ThemeColor(text: purple))),  // Test 0.
    ThemeMessageCase(  // Test 1: Text and backing.
        name: "text and backing", message: "#a77be6 #000000",
        wantMessage: .set(ThemeColor(text: purple, backing: black))
    ),
    ThemeMessageCase(name: "empty", message: "", wantMessage: .clear),  // Test 2: Empty clears.
    ThemeMessageCase(name: "blank", message: "  ", wantMessage: .clear),  // Test 3: Blank clears.
    ThemeMessageCase(name: "word", message: "purple", wantMessage: .junk),  // Test 4: Not a color.
    ThemeMessageCase(name: "no hash", message: "A77BE6", wantMessage: .junk),  // Test 5: Missing #.
    ThemeMessageCase(name: "short", message: "#FFF", wantMessage: .junk),  // Test 6: Short form.
    ThemeMessageCase(name: "alpha", message: "#A77BE6FF", wantMessage: .junk),  // Test 7: Alpha form.
    ThemeMessageCase(name: "bad digit", message: "#A77BEG", wantMessage: .junk),  // Test 8: Not hex.
    ThemeMessageCase(name: "bad backing", message: "#A77BE6 black", wantMessage: .junk),  // Test 9.
    ThemeMessageCase(name: "three", message: "#A77BE6 #000000 #FFFFFF", wantMessage: .junk),  // Test 10.
]

// testThemeMessage checks each message form.
@Test(arguments: themeMessageCases)
func testThemeMessage(test: ThemeMessageCase) {
    #expect(ThemeMessage(test.message) == test.wantMessage)
}

// testThemeMessageRoundTrip checks that a theme color reads back from its own message.
@Test(arguments: [ThemeColor(text: purple), ThemeColor(text: purple, backing: black)])
func testThemeMessageRoundTrip(color: ThemeColor) {
    #expect(ThemeMessage(color.message) == .set(color))
}

// own is the user's settings: a red shadow over white text.
let own = settings {
    $0.color = RGBA(red: 1, green: 1, blue: 1)
    $0.backing = .shadow
    $0.backingColor = RGBA(red: 1, green: 0, blue: 0)
}

// testThemeTextOnly checks that a text color draws over the user's text and keeps the user's backing.
@Test
func testThemeTextOnly() {
    let saved = own
    let drawn = ThemeColor(text: purple).applied(to: saved)
    #expect(drawn.color == purple)
    #expect(drawn.backing == .shadow)
    #expect(drawn.backingColor == RGBA(red: 1, green: 0, blue: 0))
    #expect(saved == own)
}

// testThemeBacking checks that a backing color draws as a pill over the user's own backing.
@Test
func testThemeBacking() {
    let saved = own
    let drawn = ThemeColor(text: purple, backing: black).applied(to: saved)
    #expect(drawn.color == purple)
    #expect(drawn.backing == .pill)
    #expect(drawn.backingColor == black)
    #expect(saved == own)
}

// testThemeKeepsTheRest checks that a theme changes nothing but the colors and the backing style.
@Test
func testThemeKeepsTheRest() {
    var drawn = ThemeColor(text: purple, backing: black).applied(to: own)
    drawn.color = own.color
    drawn.backing = own.backing
    drawn.backingColor = own.backingColor
    #expect(drawn == own)
}

// testThemeClear checks that a cleared theme draws the user's own colors exactly, and junk keeps the theme.
@Test
func testThemeClear() {
    var theme = ThemeMessage("#A77BE6 #000000").updating(nil)
    #expect(own.drawn(with: theme) == ThemeColor(text: purple, backing: black).applied(to: own))
    theme = ThemeMessage("nonsense").updating(theme)
    #expect(theme == ThemeColor(text: purple, backing: black))
    theme = ThemeMessage("").updating(theme)
    #expect(theme == nil)
    #expect(own.drawn(with: theme) == own)
}
