import ActivityKit
import Foundation

@available(iOS 16.1, *)
@MainActor
final class GymPulseLiveActivityManager {
    static let shared = GymPulseLiveActivityManager()

    private var currentActivity: Activity<GymPulseLiveActivityAttributes>?
    private var currentSessionId: String?

    func startActivity(session: TimerSessionState,
                       configuration: TimerConfiguration,
                       sessionId: String = UUID().uuidString) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = GymPulseLiveActivityAttributes(
            sessionId: sessionId,
            totalSets: configuration.sets,
            totalRounds: configuration.rounds,
            deepLinkURL: GymPulseDeepLink.liveActivityURL(sessionId: sessionId)
        )
        let contentState = makeContentState(from: session)

        if let existingActivity = resolveActivity(sessionId: sessionId) {
            await updateActivity(existingActivity, contentState: contentState)
            currentActivity = existingActivity
            currentSessionId = sessionId
            return
        }

        do {
            let activity = try requestActivity(attributes: attributes, contentState: contentState)
            currentActivity = activity
            currentSessionId = sessionId
        } catch {
            // Ignore request failures; the timer should continue without Live Activity.
        }
    }

    func updateActivity(session: TimerSessionState, sessionId: String? = nil) async {
        guard let activity = resolveActivity(sessionId: sessionId) else { return }
        let contentState = makeContentState(from: session)
        await updateActivity(activity, contentState: contentState)
    }

    func endActivity(finalSession: TimerSessionState? = nil, sessionId: String? = nil) async {
        guard let activity = resolveActivity(sessionId: sessionId) else { return }
        let contentState = finalSession.map { makeContentState(from: $0) }
        await endActivity(activity, contentState: contentState)
        if activity.id == currentActivity?.id {
            currentActivity = nil
            currentSessionId = nil
        }
    }

    private func resolveActivity(sessionId: String?) -> Activity<GymPulseLiveActivityAttributes>? {
        if let sessionId {
            return Activity<GymPulseLiveActivityAttributes>.activities.first { activity in
                activity.attributes.sessionId == sessionId
            }
        }
        if let currentActivity {
            return currentActivity
        }
        if let currentSessionId {
            return Activity<GymPulseLiveActivityAttributes>.activities.first { activity in
                activity.attributes.sessionId == currentSessionId
            }
        }
        return Activity<GymPulseLiveActivityAttributes>.activities.first
    }

    private func makeContentState(from session: TimerSessionState)
    -> GymPulseLiveActivityAttributes.ContentState {
        GymPulseLiveActivityAttributes.ContentState(
            phase: LiveActivityPhase(timerPhase: session.phase),
            phaseEndDate: session.phaseEndDate,
            setIndex: session.setIndex,
            roundIndex: session.roundIndex,
            isPaused: session.isPaused,
            pausedRemainingSeconds: session.isPaused ? session.pausedRemainingSeconds : nil
        )
    }

    private func requestActivity(attributes: GymPulseLiveActivityAttributes,
                                 contentState: GymPulseLiveActivityAttributes.ContentState)
    throws -> Activity<GymPulseLiveActivityAttributes> {
        if #available(iOS 16.2, *) {
            let content = ActivityContent(state: contentState, staleDate: contentState.phaseEndDate)
            return try Activity.request(attributes: attributes, content: content, pushType: nil)
        }
        return try Activity.request(attributes: attributes,
                                    contentState: contentState,
                                    pushType: nil)
    }

    private func updateActivity(_ activity: Activity<GymPulseLiveActivityAttributes>,
                                contentState: GymPulseLiveActivityAttributes.ContentState) async {
        if #available(iOS 16.2, *) {
            let content = ActivityContent(state: contentState, staleDate: contentState.phaseEndDate)
            await activity.update(content)
            return
        }
        await activity.update(using: contentState)
    }

    private func endActivity(_ activity: Activity<GymPulseLiveActivityAttributes>,
                             contentState: GymPulseLiveActivityAttributes.ContentState?) async {
        if let contentState {
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: contentState, staleDate: contentState.phaseEndDate)
                await activity.end(content, dismissalPolicy: .immediate)
                return
            }
            await activity.end(using: contentState, dismissalPolicy: .immediate)
            return
        }
        await activity.end(dismissalPolicy: .immediate)
    }
}

private enum GymPulseDeepLink {
    static func liveActivityURL(sessionId: String) -> URL? {
        var components = URLComponents()
        components.scheme = "gympulsetimer"
        components.host = "session"
        components.queryItems = [URLQueryItem(name: "id", value: sessionId)]
        return components.url
    }
}

private extension LiveActivityPhase {
    init(timerPhase: TimerPhase) {
        switch timerPhase {
        case .getReady:
            self = .getReady
        case .work:
            self = .work
        case .rest:
            self = .rest
        case .complete:
            self = .complete
        }
    }
}
