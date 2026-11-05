import AppKit
import SwiftUI

import FuginautCore

// ColorChooser picks a color three ways: a grid of swatches, a hex field, and the system color wheel. A nil
// color means automatic, so no swatch is marked and the hex field is empty until the user picks one.
struct ColorChooser: View {
    // color is the chosen color, or nil for automatic.
    @Binding var color: RGBA?
    // fallback is the color the wheel opens on while the color is automatic.
    var fallback: RGBA

    // hex is the text in the hex field.
    @State private var hex = ""
    // invalid marks hex text that is not a color, after the user commits it.
    @State private var invalid = false
    // hexFocused tracks the hex field, so leaving it commits the text.
    @FocusState private var hexFocused: Bool

    // columns is the number of swatches in each row.
    static let columns = 12
    // swatchSide is a swatch's diameter, in points.
    static let swatchSide: CGFloat = 22

    // body draws the swatch grid over the hex field and the wheel.
    var body: some View {
        VStack(spacing: 0) {
            swatchGrid
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            RowDivider()
            Row("Hex", detail: invalid ? "Use #RGB, #RRGGBB, or #RRGGBBAA." : nil) {
                HStack(spacing: 10) {
                    TextField("Hex", text: $hex, prompt: Text("Automatic"))
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                        .frame(width: 120)
                        .focused($hexFocused)
                        .onSubmit(commit)
                    ColorPicker("Color wheel", selection: wheel, supportsOpacity: true)
                        .labelsHidden()
                        .help("Open the color wheel")
                }
            }
        }
        .onAppear {
            hex = color?.hex ?? ""
        }
        .onChange(of: color) { _, new in
            hex = new?.hex ?? ""
            invalid = false
        }
        .onChange(of: hexFocused) { _, focused in
            if !focused {
                commit()
            }
        }
    }

    // swatchGrid lays the swatches out in rows, marking the chosen one.
    private var swatchGrid: some View {
        let rows = stride(from: 0, to: RGBA.swatches.count, by: Self.columns).map {
            Array(RGBA.swatches[$0..<min($0 + Self.columns, RGBA.swatches.count)])
        }
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(rows[row], id: \.hex) { swatch in
                        Swatch(color: swatch, selected: swatch == color, side: Self.swatchSide) {
                            color = swatch
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // wheel binds the system color wheel to the color, opening on the fallback while automatic.
    private var wheel: Binding<Color> {
        Binding {
            let c = color ?? fallback
            return Color(.sRGB, red: c.red, green: c.green, blue: c.blue, opacity: c.alpha)
        } set: { picked in
            guard let c = NSColor(picked).usingColorSpace(.sRGB) else {
                return
            }
            color = RGBA(red: c.redComponent, green: c.greenComponent, blue: c.blueComponent, alpha: c.alphaComponent)
        }
    }

    // commit applies the hex text. Empty text goes back to automatic, and text that is not a color is flagged
    // and left for the user to fix.
    private func commit() {
        let text = hex.trimmingCharacters(in: .whitespaces)
        if text.isEmpty {
            color = nil
            invalid = false
            return
        }
        guard let parsed = RGBA(hex: text) else {
            invalid = true
            return
        }
        invalid = false
        color = parsed
        hex = parsed.hex
    }
}

// Swatch is one round color button, ringed in the accent color when chosen.
struct Swatch: View {
    // color is the swatch's color.
    let color: RGBA
    // selected rings the swatch as the current choice.
    let selected: Bool
    // side is the swatch's diameter, in points.
    let side: CGFloat
    // action picks the swatch.
    let action: () -> Void

    // body draws the dot with a hairline edge, so white and black read on either window background.
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(.sRGB, red: color.red, green: color.green, blue: color.blue, opacity: color.alpha))
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.18)))
                .frame(width: side, height: side)
                .padding(3)
                .overlay(Circle().strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(color.hex)
        .accessibilityLabel(color.hex)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
