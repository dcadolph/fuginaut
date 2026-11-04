import Foundation
import Testing

@testable import FuginautCore

// moment is Wednesday, November 4, 2026 at 15:07:09 UTC.
let moment = Date(timeIntervalSince1970: 1_793_804_829)

// posix keeps month, weekday, and AM or PM names fixed across machines.
let posix = Locale(identifier: "en_US_POSIX")

// utc is the local zone for every case.
let utc = TimeZone(identifier: "UTC")!

// ClockTextCase is one clock text expectation.
struct ClockTextCase: Sendable, CustomTestStringConvertible {
    // Name labels the case.
    let name: String
    // Style is the clock style.
    let style: ClockStyle
    // WantText is the expected clock text.
    let wantText: String

    // testDescription labels the case in test output.
    var testDescription: String { name }
}

// style builds a ClockStyle by changing the defaults.
func style(_ change: (inout ClockStyle) -> Void) -> ClockStyle {
    var s = ClockStyle()
    change(&s)
    return s
}

// clockTextCases covers each style switch and the second time zone.
let clockTextCases: [ClockTextCase] = [
    ClockTextCase(name: "default", style: ClockStyle(), wantText: "Wed Nov 4  3:07 PM"), // Test 0: Defaults.
    ClockTextCase( // Test 1: 24-hour.
        name: "24-hour", style: style { $0.use24Hour = true }, wantText: "Wed Nov 4  15:07"
    ),
    ClockTextCase( // Test 2: Seconds.
        name: "seconds", style: style { $0.showSeconds = true }, wantText: "Wed Nov 4  3:07:09 PM"
    ),
    ClockTextCase( // Test 3: 24-hour with seconds.
        name: "24-hour seconds", style: style { $0.use24Hour = true; $0.showSeconds = true },
        wantText: "Wed Nov 4  15:07:09"
    ),
    ClockTextCase( // Test 4: No weekday.
        name: "no weekday", style: style { $0.showWeekday = false }, wantText: "Nov 4  3:07 PM"
    ),
    ClockTextCase( // Test 5: No date.
        name: "no date", style: style { $0.showDate = false }, wantText: "Wed  3:07 PM"
    ),
    ClockTextCase( // Test 6: Time only.
        name: "time only", style: style { $0.showWeekday = false; $0.showDate = false }, wantText: "3:07 PM"
    ),
    ClockTextCase( // Test 7: Second zone with a label.
        name: "second zone label",
        style: style { $0.showWeekday = false; $0.showDate = false; $0.secondZone = "Asia/Tokyo"
            $0.secondZoneLabel = " TYO " },
        wantText: "3:07 PM  ·  TYO 12:07 AM"
    ),
    ClockTextCase( // Test 8: Second zone with its abbreviation.
        name: "second zone abbreviation",
        style: style { $0.showWeekday = false; $0.showDate = false; $0.secondZone = "Etc/GMT-5" },
        wantText: "3:07 PM  ·  GMT+5 8:07 PM"
    ),
    ClockTextCase( // Test 9: Unknown zone is ignored.
        name: "bad zone", style: style { $0.showDate = false; $0.secondZone = "Nowhere/Land" },
        wantText: "Wed  3:07 PM"
    ),
]

// testClockText checks each style against the same moment.
@Test(arguments: clockTextCases)
func testClockText(test: ClockTextCase) {
    let got = ClockFormatter(style: test.style, locale: posix, zone: utc).string(moment)
    #expect(got == test.wantText)
}
