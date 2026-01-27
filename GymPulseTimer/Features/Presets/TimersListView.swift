import SwiftUI

struct TimersListView: View {
    @EnvironmentObject private var presetStore: PresetStore
    @State private var editingPreset: Preset?

    var body: some View {
        List {
            if presetStore.presets.isEmpty {
                VStack(alignment: .center, spacing: 12) {
                    Text("No timers yet")
                        .font(.headline)
                    Text("Create a preset to get started.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
                .listRowSeparator(.hidden)
            } else {
                ForEach(presetStore.presets) { preset in
                    NavigationLink {
                        RunView(preset: preset)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name)
                                .font(.headline)
                            Text(preset.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            editingPreset = preset
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
                .onDelete { offsets in
                    presetStore.delete(at: offsets)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Timers")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editingPreset = Preset.makeDefault()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingPreset) { preset in
            SetupView(preset: preset)
        }
    }
}
