import SwiftUI
import UIKit

struct SegmentedPicker: UIViewRepresentable {
    @Binding var selection: Int
    let segments: [String]
    let selectedTint: UIColor
    let background: UIColor
    let selectedTextColor: UIColor
    let normalTextColor: UIColor

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: segments)
        control.selectedSegmentIndex = selection
        control.addTarget(context.coordinator,
                          action: #selector(Coordinator.changed(_:)),
                          for: .valueChanged)
        applyColors(to: control)
        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        if uiView.selectedSegmentIndex != selection {
            uiView.selectedSegmentIndex = selection
        }
        applyColors(to: uiView)
    }

    private func applyColors(to control: UISegmentedControl) {
        control.backgroundColor = background
        control.selectedSegmentTintColor = selectedTint
        // Setting tintColor to .clear removes the colored border ring on selection
        control.tintColor = .clear
        // Also clear divider images that can carry tint color
        let empty = UIImage()
        control.setDividerImage(empty, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
        control.setDividerImage(empty, forLeftSegmentState: .normal, rightSegmentState: .selected, barMetrics: .default)
        control.setDividerImage(empty, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        control.setTitleTextAttributes([.foregroundColor: selectedTextColor], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: normalTextColor], for: .normal)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject {
        var parent: SegmentedPicker
        init(_ parent: SegmentedPicker) { self.parent = parent }
        @objc func changed(_ sender: UISegmentedControl) {
            parent.selection = sender.selectedSegmentIndex
        }
    }
}
