import Foundation

// ClockStyle chooses what the clock text shows.
public struct ClockStyle: Codable, Equatable, Sendable {
    // use24Hour shows hours from 00 to 23 with no AM or PM.
    public var use24Hour = false
    // showSeconds adds seconds to the time.
    public var showSeconds = false
    // showWeekday adds the short weekday name.
    public var showWeekday = true
    // showDate adds the short month and day.
    public var showDate = true
    // secondZone is the time zone identifier for a second time, or empty for none.
    public var secondZone = ""
    // secondZoneLabel names the second time, or empty to use the zone's abbreviation.
    public var secondZoneLabel = ""

    // init builds the default style.
    public init() {}

    // init decodes a style and fills keys it lacks with defaults, so saved settings survive new fields.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ClockStyle()
        use24Hour = try c.decodeIfPresent(Bool.self, forKey: .use24Hour) ?? d.use24Hour
        showSeconds = try c.decodeIfPresent(Bool.self, forKey: .showSeconds) ?? d.showSeconds
        showWeekday = try c.decodeIfPresent(Bool.self, forKey: .showWeekday) ?? d.showWeekday
        showDate = try c.decodeIfPresent(Bool.self, forKey: .showDate) ?? d.showDate
        secondZone = try c.decodeIfPresent(String.self, forKey: .secondZone) ?? d.secondZone
        secondZoneLabel = try c.decodeIfPresent(String.self, forKey: .secondZoneLabel) ?? d.secondZoneLabel
    }

    // timePattern is the date format for the time alone.
    public var timePattern: String {
        var time = use24Hour ? "HH:mm" : "h:mm"
        if showSeconds {
            time += ":ss"
        }
        return use24Hour ? time : time + " a"
    }

    // pattern is the date format for the whole clock, with two spaces between the day and the time.
    public var pattern: String {
        var day: [String] = []
        if showWeekday {
            day.append("EEE")
        }
        if showDate {
            day.append("MMM d")
        }
        return day.isEmpty ? timePattern : day.joined(separator: " ") + "  " + timePattern
    }
}

// ClockFormatter turns a date into the clock text for one style. Build a new one when the style changes.
public final class ClockFormatter {
    // main formats the local day and time.
    private let main: DateFormatter
    // second formats the second time zone, or is nil when the style has none.
    private let second: DateFormatter?
    // secondLabel is the fixed label for the second time, or empty to use the zone's abbreviation.
    private let secondLabel: String

    // init prepares the formatters for the style in the given locale and local time zone.
    public init(style: ClockStyle, locale: Locale = .current, zone: TimeZone = .current) {
        main = DateFormatter()
        main.locale = locale
        main.timeZone = zone
        main.dateFormat = style.pattern
        if !style.secondZone.isEmpty, let other = TimeZone(identifier: style.secondZone) {
            let f = DateFormatter()
            f.locale = locale
            f.timeZone = other
            f.dateFormat = style.timePattern
            second = f
        } else {
            second = nil
        }
        secondLabel = style.secondZoneLabel.trimmingCharacters(in: .whitespaces)
    }

    // string returns the clock text for the date.
    public func string(_ date: Date) -> String {
        let text = main.string(from: date)
        guard let second, let zone = second.timeZone else {
            return text
        }
        let label = secondLabel.isEmpty ? zone.abbreviation(for: date) ?? zone.identifier : secondLabel
        return text + "  ·  " + label + " " + second.string(from: date)
    }
}
