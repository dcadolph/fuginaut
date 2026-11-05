import AppKit
import CoreText

import FuginautCore

// ClockLook turns settings into the font and colors the clock draws with, so the real clock and the
// settings preview always match.
enum ClockLook {
    // pillAlpha is the opacity of the automatic pill behind the text.
    static let pillAlpha: CGFloat = 0.42
    // shadowAlpha is the opacity of the automatic glow behind the text.
    static let shadowAlpha: CGFloat = 0.85
    // shadowBlur is the glow's blur radius, in points.
    static let shadowBlur: CGFloat = 3

    // font returns the clock font, with digits of equal width so the text does not jitter as it ticks.
    static func font(_ settings: Settings) -> NSFont {
        let size = settings.fontSize
        let weight = weight(settings.weight)
        let base: NSFont
        switch settings.fontDesign {
        case .system:
            return .monospacedDigitSystemFont(ofSize: size, weight: weight)
        case .mono:
            return .monospacedSystemFont(ofSize: size, weight: weight)
        case .rounded:
            base = designed(.rounded, size: size, weight: weight)
        case .serif:
            base = designed(.serif, size: size, weight: weight)
        case .family:
            let manager = NSFontManager.shared
            let found = manager.font(
                withFamily: settings.fontFamily, traits: [], weight: managerWeight(settings.weight), size: size
            )
            guard let found else {
                return .monospacedDigitSystemFont(ofSize: size, weight: weight)
            }
            base = found
        }
        return evenDigits(base)
    }

    // textColor returns the clock's color for a light or dark menu bar.
    static func textColor(_ settings: Settings, dark: Bool) -> NSColor {
        guard let c = settings.color else {
            return dark ? .white : .black
        }
        return NSColor(srgbRed: c.red, green: c.green, blue: c.blue, alpha: c.alpha)
    }

    // backingColor returns the shadow or pill color for a light or dark menu bar. A chosen color is drawn as
    // picked, opacity and all. Otherwise it contrasts with the text at the automatic opacity.
    static func backingColor(_ settings: Settings, dark: Bool, automaticAlpha: CGFloat) -> NSColor {
        if let c = settings.backingColor {
            return NSColor(srgbRed: c.red, green: c.green, blue: c.blue, alpha: c.alpha)
        }
        let light = settings.color?.isLight ?? dark
        return (light ? NSColor.black : .white).withAlphaComponent(automaticAlpha)
    }

    // dynamicText returns the clock's color, following the menu bar's appearance when it has no fixed color.
    static func dynamicText(_ settings: Settings) -> NSColor {
        settings.color == nil ? .labelColor : textColor(settings, dark: true)
    }

    // dynamicBacking returns the backing color, resolved against whatever appearance draws it.
    static func dynamicBacking(_ settings: Settings, automaticAlpha: CGFloat) -> NSColor {
        NSColor(name: nil) { appearance in
            backingColor(settings, dark: isDark(appearance), automaticAlpha: automaticAlpha)
        }
    }

    // isDark reports whether an appearance is a dark one.
    static func isDark(_ appearance: NSAppearance) -> Bool {
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    // families returns every installed font family, sorted for a menu.
    static func families() -> [String] {
        NSFontManager.shared.availableFontFamilies.filter { !$0.hasPrefix(".") }.sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    // designed returns the system font in one of its alternate designs.
    private static func designed(_ design: NSFontDescriptor.SystemDesign, size: CGFloat, weight: NSFont.Weight)
        -> NSFont
    {
        let system = NSFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = system.fontDescriptor.withDesign(design) else {
            return system
        }
        return NSFont(descriptor: descriptor, size: size) ?? system
    }

    // evenDigits asks a font for equal width digits. Fonts without the feature keep their own digits.
    private static func evenDigits(_ font: NSFont) -> NSFont {
        let feature: [NSFontDescriptor.FeatureKey: Int] = [
            .typeIdentifier: kNumberSpacingType, .selectorIdentifier: kMonospacedNumbersSelector,
        ]
        let descriptor = font.fontDescriptor.addingAttributes([.featureSettings: [feature]])
        return NSFont(descriptor: descriptor, size: font.pointSize) ?? font
    }

    // weight maps a settings weight to a font weight.
    private static func weight(_ w: Weight) -> NSFont.Weight {
        switch w {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        }
    }

    // managerWeight maps a settings weight to the font manager's 0 to 15 weight scale.
    private static func managerWeight(_ w: Weight) -> Int {
        switch w {
        case .regular: 5
        case .medium: 6
        case .semibold: 8
        case .bold: 9
        }
    }
}
