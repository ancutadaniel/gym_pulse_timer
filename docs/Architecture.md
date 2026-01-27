# GymPulseTimer (iOS) - Architecture

## Overview
GymPulseTimer is a small SwiftUI app for configuring interval presets and running a
timed workout with audio and voice cues. The user flow is simple: configure a
preset in Setup, then run it in the Run screen. Timing is endDate-based to avoid
drift. Persistence is local-only using UserDefaults. There is no login or
networking in V1.

## High-level component flow (text diagram)
SetupView -> RunView -> TimerEngine -> AudioManager
SetupView -> PresetStore (UserDefaults persistence)
GymPulseTimerApp -> AppSettingsStore (appearance preference)

Notes:
- Persistence is used by Setup/App settings, not by AudioManager.
- Live Activities are planned but not implemented yet.

## State management
- Timer state lives in `TimerEngine` and the current `TimerSessionState`.
- `RunView` owns the engine and session state as `@State` and drives updates
  with a `Timer.publish` tick every 0.25 seconds.
- On each tick, `RunView` calls `engine.advanceIfNeeded(now:)` and applies any
  returned state to `sessionState`.
- Phase transitions are detected by comparing the prior phase to the new state.
  `RunView` uses `lastAnnouncedPhase` plus `didPlayCompletion` to ensure audio
  cues fire once per phase, including a single completion cue.
- `TimerSessionState.remainingSeconds(now:)` derives the countdown from
  `phaseEndDate` and a paused snapshot to avoid drift.

## Persistence
### Presets
- Persisted via `PresetStore` using `UserDefaults` with JSON encoding.
- Stored model is `Preset` (id, name, durations, sets/rounds, sound/voice).
- Setup loads presets on appear and writes on save/delete.

### Appearance
- `AppSettingsStore` stores an `AppAppearance` enum (system/light/dark) in
  `UserDefaults` key `appAppearance`.
- `GymPulseTimerApp` applies `preferredColorScheme` from settings at the root level.
- Setup exposes a segmented picker bound to `settings.appearance`.

## Audio and voice
- Audio uses `AudioToolbox` system sounds for beeps and `AVFoundation` for
  speech (`AVSpeechSynthesizer` + `AVSpeechUtterance`).
- `AudioManager` is a singleton that configures an `AVAudioSession` once with
  `.playback` and `.mixWithOthers`.
- Simulator audio/voice calls are guarded with `#if targetEnvironment(simulator)`
  to avoid noisy output in the simulator.

## Planned extensions (not implemented)
- Live Activities: ActivityKit integration should observe state changes in
  `RunView` / `TimerEngine` and start/update/end the Live Activity.
- Android: out of scope for V1; no shared code yet.

## Key paths
- App entry: `ios/GymPulseTimer/GymPulseTimer/GymPulseTimerApp.swift`
- Root view: `ios/GymPulseTimer/GymPulseTimer/ContentView.swift`
- Setup flow: `ios/GymPulseTimer/GymPulseTimer/Features/Setup/SetupView.swift`
- Run flow: `ios/GymPulseTimer/GymPulseTimer/Features/Run/RunView.swift`
- Timer engine: `ios/GymPulseTimer/GymPulseTimer/TimerEngine.swift`
- Timer models: `ios/GymPulseTimer/GymPulseTimer/TimerModels.swift`
- Audio: `ios/GymPulseTimer/GymPulseTimer/Core/Audio/AudioManager.swift`
- Preset persistence: `ios/GymPulseTimer/GymPulseTimer/Core/Persistence/PresetStore.swift`
- App settings: `ios/GymPulseTimer/GymPulseTimer/Core/Persistence/AppSettingsStore.swift`
- Planning docs: `docs/Plan.md`, `docs/PRD.md`
