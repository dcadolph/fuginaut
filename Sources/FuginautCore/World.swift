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
    // odia reads ୦୧୨୩୪୫୬୭୮୯.
    case odia
    // mongolian reads ᠐᠑᠒᠓᠔᠕᠖᠗᠘᠙.
    case mongolian
    // olChiki reads ᱐᱑᱒᱓᱔᱕᱖᱗᱘᱙, the digits of Santali.
    case olChiki
    // adlam reads 𞥐𞥑𞥒𞥓𞥔𞥕𞥖𞥗𞥘𞥙, the digits of Fulani.
    case adlam
    // nko reads ߀߁߂߃߄߅߆߇߈߉, the digits of the Manding languages.
    case nko

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
        case .odia: "orya"
        case .mongolian: "mong"
        case .olChiki: "olck"
        case .adlam: "adlm"
        case .nko: "nkoo"
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
        case .odia: "Odia"
        case .mongolian: "Mongolian"
        case .olChiki: "Ol Chiki"
        case .adlam: "Adlam"
        case .nko: "N'Ko"
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
    // vikram is the Vikram Samvat calendar of Nepal and northern India.
    case vikram
    // bangla is the Bangla calendar of Bangladesh.
    case bangla
    // gujarati is the Gujarati Hindu calendar.
    case gujarati
    // kannada is the Kannada Hindu calendar.
    case kannada
    // malayalam is the Malayalam calendar.
    case malayalam
    // marathi is the Marathi Hindu calendar.
    case marathi
    // odia is the Odia calendar.
    case odia
    // tamil is the Tamil calendar.
    case tamil
    // telugu is the Telugu Hindu calendar.
    case telugu
    // buddhist is the Thai solar calendar.
    case buddhist
    // japanese counts years by imperial era.
    case japanese
    // chinese is the Chinese lunisolar calendar.
    case chinese
    // korean is the Korean lunisolar calendar.
    case korean
    // vietnamese is the Vietnamese lunisolar calendar.
    case vietnamese
    // minguo counts years from 1912, as Taiwan does.
    case minguo
    // coptic is the Coptic calendar.
    case coptic
    // ethiopic is the Ethiopian calendar.
    case ethiopic

    // offered lists the calendars this Mac can count in, since some arrived in macOS 26.
    public static var offered: [ClockCalendar] {
        allCases.filter { $0 == .automatic || $0.identifier != nil }
    }

    // identifier is the Foundation calendar, or nil to leave the locale's own or when this Mac lacks it.
    var identifier: Calendar.Identifier? {
        if let identifier = Self.newer(self) {
            return identifier
        }
        return switch self {
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
        case .minguo: .republicOfChina
        case .coptic: .coptic
        case .ethiopic: .ethiopicAmeteMihret
        default: nil
        }
    }

    // newer returns the identifier for a calendar that arrived in macOS 26, or nil for any other or on a Mac
    // without it. It looks the calendar up by its Unicode name, so the app builds with any SDK.
    private static func newer(_ calendar: ClockCalendar) -> Calendar.Identifier? {
        let names: [ClockCalendar: String] = [
            .vikram: "vikram", .bangla: "bangla", .gujarati: "gujarati", .kannada: "kannada", .malayalam: "malayalam",
            .marathi: "marathi", .odia: "odia", .tamil: "tamil", .telugu: "telugu", .korean: "dangi",
            .vietnamese: "vietnamese",
        ]
        guard let name = names[calendar] else {
            return nil
        }
        let identifier = Locale(identifier: "en_US@calendar=" + name).calendar.identifier
        return identifier == .gregorian ? nil : identifier
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
        case .vikram: "Vikram Samvat"
        case .bangla: "Bangla"
        case .gujarati: "Gujarati"
        case .kannada: "Kannada"
        case .malayalam: "Malayalam"
        case .marathi: "Marathi"
        case .odia: "Odia"
        case .tamil: "Tamil"
        case .telugu: "Telugu"
        case .buddhist: "Buddhist"
        case .japanese: "Japanese"
        case .chinese: "Chinese"
        case .korean: "Korean"
        case .vietnamese: "Vietnamese"
        case .minguo: "Minguo"
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

    // all lists the languages offered, by English name. It holds every language macOS itself speaks, every
    // language of about thirty million speakers or more, and a language for each script and calendar offered.
    public static let all: [ClockLanguage] = [
        "af", "am", "ar", "az", "bg", "bn", "bo", "ca", "cs", "da", "de", "el", "en-GB", "en-US", "es-419", "es-ES",
        "fa", "fi", "fil", "fr", "gu", "ha", "he", "hi", "hr", "hu", "hy", "id", "ig", "it", "ja", "jv", "ka", "kk",
        "km", "kn", "ko", "lo", "ml", "mn", "mr", "ms", "my", "nb", "ne", "nl", "om", "or", "pa", "pl", "ps",
        "pt-BR", "pt-PT", "ro", "ru", "si", "sk", "so", "sr", "sv", "sw", "ta", "te", "th", "tr", "uk", "ur", "uz",
        "vi", "yo", "zh-Hans", "zh-Hant", "zu",
    ].map { ClockLanguage(id: $0, title: title($0)) }
        .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }

    // title names a language in English and in its own words. A regional language gives its own name without
    // the region, which the English name already carries, so "Spanish (Latin America)  ·  español" fits a menu.
    static func title(_ id: String) -> String {
        let english = Locale(identifier: "en_US")
        let locale = Locale(identifier: id)
        let englishTitle = english.localizedString(forIdentifier: id) ?? id
        guard let code = locale.language.languageCode?.identifier else {
            return englishTitle
        }
        let own =
            locale.language.region == nil
            ? locale.localizedString(forIdentifier: id) : locale.localizedString(forLanguageCode: code)
        guard let own, own != englishTitle, own != english.localizedString(forLanguageCode: code) else {
            return englishTitle
        }
        return englishTitle + "  ·  " + own
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
    // renamed maps an old zone name to the one that replaced it, for places renamed or zones merged. The list
    // leaves out the old name when the new one is known, and shows the new city for a saved old name.
    private static let renamed = [
        "America/Godthab": "America/Nuuk",
        "Asia/Katmandu": "Asia/Kathmandu",
        "Asia/Rangoon": "Asia/Yangon",
        "Europe/Kiev": "Europe/Kyiv",
        "Europe/Uzhgorod": "Europe/Kyiv",
        "Europe/Zaporozhye": "Europe/Kyiv",
        "Pacific/Enderbury": "Pacific/Kanton",
        "Pacific/Ponape": "Pacific/Pohnpei",
        "Pacific/Truk": "Pacific/Chuuk",
    ]

    // cities names places the system still spells the old way when it knows no newer zone name.
    private static let cities = ["Asia/Calcutta": "Kolkata"]

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
        "Europe/Kyiv": "ukraine kiev uzhhorod zaporizhzhia",
    ]

    // entries returns every known zone by city, with offsets as of the date.
    public static func entries(at date: Date) -> [ZoneEntry] {
        let known = Set(TimeZone.knownTimeZoneIdentifiers)
        return known.filter { renamed[$0].map { !known.contains($0) } ?? true }.compactMap { entry($0, at: date) }
            .sorted { $0.city.localizedStandardCompare($1.city) == .orderedAscending }
    }

    // entry builds the entry for an identifier, or returns nil for an unknown one.
    public static func entry(_ id: String, at date: Date) -> ZoneEntry? {
        guard let zone = TimeZone(identifier: id) else {
            return nil
        }
        let english = Locale(identifier: "en_US")
        let parts = (renamed[id] ?? id).replacingOccurrences(of: "_", with: " ").split(separator: "/").map(String.init)
        let offset = offset(seconds: zone.secondsFromGMT(for: date))
        let names = [
            id.replacingOccurrences(of: "_", with: " "),
            zone.localizedName(for: .standard, locale: english),
            zone.localizedName(for: .daylightSaving, locale: english),
            zone.localizedName(for: .generic, locale: english),
            zone.abbreviation(for: date),
            offset,
            aliases[renamed[id] ?? id],
            cities[id],
        ]
        return ZoneEntry(
            id: id, city: cities[id] ?? parts.last ?? id, region: parts.dropLast().joined(separator: ", "),
            offset: offset,
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
