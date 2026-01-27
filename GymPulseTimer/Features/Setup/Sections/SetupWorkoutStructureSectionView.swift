import SwiftUI

struct SetupWorkoutStructureSectionView: View {
    @Binding var sets: Int
    @Binding var rounds: Int
    let dividerColor: Color

    var body: some View {
        SetupSectionCard("Workout Structure") {
            StepperRow(title: "Sets",
                       value: $sets,
                       range: 1...TimerConfiguration.maxSetsRounds)
            Divider().background(dividerColor)
            StepperRow(title: "Rounds",
                       value: $rounds,
                       range: 1...TimerConfiguration.maxSetsRounds)
        }
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
