import SwiftUI

struct BPMPanelView: View {
    @Binding var bpm: Int
    var body: some View { Text("BPM: \(bpm)") }
}
