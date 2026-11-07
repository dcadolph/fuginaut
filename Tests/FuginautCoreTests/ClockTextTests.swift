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
    // Date is the moment to format.
    var date = moment

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
    ClockTextCase(name: "default", style: ClockStyle(), wantText: "Wed Nov 4  3:07 PM"),  // Test 0: Defaults.
    ClockTextCase(  // Test 1: 24-hour.
        name: "24-hour", style: style { $0.use24Hour = true }, wantText: "Wed Nov 4  15:07"
    ),
    ClockTextCase(  // Test 2: Seconds.
        name: "seconds", style: style { $0.showSeconds = true }, wantText: "Wed Nov 4  3:07:09 PM"
    ),
    ClockTextCase(  // Test 3: 24-hour with seconds.
        name: "24-hour seconds",
        style: style {
            $0.use24Hour = true; $0.showSeconds = true
        },
        wantText: "Wed Nov 4  15:07:09"
    ),
    ClockTextCase(  // Test 4: No weekday.
        name: "no weekday", style: style { $0.showWeekday = false }, wantText: "Nov 4  3:07 PM"
    ),
    ClockTextCase(  // Test 5: No date.
        name: "no date", style: style { $0.showDate = false }, wantText: "Wed  3:07 PM"
    ),
    ClockTextCase(  // Test 6: Time only.
        name: "time only",
        style: style {
            $0.showWeekday = false; $0.showDate = false
        }, wantText: "3:07 PM"
    ),
    ClockTextCase(  // Test 7: Second zone with a label.
        name: "second zone label",
        style: style {
            $0.showWeekday = false; $0.showDate = false; $0.secondZone = "Asia/Tokyo"
            $0.secondZoneLabel = " TYO "
        },
        wantText: "3:07 PM  ·  TYO 12:07 AM"
    ),
    ClockTextCase(  // Test 8: Second zone with its abbreviation.
        name: "second zone abbreviation",
        style: style {
            $0.showWeekday = false; $0.showDate = false; $0.secondZone = "Etc/GMT-5"
        },
        wantText: "3:07 PM  ·  GMT+5 8:07 PM"
    ),
    ClockTextCase(  // Test 9: Unknown zone is ignored.
        name: "bad zone",
        style: style {
            $0.showDate = false; $0.secondZone = "Nowhere/Land"
        },
        wantText: "Wed  3:07 PM"
    ),
    ClockTextCase(  // Test 10: Long date.
        name: "long", style: style { $0.dateStyle = .long }, wantText: "Wednesday, November 4  3:07 PM"
    ),
    ClockTextCase(  // Test 11: Long date without the weekday.
        name: "long no weekday",
        style: style {
            $0.dateStyle = .long; $0.showWeekday = false
        },
        wantText: "November 4  3:07 PM"
    ),
    ClockTextCase(  // Test 12: Numeric date.
        name: "numeric", style: style { $0.dateStyle = .numeric }, wantText: "Wed 11/4  3:07 PM"
    ),
    ClockTextCase(  // Test 13: ISO date.
        name: "iso", style: style { $0.dateStyle = .iso }, wantText: "Wed 2026-11-04  3:07 PM"
    ),
    ClockTextCase(  // Test 14: Custom pattern ignores the other switches.
        name: "custom",
        style: style {
            $0.dateStyle = .custom; $0.customPattern = "d.M. HH:mm:ss"; $0.showWeekday = false
        },
        wantText: "4.11. 15:07:09"
    ),
    ClockTextCase(  // Test 15: Default custom pattern.
        name: "custom default", style: style { $0.dateStyle = .custom }, wantText: "Wed 4 Nov  15:07"
    ),
    ClockTextCase(  // Test 16: Blank custom pattern falls back to the short style.
        name: "custom blank",
        style: style {
            $0.dateStyle = .custom; $0.customPattern = "   "
        },
        wantText: "Wed Nov 4  3:07 PM"
    ),
    ClockTextCase(  // Test 17: Capitals.
        name: "uppercase", style: style { $0.textCase = .upper }, wantText: "WED NOV 4  3:07 PM"
    ),
    ClockTextCase(  // Test 18: Capitals cover the second time.
        name: "uppercase second zone",
        style: style {
            $0.textCase = .upper; $0.showWeekday = false; $0.showDate = false
            $0.secondZone = "Asia/Tokyo"; $0.secondZoneLabel = "tyo"
        },
        wantText: "3:07 PM  ·  TYO 12:07 AM"
    ),
    ClockTextCase(  // Test 19: Day first.
        name: "day first", style: style { $0.dateStyle = .dayFirst }, wantText: "Wed 4 Nov  3:07 PM"
    ),
    ClockTextCase(  // Test 20: Day first, long.
        name: "day first long", style: style { $0.dateStyle = .dayFirstLong },
        wantText: "Wednesday 4 November  3:07 PM"
    ),
    ClockTextCase(  // Test 21: With year.
        name: "with year", style: style { $0.dateStyle = .withYear }, wantText: "Wed Nov 4, 2026  3:07 PM"
    ),
    ClockTextCase(  // Test 22: Long with year.
        name: "long with year", style: style { $0.dateStyle = .longWithYear },
        wantText: "Wednesday, November 4, 2026  3:07 PM"
    ),
    ClockTextCase(  // Test 23: Day first with year.
        name: "day first year", style: style { $0.dateStyle = .dayFirstYear }, wantText: "Wed 4 Nov 2026  3:07 PM"
    ),
    ClockTextCase(  // Test 24: Numeric with year.
        name: "numeric year", style: style { $0.dateStyle = .numericYear }, wantText: "Wed 11/4/2026  3:07 PM"
    ),
    ClockTextCase(  // Test 25: Numeric, padded.
        name: "padded", style: style { $0.dateStyle = .padded }, wantText: "Wed 11/04  3:07 PM"
    ),
    ClockTextCase(  // Test 26: Dotted.
        name: "dotted", style: style { $0.dateStyle = .dotted }, wantText: "Wed 4.11.2026  3:07 PM"
    ),
    ClockTextCase(  // Test 27: Numeric, day first.
        name: "slashed day first", style: style { $0.dateStyle = .slashedDayFirst }, wantText: "Wed 4/11/2026  3:07 PM"
    ),
    ClockTextCase(  // Test 28: Compact ISO.
        name: "compact iso", style: style { $0.dateStyle = .compactISO }, wantText: "Wed 20261104  3:07 PM"
    ),
    ClockTextCase(  // Test 29: ISO week counts from Monday, unlike the POSIX locale.
        name: "iso week", style: style { $0.dateStyle = .isoWeek }, wantText: "Wed 2026-W45  3:07 PM"
    ),
    ClockTextCase(  // Test 30: ISO week on Sunday, November 8, which ends the week.
        name: "iso week sunday",
        style: style {
            $0.dateStyle = .isoWeek; $0.showTime = false; $0.showWeekday = false
        },
        wantText: "2026-W45", date: Date(timeIntervalSince1970: 1_794_096_000)
    ),
    ClockTextCase(  // Test 31: Day of year.
        name: "day of year", style: style { $0.dateStyle = .dayOfYear }, wantText: "Wed Day 308  3:07 PM"
    ),
    ClockTextCase(  // Test 32: Time first.
        name: "time first", style: style { $0.order = .timeFirst }, wantText: "3:07 PM  Wed Nov 4"
    ),
    ClockTextCase(  // Test 33: Date only.
        name: "date only", style: style { $0.showTime = false }, wantText: "Wed Nov 4"
    ),
    ClockTextCase(  // Test 34: Hiding everything still shows the time.
        name: "nothing",
        style: style {
            $0.showTime = false; $0.showWeekday = false; $0.showDate = false
        },
        wantText: "3:07 PM"
    ),
    ClockTextCase(  // Test 35: Dot separator.
        name: "dot", style: style { $0.separator = .dot }, wantText: "Wed Nov 4 · 3:07 PM"
    ),
    ClockTextCase(  // Test 36: Bar separator, time first.
        name: "bar time first",
        style: style {
            $0.separator = .bar; $0.order = .timeFirst
        },
        wantText: "3:07 PM | Wed Nov 4"
    ),
    ClockTextCase(  // Test 37: Comma separator.
        name: "comma", style: style { $0.separator = .comma }, wantText: "Wed Nov 4, 3:07 PM"
    ),
    ClockTextCase(  // Test 38: Slash separator.
        name: "slash", style: style { $0.separator = .slash }, wantText: "Wed Nov 4 / 3:07 PM"
    ),
    ClockTextCase(  // Test 39: Dash separator.
        name: "dash", style: style { $0.separator = .dash }, wantText: "Wed Nov 4 - 3:07 PM"
    ),
    ClockTextCase(  // Test 40: The word at.
        name: "at", style: style { $0.separator = .at }, wantText: "Wed Nov 4 at 3:07 PM"
    ),
    ClockTextCase(  // Test 41: Lowercase AM and PM, also on the second time.
        name: "lower meridiem",
        style: style {
            $0.meridiem = .lower; $0.showWeekday = false; $0.showDate = false; $0.secondZone = "Asia/Tokyo"
            $0.secondZoneLabel = "TYO"
        },
        wantText: "3:07 pm  ·  TYO 12:07 am"
    ),
    ClockTextCase(  // Test 42: Hidden AM and PM.
        name: "hidden meridiem", style: style { $0.meridiem = .hidden }, wantText: "Wed Nov 4  3:07"
    ),
    ClockTextCase(  // Test 43: Leading zero on a 12-hour time.
        name: "padded hour",
        style: style {
            $0.padHour = true; $0.showSeconds = true
        },
        wantText: "Wed Nov 4  03:07:09 PM"
    ),
    ClockTextCase(  // Test 44: 24-hour time ignores the 12-hour options.
        name: "24-hour ignores meridiem",
        style: style {
            $0.use24Hour = true; $0.meridiem = .lower; $0.padHour = true
        },
        wantText: "Wed Nov 4  15:07"
    ),
    ClockTextCase(  // Test 45: Lowercase text.
        name: "lowercase", style: style { $0.textCase = .lower }, wantText: "wed nov 4  3:07 pm"
    ),
    ClockTextCase(  // Test 46: Prefix and suffix stay as typed, trimmed, and outside the capitals.
        name: "prefix suffix",
        style: style {
            $0.prefix = " 🚀 "; $0.suffix = "Go"; $0.textCase = .upper; $0.showWeekday = false
        },
        wantText: "🚀 NOV 4  3:07 PM Go"
    ),
    ClockTextCase(  // Test 47: Prefix with a custom pattern holding emoji.
        name: "custom emoji",
        style: style {
            $0.dateStyle = .custom; $0.customPattern = "⏰ h:mm a"; $0.prefix = "Now"; $0.meridiem = .lower
        },
        wantText: "Now ⏰ 3:07 PM"
    ),
]

// testClockText checks each style against the same moment.
@Test(arguments: clockTextCases)
func testClockText(test: ClockTextCase) {
    let got = ClockFormatter(style: test.style, locale: posix, zone: utc).string(test.date)
    #expect(got == test.wantText)
}
