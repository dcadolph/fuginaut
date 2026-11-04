import Foundation

// DateStyle chooses how the day reads.
public enum DateStyle: String, Codable, CaseIterable, Sendable {
    // short reads like "Wed Nov 4".
    case short
    // long reads like "Wednesday, November 4".
    case long
    // numeric reads like "Wed 11/4", ordered for the locale.
    case numeric
    // iso reads like "Wed 2026-11-04".
    case iso
    // custom uses the style's custom pattern for the whole clock.
    case custom
}

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
    // dateStyle chooses how the day reads.
    public var dateStyle = DateStyle.short
    // customPattern is the Unicode date pattern for the whole clock when dateStyle is custom.
    public var customPattern = ClockStyle.defaultCustomPattern
    // uppercase shows the clock text in capitals.
    public var uppercase = false

    // defaultCustomPattern is the pattern a new custom style starts from.
    public static let defaultCustomPattern = "EEE d MMM  HH:mm"

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
        dateStyle = try c.decodeIfPresent(DateStyle.self, forKey: .dateStyle) ?? d.dateStyle
        customPattern = try c.decodeIfPresent(String.self, forKey: .customPattern) ?? d.customPattern
        uppercase = try c.decodeIfPresent(Bool.self, forKey: .uppercase) ?? d.uppercase
    }

    // timePattern is the date format for the time alone.
    public var timePattern: String {
        var time = use24Hour ? "HH:mm" : "h:mm"
        if showSeconds {
            time += ":ss"
        }
        return use24Hour ? time : time + " a"
    }

    // pattern returns the date format for the whole clock, with two spaces between the day and the time.
    // A custom style uses its own pattern, or the short style's when the custom pattern is blank.
    public func pattern(locale: Locale) -> String {
        if dateStyle == .custom, !customPattern.trimmingCharacters(in: .whitespaces).isEmpty {
            return customPattern
        }
        guard let day = dayPattern(locale: locale) else {
            return timePattern
        }
        return day + "  " + timePattern
    }

    // dayPattern returns the date format for the weekday and date, or nil when the style shows neither. A
    // custom style reads as short here.
    public func dayPattern(locale: Locale) -> String? {
        let long = dateStyle == .long
        var day: [String] = []
        if showWeekday {
            day.append(long ? "EEEE" : "EEE")
        }
        if showDate {
            day.append(datePattern(locale: locale))
        }
        return day.isEmpty ? nil : day.joined(separator: long ? ", " : " ")
    }

    // datePattern returns the month and day part for the style.
    private func datePattern(locale: Locale) -> String {
        switch dateStyle {
        case .short, .custom: "MMM d"
        case .long: "MMMM d"
        case .numeric: DateFormatter.dateFormat(fromTemplate: "Md", options: 0, locale: locale) ?? "M/d"
        case .iso: "yyyy-MM-dd"
        }
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
    // uppercase shows the text in capitals.
    private let uppercase: Bool
    // locale is the locale the text is written and capitalized in.
    private let locale: Locale

    // init prepares the formatters for the style in the given locale and local time zone.
    public init(style: ClockStyle, locale: Locale = .current, zone: TimeZone = .current) {
        main = DateFormatter()
        main.locale = locale
        main.timeZone = zone
        main.dateFormat = style.pattern(locale: locale)
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
        uppercase = style.uppercase
        self.locale = locale
    }

    // string returns the clock text for the date.
    public func string(_ date: Date) -> String {
        var text = main.string(from: date)
        if let second, let zone = second.timeZone {
            let label = secondLabel.isEmpty ? zone.abbreviation(for: date) ?? zone.identifier : secondLabel
            text += "  ·  " + label + " " + second.string(from: date)
        }
        return uppercase ? text.uppercased(with: locale) : text
    }
}
