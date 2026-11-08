import Foundation
import Testing

@testable import FuginautCore

// worldDate is Wed Nov 4 2026, 21:07 UTC.
let worldDate = Date(timeIntervalSince1970: 1_793_826_420)

// worldText formats the date in UTC from an English base after changing the style.
func worldText(_ change: (inout ClockStyle) -> Void) -> String {
    var style = ClockStyle()
    change(&style)
    return ClockFormatter(style: style, locale: Locale(identifier: "en_US"), zone: TimeZone(identifier: "UTC")!)
        .string(worldDate)
}

// timeOnly shows a fixed time with no date.
func timeOnly(_ style: inout ClockStyle) {
    style.dateStyle = .custom
    style.customPattern = "h:mm"
}

// WorldCase is one clock text expectation.
struct WorldCase: Sendable, CustomTestStringConvertible {
    // name labels the case.
    let name: String
    // style is the style under test.
    let style: @Sendable (inout ClockStyle) -> Void
    // wantText is the expected clock text.
    let wantText: String

    // testDescription labels the case in test output.
    var testDescription: String { name }
}

// dateOnly shows the date with its year and nothing else.
func dateOnly(_ style: inout ClockStyle, _ dateStyle: DateStyle = .withYear) {
    style.dateStyle = dateStyle
    style.showWeekday = false
    style.showTime = false
}

// worldCases covers numerals, calendars, languages, ISO dates, and their mix.
let worldCases: [WorldCase] = [
    WorldCase(name: "default", style: { timeOnly(&$0) }, wantText: "9:07"),  // Test 0.
    WorldCase(  // Test 1: Devanagari digits.
        name: "devanagari",
        style: {
            timeOnly(&$0)
            $0.numerals = .devanagari
        }, wantText: "९:०७"),
    WorldCase(  // Test 2: Arabic-Indic digits.
        name: "arabic-indic",
        style: {
            timeOnly(&$0)
            $0.numerals = .arabicIndic
        }, wantText: "٩:٠٧"),
    WorldCase(  // Test 3: Tamil keeps its zero.
        name: "tamil",
        style: {
            timeOnly(&$0)
            $0.numerals = .tamil
        }, wantText: "௯:௦௭"),
    WorldCase(  // Test 4: Numerals also write the second time.
        name: "second zone digits",
        style: {
            timeOnly(&$0)
            $0.numerals = .thai
            $0.secondZone = "Asia/Tokyo"
            $0.secondZoneLabel = "TYO"
            $0.showSeconds = false
            $0.use24Hour = true
        }, wantText: "๙:๐๗  ·  TYO ๐๖:๐๗"),
    WorldCase(  // Test 5: Hebrew calendar.
        name: "hebrew",
        style: {
            dateOnly(&$0)
            $0.calendar = .hebrew
        }, wantText: "Heshvan 24, 5787"),
    WorldCase(  // Test 6: Saudi Hijri calendar.
        name: "umm al-qura",
        style: {
            dateOnly(&$0)
            $0.calendar = .islamicUmmAlQura
        }, wantText: "Jmd. I 24, 1448"),
    WorldCase(  // Test 7: Japanese years read by era, never 0008.
        name: "japanese era",
        style: {
            dateOnly(&$0)
            $0.calendar = .japanese
        }, wantText: "Nov 4, Reiwa 8"),
    WorldCase(  // Test 8: Chinese years read by cycle, never 0043.
        name: "chinese cycle",
        style: {
            dateOnly(&$0)
            $0.calendar = .chinese
        }, wantText: "Mo9 26, bing-wu"),
    WorldCase(  // Test 9: ISO stays Gregorian on another calendar.
        name: "iso gregorian",
        style: {
            dateOnly(&$0, .iso)
            $0.calendar = .buddhist
        }, wantText: "2026-11-04"),
    WorldCase(  // Test 10: Compact ISO stays Gregorian.
        name: "compact iso gregorian",
        style: {
            dateOnly(&$0, .compactISO)
            $0.calendar = .hebrew
        }, wantText: "20261104"),
    WorldCase(  // Test 11: ISO stays Gregorian but takes the chosen digits.
        name: "iso digits",
        style: {
            dateOnly(&$0, .iso)
            $0.calendar = .persian
            $0.numerals = .persian
        }, wantText: "۲۰۲۶-۱۱-۰۴"),
    WorldCase(  // Test 12: Language writes the month.
        name: "spanish",
        style: {
            $0.dateStyle = .dayFirst
            $0.showWeekday = false
            $0.showTime = false
            $0.language = "es"
        }, wantText: "4 nov"),
    WorldCase(  // Test 13: Numeric date order follows the language.
        name: "british order",
        style: {
            dateOnly(&$0, .numericYear)
            $0.language = "en-GB"
        }, wantText: "04/11/2026"),
    WorldCase(  // Test 14: Language, numerals, and calendar mix.
        name: "mix",
        style: {
            dateOnly(&$0)
            $0.language = "hi"
            $0.numerals = .devanagari
            $0.calendar = .indian
        }, wantText: "१३ कार्तिक १९४८ शक"),
    WorldCase(  // Test 15: Japanese writes its own date and time order.
        name: "japanese order",
        style: {
            $0.dateStyle = .withYear
            $0.language = "ja"
            $0.calendar = .japanese
        }, wantText: "令和8年11月4日(水)  午後9:07"),
    WorldCase(  // Test 16: Arabic writes its own date order with its own commas.
        name: "arabic order",
        style: {
            dateOnly(&$0)
            $0.language = "ar"
            $0.numerals = .arabicIndic
            $0.calendar = .islamicUmmAlQura
        }, wantText: "٢٤ جمادى الأولى، ١٤٤٨ هـ"),
    WorldCase(  // Test 17: Korean puts the year first and AM or PM before the time.
        name: "korean order",
        style: {
            $0.dateStyle = .withYear
            $0.showWeekday = false
            $0.language = "ko"
        }, wantText: "2026년 11월 4일  오후 9:07"),
    WorldCase(  // Test 18: A long style spells the weekday in native order.
        name: "french long",
        style: {
            $0.dateStyle = .longWithYear
            $0.showTime = false
            $0.language = "fr"
        }, wantText: "mercredi 4 novembre 2026"),
    WorldCase(  // Test 19: A weekday alone is still written.
        name: "weekday only",
        style: {
            $0.showDate = false
            $0.showTime = false
            $0.language = "fr"
        }, wantText: "mer."),
    WorldCase(  // Test 20: A style that hides the day still shows the time.
        name: "time only native",
        style: {
            $0.showWeekday = false
            $0.showDate = false
            $0.language = "ja"
        }, wantText: "午後9:07"),
    WorldCase(  // Test 21: The second time takes the same native order.
        name: "second zone native",
        style: {
            $0.showWeekday = false
            $0.showDate = false
            $0.language = "ja"
            $0.secondZone = "Asia/Tokyo"
            $0.secondZoneLabel = "東京"
        }, wantText: "午後9:07  ·  東京 午前6:07"),
    WorldCase(  // Test 22: Native order keeps seconds and the leading zero.
        name: "native seconds and zero",
        style: {
            $0.showWeekday = false
            $0.showDate = false
            $0.showSeconds = true
            $0.padHour = true
            $0.language = "ko"
        }, wantText: "오후 09:07:00"),
    WorldCase(  // Test 23: The leading zero reaches a Japanese hour.
        name: "japanese zero",
        style: {
            $0.showWeekday = false
            $0.showDate = false
            $0.padHour = true
            $0.language = "ja"
        }, wantText: "午後09:07"),
    WorldCase(  // Test 24: Hiding AM and PM stays plain in any language.
        name: "native hidden meridiem",
        style: {
            $0.showWeekday = false
            $0.showDate = false
            $0.meridiem = .hidden
            $0.language = "ja"
        }, wantText: "9:07"),
    WorldCase(  // Test 25: A 24-hour clock stays plain in any language.
        name: "native 24 hour",
        style: {
            $0.showWeekday = false
            $0.showDate = false
            $0.use24Hour = true
            $0.language = "ja"
        }, wantText: "21:07"),
    WorldCase(  // Test 26: ISO keeps its shape in any language.
        name: "native iso",
        style: {
            dateOnly(&$0, .iso)
            $0.language = "ja"
        }, wantText: "2026-11-04"),
    WorldCase(  // Test 27: British English keeps the style as written.
        name: "british short",
        style: {
            $0.showWeekday = false
            $0.showTime = false
            $0.language = "en-GB"
        }, wantText: "Nov 4"),
]

// testWorldText checks clock text for each world choice.
@Test(arguments: worldCases)
func testWorldText(test: WorldCase) {
    let got = worldText(test.style).replacingOccurrences(of: "\u{202F}", with: " ")
    #expect(got == test.wantText)
}

// testEveryNumeralsWritesEveryDigit checks that each choice writes a four-character 9:07, so none drops a zero.
@Test(arguments: Numerals.allCases)
func testEveryNumeralsWritesEveryDigit(numerals: Numerals) {
    let got = worldText {
        timeOnly(&$0)
        $0.numerals = numerals
    }
    #expect(got.count == 4)
    if numerals != .automatic && numerals != .western {
        #expect(got != "9:07")
    }
}

// testEveryCalendarResolves checks that each calendar other than automatic really counts in that calendar.
@Test(arguments: ClockCalendar.allCases)
func testEveryCalendarResolves(calendar: ClockCalendar) {
    var style = ClockStyle()
    style.calendar = calendar
    let got = style.locale(base: Locale(identifier: "en_US")).calendar.identifier
    #expect(got == calendar.identifier ?? .gregorian)
}

// testAutomaticKeepsBase checks that a style with no world choices leaves the locale alone.
@Test
func testAutomaticKeepsBase() {
    let base = Locale(identifier: "fr_FR")
    #expect(ClockStyle().locale(base: base) == base)
}

// testCustomPatternTakesWorldChoices checks that a custom pattern is written in the chosen numerals and left as
// typed for the year.
@Test
func testCustomPatternTakesWorldChoices() {
    let got = worldText {
        $0.dateStyle = .custom
        $0.customPattern = "yyyy"
        $0.calendar = .japanese
        $0.numerals = .devanagari
    }
    #expect(got == "०००८")
}

// testLanguagesAreKnown checks that every language has a distinct title that names it.
@Test
func testLanguagesAreKnown() {
    #expect(Set(ClockLanguage.all.map(\.title)).count == ClockLanguage.all.count)
    #expect(ClockLanguage.all.first { $0.id == "es" }?.title == "Spanish  ·  español")
}

// ZoneCase is one zone search expectation.
struct ZoneCase: Sendable, CustomTestStringConvertible {
    // query is the search text.
    let query: String
    // wantIDs holds identifiers the results must hold one of, since the system names some zones two ways.
    let wantIDs: [String]

    // testDescription labels the case in test output.
    var testDescription: String { query }
}

// zoneCases covers cities, spaces, regions, names, aliases, abbreviations, offsets, and case.
let zoneCases: [ZoneCase] = [
    ZoneCase(query: "tokyo", wantIDs: ["Asia/Tokyo"]),  // Test 0: City.
    ZoneCase(query: "new york", wantIDs: ["America/New_York"]),  // Test 1: City of two words.
    ZoneCase(query: "TOKYO", wantIDs: ["Asia/Tokyo"]),  // Test 2: Case.
    ZoneCase(query: "europe london", wantIDs: ["Europe/London"]),  // Test 3: Region and city.
    ZoneCase(query: "india", wantIDs: ["Asia/Calcutta", "Asia/Kolkata"]),  // Test 4: Alias and zone name.
    ZoneCase(query: "kolkata", wantIDs: ["Asia/Calcutta", "Asia/Kolkata"]),  // Test 10: Either spelling.
    ZoneCase(query: "mumbai", wantIDs: ["Asia/Calcutta", "Asia/Kolkata"]),  // Test 5: Alias.
    ZoneCase(query: "austin", wantIDs: ["America/Chicago"]),  // Test 6: Alias.
    ZoneCase(query: "central standard", wantIDs: ["America/Chicago"]),  // Test 7: Zone name.
    ZoneCase(query: "utc+9", wantIDs: ["Asia/Tokyo"]),  // Test 8: Offset.
    ZoneCase(query: "utc+5:30", wantIDs: ["Asia/Calcutta", "Asia/Kolkata"]),  // Test 9: Offset with minutes.
]

// testZoneSearch checks that a search finds the zone.
@Test(arguments: zoneCases)
func testZoneSearch(test: ZoneCase) {
    let got = ZoneCatalog.matches(test.query, in: ZoneCatalog.entries(at: worldDate))
    #expect(got.contains { test.wantIDs.contains($0.id) })
}

// testZoneSearchEdges checks a blank search, a search with no match, and an unknown zone.
@Test
func testZoneSearchEdges() {
    let entries = ZoneCatalog.entries(at: worldDate)
    #expect(!entries.isEmpty)
    #expect(ZoneCatalog.matches("  ", in: entries) == entries)
    #expect(ZoneCatalog.matches("zzzzzz", in: entries).isEmpty)
    #expect(ZoneCatalog.entry("Not/AZone", at: worldDate) == nil)
}

// testZoneEntry checks how an entry reads.
@Test
func testZoneEntry() {
    let got = ZoneCatalog.entry("America/Argentina/Buenos_Aires", at: worldDate)
    #expect(got?.city == "Buenos Aires")
    #expect(got?.region == "America, Argentina")
    #expect(got?.offset == "UTC-3")
}

// testZoneOffset checks offset wording on both sides of UTC.
@Test
func testZoneOffset() {
    #expect(ZoneCatalog.offset(seconds: 0) == "UTC")
    #expect(ZoneCatalog.offset(seconds: -6 * 3600) == "UTC-6")
    #expect(ZoneCatalog.offset(seconds: 5 * 3600 + 1800) == "UTC+5:30")
    #expect(ZoneCatalog.offset(seconds: -(3 * 3600 + 1800)) == "UTC-3:30")
}
