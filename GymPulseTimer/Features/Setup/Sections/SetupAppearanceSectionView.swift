import SwiftUI

struct SetupAppearanceSectionView: View {
    @Binding var selectedTheme: AppTheme

    var body: some View {
        SetupSectionCard("Appearance") {
            Picker("Appearance", selection: $selectedTheme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.title).tag(theme)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
