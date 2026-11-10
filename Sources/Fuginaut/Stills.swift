import AppKit
import SwiftUI

import FuginautCore

// Stills renders design checks to PNG offscreen, so no real screen is ever captured.
@MainActor
enum Stills {
    // argument is the launch argument that renders the stills into a directory instead of running the app.
    static let argument = "--render-stills"

    // run writes every still into dir and returns a process exit code.
    static func run(dir: String) -> Int32 {
        let out = URL(fileURLWithPath: dir, isDirectory: true)
        let glyphs: [(name: String, bar: NSColor, ink: NSColor, scale: CGFloat)] = [
            ("glyph-dark@2x.png", NSColor(white: 0.12, alpha: 1), .white, 2),
            ("glyph-light@2x.png", NSColor(white: 0.93, alpha: 1), .black, 2),
            ("glyph-dark@12x.png", NSColor(white: 0.12, alpha: 1), .white, 12),
            ("glyph-light@12x.png", NSColor(white: 0.93, alpha: 1), .black, 12),
        ]
        for glyph in glyphs {
            let image = glyphStrip(bar: glyph.bar, ink: glyph.ink, scale: glyph.scale)
            let url = out.appendingPathComponent(glyph.name)
            guard let image, write(image, to: url) else {
                FileHandle.standardError.write(Data("still failed: \(url.path)\n".utf8))
                return 1
            }
        }
        return settingsStills(out: out)
    }

    // settingsStills writes the settings window for every tab in light and dark, with made-up settings and a
    // fixed time.
    private static func settingsStills(out: URL) -> Int32 {
        let date = Date(timeIntervalSince1970: 1_793_804_829)
        var looks: [SettingsTab: FuginautCore.Settings] = [:]
        for tab in SettingsTab.allCases {
            looks[tab] = FuginautCore.Settings()
        }
        looks[.text]?.fontDesign = .rounded
        looks[.color]?.color = RGBA(hex: "#FFAD1A")
        looks[.color]?.backing = .pill
        looks[.color]?.backingColor = RGBA(hex: "#1E3A5F")
        looks[.format]?.style.dateStyle = .withYear
        looks[.format]?.style.separator = .dot
        looks[.format]?.style.meridiem = .lower
        looks[.format]?.style.prefix = "🚀"
        looks[.world]?.style.numerals = .devanagari
        looks[.world]?.style.calendar = .gregorian
        looks[.world]?.style.secondZone = "Asia/Tokyo"
        looks[.world]?.style.secondZoneLabel = "TYO"
        let login = LoginItem()
        let astronaut = NSImage(contentsOfFile: "art/astronaut.png")
        for tab in SettingsTab.allCases {
            for dark in [false, true] {
                let store = SettingsStore(fixture: looks[tab] ?? FuginautCore.Settings())
                let view = SettingsView(
                    store: store, loginItem: login,
                    tab: tab, previewDark: dark, previewDate: date, astronaut: astronaut
                )
                let name = "settings-\(tab.rawValue)-\(dark ? "dark" : "light").png"
                let url = out.appendingPathComponent(name)
                guard let image = snapshot(view, dark: dark), write(image, to: url) else {
                    FileHandle.standardError.write(Data("still failed: \(url.path)\n".utf8))
                    return 1
                }
            }
        }
        return 0
    }

    // snapshot draws a view in a window that is never shown, so AppKit controls render as they do on screen,
    // which ImageRenderer cannot do.
    private static func snapshot(_ view: some View, dark: Bool) -> CGImage? {
        let appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        let host = NSHostingView(rootView: view)
        host.appearance = appearance
        let size = host.fittingSize
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false
        )
        window.appearance = appearance
        window.contentView = host
        host.frame = NSRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        host.layoutSubtreeIfNeeded()
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else {
            return nil
        }
        host.cacheDisplay(in: host.bounds, to: rep)
        return rep.cgImage
    }

    // glyphStrip draws the template glyph tinted with ink on a menu bar colored strip, as macOS would.
    private static func glyphStrip(bar: NSColor, ink: NSColor, scale: CGFloat) -> CGImage? {
        let points = NSSize(width: 44, height: 24)
        let pixels = NSSize(width: points.width * scale, height: points.height * scale)
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(pixels.width), pixelsHigh: Int(pixels.height),
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
            )
        else {
            return nil
        }
        rep.size = points
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        bar.setFill()
        NSRect(origin: .zero, size: points).fill()
        let tinted = NSImage(size: EclipseGlyph.size, flipped: false) { rect in
            EclipseGlyph.draw(in: rect)
            ink.setFill()
            rect.fill(using: .sourceAtop)
            return true
        }
        let origin = NSPoint(
            x: (points.width - EclipseGlyph.size.width) / 2, y: (points.height - EclipseGlyph.size.height) / 2
        )
        tinted.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1)
        NSGraphicsContext.restoreGraphicsState()
        return rep.cgImage
    }

    // write saves an image as PNG.
    static func write(_ image: CGImage, to url: URL) -> Bool {
        guard let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            return false
        }
        return (try? data.write(to: url)) != nil
    }
}
