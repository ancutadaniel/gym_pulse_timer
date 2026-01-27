import ActivityKit
import SwiftUI
import WidgetKit

// NOTE: Add this file to the Widget Extension target only.

@available(iOS 16.1, *)
struct GymPulseTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GymPulseLiveActivityAttributes.self) { context in
            LiveActivityLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.7))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.phase.displayName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Set \(context.state.setIndex)/\(context.attributes.totalSets)")
                        Text("Round \(context.state.roundIndex)/\(context.attributes.totalRounds)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        CountdownText(state: context.state)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        ProgressView(value: LiveActivityProgress.progress(for: context.state))
                            .tint(context.state.phase.tintColor)
                    }
                }
            } compactLeading: {
                Text(context.state.phase.compactTitle)
                    .font(.caption2)
            } compactTrailing: {
                CountdownText(state: context.state)
                    .font(.caption2)
                    .monospacedDigit()
            } minimal: {
                CountdownText(state: context.state)
                    .font(.caption2)
                    .monospacedDigit()
            }
            .widgetURL(context.attributes.deepLinkURL)
            .keylineTint(.accentColor)
        }
    }
}

@available(iOS 16.1, *)
private struct LiveActivityLockScreenView: View {
    let context: ActivityViewContext<GymPulseLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(context.state.phase.displayName)
                    .font(.headline)
                Spacer()
                CountdownText(state: context.state)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            Text(summaryText)
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: LiveActivityProgress.progress(for: context.state))
                .tint(context.state.phase.tintColor)
        }
        .padding(.horizontal)
        .widgetURL(context.attributes.deepLinkURL)
    }

    private var summaryText: String {
        let setText = "Set \(context.state.setIndex)/\(context.attributes.totalSets)"
        let roundText = "Round \(context.state.roundIndex)/\(context.attributes.totalRounds)"
        if context.state.isPaused {
            return "\(setText) • \(roundText) • Paused"
        }
        return "\(setText) • \(roundText)"
    }
}

@available(iOS 16.1, *)
private struct CountdownText: View {
    let state: GymPulseLiveActivityAttributes.ContentState

    var body: some View {
        if state.isPaused {
            Text(LiveActivityTimeFormatter.string(from: state.pausedRemainingSeconds))
        } else {
            Text(state.phaseEndDate, style: .timer)
        }
    }
}

private enum LiveActivityProgress {
    static func progress(for state: GymPulseLiveActivityAttributes.ContentState) -> Double {
        let duration = max(0, state.phaseDurationSeconds)
        if duration == 0 {
            return 1
        }
        let remaining: TimeInterval
        if state.isPaused {
            remaining = state.pausedRemainingSeconds ?? 0
        } else {
            remaining = state.phaseEndDate.timeIntervalSince(Date())
        }
        let clampedRemaining = min(max(remaining, 0), duration)
        return max(0, min(1, (duration - clampedRemaining) / duration))
    }
}

private extension LiveActivityPhase {
    var tintColor: Color {
        switch self {
        case .getReady:
            return .orange
        case .work:
            return .green
        case .rest:
            return .blue
        case .complete:
            return .gray
        }
    }
}

private enum LiveActivityTimeFormatter {
    static func string(from seconds: TimeInterval?) -> String {
        let remaining = max(0, Int(seconds ?? 0))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let secs = remaining % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}
