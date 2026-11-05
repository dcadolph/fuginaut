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
            #"{"fontDesign":"family","fontFamily":"Avenir Next","backing":"pill","style":{"dateStyle":"iso","uppercase":true}}"#,
        wantSettings: settings {
            $0.fontDesign = .family; $0.fontFamily = "Avenir Next"; $0.backing = .pill
            $0.style.dateStyle = .iso; $0.style.uppercase = true
        }
    ),
    SettingsCase(name: "bad backing", json: #"{"backing":"glow"}"#, wantSettings: nil),  // Test 7: Unknown backing.
    SettingsCase(name: "bad weight", json: #"{"weight":"heavy"}"#, wantSettings: nil),  // Test 8: Unknown weight.
    SettingsCase(name: "not json", json: "nope", wantSettings: nil),  // Test 9: Malformed.
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
        $0.style.showSeconds = true
        $0.style.secondZone = "Europe/London"
        $0.style.secondZoneLabel = "LON"
        $0.style.dateStyle = .custom
        $0.style.customPattern = "HH:mm"
        $0.style.uppercase = true
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
