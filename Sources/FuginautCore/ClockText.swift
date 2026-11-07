import Foundation

// DateStyle chooses how the day reads.
public enum DateStyle: String, Codable, CaseIterable, Sendable {
    // short reads like "Wed Nov 4".
    case short
    // long reads like "Wednesday, November 4".
    case long
    // dayFirst reads like "Wed 4 Nov".
    case dayFirst
    // dayFirstLong reads like "Wednesday 4 November".
    case dayFirstLong
    // withYear reads like "Wed Nov 4, 2026".
    case withYear
    // longWithYear reads like "Wednesday, November 4, 2026".
    case longWithYear
    // dayFirstYear reads like "Wed 4 Nov 2026".
    case dayFirstYear
    // numeric reads like "Wed 11/4", ordered for the locale.
    case numeric
    // numericYear reads like "Wed 11/4/2026", ordered for the locale.
    case numericYear
    // padded reads like "Wed 11/04", ordered for the locale.
    case padded
    // dotted reads like "Wed 4.11.2026".
    case dotted
    // slashedDayFirst reads like "Wed 4/11/2026".
    case slashedDayFirst
    // iso reads like "Wed 2026-11-04".
    case iso
    // compactISO reads like "Wed 20261104".
    case compactISO
    // isoWeek reads like "Wed 2026-W45", counting weeks the ISO 8601 way.
    case isoWeek
    // dayOfYear reads like "Wed Day 308".
    case dayOfYear
    // custom uses the style's custom pattern for the whole clock.
    case custom

    // isLong reports whether the style spells out the weekday.
    var isLong: Bool {
        self == .long || self == .dayFirstLong || self == .longWithYear
    }
}

// ClockOrder chooses whether the day or the time comes first.
public enum ClockOrder: String, Codable, CaseIterable, Sendable {
    // dateFirst reads like "Wed Nov 4  3:07 PM".
    case dateFirst
    // timeFirst reads like "3:07 PM  Wed Nov 4".
    case timeFirst
}

// Separator is what sits between the day and the time.
public enum Separator: String, Codable, CaseIterable, Sendable {
    // spaces is two spaces.
    case spaces
    // dot is a middle dot.
    case dot
    // bar is a vertical bar.
    case bar
    // comma is a comma.
    case comma
    // slash is a slash.
    case slash
    // dash is a hyphen.
    case dash
    // at is the word "at".
    case at

    // pattern is the separator as quoted date pattern text.
    public var pattern: String {
        switch self {
        case .spaces: "  "
        case .dot: " · "
        case .bar: " | "
        case .comma: ", "
        case .slash: " / "
        case .dash: " - "
        case .at: " 'at' "
        }
    }
}

// Meridiem chooses how AM and PM show on a 12-hour clock.
public enum Meridiem: String, Codable, CaseIterable, Sendable {
    // upper shows "PM".
    case upper
    // lower shows "pm".
    case lower
    // hidden shows neither.
    case hidden
}

// TextCase chooses the capitals of the clock text.
public enum TextCase: String, Codable, CaseIterable, Sendable {
    // normal leaves the text as the formatter writes it.
    case normal
    // upper shows the text in capitals.
    case upper
    // lower shows the text in small letters.
    case lower
}

// ClockStyle chooses what the clock text shows.
public struct ClockStyle: Codable, Equatable, Sendable {
    // use24Hour shows hours from 00 to 23 with no AM or PM.
    public var use24Hour = false
    // showSeconds adds seconds to the time.
    public var showSeconds = false
    // showWeekday adds the weekday name.
    public var showWeekday = true
    // showDate adds the date.
    public var showDate = true
    // showTime adds the time.
    public var showTime = true
    // padHour adds a leading zero to a 12-hour time before ten.
    public var padHour = false
    // meridiem chooses how AM and PM show on a 12-hour clock.
    public var meridiem = Meridiem.upper
    // order chooses whether the day or the time comes first.
    public var order = ClockOrder.dateFirst
    // separator sits between the day and the time.
    public var separator = Separator.spaces
    // secondZone is the time zone identifier for a second time, or empty for none.
    public var secondZone = ""
    // secondZoneLabel names the second time, or empty to use the zone's abbreviation.
    public var secondZoneLabel = ""
    // dateStyle chooses how the day reads.
    public var dateStyle = DateStyle.short
    // customPattern is the Unicode date pattern for the whole clock when dateStyle is custom.
    public var customPattern = ClockStyle.defaultCustomPattern
    // textCase chooses the capitals of the clock text.
    public var textCase = TextCase.normal
    // prefix is text or emoji shown before the clock, as typed.
    public var prefix = ""
    // suffix is text or emoji shown after the clock, as typed.
    public var suffix = ""

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
        showTime = try c.decodeIfPresent(Bool.self, forKey: .showTime) ?? d.showTime
        padHour = try c.decodeIfPresent(Bool.self, forKey: .padHour) ?? d.padHour
        meridiem = try c.decodeIfPresent(Meridiem.self, forKey: .meridiem) ?? d.meridiem
        order = try c.decodeIfPresent(ClockOrder.self, forKey: .order) ?? d.order
        separator = try c.decodeIfPresent(Separator.self, forKey: .separator) ?? d.separator
        secondZone = try c.decodeIfPresent(String.self, forKey: .secondZone) ?? d.secondZone
        secondZoneLabel = try c.decodeIfPresent(String.self, forKey: .secondZoneLabel) ?? d.secondZoneLabel
        dateStyle = try c.decodeIfPresent(DateStyle.self, forKey: .dateStyle) ?? d.dateStyle
        customPattern = try c.decodeIfPresent(String.self, forKey: .customPattern) ?? d.customPattern
        textCase = try c.decodeIfPresent(TextCase.self, forKey: .textCase) ?? d.textCase
        prefix = try c.decodeIfPresent(String.self, forKey: .prefix) ?? d.prefix
        suffix = try c.decodeIfPresent(String.self, forKey: .suffix) ?? d.suffix
    }

    // timePattern is the date format for the time alone.
    public var timePattern: String {
        let seconds = showSeconds ? ":ss" : ""
        if use24Hour {
            return "HH:mm" + seconds
        }
        let time = (padHour ? "hh" : "h") + ":mm" + seconds
        return meridiem == .hidden ? time : time + " a"
    }

    // usesCustomPattern reports whether the custom pattern replaces the built-in parts.
    public var usesCustomPattern: Bool {
        dateStyle == .custom && !customPattern.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // pattern returns the date format for the whole clock. A custom style uses its own pattern, or the short
    // style's when the custom pattern is blank. A style that hides everything still shows the time.
    public func pattern(locale: Locale) -> String {
        if usesCustomPattern {
            return customPattern
        }
        let day = dayPattern(locale: locale)
        let time = showTime ? timePattern : nil
        switch (day, time) {
        case (let day?, let time?):
            return order == .dateFirst ? day + separator.pattern + time : time + separator.pattern + day
        case (let day?, nil):
            return day
        case (nil, _):
            return timePattern
        }
    }

    // dayPattern returns the date format for the weekday and date, or nil when the style shows neither. A
    // custom style reads as short here.
    public func dayPattern(locale: Locale) -> String? {
        let long = dateStyle.isLong
        var day: [String] = []
        if showWeekday {
            day.append(long ? "EEEE" : "EEE")
        }
        if showDate {
            day.append(datePattern(locale: locale))
        }
        let joiner = dateStyle == .long || dateStyle == .longWithYear ? ", " : " "
        return day.isEmpty ? nil : day.joined(separator: joiner)
    }

    // datePattern returns the month and day part for the style.
    private func datePattern(locale: Locale) -> String {
        switch dateStyle {
        case .short, .custom: "MMM d"
        case .long: "MMMM d"
        case .dayFirst: "d MMM"
        case .dayFirstLong: "d MMMM"
        case .withYear: "MMM d, yyyy"
        case .longWithYear: "MMMM d, yyyy"
        case .dayFirstYear: "d MMM yyyy"
        case .numeric: DateFormatter.dateFormat(fromTemplate: "Md", options: 0, locale: locale) ?? "M/d"
        case .numericYear: DateFormatter.dateFormat(fromTemplate: "yMd", options: 0, locale: locale) ?? "M/d/yyyy"
        case .padded: DateFormatter.dateFormat(fromTemplate: "MMdd", options: 0, locale: locale) ?? "MM/dd"
        case .dotted: "d.M.yyyy"
        case .slashedDayFirst: "d/M/yyyy"
        case .iso: "yyyy-MM-dd"
        case .compactISO: "yyyyMMdd"
        case .isoWeek: "YYYY-'W'ww"
        case .dayOfYear: "'Day' D"
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
    // textCase chooses the capitals of the clock text.
    private let textCase: TextCase
    // prefix is shown before the clock text, as typed.
    private let prefix: String
    // suffix is shown after the clock text, as typed.
    private let suffix: String
    // locale is the locale the text is written and capitalized in.
    private let locale: Locale

    // init prepares the formatters for the style in the given locale and local time zone.
    public init(style: ClockStyle, locale: Locale = .current, zone: TimeZone = .current) {
        let lowerMeridiem = !style.usesCustomPattern && style.meridiem == .lower
        main = Self.formatter(locale: locale, zone: zone, lowerMeridiem: lowerMeridiem)
        if !style.usesCustomPattern, style.dateStyle == .isoWeek {
            var calendar = Calendar(identifier: .iso8601)
            calendar.locale = locale
            calendar.timeZone = zone
            main.calendar = calendar
        }
        main.dateFormat = style.pattern(locale: locale)
        if !style.secondZone.isEmpty, let other = TimeZone(identifier: style.secondZone) {
            let f = Self.formatter(locale: locale, zone: other, lowerMeridiem: lowerMeridiem)
            f.dateFormat = style.timePattern
            second = f
        } else {
            second = nil
        }
        secondLabel = style.secondZoneLabel.trimmingCharacters(in: .whitespaces)
        textCase = style.textCase
        prefix = style.prefix.trimmingCharacters(in: .whitespaces)
        suffix = style.suffix.trimmingCharacters(in: .whitespaces)
        self.locale = locale
    }

    // formatter builds a date formatter for a locale and zone, with lowercase AM and PM when asked.
    private static func formatter(locale: Locale, zone: TimeZone, lowerMeridiem: Bool) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = zone
        if lowerMeridiem {
            f.amSymbol = f.amSymbol.lowercased(with: locale)
            f.pmSymbol = f.pmSymbol.lowercased(with: locale)
        }
        return f
    }

    // string returns the clock text for the date.
    public func string(_ date: Date) -> String {
        var text = main.string(from: date)
        if let second, let zone = second.timeZone {
            let label = secondLabel.isEmpty ? zone.abbreviation(for: date) ?? zone.identifier : secondLabel
            text += "  ·  " + label + " " + second.string(from: date)
        }
        switch textCase {
        case .normal: break
        case .upper: text = text.uppercased(with: locale)
        case .lower: text = text.lowercased(with: locale)
        }
        return [prefix, text, suffix].filter { !$0.isEmpty }.joined(separator: " ")
    }
}
