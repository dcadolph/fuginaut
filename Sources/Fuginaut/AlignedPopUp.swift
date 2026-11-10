import AppKit
import SwiftUI

// AlignedPopUpEntry is one row of an AlignedPopUp: a name on the left, an example on the right, or a divider.
struct AlignedPopUpEntry<Value: Hashable>: Identifiable {
    // value is what choosing the row selects, or nil for a divider.
    let value: Value?
    // name is the left column.
    let name: String
    // example is the right column, or empty when the row has none.
    let example: String

    // id identifies the row.
    var id: String { value == nil ? "divider-\(name)" : "\(name)|\(example)" }
}

// AlignedPopUp is a pop-up menu whose rows line up in two columns: names flush left and examples flush right.
struct AlignedPopUp<Value: Hashable>: NSViewRepresentable {
    // entries lists the rows in menu order.
    let entries: [AlignedPopUpEntry<Value>]
    // selection is the chosen value.
    @Binding var selection: Value
    // width is the width of the closed button.
    let width: CGFloat

    // tabStop is where the right-aligned example column ends, in points.
    private static var tabStop: CGFloat { 330 }

    // makeCoordinator creates the object that receives menu choices.
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // makeNSView builds the pop-up button.
    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.target = context.coordinator
        button.action = #selector(Coordinator.chose(_:))
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }

    // updateNSView rebuilds the menu and shows the current choice.
    func updateNSView(_ button: NSPopUpButton, context: Context) {
        context.coordinator.set = { selection = $0 }
        context.coordinator.values = entries.map(\.value)
        button.removeAllItems()
        let paragraph = NSMutableParagraphStyle()
        paragraph.tabStops = [NSTextTab(textAlignment: .right, location: Self.tabStop)]
        let font = NSFont.menuFont(ofSize: 0)
        let muted = NSColor.secondaryLabelColor
        for entry in entries {
            guard entry.value != nil else {
                button.menu?.addItem(.separator())
                continue
            }
            let item = NSMenuItem(title: entry.name, action: nil, keyEquivalent: "")
            let text = NSMutableAttributedString(
                string: entry.name, attributes: [.font: font, .paragraphStyle: paragraph])
            if !entry.example.isEmpty {
                text.append(
                    NSAttributedString(
                        string: "\t" + entry.example,
                        attributes: [.font: font, .foregroundColor: muted, .paragraphStyle: paragraph]))
            }
            item.attributedTitle = text
            button.menu?.addItem(item)
        }
        if let index = entries.firstIndex(where: { $0.value == selection }) {
            button.selectItem(at: index)
        }
        button.frame.size.width = width
    }

    // sizeThatFits keeps the button at the requested width.
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSPopUpButton, context: Context) -> CGSize? {
        CGSize(width: width, height: nsView.intrinsicContentSize.height)
    }

    // Coordinator receives the chosen row and reports its value.
    final class Coordinator: NSObject {
        // values holds each row's value in menu order, nil for dividers.
        var values: [Value?] = []
        // set stores a chosen value.
        var set: (Value) -> Void = { _ in }

        // chose reports the chosen row.
        @MainActor @objc func chose(_ sender: NSPopUpButton) {
            let index = sender.indexOfSelectedItem
            if values.indices.contains(index), let value = values[index] {
                set(value)
            }
        }
    }
}
