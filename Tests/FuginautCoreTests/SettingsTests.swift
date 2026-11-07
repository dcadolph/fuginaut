import Foundation
import Testing

@testable import FuginautCore

// SettingsCase is one decoding expectation.
struct SettingsCase: Sendable, CustomTestStringConvertible {
    // Name labels the case.
    let name: String
    // JSON is the saved settings.
    let json: String
    // WantSettings is the expected result, or nil when decoding should fail.
    let wantSettings: Settings?

    // testDescription labels the case in test output.
    var testDescription: String { name }
}

// settings builds Settings by changing the defaults.
func settings(_ change: (inout Settings) -> Void) -> Settings {
    var s = Settings()
    change(&s)
    return s
}

// settingsCases covers empty, partial, out of range, nested, and malformed input.
let settingsCases: [SettingsCase] = [
    SettingsCase(name: "empty", json: "{}", wantSettings: Settings()),  // Test 0: All defaults.
    SettingsCase(  // Test 1: Partial keeps the rest default.
        name: "partial", json: #"{"offset":-40,"fontSize":20}"#,
        wantSettings: settings {
            $0.offset = -40; $0.fontSize = 20
        }
    ),
    SettingsCase(  // Test 2: Too big is clamped.
        name: "clamp high", json: #"{"fontSize":200,"offset":9000}"#,
        wantSettings: settings {
            $0.fontSize = 40; $0.offset = 600
        }
    ),
    SettingsCase(  // Test 3: Too small is clamped.
        name: "clamp low", json: #"{"fontSize":1,"offset":-9000}"#,
        wantSettings: settings {
            $0.fontSize = 9; $0.offset = -600
        }
    ),
    SettingsCase(  // Test 4: Partial nested style.
        name: "nested", json: #"{"style":{"use24Hour":true},"clickOpensSettings":false}"#,
        wantSettings: settings {
            $0.style.use24Hour = true; $0.clickOpensSettings = false
        }
    ),
    SettingsCase(  // Test 5: Color and display choices.
        name: "color", json: #"{"color":{"red":1,"green":0.5,"blue":0,"alpha":0.8},"displays":{"A":false}}"#,
        wantSettings: settings {
            $0.color = RGBA(red: 1, green: 0.5, blue: 0, alpha: 0.8); $0.displays = ["A": false]
        }
    ),
    SettingsCase(  // Test 6: Font, backing, and new style fields.
        name: "font and backing",
        json:
            #"{"fontDesign":"family","fontFamily":"Avenir Next","backing":"pill","style":{"dateStyle":"iso","textCase":"upper","prefix":"🚀"}}"#,
        wantSettings: settings {
            $0.fontDesign = .family; $0.fontFamily = "Avenir Next"; $0.backing = .pill
            $0.style.dateStyle = .iso; $0.style.textCase = .upper; $0.style.prefix = "🚀"
        }
    ),
    SettingsCase(  // Test 7: Backing color.
        name: "backing color", json: #"{"backing":"pill","backingColor":{"red":0,"green":0,"blue":1,"alpha":1}}"#,
        wantSettings: settings {
            $0.backing = .pill; $0.backingColor = RGBA(red: 0, green: 0, blue: 1)
        }
    ),
    SettingsCase(name: "bad backing", json: #"{"backing":"glow"}"#, wantSettings: nil),  // Test 8: Unknown backing.
    SettingsCase(name: "bad weight", json: #"{"weight":"heavy"}"#, wantSettings: nil),  // Test 9: Unknown weight.
    SettingsCase(name: "not json", json: "nope", wantSettings: nil),  // Test 10: Malformed.
]

// testDecode checks each saved form.
@Test(arguments: settingsCases)
func testDecode(test: SettingsCase) {
    let got = try? JSONDecoder().decode(Settings.self, from: Data(test.json.utf8))
    #expect(got == test.wantSettings)
}

// testRoundTrip checks that every field survives encoding and decoding.
@Test
func testRoundTrip() throws {
    let want = settings {
        $0.offset = -12
        $0.fontSize = 18
        $0.weight = .bold
        $0.fontDesign = .rounded
        $0.fontFamily = "Menlo"
        $0.backing = .shadow
        $0.color = RGBA(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)
        $0.backingColor = RGBA(red: 0.9, green: 0.1, blue: 0.3, alpha: 0.5)
        $0.style.showSeconds = true
        $0.style.secondZone = "Europe/London"
        $0.style.secondZoneLabel = "LON"
        $0.style.dateStyle = .custom
        $0.style.customPattern = "HH:mm"
        $0.style.textCase = .upper
        $0.displays = ["X": false, "Y": true]
        $0.showWhenBarHidden = true
        $0.showMenuIcon = false
        $0.clickOpensSettings = false
    }
    let got = try JSONDecoder().decode(Settings.self, from: JSONEncoder().encode(want))
    #expect(got == want)
}

// testRGBAClamp checks that components outside 0 to 1 are clamped.
@Test
func testRGBAClamp() {
    #expect(RGBA(red: -1, green: 2, blue: 0.5, alpha: 3) == RGBA(red: 0, green: 1, blue: 0.5, alpha: 1))
}

// LightCase is one light or dark color expectation.
struct LightCase: Sendable, CustomTestStringConvertible {
    // Name labels the case.
    let name: String
    // Color is the text color.
    let color: RGBA
    // WantLight is whether the color reads as light.
    let wantLight: Bool

    // testDescription labels the case in test output.
    var testDescription: String { name }
}

// lightCases covers the extremes and colors near the middle.
let lightCases: [LightCase] = [
    LightCase(name: "white", color: RGBA(red: 1, green: 1, blue: 1), wantLight: true),  // Test 0: White.
    LightCase(name: "black", color: RGBA(red: 0, green: 0, blue: 0), wantLight: false),  // Test 1: Black.
    LightCase(name: "yellow", color: RGBA(red: 1, green: 0.85, blue: 0), wantLight: true),  // Test 2: Yellow.
    LightCase(name: "navy", color: RGBA(red: 0, green: 0, blue: 0.5), wantLight: false),  // Test 3: Navy.
    LightCase(name: "mid gray", color: RGBA(red: 0.5, green: 0.5, blue: 0.5), wantLight: true),  // Test 4: Gray.
]

// testIsLight checks which colors call for a dark backing.
@Test(arguments: lightCases)
func testIsLight(test: LightCase) {
    #expect(test.color.isLight == test.wantLight)
}

// ShowsCase is one expectation for whether a display shows the clock.
struct ShowsCase: Sendable, CustomTestStringConvertible {
    // Name labels the case.
    let name: String
    // Displays holds the saved choices.
    let displays: [String: Bool]
    // BuiltIn is whether the display is a laptop's own screen.
    let builtIn: Bool
    // ExternalConnected is whether any external display is connected.
    let externalConnected: Bool
    // WantShows is whether the display shows the clock.
    let wantShows: Bool

    // testDescription labels the case in test output.
    var testDescription: String { name }
}

// showsCases covers the defaults for each kind of display and choices that override them.
let showsCases: [ShowsCase] = [
    ShowsCase(  // Test 0: External display shows by default.
        name: "external", displays: [:], builtIn: false, externalConnected: true, wantShows: true
    ),
    ShowsCase(  // Test 1: Laptop screen starts off beside an external display.
        name: "built-in with external", displays: [:], builtIn: true, externalConnected: true, wantShows: false
    ),
    ShowsCase(  // Test 2: Laptop screen alone shows, so a first run is never blank.
        name: "built-in alone", displays: [:], builtIn: true, externalConnected: false, wantShows: true
    ),
    ShowsCase(  // Test 3: Choosing on wins over the default.
        name: "chosen on", displays: ["D": true], builtIn: true, externalConnected: true, wantShows: true
    ),
    ShowsCase(  // Test 4: Choosing off wins over the default.
        name: "chosen off", displays: ["D": false], builtIn: false, externalConnected: true, wantShows: false
    ),
    ShowsCase(  // Test 5: Another display's choice does not apply.
        name: "other choice", displays: ["E": false], builtIn: false, externalConnected: true, wantShows: true
    ),
]

// testShows checks which displays show the clock.
@Test(arguments: showsCases)
func testShows(test: ShowsCase) {
    var s = Settings()
    s.displays = test.displays
    #expect(s.shows("D", builtIn: test.builtIn, externalConnected: test.externalConnected) == test.wantShows)
}

// HexCase is one hex parsing expectation.
struct HexCase: Sendable, CustomTestStringConvertible {
    // Name labels the case.
    let name: String
    // Hex is the text the user typed.
    let hex: String
    // WantColor is the parsed color, or nil when the text is not a color.
    let wantColor: RGBA?
    // WantHex is the color formatted back, or empty when the text is not a color.
    let wantHex: String

    // testDescription labels the case in test output.
    var testDescription: String { name }
}

// hexCases covers every accepted length, case, spacing, and malformed input.
let hexCases: [HexCase] = [
    HexCase(  // Test 0: Six digits with a hash.
        name: "rrggbb", hex: "#FF8000", wantColor: RGBA(red: 1, green: 128.0 / 255, blue: 0), wantHex: "#FF8000"
    ),
    HexCase(  // Test 1: Lowercase without a hash, padded with spaces.
        name: "lowercase bare", hex: " 0a84ff ", wantColor: RGBA(red: 10.0 / 255, green: 132.0 / 255, blue: 1),
        wantHex: "#0A84FF"
    ),
    HexCase(  // Test 2: Three digits double up.
        name: "rgb", hex: "#FA0", wantColor: RGBA(red: 1, green: 170.0 / 255, blue: 0), wantHex: "#FFAA00"
    ),
    HexCase(  // Test 3: Eight digits carry opacity.
        name: "rrggbbaa", hex: "#00000080", wantColor: RGBA(red: 0, green: 0, blue: 0, alpha: 128.0 / 255),
        wantHex: "#00000080"
    ),
    HexCase(name: "empty", hex: "", wantColor: nil, wantHex: ""),  // Test 4: Empty.
    HexCase(name: "hash only", hex: "#", wantColor: nil, wantHex: ""),  // Test 5: Hash alone.
    HexCase(name: "five digits", hex: "#12345", wantColor: nil, wantHex: ""),  // Test 6: Wrong length.
    HexCase(name: "not hex", hex: "#GGHHII", wantColor: nil, wantHex: ""),  // Test 7: Bad digits.
    HexCase(name: "two hashes", hex: "##FFFFFF", wantColor: nil, wantHex: ""),  // Test 8: Extra hash.
]

// testHex checks hex parsing and formatting.
@Test(arguments: hexCases)
func testHex(test: HexCase) {
    let got = RGBA(hex: test.hex)
    #expect(got == test.wantColor)
    #expect((got?.hex ?? "") == test.wantHex)
}

// testSwatches checks that every swatch parses and none repeats.
@Test
func testSwatches() {
    #expect(RGBA.swatches.count == RGBA.swatchHexes.count)
    #expect(Set(RGBA.swatches.map(\.hex)).count == RGBA.swatches.count)
}
