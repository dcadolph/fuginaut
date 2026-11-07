import AppKit
import SwiftUI

import FuginautCore

// SettingsTab names one page of the settings window.
enum SettingsTab: String, CaseIterable, Identifiable {
    case size
    case text
    case color
    case format
    case general

    // id identifies the tab in lists.
    var id: Self { self }

    // title is the tab's label.
    var title: String {
        switch self {
        case .size: "Size"
        case .text: "Text"
        case .color: "Color"
        case .format: "Format"
        case .general: "General"
        }
    }

    // symbol is the tab's SF Symbol.
    var symbol: String {
        switch self {
        case .size: "textformat.size"
        case .text: "textformat"
        case .color: "paintpalette"
        case .format: "calendar.badge.clock"
        case .general: "gearshape"
        }
    }
}

// SettingsView is the settings window's content: a live preview over tabbed cards. Every change applies to the
// clock right away.
struct SettingsView: View {
    // store holds the live settings.
    @Bindable var store: SettingsStore
    // loginItem starts Fuginaut at login.
    var loginItem: LoginItem
    // tab is the page on show.
    @State var tab: SettingsTab = .size
    // previewDark draws the preview's menu bar dark, or follows the system when nil.
    @State var previewDark: Bool?
    // previewDate pins the preview's time, for stills. Nil shows the live time.
    var previewDate: Date?
    // astronaut is the header art, loaded from the app bundle.
    var astronaut: NSImage? = AstronautHeader.bundled()

    // colorScheme is the window's appearance, which the preview follows until flipped.
    @Environment(\.colorScheme) private var colorScheme

    // width is the window's content width.
    static let width: CGFloat = 540
    // pageHeight is the height of the card area, fixed so the window keeps its size across tabs.
    static let pageHeight: CGFloat = 372
    // zones lists every time zone identifier for the second time picker.
    private static let zones = TimeZone.knownTimeZoneIdentifiers.sorted()
    // families lists the installed font families for the font picker.
    private static let families = ClockLook.families()
    // patternHelp is the Unicode table of date pattern letters.
    private static let patternHelp = URL(
        string: "https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table"
    )

    // body lays out the astronaut header, the preview, the tab strip, and the current page.
    var body: some View {
        VStack(spacing: 0) {
            AstronautHeader(astronaut: astronaut)
            ClockPreview(settings: store.settings, dark: dark, date: previewDate)
                .padding([.horizontal, .top], 16)
            tabStrip
                .padding(.vertical, 10)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    page
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(height: Self.pageHeight)
        }
        .frame(width: Self.width)
        .background(Color(nsColor: .windowBackgroundColor))
        .toggleStyle(.switch)
        .controlSize(.small)
    }

    // dark binds the preview's appearance, starting from the window's.
    private var dark: Binding<Bool> {
        Binding {
            previewDark ?? (colorScheme == .dark)
        } set: { on in
            previewDark = on
        }
    }

    // tabStrip draws the page buttons in a centered row.
    private var tabStrip: some View {
        HStack(spacing: 4) {
            ForEach(SettingsTab.allCases) { item in
                Button {
                    tab = item
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 16, weight: .regular))
                            .frame(height: 20)
                        Text(item.title)
                            .font(.system(size: 11, weight: tab == item ? .semibold : .regular))
                    }
                    .frame(width: 82, height: 46)
                    .foregroundStyle(tab == item ? Color.accentColor : Color.secondary)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(tab == item ? Color.primary.opacity(0.08) : .clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // page returns the cards for the current tab.
    @ViewBuilder private var page: some View {
        switch tab {
        case .size:
            sizeCard
            positionCard
        case .text:
            typefaceCard
        case .color:
            textColorCard
            backingCard
        case .format:
            dayCard
            extrasCard
            secondTimeCard
        case .general:
            displaysCard
            behaviorCard
            footer
        }
    }

    // sizeCard holds how big the clock reads.
    private var sizeCard: some View {
        Card("Size") {
            Row("Size") {
                HStack(spacing: 8) {
                    Slider(value: whole(\.fontSize), in: FuginautCore.Settings.fontSizes)
                        .frame(width: 220)
                    Text("\(Int(store.settings.fontSize)) pt")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                }
            }
        }
    }

    // positionCard holds the nudge away from the center of the bar.
    private var positionCard: some View {
        Card("Position") {
            Row("Nudge", detail: "The clock sits at the center of the menu bar. Nudge it off a busy spot.") {
                HStack(spacing: 8) {
                    Slider(value: whole(\.offset), in: FuginautCore.Settings.offsets)
                        .frame(width: 170)
                    Text("\(Int(store.settings.offset)) pt")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .trailing)
                    ResetButton(disabled: store.settings.offset == 0) {
                        store.settings.offset = 0
                    }
                }
            }
        }
    }

    // displaysCard holds one switch per connected display. A laptop's own screen starts off while an external
    // display is connected.
    private var displaysCard: some View {
        let displays = Display.all()
        let external = displays.contains { !$0.builtIn }
        return Card("Displays") {
            ForEach(Array(displays.enumerated()), id: \.element.uuid) { index, display in
                if index > 0 {
                    RowDivider()
                }
                Row(display.name) {
                    Toggle(display.name, isOn: shown(display, external: external)).labelsHidden()
                }
            }
        }
    }

    // typefaceCard holds the font, its weight, and its capitals.
    private var typefaceCard: some View {
        Card("Typeface") {
            Row("Font") {
                Picker("Font", selection: fontChoice) {
                    Text("System").tag(FontDesign.system.rawValue)
                    Text("Rounded").tag(FontDesign.rounded.rawValue)
                    Text("Mono").tag(FontDesign.mono.rawValue)
                    Text("Serif").tag(FontDesign.serif.rawValue)
                    Divider()
                    ForEach(familyChoices, id: \.self) { family in
                        Text(family).tag("family:" + family)
                    }
                }
                .labelsHidden()
                .frame(width: 200)
            }
            RowDivider()
            Row("Weight") {
                Picker("Weight", selection: $store.settings.weight) {
                    Text("Regular").tag(Weight.regular)
                    Text("Medium").tag(Weight.medium)
                    Text("Semibold").tag(Weight.semibold)
                    Text("Bold").tag(Weight.bold)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 280)
            }
            RowDivider()
            Row("Capitals") {
                Picker("Capitals", selection: $store.settings.style.textCase) {
                    Text("As written").tag(TextCase.normal)
                    Text("ALL CAPS").tag(TextCase.upper)
                    Text("lowercase").tag(TextCase.lower)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 280)
            }
        }
    }

    // textColorCard holds the clock's color: automatic, or picked from the swatches, a hex value, or the wheel.
    private var textColorCard: some View {
        Card("Text color") {
            Row(
                "Match the menu bar",
                detail: "White on dark menu bars and black on light ones. Pick a color to turn off."
            ) {
                Toggle("Match the menu bar", isOn: matchSystem).labelsHidden()
            }
            RowDivider()
            ColorChooser(color: $store.settings.color, fallback: RGBA(red: 1, green: 1, blue: 1))
        }
    }

    // backingCard holds the shadow or pill behind the text and its color.
    private var backingCard: some View {
        Card("Backing") {
            Row("Style", detail: "Keeps the text readable over busy wallpaper.") {
                Picker("Style", selection: $store.settings.backing) {
                    Text("None").tag(Backing.none)
                    Text("Shadow").tag(Backing.shadow)
                    Text("Pill").tag(Backing.pill)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 190)
            }
            if store.settings.backing != .none {
                RowDivider()
                Row("Automatic color", detail: "The opposite of the text color. Pick one to stand out on any bar.") {
                    Toggle("Automatic color", isOn: automaticBacking).labelsHidden()
                }
                RowDivider()
                ColorChooser(color: $store.settings.backingColor, fallback: RGBA(red: 0, green: 0, blue: 0))
            }
        }
    }

    // dayCard holds the date style and the switches for each part, or the custom pattern.
    private var dayCard: some View {
        Card("Day and time") {
            Row("Style") {
                Picker("Style", selection: dateStyle) {
                    ForEach(Self.styleGroups.indices, id: \.self) { index in
                        if index > 0 {
                            Divider()
                        }
                        ForEach(Self.styleGroups[index], id: \.self) { style in
                            Text(Self.styleTitle(style)).tag(style)
                        }
                    }
                }
                .labelsHidden()
                .frame(width: 280)
            }
            if store.settings.style.dateStyle == .custom {
                RowDivider()
                Row("Pattern") {
                    HStack(spacing: 8) {
                        TextField("Pattern", text: $store.settings.style.customPattern)
                            .font(.system(.body, design: .monospaced))
                            .textFieldStyle(.roundedBorder)
                            .labelsHidden()
                            .frame(width: 210)
                        patternMenu
                        ResetButton(disabled: store.settings.style.customPattern == ClockStyle.defaultCustomPattern) {
                            store.settings.style.customPattern = ClockStyle.defaultCustomPattern
                        }
                    }
                }
                RowDivider()
                HStack(spacing: 4) {
                    Text("Unicode date letters. Quote literal words. Emoji work as typed.")
                    if let help = Self.patternHelp {
                        Link("Letters", destination: help)
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                partRows
            }
        }
    }

    // partRows holds the switches for the weekday, date, and time, and how they sit together.
    @ViewBuilder private var partRows: some View {
        let style = store.settings.style
        RowDivider()
        Row("Weekday") {
            Toggle("Weekday", isOn: $store.settings.style.showWeekday).labelsHidden()
        }
        RowDivider()
        Row("Date") {
            Toggle("Date", isOn: $store.settings.style.showDate).labelsHidden()
        }
        RowDivider()
        Row("Time") {
            Toggle("Time", isOn: $store.settings.style.showTime).labelsHidden()
        }
        if style.showTime, style.showWeekday || style.showDate {
            RowDivider()
            Row("Order") {
                Picker("Order", selection: $store.settings.style.order) {
                    Text("Date first").tag(ClockOrder.dateFirst)
                    Text("Time first").tag(ClockOrder.timeFirst)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 200)
            }
            RowDivider()
            Row("Between") {
                Picker("Between", selection: $store.settings.style.separator) {
                    ForEach(Separator.allCases, id: \.self) { separator in
                        Text(Self.separatorTitle(separator)).tag(separator)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
            }
        }
        if style.showTime {
            RowDivider()
            Row("24-hour time") {
                Toggle("24-hour time", isOn: $store.settings.style.use24Hour).labelsHidden()
            }
            if !style.use24Hour {
                RowDivider()
                Row("AM and PM") {
                    Picker("AM and PM", selection: $store.settings.style.meridiem) {
                        Text("PM").tag(Meridiem.upper)
                        Text("pm").tag(Meridiem.lower)
                        Text("None").tag(Meridiem.hidden)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 200)
                }
                RowDivider()
                Row("Leading zero", detail: "Shows 09:05 instead of 9:05.") {
                    Toggle("Leading zero", isOn: $store.settings.style.padHour).labelsHidden()
                }
            }
            RowDivider()
            Row("Seconds") {
                Toggle("Seconds", isOn: $store.settings.style.showSeconds).labelsHidden()
            }
        }
    }

    // patternMenu offers example patterns and the pattern letters to add to the custom pattern.
    private var patternMenu: some View {
        Menu {
            Section("Examples") {
                ForEach(Self.patternExamples, id: \.self) { example in
                    Button(Self.sample(pattern: example)) {
                        store.settings.style.customPattern = example
                    }
                }
            }
            Section("Add") {
                ForEach(Self.patternLetters, id: \.letters) { item in
                    Button(item.name + "  ·  " + Self.sample(pattern: item.letters)) {
                        addToPattern(item.letters)
                    }
                }
            }
        } label: {
            Image(systemName: "plus")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Examples and pattern letters")
    }

    // extrasCard holds the text or emoji shown before and after the clock.
    private var extrasCard: some View {
        Card("Before and after") {
            Row("Before", detail: "Text or emoji, e.g. Control-Command-Space.") {
                TextField("Before", text: $store.settings.style.prefix, prompt: Text("None"))
                    .textFieldStyle(.roundedBorder)
                    .labelsHidden()
                    .frame(width: 160)
            }
            RowDivider()
            Row("After") {
                TextField("After", text: $store.settings.style.suffix, prompt: Text("None"))
                    .textFieldStyle(.roundedBorder)
                    .labelsHidden()
                    .frame(width: 160)
            }
        }
    }

    // secondTimeCard holds the second time zone and its label.
    private var secondTimeCard: some View {
        Card("Second time") {
            Row("Time zone") {
                Picker("Time zone", selection: $store.settings.style.secondZone) {
                    Text("None").tag("")
                    Divider()
                    ForEach(Self.zones, id: \.self) { zone in
                        Text(zone.replacingOccurrences(of: "_", with: " ")).tag(zone)
                    }
                }
                .labelsHidden()
                .frame(width: 220)
            }
            if !store.settings.style.secondZone.isEmpty {
                RowDivider()
                Row("Label") {
                    TextField("Label", text: $store.settings.style.secondZoneLabel, prompt: Text("Zone abbreviation"))
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                        .frame(width: 160)
                }
            }
        }
    }

    // behaviorCard holds visibility and login.
    private var behaviorCard: some View {
        Card("Behavior") {
            Row("Show when the menu bar hides", detail: "Keeps the clock up in full screen apps.") {
                Toggle("Show when the menu bar hides", isOn: $store.settings.showWhenBarHidden).labelsHidden()
            }
            RowDivider()
            Row("Click the clock to open settings", detail: "When off, clicks pass through the clock.") {
                Toggle("Click the clock to open settings", isOn: $store.settings.clickOpensSettings).labelsHidden()
            }
            RowDivider()
            Row("Show menu bar icon", detail: menuIconDetail) {
                Toggle("Show menu bar icon", isOn: $store.settings.showMenuIcon).labelsHidden()
            }
            RowDivider()
            Row("Open at login", detail: loginDetail) {
                Toggle("Open at login", isOn: openAtLogin).labelsHidden()
            }
        }
    }

    // footer holds the version, reset, and quit.
    private var footer: some View {
        HStack {
            Text("Fuginaut \(Self.version)")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Restore Defaults") {
                store.reset()
            }
            Button("Quit Fuginaut") {
                NSApp.terminate(nil)
            }
        }
        .controlSize(.regular)
        .padding(.horizontal, 4)
    }

    // menuIconDetail tells how to get back to settings once the menu bar icon is hidden.
    private var menuIconDetail: String? {
        guard !store.settings.showMenuIcon else {
            return nil
        }
        return store.settings.clickOpensSettings
            ? "Click the clock to get back here."
            : "Open Fuginaut again from Applications to get back here."
    }

    // loginDetail explains a login item that needs approval or failed to change.
    private var loginDetail: String? {
        if let error = loginItem.lastError {
            return error
        }
        return loginItem.needsApproval ? "Allow Fuginaut in System Settings, under General, then Login Items." : nil
    }

    // version is the app's version from its bundle.
    private static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    // styleGroups orders the date styles for the style menu, one group per section.
    private static let styleGroups: [[DateStyle]] = [
        [.short, .long, .dayFirst, .dayFirstLong],
        [.withYear, .longWithYear, .dayFirstYear],
        [.numeric, .numericYear, .padded, .dotted, .slashedDayFirst],
        [.iso, .compactISO, .isoWeek, .dayOfYear],
        [.custom],
    ]

    // patternExamples are ready custom patterns, emoji included.
    private static let patternExamples = [
        "EEE d MMM  HH:mm",
        "EEEE '·' h:mm a",
        "h:mm a '·' MMMM d",
        "EEE d MMM yyyy  HH:mm",
        "HH:mm:ss zzz",
        "'Week' w '·' EEE HH:mm",
        "QQQ yyyy '·' HH:mm",
        "🚀 EEE d MMM  HH:mm",
        "⏰ h:mm a",
        "☕️ EEE h:mm a",
        "🌙 MMM d  HH:mm",
    ]

    // patternLetters names the common pattern letters for the add menu.
    private static let patternLetters: [(name: String, letters: String)] = [
        ("Weekday", "EEE"),
        ("Full weekday", "EEEE"),
        ("Day", "d"),
        ("Month", "MMM"),
        ("Full month", "MMMM"),
        ("Month number", "MM"),
        ("Year", "yyyy"),
        ("Short year", "yy"),
        ("Hour, 12-hour", "h"),
        ("Hour, 24-hour", "HH"),
        ("Minute", "mm"),
        ("Second", "ss"),
        ("AM or PM", "a"),
        ("Week of year", "w"),
        ("Day of year", "D"),
        ("Quarter", "QQQ"),
        ("Time zone", "zzz"),
        ("Quoted text", "'text'"),
    ]

    // dateStyle binds the style picker. Choosing custom for the first time starts the pattern from the style
    // on show, so editing begins from what the clock already reads.
    private var dateStyle: Binding<DateStyle> {
        Binding {
            store.settings.style.dateStyle
        } set: { next in
            var style = store.settings.style
            if next == .custom, style.dateStyle != .custom, style.customPattern == ClockStyle.defaultCustomPattern {
                style.customPattern = style.pattern(locale: .current)
            }
            style.dateStyle = next
            store.settings.style = style
        }
    }

    // addToPattern adds pattern letters to the end of the custom pattern, after a space.
    private func addToPattern(_ letters: String) {
        var pattern = store.settings.style.customPattern
        if !pattern.isEmpty, !pattern.hasSuffix(" ") {
            pattern += " "
        }
        store.settings.style.customPattern = pattern + letters
    }

    // sample formats the current time with a pattern.
    private static func sample(pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = pattern
        return formatter.string(from: Date())
    }

    // separatorTitle names what sits between the day and the time.
    private static func separatorTitle(_ separator: Separator) -> String {
        switch separator {
        case .spaces: "Two spaces"
        case .dot: "Dot  ·"
        case .bar: "Bar  |"
        case .comma: "Comma  ,"
        case .slash: "Slash  /"
        case .dash: "Dash  -"
        case .at: "The word at"
        }
    }

    // styleTitle names a date style with an example from today.
    private static func styleTitle(_ style: DateStyle) -> String {
        guard style != .custom else {
            return "Custom pattern"
        }
        var sample = ClockStyle()
        sample.dateStyle = style
        sample.showTime = false
        let name: String =
            switch style {
            case .short: "Short"
            case .long: "Long"
            case .dayFirst: "Day first"
            case .dayFirstLong: "Day first, long"
            case .withYear: "With year"
            case .longWithYear: "Long with year"
            case .dayFirstYear: "Day first with year"
            case .numeric: "Numeric"
            case .numericYear: "Numeric with year"
            case .padded: "Numeric, padded"
            case .dotted: "Dotted"
            case .slashedDayFirst: "Numeric, day first"
            case .iso: "ISO"
            case .compactISO: "Compact ISO"
            case .isoWeek: "ISO week"
            case .dayOfYear: "Day of year"
            case .custom: "Custom"
            }
        return name + "  ·  " + ClockFormatter(style: sample).string(Date())
    }

    // familyChoices lists installed families, plus the chosen one if it is no longer installed.
    private var familyChoices: [String] {
        let chosen = store.settings.fontFamily
        if store.settings.fontDesign == .family, !chosen.isEmpty, !Self.families.contains(chosen) {
            return [chosen] + Self.families
        }
        return Self.families
    }

    // fontChoice binds the font picker to the design and family, tagging families as "family:<name>".
    private var fontChoice: Binding<String> {
        Binding {
            let s = store.settings
            return s.fontDesign == .family ? "family:" + s.fontFamily : s.fontDesign.rawValue
        } set: { tag in
            var s = store.settings
            if tag.hasPrefix("family:") {
                s.fontDesign = .family
                s.fontFamily = String(tag.dropFirst("family:".count))
            } else {
                s.fontDesign = FontDesign(rawValue: tag) ?? .system
            }
            store.settings = s
        }
    }

    // whole binds a slider to a setting rounded to whole points, without the tick marks a step draws.
    private func whole(_ key: WritableKeyPath<FuginautCore.Settings, Double>) -> Binding<Double> {
        Binding {
            store.settings[keyPath: key]
        } set: { value in
            store.settings[keyPath: key] = value.rounded()
        }
    }

    // shown binds a display's switch to whether it shows the clock, recording a flip as the user's choice.
    private func shown(_ display: Display, external: Bool) -> Binding<Bool> {
        Binding {
            store.settings.shows(display.uuid, builtIn: display.builtIn, externalConnected: external)
        } set: { on in
            store.settings.displays[display.uuid] = on
        }
    }

    // matchSystem binds the switch to whether the color follows the system. Turning it off starts from white.
    private var matchSystem: Binding<Bool> {
        Binding {
            store.settings.color == nil
        } set: { on in
            store.settings.color = on ? nil : RGBA(red: 1, green: 1, blue: 1)
        }
    }

    // automaticBacking binds the switch to whether the backing contrasts on its own. Turning it off starts from
    // the automatic color at full strength.
    private var automaticBacking: Binding<Bool> {
        Binding {
            store.settings.backingColor == nil
        } set: { on in
            let light = store.settings.color?.isLight ?? true
            store.settings.backingColor =
                on ? nil : (light ? RGBA(red: 0, green: 0, blue: 0) : RGBA(red: 1, green: 1, blue: 1))
        }
    }

    // openAtLogin binds the switch to the login item registration.
    private var openAtLogin: Binding<Bool> {
        Binding {
            loginItem.isEnabled || loginItem.needsApproval
        } set: { on in
            loginItem.setEnabled(on)
        }
    }
}

// Card groups rows under a heading on a rounded panel, like System Settings.
struct Card<Content: View>: View {
    // title is the heading above the panel.
    let title: String
    // content is the rows inside the panel.
    @ViewBuilder let content: Content

    // init builds a card from a heading and its rows.
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    // body draws the heading and the panel.
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.primary.opacity(0.09))
            )
        }
    }
}

// Row is one line of a card: a title with an optional detail line, and a control on the right.
struct Row<Control: View>: View {
    // title names the setting.
    let title: String
    // detail explains the setting in a smaller line, or is nil for none.
    let detail: String?
    // control changes the setting.
    @ViewBuilder let control: Control

    // init builds a row from a title, an optional detail, and its control.
    init(_ title: String, detail: String? = nil, @ViewBuilder control: () -> Control) {
        self.title = title
        self.detail = detail
        self.control = control()
    }

    // body draws the title on the left and the control on the right.
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            control
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: 38)
    }
}

// RowDivider separates rows inside a card, inset from the leading edge.
struct RowDivider: View {
    // body draws the hairline.
    var body: some View {
        Divider().padding(.leading, 12)
    }
}

// ResetButton is a small borderless button that puts one setting back to its default.
struct ResetButton: View {
    // disabled dims the button when the setting is already at its default.
    let disabled: Bool
    // action restores the default.
    let action: () -> Void

    // body draws the arrow.
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.counterclockwise")
        }
        .buttonStyle(.borderless)
        .disabled(disabled)
        .help("Reset")
    }
}
