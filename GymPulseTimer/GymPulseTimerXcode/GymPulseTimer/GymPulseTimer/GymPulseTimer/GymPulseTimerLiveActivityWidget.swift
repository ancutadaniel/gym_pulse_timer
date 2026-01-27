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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.phase.displayName)
                            .font(.headline)
                        Text("Set \(context.state.setIndex)/\(context.attributes.totalSets)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Round \(context.state.roundIndex)/\(context.attributes.totalRounds)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    CountdownText(state: context.state)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            } compactLeading: {
                Text(context.state.phase.compactTitle)
                    .font(.caption2)
            } compactTrailing: {
                CountdownText(state: context.state)
                    .font(.caption2)
                    .monospacedDigit()
            } minimal: {
                Text(context.state.phase.compactTitle)
                    .font(.caption2)
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
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(context.state.phase.displayName)
                    .font(.headline)
                Text("Set \(context.state.setIndex)/\(context.attributes.totalSets)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Round \(context.state.roundIndex)/\(context.attributes.totalRounds)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if context.state.isPaused {
                    Text("Paused")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            CountdownText(state: context.state)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .padding(.horizontal)
        .widgetURL(context.attributes.deepLinkURL)
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
