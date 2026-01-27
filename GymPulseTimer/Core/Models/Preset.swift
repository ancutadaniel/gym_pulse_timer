import Foundation

struct Preset: Identifiable, Codable, Equatable {
    static let defaultName = "New Timer"

    var id: UUID
    var name: String
    var getReadySeconds: Int
    var workSeconds: Int
    var restSeconds: Int
    var sets: Int
    var rounds: Int
    var soundEnabled: Bool
    var voiceEnabled: Bool
    var updatedAt: Date

    static func makeDefault() -> Preset {
        Preset(
            id: UUID(),
            name: defaultName,
            getReadySeconds: 10,
            workSeconds: 60,
            restSeconds: 60,
            sets: 1,
            rounds: 4,
            soundEnabled: true,
            voiceEnabled: true,
            updatedAt: Date()
        )
    }

    static func normalizedName(_ name: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cappedName = String(trimmedName.prefix(30))
        return cappedName.isEmpty ? Preset.defaultName : cappedName
    }

    func normalized() -> Preset {
        let finalName = Preset.normalizedName(name)

        return Preset(
            id: id,
            name: finalName,
            getReadySeconds: getReadySeconds.clamped(to: 0...TimerConfiguration.maxDurationSeconds),
            workSeconds: workSeconds.clamped(to: 1...TimerConfiguration.maxDurationSeconds),
            restSeconds: restSeconds.clamped(to: 1...TimerConfiguration.maxDurationSeconds),
            sets: sets.clamped(to: 1...TimerConfiguration.maxSetsRounds),
            rounds: rounds.clamped(to: 1...TimerConfiguration.maxSetsRounds),
            soundEnabled: soundEnabled,
            voiceEnabled: voiceEnabled,
            updatedAt: updatedAt
        )
    }

    var timerConfiguration: TimerConfiguration {
        TimerConfiguration(
            getReadySeconds: getReadySeconds,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            sets: sets,
            rounds: rounds
        ).normalized()
    }

    var summary: String {
        let getReady = Self.formatDuration(getReadySeconds)
        let work = Self.formatDuration(workSeconds)
        let rest = Self.formatDuration(restSeconds)
        return "Get Ready \(getReady), Work \(work), Rest \(rest), Sets \(sets), Rounds \(rounds)"
    }

    static func formatDuration(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let minutes = clamped / 60
        let secs = clamped % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
