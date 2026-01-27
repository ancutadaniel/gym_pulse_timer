import SwiftUI

struct SetupAudioSectionView: View {
    @Binding var soundEnabled: Bool
    @Binding var voiceEnabled: Bool
    let dividerColor: Color

    var body: some View {
        SetupSectionCard("Audio") {
            Toggle("Sound", isOn: $soundEnabled)
                .tint(.green)
            Divider().background(dividerColor)
            Toggle("Voice (EN)", isOn: $voiceEnabled)
                .tint(.green)
        }
    }
}
