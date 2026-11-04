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
        name: "partial", json: #"{"anchor":"left","fontSize":20}"#,
        wantSettings: settings {
            $0.anchor = .left; $0.fontSize = 20
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
        name: "nested", json: #"{"style":{"use24Hour":true}}"#,
        wantSettings: settings { $0.style.use24Hour = true }
    ),
    SettingsCase(  // Test 5: Color and hidden displays.
        name: "color", json: #"{"color":{"red":1,"green":0.5,"blue":0,"alpha":0.8},"hiddenDisplays":["A"]}"#,
        wantSettings: settings {
            $0.color = RGBA(red: 1, green: 0.5, blue: 0, alpha: 0.8); $0.hiddenDisplays = ["A"]
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
    SettingsCase(name: "bad anchor", json: #"{"anchor":"up"}"#, wantSettings: nil),  // Test 8: Unknown anchor.
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
        $0.anchor = .left
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
        $0.hiddenDisplays = ["X", "Y"]
        $0.showWhenBarHidden = true
        $0.showMenuIcon = false
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
