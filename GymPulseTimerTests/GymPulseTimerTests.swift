//
//  GymPulseTimerTests.swift
//  GymPulseTimerTests
//
//  Created by web3bit on 26.01.26.
//

import Testing
import Foundation
@testable import GymPulseTimer

// MARK: - Helpers

/// A fixed reference date used throughout all tests so that time calculations
/// are deterministic and easy to reason about.
private let refDate = Date(timeIntervalSinceReferenceDate: 0)

/// Convenience to create a `Date` offset from `refDate`.
private func date(adding seconds: TimeInterval) -> Date {
    refDate.addingTimeInterval(seconds)
}

/// Builds a default configuration that is convenient for most tests:
/// 5 s get-ready, 30 s work, 15 s rest, 3 rounds, 2 sets.
private func defaultConfig(
    getReady: Int = 5,
    work: Int = 30,
    rest: Int = 15,
    sets: Int = 2,
    rounds: Int = 3
) -> TimerConfiguration {
    TimerConfiguration(
        getReadySeconds: getReady,
        workSeconds: work,
        restSeconds: rest,
        sets: sets,
        rounds: rounds
    )
}

// MARK: - TimerPhase Tests

@Suite("TimerPhase")
struct TimerPhaseTests {

    @Test("All cases are present")
    func allCases() {
        let cases = TimerPhase.allCases
        #expect(cases.count == 4)
        #expect(cases.contains(.getReady))
        #expect(cases.contains(.work))
        #expect(cases.contains(.rest))
        #expect(cases.contains(.complete))
    }

    @Test("Raw values match expected strings")
    func rawValues() {
        #expect(TimerPhase.getReady.rawValue == "getReady")
        #expect(TimerPhase.work.rawValue == "work")
        #expect(TimerPhase.rest.rawValue == "rest")
        #expect(TimerPhase.complete.rawValue == "complete")
    }

    @Test("Round-trips through JSON encoding and decoding")
    func codable() throws {
        for phase in TimerPhase.allCases {
            let data = try JSONEncoder().encode(phase)
            let decoded = try JSONDecoder().decode(TimerPhase.self, from: data)
            #expect(decoded == phase)
        }
    }
}

// MARK: - Comparable.clamped Tests

@Suite("Comparable.clamped(to:)")
struct ClampedTests {

    @Test("Value below range returns lower bound")
    func belowRange() {
        #expect((-5).clamped(to: 0...100) == 0)
    }

    @Test("Value above range returns upper bound")
    func aboveRange() {
        #expect(200.clamped(to: 0...100) == 100)
    }

    @Test("Value inside range is unchanged")
    func insideRange() {
        #expect(50.clamped(to: 0...100) == 50)
    }

    @Test("Value at lower bound is unchanged")
    func atLowerBound() {
        #expect(0.clamped(to: 0...100) == 0)
    }

    @Test("Value at upper bound is unchanged")
    func atUpperBound() {
        #expect(100.clamped(to: 0...100) == 100)
    }

    @Test("Works with Double")
    func doubleValues() {
        #expect((-1.5).clamped(to: 0.0...1.0) == 0.0)
        #expect(0.5.clamped(to: 0.0...1.0) == 0.5)
        #expect(2.0.clamped(to: 0.0...1.0) == 1.0)
    }
}

// MARK: - TimerConfiguration Tests

@Suite("TimerConfiguration")
struct TimerConfigurationTests {

    // MARK: normalized()

    @Test("normalized() clamps negative getReadySeconds to 0")
    func normalizedClampsNegativeGetReady() {
        let config = TimerConfiguration(
            getReadySeconds: -10, workSeconds: 30, restSeconds: 15, sets: 2, rounds: 3
        ).normalized()
        #expect(config.getReadySeconds == 0)
    }

    @Test("normalized() clamps getReadySeconds above max to maxDurationSeconds")
    func normalizedClampsExcessiveGetReady() {
        let config = TimerConfiguration(
            getReadySeconds: 100_000, workSeconds: 30, restSeconds: 15, sets: 2, rounds: 3
        ).normalized()
        #expect(config.getReadySeconds == TimerConfiguration.maxDurationSeconds)
    }

    @Test("normalized() clamps negative workSeconds to 0")
    func normalizedClampsNegativeWork() {
        let config = TimerConfiguration(
            getReadySeconds: 5, workSeconds: -1, restSeconds: 15, sets: 2, rounds: 3
        ).normalized()
        #expect(config.workSeconds == 0)
    }

    @Test("normalized() clamps workSeconds above max to maxDurationSeconds")
    func normalizedClampsExcessiveWork() {
        let config = TimerConfiguration(
            getReadySeconds: 5, workSeconds: 90_000, restSeconds: 15, sets: 2, rounds: 3
        ).normalized()
        #expect(config.workSeconds == TimerConfiguration.maxDurationSeconds)
    }

    @Test("normalized() clamps negative restSeconds to 0")
    func normalizedClampsNegativeRest() {
        let config = TimerConfiguration(
            getReadySeconds: 5, workSeconds: 30, restSeconds: -5, sets: 2, rounds: 3
        ).normalized()
        #expect(config.restSeconds == 0)
    }

    @Test("normalized() clamps restSeconds above max to maxDurationSeconds")
    func normalizedClampsExcessiveRest() {
        let config = TimerConfiguration(
            getReadySeconds: 5, workSeconds: 30, restSeconds: 100_000, sets: 2, rounds: 3
        ).normalized()
        #expect(config.restSeconds == TimerConfiguration.maxDurationSeconds)
    }

    @Test("normalized() clamps sets below 1 to 1")
    func normalizedClampsSetsBelow1() {
        let config = TimerConfiguration(
            getReadySeconds: 5, workSeconds: 30, restSeconds: 15, sets: 0, rounds: 3
        ).normalized()
        #expect(config.sets == 1)
    }

    @Test("normalized() clamps sets above max to maxSetsRounds")
    func normalizedClampsSetsAboveMax() {
        let config = TimerConfiguration(
            getReadySeconds: 5, workSeconds: 30, restSeconds: 15, sets: 200, rounds: 3
        ).normalized()
        #expect(config.sets == TimerConfiguration.maxSetsRounds)
    }

    @Test("normalized() clamps rounds below 1 to 1")
    func normalizedClampsRoundsBelow1() {
        let config = TimerConfiguration(
            getReadySeconds: 5, workSeconds: 30, restSeconds: 15, sets: 2, rounds: -3
        ).normalized()
        #expect(config.rounds == 1)
    }

    @Test("normalized() clamps rounds above max to maxSetsRounds")
    func normalizedClampsRoundsAboveMax() {
        let config = TimerConfiguration(
            getReadySeconds: 5, workSeconds: 30, restSeconds: 15, sets: 2, rounds: 150
        ).normalized()
        #expect(config.rounds == TimerConfiguration.maxSetsRounds)
    }

    @Test("normalized() leaves valid values untouched")
    func normalizedLeavesValidValues() {
        let original = defaultConfig()
        let normalized = original.normalized()
        #expect(normalized == original)
    }

    @Test("normalized() clamps all fields simultaneously")
    func normalizedClampsAllAtOnce() {
        let config = TimerConfiguration(
            getReadySeconds: -1, workSeconds: -1, restSeconds: -1, sets: 0, rounds: 0
        ).normalized()
        #expect(config.getReadySeconds == 0)
        #expect(config.workSeconds == 0)
        #expect(config.restSeconds == 0)
        #expect(config.sets == 1)
        #expect(config.rounds == 1)
    }

    // MARK: maxDurationSeconds and maxSetsRounds constants

    @Test("maxDurationSeconds is 86399 (just under 24 hours)")
    func maxDurationConstant() {
        #expect(TimerConfiguration.maxDurationSeconds == 86_399)
    }

    @Test("maxSetsRounds is 99")
    func maxSetsRoundsConstant() {
        #expect(TimerConfiguration.maxSetsRounds == 99)
    }

    // MARK: duration(for:)

    @Test("duration(for: .getReady) returns getReadySeconds as TimeInterval")
    func durationGetReady() {
        let config = defaultConfig(getReady: 10)
        #expect(config.duration(for: .getReady) == 10.0)
    }

    @Test("duration(for: .work) returns workSeconds as TimeInterval")
    func durationWork() {
        let config = defaultConfig(work: 45)
        #expect(config.duration(for: .work) == 45.0)
    }

    @Test("duration(for: .rest) returns restSeconds as TimeInterval")
    func durationRest() {
        let config = defaultConfig(rest: 20)
        #expect(config.duration(for: .rest) == 20.0)
    }

    @Test("duration(for: .complete) always returns 0")
    func durationComplete() {
        let config = defaultConfig()
        #expect(config.duration(for: .complete) == 0.0)
    }

    @Test("duration(for:) works with zero-second phases")
    func durationZero() {
        let config = defaultConfig(getReady: 0, work: 0, rest: 0)
        #expect(config.duration(for: .getReady) == 0.0)
        #expect(config.duration(for: .work) == 0.0)
        #expect(config.duration(for: .rest) == 0.0)
    }

    // MARK: Equatable

    @Test("Two identical configurations are equal")
    func equatable() {
        let a = defaultConfig()
        let b = defaultConfig()
        #expect(a == b)
    }

    @Test("Two different configurations are not equal")
    func notEqual() {
        let a = defaultConfig(work: 30)
        let b = defaultConfig(work: 45)
        #expect(a != b)
    }

    // MARK: Codable

    @Test("Round-trips through JSON")
    func codable() throws {
        let original = defaultConfig()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TimerConfiguration.self, from: data)
        #expect(decoded == original)
    }
}

// MARK: - TimerSessionState Tests

@Suite("TimerSessionState")
struct TimerSessionStateTests {

    // MARK: remainingTimeInterval

    @Test("remainingTimeInterval returns positive time when phaseEndDate is in the future")
    func remainingTimeIntervalPositive() {
        let state = TimerSessionState(
            phase: .work,
            setIndex: 1,
            roundIndex: 1,
            phaseEndDate: date(adding: 30),
            isPaused: false,
            pausedRemainingSeconds: nil
        )
        let remaining = state.remainingTimeInterval(now: date(adding: 10))
        #expect(remaining == 20.0)
    }

    @Test("remainingTimeInterval returns 0 when phaseEndDate equals now")
    func remainingTimeIntervalExactlyZero() {
        let state = TimerSessionState(
            phase: .work,
            setIndex: 1,
            roundIndex: 1,
            phaseEndDate: date(adding: 30),
            isPaused: false,
            pausedRemainingSeconds: nil
        )
        let remaining = state.remainingTimeInterval(now: date(adding: 30))
        #expect(remaining == 0.0)
    }

    @Test("remainingTimeInterval never returns negative (clamps to 0)")
    func remainingTimeIntervalNeverNegative() {
        let state = TimerSessionState(
            phase: .work,
            setIndex: 1,
            roundIndex: 1,
            phaseEndDate: date(adding: 10),
            isPaused: false,
            pausedRemainingSeconds: nil
        )
        let remaining = state.remainingTimeInterval(now: date(adding: 20))
        #expect(remaining == 0.0)
    }

    @Test("remainingTimeInterval returns pausedRemainingSeconds when paused")
    func remainingTimeIntervalPaused() {
        let state = TimerSessionState(
            phase: .work,
            setIndex: 1,
            roundIndex: 1,
            phaseEndDate: refDate,
            isPaused: true,
            pausedRemainingSeconds: 12.5
        )
        // The actual now value should not matter when paused.
        let remaining = state.remainingTimeInterval(now: date(adding: 999))
        #expect(remaining == 12.5)
    }

    @Test("remainingTimeInterval returns 0 when paused with nil pausedRemainingSeconds")
    func remainingTimeIntervalPausedNil() {
        let state = TimerSessionState(
            phase: .work,
            setIndex: 1,
            roundIndex: 1,
            phaseEndDate: refDate,
            isPaused: true,
            pausedRemainingSeconds: nil
        )
        let remaining = state.remainingTimeInterval(now: date(adding: 5))
        #expect(remaining == 0.0)
    }

    @Test("remainingTimeInterval returns 0 when paused with negative pausedRemainingSeconds")
    func remainingTimeIntervalPausedNegative() {
        let state = TimerSessionState(
            phase: .work,
            setIndex: 1,
            roundIndex: 1,
            phaseEndDate: refDate,
            isPaused: true,
            pausedRemainingSeconds: -5.0
        )
        let remaining = state.remainingTimeInterval(now: refDate)
        #expect(remaining == 0.0)
    }

    // MARK: remainingSeconds

    @Test("remainingSeconds returns ceiling of remainingTimeInterval")
    func remainingSecondsCeiling() {
        let state = TimerSessionState(
            phase: .work,
            setIndex: 1,
            roundIndex: 1,
            phaseEndDate: date(adding: 30),
            isPaused: false,
            pausedRemainingSeconds: nil
        )
        // 30 - 10.5 = 19.5, ceil = 20
        let secs = state.remainingSeconds(now: date(adding: 10.5))
        #expect(secs == 20)
    }

    @Test("remainingSeconds returns exact integer when no fractional part")
    func remainingSecondsExact() {
        let state = TimerSessionState(
            phase: .work,
            setIndex: 1,
            roundIndex: 1,
            phaseEndDate: date(adding: 30),
            isPaused: false,
            pausedRemainingSeconds: nil
        )
        let secs = state.remainingSeconds(now: date(adding: 10))
        #expect(secs == 20)
    }

    @Test("remainingSeconds returns 0 when time is up")
    func remainingSecondsZero() {
        let state = TimerSessionState(
            phase: .work,
            setIndex: 1,
            roundIndex: 1,
            phaseEndDate: date(adding: 30),
            isPaused: false,
            pausedRemainingSeconds: nil
        )
        let secs = state.remainingSeconds(now: date(adding: 30))
        #expect(secs == 0)
    }

    @Test("remainingSeconds when paused uses pausedRemainingSeconds")
    func remainingSecondsPaused() {
        let state = TimerSessionState(
            phase: .work,
            setIndex: 1,
            roundIndex: 1,
            phaseEndDate: refDate,
            isPaused: true,
            pausedRemainingSeconds: 7.3
        )
        #expect(state.remainingSeconds(now: refDate) == 8) // ceil(7.3)
    }

    // MARK: Codable

    @Test("Round-trips through JSON")
    func codable() throws {
        let state = TimerSessionState(
            phase: .work,
            setIndex: 2,
            roundIndex: 3,
            phaseEndDate: date(adding: 60),
            isPaused: false,
            pausedRemainingSeconds: nil
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(TimerSessionState.self, from: data)
        #expect(decoded == state)
    }

    @Test("Round-trips through JSON when paused")
    func codablePaused() throws {
        let state = TimerSessionState(
            phase: .rest,
            setIndex: 1,
            roundIndex: 2,
            phaseEndDate: refDate,
            isPaused: true,
            pausedRemainingSeconds: 12.5
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(TimerSessionState.self, from: data)
        #expect(decoded == state)
    }
}

// MARK: - TimerEngine Start Tests

@Suite("TimerEngine - Start")
struct TimerEngineStartTests {

    @Test("State is nil before start is called")
    func stateNilBeforeStart() {
        let engine = TimerEngine(configuration: defaultConfig())
        #expect(engine.state == nil)
    }

    @Test("start() sets phase to getReady when getReadySeconds > 0")
    func startWithGetReady() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 5))
        engine.start(now: refDate)

        let state = try! #require(engine.state)
        #expect(state.phase == .getReady)
        #expect(state.setIndex == 1)
        #expect(state.roundIndex == 1)
        #expect(state.isPaused == false)
        #expect(state.pausedRemainingSeconds == nil)
        #expect(state.phaseEndDate == date(adding: 5))
    }

    @Test("start() sets phase to work when getReadySeconds == 0")
    func startWithoutGetReady() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 30))
        engine.start(now: refDate)

        let state = try! #require(engine.state)
        #expect(state.phase == .work)
        #expect(state.setIndex == 1)
        #expect(state.roundIndex == 1)
        #expect(state.phaseEndDate == date(adding: 30))
    }

    @Test("start() normalizes configuration (negative getReady treated as 0)")
    func startNormalizesConfig() {
        let engine = TimerEngine(
            configuration: TimerConfiguration(
                getReadySeconds: -5, workSeconds: 20, restSeconds: 10, sets: 1, rounds: 1
            )
        )
        engine.start(now: refDate)

        let state = try! #require(engine.state)
        // Negative getReady is normalized to 0, so should start in work
        #expect(state.phase == .work)
        #expect(state.phaseEndDate == date(adding: 20))
    }

    @Test("Calling start() a second time resets state")
    func startResetsState() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 5, work: 30))
        engine.start(now: refDate)
        // Advance past getReady
        engine.advanceIfNeeded(now: date(adding: 6))
        #expect(engine.state?.phase == .work)

        // Start again
        engine.start(now: date(adding: 100))
        let state = try! #require(engine.state)
        #expect(state.phase == .getReady)
        #expect(state.setIndex == 1)
        #expect(state.roundIndex == 1)
    }
}

// MARK: - TimerEngine Transition Tests

@Suite("TimerEngine - Transitions")
struct TimerEngineTransitionTests {

    @Test("getReady transitions to work")
    func getReadyToWork() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 5, work: 30))
        engine.start(now: refDate)
        engine.advanceIfNeeded(now: date(adding: 5))

        let state = try! #require(engine.state)
        #expect(state.phase == .work)
        #expect(state.setIndex == 1)
        #expect(state.roundIndex == 1)
        #expect(state.phaseEndDate == date(adding: 5 + 30))
    }

    @Test("work transitions to rest")
    func workToRest() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 10, rest: 5))
        engine.start(now: refDate)
        engine.advanceIfNeeded(now: date(adding: 10))

        let state = try! #require(engine.state)
        #expect(state.phase == .rest)
        #expect(state.phaseEndDate == date(adding: 10 + 5))
    }

    @Test("rest transitions to work in next round")
    func restToWorkNextRound() {
        // 1 set, 3 rounds
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 10, rest: 5, sets: 1, rounds: 3))
        engine.start(now: refDate)

        // work phase (round 1)
        engine.advanceIfNeeded(now: date(adding: 10))
        #expect(engine.state?.phase == .rest)
        #expect(engine.state?.roundIndex == 1)

        // rest phase done -> next round
        engine.advanceIfNeeded(now: date(adding: 15))
        let state = try! #require(engine.state)
        #expect(state.phase == .work)
        #expect(state.roundIndex == 2)
        #expect(state.setIndex == 1)
    }

    @Test("Full cycle: getReady -> work -> rest -> work(r2) -> rest -> work(r3) -> rest -> complete")
    func fullSingleSetCycle() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 3, work: 10, rest: 5, sets: 1, rounds: 3))
        engine.start(now: refDate)
        var t: TimeInterval = 0

        // getReady
        #expect(engine.state?.phase == .getReady)
        t += 3
        engine.advanceIfNeeded(now: date(adding: t)) // t=3

        // work round 1
        #expect(engine.state?.phase == .work)
        #expect(engine.state?.roundIndex == 1)
        t += 10
        engine.advanceIfNeeded(now: date(adding: t)) // t=13

        // rest round 1
        #expect(engine.state?.phase == .rest)
        #expect(engine.state?.roundIndex == 1)
        t += 5
        engine.advanceIfNeeded(now: date(adding: t)) // t=18

        // work round 2
        #expect(engine.state?.phase == .work)
        #expect(engine.state?.roundIndex == 2)
        t += 10
        engine.advanceIfNeeded(now: date(adding: t)) // t=28

        // rest round 2
        #expect(engine.state?.phase == .rest)
        #expect(engine.state?.roundIndex == 2)
        t += 5
        engine.advanceIfNeeded(now: date(adding: t)) // t=33

        // work round 3
        #expect(engine.state?.phase == .work)
        #expect(engine.state?.roundIndex == 3)
        t += 10
        engine.advanceIfNeeded(now: date(adding: t)) // t=43

        // rest round 3
        #expect(engine.state?.phase == .rest)
        #expect(engine.state?.roundIndex == 3)
        t += 5
        engine.advanceIfNeeded(now: date(adding: t)) // t=48

        // complete
        let state = try! #require(engine.state)
        #expect(state.phase == .complete)
        #expect(state.setIndex == 1)
        #expect(state.roundIndex == 3)
    }

    @Test("Round overflow advances to next set")
    func roundOverflowAdvancesSet() {
        // 2 sets, 2 rounds
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 5, rest: 3, sets: 2, rounds: 2))
        engine.start(now: refDate)
        var t: TimeInterval = 0

        // Set 1, Round 1: work
        t += 5; engine.advanceIfNeeded(now: date(adding: t))  // -> rest
        t += 3; engine.advanceIfNeeded(now: date(adding: t))  // -> work (round 2)
        #expect(engine.state?.setIndex == 1)
        #expect(engine.state?.roundIndex == 2)

        // Set 1, Round 2: work
        t += 5; engine.advanceIfNeeded(now: date(adding: t))  // -> rest
        t += 3; engine.advanceIfNeeded(now: date(adding: t))  // -> work (set 2, round 1)
        #expect(engine.state?.setIndex == 2)
        #expect(engine.state?.roundIndex == 1)
        #expect(engine.state?.phase == .work)
    }

    @Test("Completes after last set and last round")
    func completesAfterLastSetRound() {
        // 2 sets, 2 rounds
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 5, rest: 3, sets: 2, rounds: 2))
        engine.start(now: refDate)
        var t: TimeInterval = 0

        // Set 1, Round 1
        t += 5; engine.advanceIfNeeded(now: date(adding: t))  // -> rest
        t += 3; engine.advanceIfNeeded(now: date(adding: t))  // -> work (r2)
        // Set 1, Round 2
        t += 5; engine.advanceIfNeeded(now: date(adding: t))  // -> rest
        t += 3; engine.advanceIfNeeded(now: date(adding: t))  // -> work (set 2, r1)
        // Set 2, Round 1
        t += 5; engine.advanceIfNeeded(now: date(adding: t))  // -> rest
        t += 3; engine.advanceIfNeeded(now: date(adding: t))  // -> work (set 2, r2)
        // Set 2, Round 2
        t += 5; engine.advanceIfNeeded(now: date(adding: t))  // -> rest
        t += 3; engine.advanceIfNeeded(now: date(adding: t))  // -> complete

        let state = try! #require(engine.state)
        #expect(state.phase == .complete)
        #expect(state.setIndex == 2)
        #expect(state.roundIndex == 2)
    }

    @Test("advanceIfNeeded does nothing before phase end")
    func advanceDoesNothingEarly() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 10))
        engine.start(now: refDate)
        engine.advanceIfNeeded(now: date(adding: 5))

        #expect(engine.state?.phase == .getReady)
    }

    @Test("advanceIfNeeded does nothing when state is nil")
    func advanceWithNilState() {
        let engine = TimerEngine(configuration: defaultConfig())
        engine.advanceIfNeeded(now: refDate) // should not crash
        #expect(engine.state == nil)
    }

    @Test("advanceIfNeeded does nothing when paused")
    func advanceWhenPaused() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 10))
        engine.start(now: refDate)
        engine.pause(now: date(adding: 3))
        engine.advanceIfNeeded(now: date(adding: 20))

        #expect(engine.state?.phase == .getReady)
        #expect(engine.state?.isPaused == true)
    }

    @Test("advanceIfNeeded does nothing when complete")
    func advanceWhenComplete() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 5, rest: 3, sets: 1, rounds: 1))
        engine.start(now: refDate)
        // work -> rest -> complete
        engine.advanceIfNeeded(now: date(adding: 5))
        engine.advanceIfNeeded(now: date(adding: 8))
        #expect(engine.state?.phase == .complete)

        // Calling advance again should be a no-op
        engine.advanceIfNeeded(now: date(adding: 100))
        #expect(engine.state?.phase == .complete)
    }

    @Test("advanceIfNeeded skips multiple phases when large time passes")
    func advanceSkipsMultiplePhases() {
        // getReady=3, work=5, rest=2, 1 set, 2 rounds
        // Total: 3 + 5 + 2 + 5 + 2 = 17 seconds to completion
        let engine = TimerEngine(configuration: defaultConfig(getReady: 3, work: 5, rest: 2, sets: 1, rounds: 2))
        engine.start(now: refDate)

        // Jump past entire workout
        engine.advanceIfNeeded(now: date(adding: 20))

        let state = try! #require(engine.state)
        #expect(state.phase == .complete)
    }

    @Test("advanceIfNeeded skips exactly to the correct intermediate phase")
    func advanceSkipsToCorrectPhase() {
        // getReady=3, work=5, rest=2, 1 set, 3 rounds
        // Phase timeline:
        //   0-3: getReady
        //   3-8: work R1
        //   8-10: rest R1
        //   10-15: work R2
        //   ...
        let engine = TimerEngine(configuration: defaultConfig(getReady: 3, work: 5, rest: 2, sets: 1, rounds: 3))
        engine.start(now: refDate)

        // Jump to t=9 -> past getReady(3) and work R1(5), 1s into rest R1 (8-10)
        engine.advanceIfNeeded(now: date(adding: 9))

        let state = try! #require(engine.state)
        #expect(state.phase == .rest)
        #expect(state.roundIndex == 1)
        // phaseEndDate for rest R1 should be 3 + 5 + 2 = 10
        #expect(state.phaseEndDate == date(adding: 10))
        // 1 second remaining
        #expect(state.remainingSeconds(now: date(adding: 9)) == 1)
    }
}

// MARK: - TimerEngine Pause/Resume Tests

@Suite("TimerEngine - Pause and Resume")
struct TimerEnginePauseResumeTests {

    @Test("pause() sets isPaused and stores remaining seconds")
    func pauseStoresRemaining() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 10))
        engine.start(now: refDate)
        engine.pause(now: date(adding: 3))

        let state = try! #require(engine.state)
        #expect(state.isPaused == true)
        #expect(state.pausedRemainingSeconds == 7.0)
        #expect(state.phase == .getReady)
    }

    @Test("pause() is a no-op when already paused")
    func pauseWhenAlreadyPaused() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 10))
        engine.start(now: refDate)
        engine.pause(now: date(adding: 3))
        let stateAfterFirstPause = engine.state

        engine.pause(now: date(adding: 8)) // should not change anything
        #expect(engine.state == stateAfterFirstPause)
    }

    @Test("pause() is a no-op when phase is complete")
    func pauseWhenComplete() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 5, rest: 3, sets: 1, rounds: 1))
        engine.start(now: refDate)
        engine.advanceIfNeeded(now: date(adding: 5))
        engine.advanceIfNeeded(now: date(adding: 8))
        #expect(engine.state?.phase == .complete)

        let stateBefore = engine.state
        engine.pause(now: date(adding: 10))
        #expect(engine.state == stateBefore) // unchanged
    }

    @Test("pause() is a no-op when state is nil")
    func pauseWhenNil() {
        let engine = TimerEngine(configuration: defaultConfig())
        engine.pause(now: refDate) // should not crash
        #expect(engine.state == nil)
    }

    @Test("pause() clamps remaining to 0 when called after phase end")
    func pauseAfterPhaseEnd() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 5))
        engine.start(now: refDate)
        // Pause after getReady would have ended (but without calling advance)
        engine.pause(now: date(adding: 10))

        let state = try! #require(engine.state)
        #expect(state.isPaused == true)
        #expect(state.pausedRemainingSeconds == 0.0)
    }

    @Test("resume() unpauses and sets new phaseEndDate")
    func resumeSetNewEndDate() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 10))
        engine.start(now: refDate)
        engine.pause(now: date(adding: 3))   // 7 seconds remaining
        engine.resume(now: date(adding: 100)) // resume at t=100

        let state = try! #require(engine.state)
        #expect(state.isPaused == false)
        #expect(state.pausedRemainingSeconds == nil)
        #expect(state.phaseEndDate == date(adding: 107))
    }

    @Test("resume() is a no-op when not paused")
    func resumeWhenNotPaused() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 10))
        engine.start(now: refDate)

        let stateBefore = engine.state
        engine.resume(now: date(adding: 3))
        #expect(engine.state == stateBefore)
    }

    @Test("resume() is a no-op when phase is complete")
    func resumeWhenComplete() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 5, rest: 3, sets: 1, rounds: 1))
        engine.start(now: refDate)
        engine.advanceIfNeeded(now: date(adding: 8))
        #expect(engine.state?.phase == .complete)

        let stateBefore = engine.state
        engine.resume(now: date(adding: 20))
        #expect(engine.state == stateBefore)
    }

    @Test("resume() is a no-op when state is nil")
    func resumeWhenNil() {
        let engine = TimerEngine(configuration: defaultConfig())
        engine.resume(now: refDate)
        #expect(engine.state == nil)
    }

    @Test("Pause then resume preserves remaining time and allows normal advance")
    func pauseResumeAndAdvance() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 10, work: 20))
        engine.start(now: refDate)

        // Pause at t=4 (6 seconds remaining in getReady)
        engine.pause(now: date(adding: 4))
        #expect(engine.state?.remainingSeconds(now: date(adding: 4)) == 6)

        // Resume at t=50
        engine.resume(now: date(adding: 50))
        // phaseEndDate = 50 + 6 = 56
        #expect(engine.state?.phaseEndDate == date(adding: 56))

        // At t=55, still in getReady (1 second left)
        engine.advanceIfNeeded(now: date(adding: 55))
        #expect(engine.state?.phase == .getReady)

        // At t=56, getReady ends, transition to work
        engine.advanceIfNeeded(now: date(adding: 56))
        #expect(engine.state?.phase == .work)
        #expect(engine.state?.phaseEndDate == date(adding: 56 + 20))
    }

    @Test("Multiple pause/resume cycles accumulate correctly")
    func multiplePauseResumeCycles() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 20))
        engine.start(now: refDate)

        // Pause at t=5 -> 15 remaining
        engine.pause(now: date(adding: 5))
        #expect(engine.state?.pausedRemainingSeconds == 15.0)

        // Resume at t=10 -> phaseEndDate = 10 + 15 = 25
        engine.resume(now: date(adding: 10))
        #expect(engine.state?.phaseEndDate == date(adding: 25))

        // Pause at t=18 -> 7 remaining
        engine.pause(now: date(adding: 18))
        #expect(engine.state?.pausedRemainingSeconds == 7.0)

        // Resume at t=100 -> phaseEndDate = 100 + 7 = 107
        engine.resume(now: date(adding: 100))
        #expect(engine.state?.phaseEndDate == date(adding: 107))
    }
}

// MARK: - TimerEngine Restart Tests

@Suite("TimerEngine - Restart")
struct TimerEngineRestartTests {

    @Test("restart() resets to initial state")
    func restartResetsState() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 5, work: 10, rest: 5, sets: 2, rounds: 2))
        engine.start(now: refDate)
        // Progress the timer
        engine.advanceIfNeeded(now: date(adding: 15))  // past getReady + work
        #expect(engine.state?.phase == .rest)

        engine.restart(now: date(adding: 100))
        let state = try! #require(engine.state)
        #expect(state.phase == .getReady)
        #expect(state.setIndex == 1)
        #expect(state.roundIndex == 1)
        #expect(state.isPaused == false)
        #expect(state.phaseEndDate == date(adding: 105))
    }

    @Test("restart() works from paused state")
    func restartFromPaused() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 10))
        engine.start(now: refDate)
        engine.pause(now: date(adding: 3))
        #expect(engine.state?.isPaused == true)

        engine.restart(now: date(adding: 50))
        let state = try! #require(engine.state)
        #expect(state.isPaused == false)
        #expect(state.phase == .getReady)
        #expect(state.phaseEndDate == date(adding: 60))
    }

    @Test("restart() works from complete state")
    func restartFromComplete() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 5, rest: 3, sets: 1, rounds: 1))
        engine.start(now: refDate)
        engine.advanceIfNeeded(now: date(adding: 8))
        #expect(engine.state?.phase == .complete)

        engine.restart(now: date(adding: 20))
        let state = try! #require(engine.state)
        #expect(state.phase == .work) // getReady == 0
        #expect(state.setIndex == 1)
        #expect(state.roundIndex == 1)
    }
}

// MARK: - Edge Cases

@Suite("TimerEngine - Edge Cases")
struct TimerEngineEdgeCaseTests {

    @Test("Single round and single set completes after work + rest")
    func singleRoundSingleSet() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 10, rest: 5, sets: 1, rounds: 1))
        engine.start(now: refDate)

        engine.advanceIfNeeded(now: date(adding: 10)) // work -> rest
        #expect(engine.state?.phase == .rest)

        engine.advanceIfNeeded(now: date(adding: 15)) // rest -> complete
        #expect(engine.state?.phase == .complete)
        #expect(engine.state?.setIndex == 1)
        #expect(engine.state?.roundIndex == 1)
    }

    @Test("1-second phases transition correctly")
    func oneSecondPhases() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 1, work: 1, rest: 1, sets: 1, rounds: 1))
        engine.start(now: refDate)

        engine.advanceIfNeeded(now: date(adding: 1))
        #expect(engine.state?.phase == .work)

        engine.advanceIfNeeded(now: date(adding: 2))
        #expect(engine.state?.phase == .rest)

        engine.advanceIfNeeded(now: date(adding: 3))
        #expect(engine.state?.phase == .complete)
    }

    @Test("getReady=0 skips directly to work")
    func noGetReady() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 10))
        engine.start(now: refDate)
        #expect(engine.state?.phase == .work)
    }

    @Test("0-second work phase transitions immediately through work")
    func zeroWork() {
        // getReady=0, work=0, rest=5, 1 set, 1 round
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 0, rest: 5, sets: 1, rounds: 1))
        engine.start(now: refDate)
        // Starts in work phase with 0 duration, so phaseEndDate == refDate
        #expect(engine.state?.phase == .work)

        // Advancing should immediately skip through work to rest
        engine.advanceIfNeeded(now: refDate)
        #expect(engine.state?.phase == .rest)
    }

    @Test("0-second rest phase transitions immediately to next round")
    func zeroRest() {
        // getReady=0, work=5, rest=0, 1 set, 2 rounds
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 5, rest: 0, sets: 1, rounds: 2))
        engine.start(now: refDate)

        // work done at t=5 -> rest has 0 duration -> should skip to work round 2
        engine.advanceIfNeeded(now: date(adding: 5))
        #expect(engine.state?.phase == .work)
        #expect(engine.state?.roundIndex == 2)
    }

    @Test("All zero durations go straight to complete")
    func allZeroDurations() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 0, rest: 0, sets: 1, rounds: 1))
        engine.start(now: refDate)
        engine.advanceIfNeeded(now: refDate)

        #expect(engine.state?.phase == .complete)
    }

    @Test("Large number of sets and rounds completes correctly via skip")
    func manyRoundsAndSetsSkip() {
        // 3 sets, 3 rounds, very short phases
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 1, rest: 1, sets: 3, rounds: 3))
        engine.start(now: refDate)

        // Total time: 3 sets * 3 rounds * (1 work + 1 rest) = 18 seconds
        engine.advanceIfNeeded(now: date(adding: 100))

        let state = try! #require(engine.state)
        #expect(state.phase == .complete)
        #expect(state.setIndex == 3)
        #expect(state.roundIndex == 3)
    }

    @Test("advanceIfNeeded with exactly the phase end time triggers transition")
    func advanceExactlyAtPhaseEnd() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 5, work: 10))
        engine.start(now: refDate)
        engine.advanceIfNeeded(now: date(adding: 5)) // exactly at getReady end

        #expect(engine.state?.phase == .work)
    }

    @Test("Configuration is normalized in init, not just on access")
    func configNormalizedOnInit() {
        let engine = TimerEngine(
            configuration: TimerConfiguration(
                getReadySeconds: -1, workSeconds: 100_000, restSeconds: 10, sets: 0, rounds: 200
            )
        )
        #expect(engine.configuration.getReadySeconds == 0)
        #expect(engine.configuration.workSeconds == TimerConfiguration.maxDurationSeconds)
        #expect(engine.configuration.sets == 1)
        #expect(engine.configuration.rounds == TimerConfiguration.maxSetsRounds)
    }

    @Test("Multiple sets with multiple rounds track indices correctly throughout")
    func multipleSetRoundIndexTracking() {
        // 2 sets, 3 rounds, getReady=0, work=2, rest=1
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 2, rest: 1, sets: 2, rounds: 3))
        engine.start(now: refDate)
        var t: TimeInterval = 0

        // Collect (set, round) at each work phase
        var workEntries: [(set: Int, round: Int)] = []

        let totalWorkPhases = 2 * 3 // sets * rounds
        for _ in 0..<totalWorkPhases {
            let s = try! #require(engine.state)
            #expect(s.phase == .work)
            workEntries.append((set: s.setIndex, round: s.roundIndex))
            t += 2; engine.advanceIfNeeded(now: date(adding: t))  // work -> rest
            if engine.state?.phase == .complete { break }
            t += 1; engine.advanceIfNeeded(now: date(adding: t))  // rest -> work (or complete)
        }

        #expect(workEntries.count == 6)
        #expect(workEntries[0].set == 1 && workEntries[0].round == 1)
        #expect(workEntries[1].set == 1 && workEntries[1].round == 2)
        #expect(workEntries[2].set == 1 && workEntries[2].round == 3)
        #expect(workEntries[3].set == 2 && workEntries[3].round == 1)
        #expect(workEntries[4].set == 2 && workEntries[4].round == 2)
        #expect(workEntries[5].set == 2 && workEntries[5].round == 3)

        #expect(engine.state?.phase == .complete)
    }

    @Test("Advance past multiple phases at once lands in correct mid-phase state")
    func advancePastMultiplePhasesLandsCorrectly() {
        // getReady=3, work=5, rest=2, 1 set, 3 rounds
        // Phase timeline:
        //   0-3: getReady
        //   3-8: work R1
        //   8-10: rest R1
        //   10-15: work R2
        //   15-17: rest R2
        //   17-22: work R3
        //   22-24: rest R3
        //   24: complete
        let engine = TimerEngine(configuration: defaultConfig(getReady: 3, work: 5, rest: 2, sets: 1, rounds: 3))
        engine.start(now: refDate)

        // Jump to t=12 -> should be in work R2 (10-15)
        engine.advanceIfNeeded(now: date(adding: 12))
        let state = try! #require(engine.state)
        #expect(state.phase == .work)
        #expect(state.roundIndex == 2)
        #expect(state.phaseEndDate == date(adding: 15))
        // remaining should be 3
        #expect(state.remainingSeconds(now: date(adding: 12)) == 3)
    }

    @Test("Pause during work, resume, complete rest of workout")
    func pauseDuringWorkResumeComplete() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 10, rest: 5, sets: 1, rounds: 1))
        engine.start(now: refDate)

        // Pause at t=4 -> 6s remaining in work
        engine.pause(now: date(adding: 4))
        #expect(engine.state?.isPaused == true)
        #expect(engine.state?.pausedRemainingSeconds == 6.0)

        // Resume at t=20 -> phaseEndDate = 20 + 6 = 26
        engine.resume(now: date(adding: 20))
        #expect(engine.state?.phaseEndDate == date(adding: 26))

        // Advance past work at t=26
        engine.advanceIfNeeded(now: date(adding: 26))
        #expect(engine.state?.phase == .rest)

        // Advance past rest at t=31
        engine.advanceIfNeeded(now: date(adding: 31))
        #expect(engine.state?.phase == .complete)
    }

    @Test("Advance at exactly the last phase boundary results in complete")
    func advanceExactlyAtLastBoundary() {
        // 1 set, 1 round, getReady=0, work=5, rest=3 => total 8s
        let engine = TimerEngine(configuration: defaultConfig(getReady: 0, work: 5, rest: 3, sets: 1, rounds: 1))
        engine.start(now: refDate)
        engine.advanceIfNeeded(now: date(adding: 8))
        #expect(engine.state?.phase == .complete)
    }

    @Test("remainingSeconds uses ceiling so 0.1s remaining shows as 1")
    func remainingSecondsCeilingEdge() {
        let engine = TimerEngine(configuration: defaultConfig(getReady: 10))
        engine.start(now: refDate)

        let state = try! #require(engine.state)
        #expect(state.remainingSeconds(now: date(adding: 9.1)) == 1)
        #expect(state.remainingSeconds(now: date(adding: 9.9)) == 1)
        #expect(state.remainingSeconds(now: date(adding: 10.0)) == 0)
    }
}
