import Foundation

// Weight names the clock's font weight.
public enum Weight: String, Codable, CaseIterable, Sendable {
    case regular
    case medium
    case semibold
    case bold
}

// FontDesign chooses the clock's typeface.
public enum FontDesign: String, Codable, CaseIterable, Sendable {
    // system is the menu bar's own font.
    case system
    // rounded is the system font with rounded ends.
    case rounded
    // mono is the system monospaced font.
    case mono
    // serif is the system serif font.
    case serif
    // family is an installed font family, named by Settings.fontFamily.
    case family
}

// Backing chooses what sits behind the clock text to keep it readable over busy wallpaper.
public enum Backing: String, Codable, CaseIterable, Sendable {
    // none draws the text alone.
    case none
    // shadow draws a soft glow in the contrasting color behind the text.
    case shadow
    // pill draws a rounded capsule in the contrasting color behind the text.
    case pill
}

// RGBA is a color in sRGB components from 0 to 1.
public struct RGBA: Codable, Equatable, Sendable {
    // red is the red component.
    public var red: Double
    // green is the green component.
    public var green: Double
    // blue is the blue component.
    public var blue: Double
    // alpha is the opacity.
    public var alpha: Double

    // init builds a color and clamps each component to the 0 to 1 range.
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = Self.clamp(red)
        self.green = Self.clamp(green)
        self.blue = Self.clamp(blue)
        self.alpha = Self.clamp(alpha)
    }

    // luminance is the color's relative luminance from 0 to 1, by the WCAG formula.
    public var luminance: Double {
        func linear(_ c: Double) -> Double {
            c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    // isLight reports whether the color reads as light, so a backing behind it should be dark.
    public var isLight: Bool {
        luminance > 0.179
    }

    // clamp limits a component to the 0 to 1 range.
    private static func clamp(_ v: Double) -> Double {
        min(1, max(0, v))
    }
}

// Settings holds everything the user can change.
public struct Settings: Codable, Equatable, Sendable {
    // fontSizes is the allowed range for fontSize.
    public static let fontSizes: ClosedRange<Double> = 9...40
    // offsets is the allowed range for offset, in points.
    public static let offsets: ClosedRange<Double> = -600...600

    // anchor is where the clock sits along the bar.
    public var anchor: Anchor = .center
    // offset moves the clock right from its anchor, in points. Negative moves it left.
    public var offset: Double = 0
    // fontSize is the clock's font size, in points.
    public var fontSize: Double = 13
    // weight is the clock's font weight.
    public var weight: Weight = .medium
    // fontDesign is the clock's typeface.
    public var fontDesign: FontDesign = .system
    // fontFamily names the installed family used when fontDesign is family.
    public var fontFamily = ""
    // backing is what sits behind the clock text.
    public var backing: Backing = .none
    // color is the clock's color, or nil to follow the system's text color.
    public var color: RGBA?
    // style chooses what the clock text shows.
    public var style = ClockStyle()
    // hiddenDisplays holds the UUIDs of displays that show no clock.
    public var hiddenDisplays: Set<String> = []
    // showWhenBarHidden keeps the clock up in full screen and when the menu bar hides itself.
    public var showWhenBarHidden = false
    // showMenuIcon shows the menu bar icon that opens settings.
    public var showMenuIcon = true

    // init builds the default settings.
    public init() {}

    // init decodes settings, fills keys they lack with defaults, and clamps numbers to their ranges.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Settings()
        anchor = try c.decodeIfPresent(Anchor.self, forKey: .anchor) ?? d.anchor
        offset = try c.decodeIfPresent(Double.self, forKey: .offset) ?? d.offset
        fontSize = try c.decodeIfPresent(Double.self, forKey: .fontSize) ?? d.fontSize
        weight = try c.decodeIfPresent(Weight.self, forKey: .weight) ?? d.weight
        fontDesign = try c.decodeIfPresent(FontDesign.self, forKey: .fontDesign) ?? d.fontDesign
        fontFamily = try c.decodeIfPresent(String.self, forKey: .fontFamily) ?? d.fontFamily
        backing = try c.decodeIfPresent(Backing.self, forKey: .backing) ?? d.backing
        color = try c.decodeIfPresent(RGBA.self, forKey: .color)
        style = try c.decodeIfPresent(ClockStyle.self, forKey: .style) ?? d.style
        hiddenDisplays = try c.decodeIfPresent(Set<String>.self, forKey: .hiddenDisplays) ?? d.hiddenDisplays
        showWhenBarHidden = try c.decodeIfPresent(Bool.self, forKey: .showWhenBarHidden) ?? d.showWhenBarHidden
        showMenuIcon = try c.decodeIfPresent(Bool.self, forKey: .showMenuIcon) ?? d.showMenuIcon
        offset = min(Self.offsets.upperBound, max(Self.offsets.lowerBound, offset))
        fontSize = min(Self.fontSizes.upperBound, max(Self.fontSizes.lowerBound, fontSize))
    }
}
