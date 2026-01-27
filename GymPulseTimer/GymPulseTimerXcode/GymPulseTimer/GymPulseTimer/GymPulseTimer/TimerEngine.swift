import Combine
import Foundation

final class TimerEngine: ObservableObject {
    @Published private(set) var state: TimerSessionState?
    let configuration: TimerConfiguration

    init(configuration: TimerConfiguration) {
        self.configuration = configuration.normalized()
    }

    func start(now: Date = Date()) {
        state = initialState(now: now)
    }

    func restart(now: Date = Date()) {
        start(now: now)
    }

    func pause(now: Date = Date()) {
        guard var state, !state.isPaused, state.phase != .complete else { return }
        let remaining = max(0, state.phaseEndDate.timeIntervalSince(now))
        state.isPaused = true
        state.pausedRemainingSeconds = remaining
        state.phaseEndDate = now
        self.state = state
    }

    func resume(now: Date = Date()) {
        guard var state, state.isPaused, state.phase != .complete else { return }
        let remaining = max(0, state.pausedRemainingSeconds ?? 0)
        state.isPaused = false
        state.pausedRemainingSeconds = nil
        state.phaseEndDate = now.addingTimeInterval(remaining)
        self.state = state
    }

    func advanceIfNeeded(now: Date = Date()) {
        guard let state else { return }
        guard !state.isPaused, state.phase != .complete else { return }
        guard now >= state.phaseEndDate else { return }

        var updated = state
        var iterations = 0
        let maxIterations = max(1, configuration.sets * configuration.rounds * 2 + 2)

        while now >= updated.phaseEndDate,
              updated.phase != .complete,
              !updated.isPaused,
              iterations < maxIterations {
            let phaseEndDate = updated.phaseEndDate
            updated = nextState(after: updated, phaseEndDate: phaseEndDate)
            iterations += 1
        }

        if iterations >= maxIterations, updated.phase != .complete {
            updated = completeState(setIndex: configuration.sets,
                                    roundIndex: configuration.rounds,
                                    phaseEndDate: updated.phaseEndDate)
        }

        self.state = updated
    }

    private func initialState(now: Date) -> TimerSessionState {
        let startPhase: TimerPhase = configuration.getReadySeconds > 0 ? .getReady : .work
        let duration = configuration.duration(for: startPhase)
        return TimerSessionState(
            phase: startPhase,
            setIndex: 1,
            roundIndex: 1,
            phaseEndDate: now.addingTimeInterval(duration),
            isPaused: false,
            pausedRemainingSeconds: nil
        )
    }

    private func nextState(after state: TimerSessionState, phaseEndDate: Date) -> TimerSessionState {
        switch state.phase {
        case .getReady:
            return nextPhaseState(phase: .work,
                                  setIndex: state.setIndex,
                                  roundIndex: state.roundIndex,
                                  phaseEndDate: phaseEndDate)
        case .work:
            return nextPhaseState(phase: .rest,
                                  setIndex: state.setIndex,
                                  roundIndex: state.roundIndex,
                                  phaseEndDate: phaseEndDate)
        case .rest:
            var nextRound = state.roundIndex + 1
            var nextSet = state.setIndex
            if nextRound > configuration.rounds {
                nextRound = 1
                nextSet += 1
            }
            if nextSet > configuration.sets {
                return completeState(setIndex: configuration.sets,
                                     roundIndex: configuration.rounds,
                                     phaseEndDate: phaseEndDate)
            }
            return nextPhaseState(phase: .work,
                                  setIndex: nextSet,
                                  roundIndex: nextRound,
                                  phaseEndDate: phaseEndDate)
        case .complete:
            return state
        }
    }

    private func nextPhaseState(phase: TimerPhase,
                                setIndex: Int,
                                roundIndex: Int,
                                phaseEndDate: Date) -> TimerSessionState {
        let duration = configuration.duration(for: phase)
        return TimerSessionState(
            phase: phase,
            setIndex: setIndex,
            roundIndex: roundIndex,
            phaseEndDate: phaseEndDate.addingTimeInterval(duration),
            isPaused: false,
            pausedRemainingSeconds: nil
        )
    }

    private func completeState(setIndex: Int,
                               roundIndex: Int,
                               phaseEndDate: Date) -> TimerSessionState {
        TimerSessionState(
            phase: .complete,
            setIndex: setIndex,
            roundIndex: roundIndex,
            phaseEndDate: phaseEndDate,
            isPaused: false,
            pausedRemainingSeconds: nil
        )
    }
}
