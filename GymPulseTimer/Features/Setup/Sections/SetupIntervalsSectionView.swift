import SwiftUI

struct SetupIntervalsSectionView: View {
    @Binding var getReadySeconds: Int
    @Binding var workSeconds: Int
    @Binding var restSeconds: Int
    let dividerColor: Color

    var body: some View {
        SetupSectionCard("Intervals", titleFont: .title2) {
            IntervalRow(title: "Get Ready",
                        totalSeconds: $getReadySeconds,
                        allowZero: true)

            Divider().background(dividerColor)

            IntervalRow(title: "Work",
                        totalSeconds: $workSeconds,
                        allowZero: false)

            Divider().background(dividerColor)

            IntervalRow(title: "Rest",
                        totalSeconds: $restSeconds,
                        allowZero: false)
        }
    }
}

private struct IntervalRow: View {
    let title: String
    @Binding var totalSeconds: Int
    let allowZero: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
            TimeWheelPicker(totalSeconds: $totalSeconds, allowZero: allowZero)
        }
        .padding(.vertical, 4)
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
