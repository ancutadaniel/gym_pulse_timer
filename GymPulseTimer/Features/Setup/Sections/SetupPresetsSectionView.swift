import SwiftUI

struct SetupPresetsSectionView: View {
    let presets: [Preset]
    let selectedPresetId: UUID?
    let dividerColor: Color
    let onSelect: (Preset) -> Void
    let onRename: (Preset) -> Void
    let onDelete: (Preset) -> Void
    let onSave: () -> Void

    var body: some View {
        SetupSectionCard("Presets") {
            VStack(alignment: .leading, spacing: 12) {
                if presets.isEmpty {
                    Text("No presets yet")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(presets) { preset in
                        presetRow(preset)
                        if preset.id != presets.last?.id {
                            Divider().background(dividerColor)
                        }
                    }
                }

                Divider().background(dividerColor)

                Button("Save Preset") {
                    onSave()
                }
                .font(.headline)
                .foregroundStyle(.blue)
            }
        }
    }

    private func presetRow(_ preset: Preset) -> some View {
        let isSelected = preset.id == selectedPresetId
        return Button {
            onSelect(preset)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(.headline)
                    Text(preset.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.18) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Rename") {
                onRename(preset)
            }
            Button(role: .destructive) {
                onDelete(preset)
            } label: {
                Text("Delete")
            }
        }
    }
}
