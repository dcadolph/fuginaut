import Foundation

// Numerals chooses the digits the clock is written in.
public enum Numerals: String, Codable, CaseIterable, Sendable {
    // automatic follows the language or the Mac.
    case automatic
    // western reads 0123456789.
    case western
    // arabicIndic reads ٠١٢٣٤٥٦٧٨٩.
    case arabicIndic
    // persian reads ۰۱۲۳۴۵۶۷۸۹.
    case persian
    // devanagari reads ०१२३४५६७८९.
    case devanagari
    // bengali reads ০১২৩৪৫৬৭৮৯.
    case bengali
    // gurmukhi reads ੦੧੨੩੪੫੬੭੮੯.
    case gurmukhi
    // gujarati reads ૦૧૨૩૪૫૬૭૮૯.
    case gujarati
    // kannada reads ೦೧೨೩೪೫೬೭೮೯.
    case kannada
    // malayalam reads ൦൧൨൩൪൫൬൭൮൯.
    case malayalam
    // tamil reads ௦௧௨௩௪௫௬௭௮௯, the decimal digits with a zero.
    case tamil
    // telugu reads ౦౧౨౩౪౫౬౭౮౯.
    case telugu
    // tibetan reads ༠༡༢༣༤༥༦༧༨༩.
    case tibetan
    // thai reads ๐๑๒๓๔๕๖๗๘๙.
    case thai
    // lao reads ໐໑໒໓໔໕໖໗໘໙.
    case lao
    // burmese reads ၀၁၂၃၄၅၆၇၈၉.
    case burmese
    // khmer reads ០១២៣៤៥៦៧៨៩.
    case khmer
    // chinese reads 〇一二三四五六七八九.
    case chinese

    // identifier is the Unicode numbering system, or nil to leave the locale's own.
    var identifier: String? {
        switch self {
        case .automatic: nil
        case .western: "latn"
        case .arabicIndic: "arab"
        case .persian: "arabext"
        case .devanagari: "deva"
        case .bengali: "beng"
        case .gurmukhi: "guru"
        case .gujarati: "gujr"
        case .kannada: "knda"
        case .malayalam: "mlym"
        case .tamil: "tamldec"
        case .telugu: "telu"
        case .tibetan: "tibt"
        case .thai: "thai"
        case .lao: "laoo"
        case .burmese: "mymr"
        case .khmer: "khmr"
        case .chinese: "hanidec"
        }
    }

    // title names the digits in menus.
    public var title: String {
        switch self {
        case .automatic: "Automatic"
        case .western: "Western"
        case .arabicIndic: "Arabic-Indic"
        case .persian: "Persian"
        case .devanagari: "Devanagari"
        case .bengali: "Bengali"
        case .gurmukhi: "Gurmukhi"
        case .gujarati: "Gujarati"
        case .kannada: "Kannada"
        case .malayalam: "Malayalam"
        case .tamil: "Tamil"
        case .telugu: "Telugu"
        case .tibetan: "Tibetan"
        case .thai: "Thai"
        case .lao: "Lao"
        case .burmese: "Burmese"
        case .khmer: "Khmer"
        case .chinese: "Chinese"
        }
    }
}

// ClockCalendar chooses the calendar the date is counted in.
public enum ClockCalendar: String, Codable, CaseIterable, Sendable {
    // automatic follows the language or the Mac.
    case automatic
    // gregorian is the international calendar.
    case gregorian
    // islamic is the astronomical Hijri calendar.
    case islamic
    // islamicCivil is the tabular Hijri calendar.
    case islamicCivil
    // islamicUmmAlQura is the Hijri calendar of Saudi Arabia.
    case islamicUmmAlQura
    // hebrew is the Hebrew calendar.
    case hebrew
    // persian is the Solar Hijri calendar.
    case persian
    // indian is the Indian national calendar.
    case indian
    // buddhist is the Thai solar calendar.
    case buddhist
    // japanese counts years by imperial era.
    case japanese
    // chinese is the Chinese lunisolar calendar.
    case chinese
    // coptic is the Coptic calendar.
    case coptic
    // ethiopic is the Ethiopian calendar.
    case ethiopic

    // identifier is the Foundation calendar, or nil to leave the locale's own.
    var identifier: Calendar.Identifier? {
        switch self {
        case .automatic: nil
        case .gregorian: .gregorian
        case .islamic: .islamic
        case .islamicCivil: .islamicCivil
        case .islamicUmmAlQura: .islamicUmmAlQura
        case .hebrew: .hebrew
        case .persian: .persian
        case .indian: .indian
        case .buddhist: .buddhist
        case .japanese: .japanese
        case .chinese: .chinese
        case .coptic: .coptic
        case .ethiopic: .ethiopicAmeteMihret
        }
    }

    // title names the calendar in menus.
    public var title: String {
        switch self {
        case .automatic: "Automatic"
        case .gregorian: "Gregorian"
        case .islamic: "Islamic"
        case .islamicCivil: "Islamic, civil"
        case .islamicUmmAlQura: "Islamic, Umm al-Qura"
        case .hebrew: "Hebrew"
        case .persian: "Persian"
        case .indian: "Indian national"
        case .buddhist: "Buddhist"
        case .japanese: "Japanese"
        case .chinese: "Chinese"
        case .coptic: "Coptic"
        case .ethiopic: "Ethiopian"
        }
    }
}

// ClockLanguage is a language the clock can write its day and month names in.
public struct ClockLanguage: Sendable, Equatable, Identifiable {
    // id is the locale identifier.
    public let id: String
    // title is the language's English name and its own name, for menus.
    public let title: String

    // all lists the languages offered, by English name.
    public static let all: [ClockLanguage] = [
        "ar", "bn", "zh-Hans", "zh-Hant", "nl", "en-US", "en-GB", "fr", "de", "el", "he", "hi", "id", "it", "ja",
        "ko", "fa", "pl", "pt", "ru", "es", "sv", "th", "tr", "uk", "ur", "vi",
    ].map { id in
        let english = Locale(identifier: "en_US").localizedString(forIdentifier: id) ?? id
        let own = Locale(identifier: id).localizedString(forIdentifier: id) ?? id
        return ClockLanguage(id: id, title: english == own ? english : english + "  ·  " + own)
    }
}

// ZoneEntry is one time zone in the search list.
public struct ZoneEntry: Sendable, Equatable, Identifiable {
    // id is the IANA time zone identifier.
    public let id: String
    // city is the last part of the identifier, as words.
    public let city: String
    // region is the identifier's leading parts, as words.
    public let region: String
    // offset is the distance from UTC, such as UTC-6 or UTC+5:30.
    public let offset: String
    // terms is the lowercase text a search looks through.
    let terms: String
}

// ZoneCatalog finds time zones by city, region, zone name, abbreviation, or offset.
public enum ZoneCatalog {
    // aliases adds places a zone covers that its identifier and names leave out.
    private static let aliases = [
        "America/Chicago": "dallas austin houston texas",
        "America/Los_Angeles": "san francisco seattle california",
        "America/New_York": "boston washington miami atlanta",
        "Asia/Dhaka": "bangladesh",
        "Asia/Dubai": "abu dhabi uae emirates",
        "Asia/Ho_Chi_Minh": "saigon vietnam",
        "Asia/Karachi": "pakistan lahore",
        "Asia/Calcutta": "india kolkata mumbai delhi bangalore bengaluru",
        "Asia/Kolkata": "india calcutta mumbai delhi bangalore bengaluru",
        "Asia/Riyadh": "saudi arabia mecca",
        "Asia/Seoul": "korea",
        "Asia/Shanghai": "china beijing",
        "Asia/Tokyo": "japan osaka",
    ]

    // entries returns every known zone by city, with offsets as of the date.
    public static func entries(at date: Date) -> [ZoneEntry] {
        TimeZone.knownTimeZoneIdentifiers.compactMap { entry($0, at: date) }
            .sorted { $0.city.localizedStandardCompare($1.city) == .orderedAscending }
    }

    // entry builds the entry for an identifier, or returns nil for an unknown one.
    public static func entry(_ id: String, at date: Date) -> ZoneEntry? {
        guard let zone = TimeZone(identifier: id) else {
            return nil
        }
        let english = Locale(identifier: "en_US")
        let parts = id.replacingOccurrences(of: "_", with: " ").split(separator: "/").map(String.init)
        let offset = offset(seconds: zone.secondsFromGMT(for: date))
        let names = [
            id.replacingOccurrences(of: "_", with: " "),
            zone.localizedName(for: .standard, locale: english),
            zone.localizedName(for: .daylightSaving, locale: english),
            zone.localizedName(for: .generic, locale: english),
            zone.abbreviation(for: date),
            offset,
            aliases[id],
        ]
        return ZoneEntry(
            id: id, city: parts.last ?? id, region: parts.dropLast().joined(separator: ", "), offset: offset,
            terms: names.compactMap { $0 }.joined(separator: " ").lowercased())
    }

    // matches keeps the entries holding every word of the query. A blank query keeps them all.
    public static func matches(_ query: String, in entries: [ZoneEntry]) -> [ZoneEntry] {
        let words = query.lowercased().split(whereSeparator: \.isWhitespace)
        return words.isEmpty ? entries : entries.filter { entry in words.allSatisfy { entry.terms.contains($0) } }
    }

    // offset writes a distance from UTC, such as UTC, UTC-6, or UTC+5:30.
    static func offset(seconds: Int) -> String {
        guard seconds != 0 else {
            return "UTC"
        }
        let minutes = abs(seconds) / 60
        let hours = "UTC" + (seconds < 0 ? "-" : "+") + String(minutes / 60)
        return minutes % 60 == 0 ? hours : hours + ":" + String(format: "%02d", minutes % 60)
    }
}
