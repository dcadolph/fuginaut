import AppKit
import SwiftUI

import FuginautCore

// ClockPreview shows the clock as it will look, on a made-up menu bar over a made-up wallpaper.
struct ClockPreview: View {
    // settings is the look to preview.
    let settings: FuginautCore.Settings
    // dark draws a dark menu bar instead of a light one.
    @Binding var dark: Bool
    // date pins the time shown, for stills. Nil shows the live time.
    var date: Date?

    // height is the preview's height in points.
    static let height: CGFloat = 92
    // screenWidth is the width of the main display, which the preview's width stands for when scaling the
    // nudge.
    private static let screenWidth = NSScreen.main?.frame.width ?? 1512

    // body draws the wallpaper, the bar, and the appearance switch.
    var body: some View {
        Group {
            if let date {
                scene(date)
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    scene(context.date)
                }
            }
        }
        .frame(height: Self.height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.primary.opacity(0.12))
        )
    }

    // scene lays out one frame of the preview at a moment.
    private func scene(_ now: Date) -> some View {
        ZStack(alignment: .bottom) {
            wallpaper
            GeometryReader { geo in
                bar(now, width: geo.size.width)
            }
            HStack {
                Label("Live preview", systemImage: "eye")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .frame(height: 20)
                    .background(Capsule().fill(.black.opacity(0.28)))
                Spacer()
                appearanceSwitch
            }
            .padding(10)
        }
    }

    // wallpaper is a flat two-tone split on a hard diagonal in the astronaut's suit cream and space black:
    // black over cream for the dark bar, cream over black for the light one, so the translucent bar keeps
    // its own tone.
    private var wallpaper: some View {
        let cream = Color(red: 0.96, green: 0.94, blue: 0.90)
        let space = Color(red: 0.04, green: 0.04, blue: 0.05)
        let top = dark ? space : cream
        let bottom = dark ? cream : space
        return ZStack {
            top
            DiagonalSplit().fill(bottom)
        }
    }

    // appearanceSwitch flips the preview between a light and a dark menu bar.
    private var appearanceSwitch: some View {
        Button {
            dark.toggle()
        } label: {
            Image(systemName: dark ? "moon.fill" : "sun.max.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 20)
                .background(Capsule().fill(.black.opacity(0.28)))
        }
        .buttonStyle(.plain)
        .help(dark ? "Preview a light menu bar" : "Preview a dark menu bar")
    }

    // bar draws the menu bar strip with faint stand-ins for menus and status items, so the clock is the only
    // real text on it.
    private func bar(_ now: Date, width: CGFloat) -> some View {
        let height = NSStatusBar.system.thickness
        let ink = dark ? Color.white : Color.black
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(dark ? Color.black.opacity(0.32) : Color.white.opacity(0.5))
                .frame(height: height)
            HStack(spacing: 10) {
                ForEach(Array(Self.menuWidths.enumerated()), id: \.offset) { _, menu in
                    Capsule().frame(width: menu, height: 6)
                }
            }
            .foregroundStyle(ink.opacity(0.22))
            .padding(.leading, 14)
            .frame(height: height)
            HStack(spacing: 10) {
                Image(nsImage: EclipseGlyph.image())
                    .renderingMode(.template)
                    .foregroundStyle(ink.opacity(0.75))
                ForEach(Array(Self.statusWidths.enumerated()), id: \.offset) { _, item in
                    Capsule().frame(width: item, height: 6)
                }
                .foregroundStyle(ink.opacity(0.22))
            }
            .frame(width: width - 14, height: height, alignment: .trailing)
            clock(now, width: width, barHeight: height)
        }
        .frame(width: width, alignment: .topLeading)
    }

    // menuWidths are the widths of the stand-ins for the app menus on the left.
    private static let menuWidths: [CGFloat] = [12, 34, 20, 22, 24]
    // statusWidths are the widths of the stand-ins for the status items and Apple's clock on the right.
    private static let statusWidths: [CGFloat] = [14, 18, 54]

    // clock draws the clock text at the place the real panel would sit, scaled to the preview's width.
    private func clock(_ now: Date, width: CGFloat, barHeight: CGFloat) -> some View {
        let text = ClockFormatter(style: settings.style).string(now)
        let font = ClockLook.font(settings)
        let measured = (text as NSString).size(withAttributes: [.font: font])
        let size = CGSize(width: ceil(measured.width), height: ceil(measured.height))
        let strip = Bar(frame: CGRect(x: 0, y: 0, width: width, height: max(barHeight, size.height)), height: barHeight)
        let offset = settings.offset * width / Self.screenWidth
        let panel =
            Placement.frame(bar: strip, text: size, offset: offset)
            ?? CGRect(x: 0, y: 0, width: size.width + Placement.padding * 2, height: barHeight)
        let textBottom = Placement.textY(barHeight: barHeight, textHeight: size.height)
        let textRect = CGRect(x: Placement.padding, y: textBottom, width: size.width, height: size.height)
        let pill = Placement.pill(panel: CGRect(origin: .zero, size: panel.size), text: textRect)
        let textColor = Color(nsColor: ClockLook.textColor(settings, dark: dark))
        let backing = Color(nsColor: ClockLook.backingColor(settings, dark: dark))
        return ZStack(alignment: .topLeading) {
            if settings.backing == .pill {
                Capsule()
                    .fill(backing.opacity(ClockLook.pillAlpha))
                    .frame(width: pill.width, height: pill.height)
                    .offset(x: pill.minX, y: panel.height - pill.maxY)
            }
            Text(text)
                .font(Font(font))
                .foregroundStyle(textColor)
                .fixedSize()
                .shadow(
                    color: settings.backing == .shadow ? backing.opacity(ClockLook.shadowAlpha) : .clear,
                    radius: ClockLook.shadowBlur / 2
                )
                .offset(x: textRect.minX, y: panel.height - textRect.maxY)
        }
        .frame(width: panel.width, height: panel.height, alignment: .topLeading)
        .offset(x: panel.minX)
    }

}

// DiagonalSplit is the lower part of a rectangle cut by a line rising from left to right.
struct DiagonalSplit: Shape {
    // path fills below the line from 80 percent down the left edge to 35 percent down the right edge.
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.8))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.35))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
