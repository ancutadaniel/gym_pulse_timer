import SwiftUI
import Combine

struct RunView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine: TimerEngine
    @StateObject private var audioCueManager = AudioCueManager()
    @State private var now = Date()
    @State private var liveActivitySessionId = UUID().uuidString
    @State private var lastPhase: TimerPhase?
    @State private var lastRemainingSeconds = -1

    private let preset: Preset
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    init(preset: Preset) {
        self.preset = preset
        _engine = StateObject(wrappedValue: TimerEngine(configuration: preset.timerConfiguration))
    }

    var body: some View {
        let state = engine.state
        let remainingSeconds = state?.remainingSeconds(now: now) ?? 0

        VStack(spacing: 24) {
            Spacer()

            Text("Gym Pulse Timer")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)

            Text(phaseLabel(for: state))
                .font(.title3.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.secondary)

            Text(formatTime(remainingSeconds))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()

            ProgressRingView(progress: progress(for: state),
                             lineWidth: 18,
                             color: phaseColor(for: state))
                .frame(width: 260, height: 260)

            HStack(spacing: 24) {
                Text("Set \(state?.setIndex ?? 1)/\(preset.sets)")
                Text("Round \(state?.roundIndex ?? 1)/\(preset.rounds)")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ControlButton(title: pauseButtonTitle(for: state),
                              background: .blue,
                              foreground: .white,
                              isDisabled: state?.phase == .complete,
                              action: togglePause)

                ControlButton(title: "Restart",
                              background: Color(.secondarySystemFill),
                              action: restart)

                ControlButton(title: "Stop",
                              background: Color(.secondarySystemFill),
                              action: stop)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            audioCueManager.updatePreferences(soundEnabled: preset.soundEnabled,
                                              voiceEnabled: preset.voiceEnabled)
            if engine.state == nil {
                let start = Date()
                now = start
                engine.start(now: start)
            }
            if let state = engine.state {
                handleAudioCues(for: state)
            }
            startLiveActivityIfNeeded()
        }
        .onChange(of: engine.state) { newState in
            guard let newState else { return }
            if newState.phase == .complete {
                endLiveActivity(finalState: newState)
            } else {
                updateLiveActivity(with: newState)
            }
            handleAudioCues(for: newState)
        }
        .onReceive(timer) { tick in
            now = tick
            engine.advanceIfNeeded(now: tick)
            if let state = engine.state {
                handleAudioCues(for: state)
            }
        }
        .onDisappear {
            endLiveActivity(finalState: engine.state)
        }
    }

    private func togglePause() {
        guard let state = engine.state else {
            let start = Date()
            now = start
            engine.start(now: start)
            return
        }
        if state.isPaused {
            engine.resume(now: now)
        } else {
            engine.pause(now: now)
        }
    }

    private func restart() {
        let start = Date()
        now = start
        engine.restart(now: start)
        lastPhase = nil
        lastRemainingSeconds = -1
    }

    private func stop() {
        endLiveActivity(finalState: engine.state)
        dismiss()
    }

    private func pauseButtonTitle(for state: TimerSessionState?) -> String {
        guard let state else { return "Pause" }
        return state.isPaused ? "Resume" : "Pause"
    }

    private func phaseLabel(for state: TimerSessionState?) -> String {
        guard let state else { return "GET READY" }
        switch state.phase {
        case .getReady:
            return "GET READY"
        case .work:
            return "WORK"
        case .rest:
            return "REST"
        case .complete:
            return "COMPLETE"
        }
    }

    private func phaseColor(for state: TimerSessionState?) -> Color {
        guard let state else { return .blue }
        switch state.phase {
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

    private func progress(for state: TimerSessionState?) -> Double {
        guard let state else { return 0 }
        if state.phase == .complete { return 1 }
        let duration = engine.configuration.duration(for: state.phase)
        guard duration > 0 else { return 0 }
        let remaining = state.remainingTimeInterval(now: now)
        let elapsed = max(0, duration - remaining)
        return max(0, min(1, elapsed / duration))
    }

    private func formatTime(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let secs = clamped % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func handleAudioCues(for state: TimerSessionState) {
        guard !state.isPaused else { return }
        let remaining = state.remainingSeconds(now: now)
        if lastPhase != state.phase {
            lastPhase = state.phase
            lastRemainingSeconds = remaining
            audioCueManager.playPhaseStart(phase: state.phase)
        }
        if remaining != lastRemainingSeconds {
            if (1...3).contains(remaining) {
                audioCueManager.playCountdown(second: remaining)
            }
            lastRemainingSeconds = remaining
        }
    }

    private func startLiveActivityIfNeeded() {
        guard let state = engine.state else { return }
        if #available(iOS 16.1, *) {
            Task {
                await GymPulseLiveActivityManager.shared.startActivity(
                    session: state,
                    configuration: engine.configuration,
                    sessionId: liveActivitySessionId
                )
            }
        }
    }

    private func updateLiveActivity(with state: TimerSessionState) {
        if #available(iOS 16.1, *) {
            Task {
                await GymPulseLiveActivityManager.shared.updateActivity(
                    session: state,
                    sessionId: liveActivitySessionId
                )
            }
        }
    }

    private func endLiveActivity(finalState: TimerSessionState?) {
        if #available(iOS 16.1, *) {
            Task {
                await GymPulseLiveActivityManager.shared.endActivity(
                    finalSession: finalState,
                    sessionId: liveActivitySessionId
                )
            }
        }
    }
}

private struct ControlButton: View {
    let title: String
    let background: Color
    var foreground: Color = .primary
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .background(background)
        .foregroundStyle(foreground)
        .clipShape(Capsule())
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}
