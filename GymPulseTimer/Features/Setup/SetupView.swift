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
    @State private var isShowingSavePrompt = false
    @State private var pendingPresetName = ""
    @State private var isShowingRenamePrompt = false
    @State private var renameTarget: Preset?
    @State private var pendingRename = ""
    @State private var suppressAudioPreview = false

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
                sectionHeader("Intervals")

                CardView {
                    IntervalSection(title: "Get Ready",
                                    totalSeconds: $getReadySeconds,
                                    allowZero: true)

                    Divider().background(dividerColor)

                    IntervalSection(title: "Work",
                                    totalSeconds: $workSeconds,
                                    allowZero: false)

                    Divider().background(dividerColor)

                    IntervalSection(title: "Rest",
                                    totalSeconds: $restSeconds,
                                    allowZero: false)
                }

                sectionHeader("Structure")
                CardView {
                    StepperRow(title: "Sets",
                               value: $sets,
                               range: 1...TimerConfiguration.maxSetsRounds)
                    Divider().background(dividerColor)
                    StepperRow(title: "Rounds",
                               value: $rounds,
                               range: 1...TimerConfiguration.maxSetsRounds)
                }

                sectionHeader("Audio")
                CardView {
                    Toggle("Sound", isOn: $soundEnabled)
                        .tint(.green)
                    Divider().background(dividerColor)
                    Toggle("Voice (EN)", isOn: $voiceEnabled)
                        .tint(.green)
                }

                sectionHeader("Appearance")
                CardView {
                    Picker("Appearance", selection: selectedTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                sectionHeader("Presets")
                CardView {
                    presetsSection
                }

                NavigationLink {
                    RunView(preset: activePreset)
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
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .alert("Save Preset", isPresented: $isShowingSavePrompt) {
            TextField("Preset name", text: $pendingPresetName)
            Button("Save") {
                savePreset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Name your preset to save it.")
        }
        .alert("Rename Preset", isPresented: $isShowingRenamePrompt) {
            TextField("Preset name", text: $pendingRename)
            Button("Save") {
                commitRename()
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
            if newValue, !suppressAudioPreview {
                audioCueManager.previewSound()
            }
        }
        .onChange(of: voiceEnabled) { newValue in
            audioCueManager.updatePreferences(soundEnabled: soundEnabled,
                                              voiceEnabled: newValue)
            if newValue, !suppressAudioPreview {
                audioCueManager.previewVoice()
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
    }

    private var dividerColor: Color {
        Color.secondary.opacity(0.2)
    }

    private var selectedTheme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: appThemeRaw) ?? .system },
            set: { appThemeRaw = $0.rawValue }
        )
    }

    private var activePreset: Preset {
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

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if presetStore.presets.isEmpty {
                Text("No presets yet")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(presetStore.presets) { preset in
                    presetRow(preset)
                    if preset.id != presetStore.presets.last?.id {
                        Divider().background(dividerColor)
                    }
                }
            }

            Divider().background(dividerColor)

            Button("Save Preset") {
                showSavePrompt()
            }
            .font(.headline)
            .foregroundStyle(.blue)
        }
    }

    private func presetRow(_ preset: Preset) -> some View {
        let isSelected = preset.id == selectedPresetId
        return Button {
            applyPreset(preset)
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
                beginRename(preset)
            }
            Button(role: .destructive) {
                deletePreset(preset)
            } label: {
                Text("Delete")
            }
        }
    }

    private func applyPreset(_ preset: Preset) {
        selectedPresetId = preset.id
        applyPresetValues(preset)
    }

    private func applyPresetValues(_ preset: Preset) {
        suppressAudioPreview = true
        presetName = preset.name
        getReadySeconds = preset.getReadySeconds
        workSeconds = preset.workSeconds
        restSeconds = preset.restSeconds
        sets = preset.sets
        rounds = preset.rounds
        soundEnabled = preset.soundEnabled
        voiceEnabled = preset.voiceEnabled
        DispatchQueue.main.async {
            suppressAudioPreview = false
        }
    }

    private func beginRename(_ preset: Preset) {
        renameTarget = preset
        pendingRename = preset.name
        isShowingRenamePrompt = true
    }

    private func commitRename() {
        guard let target = renameTarget else { return }
        presetStore.rename(id: target.id, to: pendingRename)
        if target.id == selectedPresetId {
            presetName = Preset.normalizedName(pendingRename)
        }
        renameTarget = nil
    }

    private func deletePreset(_ preset: Preset) {
        presetStore.delete(preset)
        if preset.id == selectedPresetId {
            selectedPresetId = nil
            applyPresetValues(Preset.makeDefault())
        }
    }

    private func showSavePrompt() {
        pendingPresetName = presetName.isEmpty ? Preset.defaultName : presetName
        isShowingSavePrompt = true
    }

    private func savePreset() {
        let finalName = Preset.normalizedName(pendingPresetName)
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

private struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct IntervalSection: View {
    let title: String
    @Binding var totalSeconds: Int
    let allowZero: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            TimeWheelPicker(totalSeconds: $totalSeconds, allowZero: allowZero)
        }
        .padding(.vertical, 4)
    }
}

private struct StepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(.secondary)
            StepperPill(value: $value, range: range)
                .padding(.leading, 8)
        }
    }
}

private struct StepperPill: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 0) {
            Button {
                decrement()
            } label: {
                Text("-")
                    .font(.headline)
                    .frame(width: 34, height: 26)
            }
            .disabled(value <= range.lowerBound)

            Rectangle()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 1, height: 16)

            Button {
                increment()
            } label: {
                Text("+")
                    .font(.headline)
                    .frame(width: 34, height: 26)
            }
            .disabled(value >= range.upperBound)
        }
        .foregroundStyle(.primary)
        .background(Color(.secondarySystemFill))
        .clipShape(Capsule())
        .buttonStyle(.plain)
    }

    private func decrement() {
        guard value > range.lowerBound else { return }
        value -= 1
    }

    private func increment() {
        guard value < range.upperBound else { return }
        value += 1
    }
}

private struct TimeWheelPicker: View {
    @Binding var totalSeconds: Int
    let allowZero: Bool

    @State private var hours: Int
    @State private var minutes: Int
    @State private var seconds: Int

    init(totalSeconds: Binding<Int>, allowZero: Bool) {
        self._totalSeconds = totalSeconds
        self.allowZero = allowZero

        let initial = max(allowZero ? 0 : 1,
                          min(totalSeconds.wrappedValue, TimerConfiguration.maxDurationSeconds))
        _hours = State(initialValue: initial / 3600)
        _minutes = State(initialValue: (initial % 3600) / 60)
        _seconds = State(initialValue: initial % 60)
    }

    var body: some View {
        HStack(spacing: 12) {
            wheel(selection: $hours, values: Array(0...maxHours)) { value in
                value == 1 ? "1 hour" : "\(value) hours"
            }
            wheel(selection: $minutes, values: Array(0...59)) { value in
                "\(value) min"
            }
            wheel(selection: $seconds, values: Array(0...59)) { value in
                "\(value) sec"
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .onAppear {
            syncFromTotalSeconds(totalSeconds)
        }
        // iOS 17 style onChange (no deprecated warning)
        .onChange(of: hours) { _ in updateTotalSeconds() }
        .onChange(of: minutes) { _ in updateTotalSeconds() }
        .onChange(of: seconds) { _ in updateTotalSeconds() }
        .onChange(of: totalSeconds) { newValue in
            syncFromTotalSeconds(newValue)
        }
    }

    private var maxHours: Int {
        max(0, TimerConfiguration.maxDurationSeconds / 3600)
    }

    private func wheel(
        selection: Binding<Int>,
        values: [Int],
        label: @escaping (Int) -> String
    ) -> some View {
        Picker("", selection: selection) {
            ForEach(values, id: \.self) { item in
                Text(label(item)).tag(item)
            }
        }
        .labelsHidden()
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
        .compositingGroup()
    }

    private func syncFromTotalSeconds(_ value: Int) {
        let minValue = allowZero ? 0 : 1
        let clamped = min(max(value, minValue), TimerConfiguration.maxDurationSeconds)

        let newHours = clamped / 3600
        let newMinutes = (clamped % 3600) / 60
        let newSeconds = clamped % 60

        if hours != newHours { hours = newHours }
        if minutes != newMinutes { minutes = newMinutes }
        if seconds != newSeconds { seconds = newSeconds }
    }

    private func updateTotalSeconds() {
        minutes = min(max(minutes, 0), 59)
        seconds = min(max(seconds, 0), 59)

        var computed = (hours * 3600) + (minutes * 60) + seconds

        if !allowZero && computed == 0 {
            computed = 1
            hours = 0
            minutes = 0
            seconds = 1
        }

        totalSeconds = computed
    }
}
