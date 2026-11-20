import Foundation

// ThemeColor is the color a Mac-wide theme draws the clock in. It sits over the user's own text color and, when
// it carries a backing, over the backing color with a pill behind the text. The user's settings never change.
public struct ThemeColor: Equatable, Sendable {
    // notificationName is the distributed notification a theme switcher posts. Its object is a ThemeMessage.
    public static let notificationName = "com.dcadolph.fuginaut.themeColor"

    // text is the clock's text color.
    public var text: RGBA
    // backing is the pill color behind the text, or nil to keep the user's own backing.
    public var backing: RGBA?

    // init builds a theme color.
    public init(text: RGBA, backing: RGBA? = nil) {
        self.text = text
        self.backing = backing
    }

    // message formats the theme color the way a theme switcher sends it, so it can be read back later.
    public var message: String {
        guard let backing else {
            return text.hex
        }
        return text.hex + " " + backing.hex
    }

    // applied returns the settings to draw: the user's settings with the theme's text color and, when the theme
    // carries a backing, its backing color drawn as a pill.
    public func applied(to settings: Settings) -> Settings {
        var drawn = settings
        drawn.color = text
        if let backing {
            drawn.backingColor = backing
            drawn.backing = .pill
        }
        return drawn
    }
}

extension Settings {
    // drawn returns the settings to draw while a theme color is held, or the settings themselves without one.
    public func drawn(with theme: ThemeColor?) -> Settings {
        theme?.applied(to: self) ?? self
    }
}

// ThemeMessage is what a theme switcher's message asks for.
public enum ThemeMessage: Equatable, Sendable {
    // set draws the clock in a theme color.
    case set(ThemeColor)
    // clear puts back the user's own colors.
    case clear
    // junk is a message that cannot be read, which changes nothing.
    case junk

    // init reads a message: empty clears, #RRGGBB sets the text color, and a second #RRGGBB after a space sets
    // the backing color too. Anything else is junk.
    public init(_ message: String) {
        let parts = message.split(whereSeparator: \.isWhitespace).map(String.init)
        if parts.isEmpty {
            self = .clear
            return
        }
        let colors = parts.compactMap(Self.color)
        guard parts.count <= 2, colors.count == parts.count else {
            self = .junk
            return
        }
        self = .set(ThemeColor(text: colors[0], backing: colors.count > 1 ? colors[1] : nil))
    }

    // updating returns the theme color to hold after this message arrives while current is held.
    public func updating(_ current: ThemeColor?) -> ThemeColor? {
        switch self {
        case .set(let color): color
        case .clear: nil
        case .junk: current
        }
    }

    // color parses one #RRGGBB color, or returns nil for any other form.
    private static func color(_ part: String) -> RGBA? {
        guard part.count == 7, part.hasPrefix("#") else {
            return nil
        }
        return RGBA(hex: part)
    }
}
