import Foundation

// Weight names the clock's font weight.
public enum Weight: String, Codable, CaseIterable, Sendable {
    case regular
    case medium
    case semibold
    case bold
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
        color = try c.decodeIfPresent(RGBA.self, forKey: .color)
        style = try c.decodeIfPresent(ClockStyle.self, forKey: .style) ?? d.style
        hiddenDisplays = try c.decodeIfPresent(Set<String>.self, forKey: .hiddenDisplays) ?? d.hiddenDisplays
        showWhenBarHidden = try c.decodeIfPresent(Bool.self, forKey: .showWhenBarHidden) ?? d.showWhenBarHidden
        showMenuIcon = try c.decodeIfPresent(Bool.self, forKey: .showMenuIcon) ?? d.showMenuIcon
        offset = min(Self.offsets.upperBound, max(Self.offsets.lowerBound, offset))
        fontSize = min(Self.fontSizes.upperBound, max(Self.fontSizes.lowerBound, fontSize))
    }
}
