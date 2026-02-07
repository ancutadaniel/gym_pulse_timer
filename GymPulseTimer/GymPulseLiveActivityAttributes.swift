import ActivityKit
import Foundation

enum LiveActivityPhase: String, Codable, Hashable {
    case getReady
    case work
    case rest
    case complete

    var displayName: String {
        switch self {
        case .getReady:
            return "Get Ready"
        case .work:
            return "Work"
        case .rest:
            return "Rest"
        case .complete:
            return "Complete"
        }
    }

    var compactTitle: String {
        switch self {
        case .getReady:
            return "GR"
        case .work:
            return "W"
        case .rest:
            return "R"
        case .complete:
            return "Done"
        }
    }
}

struct GymPulseLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: LiveActivityPhase
        var phaseEndDate: Date
        var phaseDurationSeconds: TimeInterval
        var setIndex: Int
        var roundIndex: Int
        var isPaused: Bool
        var pausedRemainingSeconds: TimeInterval?
    }

    var sessionId: String
    var totalSets: Int
    var totalRounds: Int
    var deepLinkURL: URL?
}
