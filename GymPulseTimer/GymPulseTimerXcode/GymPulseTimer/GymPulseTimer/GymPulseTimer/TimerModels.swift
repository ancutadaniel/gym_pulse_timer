import Foundation

enum TimerPhase: String, Codable, CaseIterable {
    case getReady
    case work
    case rest
    case complete
}

struct TimerConfiguration: Equatable, Codable {
    static let maxDurationSeconds = 86_399
    static let maxSetsRounds = 99

    var getReadySeconds: Int
    var workSeconds: Int
    var restSeconds: Int
    var sets: Int
    var rounds: Int

    func normalized() -> TimerConfiguration {
        TimerConfiguration(
            getReadySeconds: getReadySeconds.clamped(to: 0...Self.maxDurationSeconds),
            workSeconds: workSeconds.clamped(to: 0...Self.maxDurationSeconds),
            restSeconds: restSeconds.clamped(to: 0...Self.maxDurationSeconds),
            sets: sets.clamped(to: 1...Self.maxSetsRounds),
            rounds: rounds.clamped(to: 1...Self.maxSetsRounds)
        )
    }

    func duration(for phase: TimerPhase) -> TimeInterval {
        switch phase {
        case .getReady:
            return TimeInterval(getReadySeconds)
        case .work:
            return TimeInterval(workSeconds)
        case .rest:
            return TimeInterval(restSeconds)
        case .complete:
            return 0
        }
    }
}

struct TimerSessionState: Equatable, Codable {
    var phase: TimerPhase
    var setIndex: Int
    var roundIndex: Int
    var phaseEndDate: Date
    var isPaused: Bool
    var pausedRemainingSeconds: TimeInterval?

    func remainingTimeInterval(now: Date = Date()) -> TimeInterval {
        if isPaused {
            return max(0, pausedRemainingSeconds ?? 0)
        }
        return max(0, phaseEndDate.timeIntervalSince(now))
    }

    func remainingSeconds(now: Date = Date()) -> Int {
        Int(ceil(remainingTimeInterval(now: now)))
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
