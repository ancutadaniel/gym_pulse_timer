import SwiftUI

struct SetupView: View {
    @EnvironmentObject private var presetStore: PresetStore
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue
    @StateObject private var audioCueManager = AudioCueManager()

    @State private var selectedPresetId: UUID?
    @State private var presetName: String
    @State private var getReadySeconds: Int
    @State private var workSeconds: Int
    @State private var restSeconds: Int
    @State private var sets: Int
    @State private var rounds: Int
    @State private var soundEnabled: Bool
    @State private var voiceEnabled: Bool
    @State private var isSaveAlertPresented = false
    @State private var draftPresetName = ""
    @State private var isRenameAlertPresented = false
    @State private var presetToRename: Preset?
    @State private var draftRename = ""
    @State private var isAudioPreviewSuppressed = false

    init(preset: Preset = Preset.makeDefault()) {
        _selectedPresetId = State(initialValue: preset.id)
        _presetName = State(initialValue: preset.name)
        _getReadySeconds = State(initialValue: preset.getReadySeconds)
        _workSeconds = State(initialValue: preset.workSeconds)
        _restSeconds = State(initialValue: preset.restSeconds)
        _sets = State(initialValue: preset.sets)
        _rounds = State(initialValue: preset.rounds)
        _soundEnabled = State(initialValue: preset.soundEnabled)
        _voiceEnabled = State(initialValue: preset.voiceEnabled)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SetupIntervalsSectionView(getReadySeconds: $getReadySeconds,
                                          workSeconds: $workSeconds,
                                          restSeconds: $restSeconds,
                                          dividerColor: sectionDividerColor)
                SetupWorkoutStructureSectionView(sets: $sets,
                                                 rounds: $rounds,
                                                 dividerColor: sectionDividerColor)
                SetupAudioSectionView(soundEnabled: $soundEnabled,
                                      voiceEnabled: $voiceEnabled,
                                      dividerColor: sectionDividerColor)
                SetupAppearanceSectionView(selectedTheme: selectedTheme)
                SetupPresetsSectionView(presets: presetStore.presets,
                                        selectedPresetId: selectedPresetId,
                                        dividerColor: sectionDividerColor,
                                        onSelect: selectPreset,
                                        onRename: startRename,
                                        onDelete: deletePreset,
                                        onSave: presentSaveAlert)
                startWorkoutButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .alert("Save Preset", isPresented: $isSaveAlertPresented) {
            TextField("Preset name", text: $draftPresetName)
            Button("Save") {
                savePreset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Name your preset to save it.")
        }
        .alert("Rename Preset", isPresented: $isRenameAlertPresented) {
            TextField("Preset name", text: $draftRename)
            Button("Save") {
                applyRename()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Update the preset name.")
        }
        .onAppear {
            audioCueManager.updatePreferences(soundEnabled: soundEnabled,
                                              voiceEnabled: voiceEnabled)
        }
        .onChange(of: soundEnabled) { newValue in
            audioCueManager.updatePreferences(soundEnabled: newValue,
                                              voiceEnabled: voiceEnabled)
            if newValue, !isAudioPreviewSuppressed {
                audioCueManager.previewSound()
            }
        }
        .onChange(of: voiceEnabled) { newValue in
            audioCueManager.updatePreferences(soundEnabled: soundEnabled,
                                              voiceEnabled: newValue)
            if newValue, !isAudioPreviewSuppressed {
                audioCueManager.previewVoice()
            }
        }
    }

    private var startWorkoutButton: some View {
        NavigationLink {
            RunView(preset: currentPreset)
                .toolbar(.hidden, for: .navigationBar)
        } label: {
            Text("Start Workout")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var sectionDividerColor: Color {
        Color.secondary.opacity(0.2)
    }

    private var selectedTheme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: appThemeRaw) ?? .system },
            set: { appThemeRaw = $0.rawValue }
        )
    }

    private var currentPreset: Preset {
        Preset(
            id: selectedPresetId ?? UUID(),
            name: presetName,
            getReadySeconds: getReadySeconds,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            sets: sets,
            rounds: rounds,
            soundEnabled: soundEnabled,
            voiceEnabled: voiceEnabled,
            updatedAt: Date()
        ).normalized()
    }

    private func selectPreset(_ preset: Preset) {
        selectedPresetId = preset.id
        applyPresetDetails(preset)
    }

    private func applyPresetDetails(_ preset: Preset) {
        isAudioPreviewSuppressed = true
        presetName = preset.name
        getReadySeconds = preset.getReadySeconds
        workSeconds = preset.workSeconds
        restSeconds = preset.restSeconds
        sets = preset.sets
        rounds = preset.rounds
        soundEnabled = preset.soundEnabled
        voiceEnabled = preset.voiceEnabled
        DispatchQueue.main.async {
            isAudioPreviewSuppressed = false
        }
    }

    private func startRename(_ preset: Preset) {
        presetToRename = preset
        draftRename = preset.name
        isRenameAlertPresented = true
    }

    private func applyRename() {
        guard let target = presetToRename else { return }
        presetStore.rename(id: target.id, to: draftRename)
        if target.id == selectedPresetId {
            presetName = Preset.normalizedName(draftRename)
        }
        presetToRename = nil
    }

    private func deletePreset(_ preset: Preset) {
        presetStore.delete(preset)
        if preset.id == selectedPresetId {
            selectedPresetId = nil
            applyPresetDetails(Preset.makeDefault())
        }
    }

    private func presentSaveAlert() {
        draftPresetName = presetName.isEmpty ? Preset.defaultName : presetName
        isSaveAlertPresented = true
    }

    private func savePreset() {
        let finalName = Preset.normalizedName(draftPresetName)
        let preset = Preset(
            id: selectedPresetId ?? UUID(),
            name: finalName,
            getReadySeconds: getReadySeconds,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            sets: sets,
            rounds: rounds,
            soundEnabled: soundEnabled,
            voiceEnabled: voiceEnabled,
            updatedAt: Date()
        ).normalized()

        presetStore.upsert(preset)
        selectedPresetId = preset.id
        presetName = preset.name
    }
}
