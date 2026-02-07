# GymPulseTimer (iOS) - Architecture

## Overview
GymPulseTimer is a SwiftUI app for configuring interval presets and running a
timed workout with audio/voice cues and Live Activity support. The user flow is:
browse presets in Timers list, configure a preset in Setup, then run it in the
Run screen. Timing is endDate-based to avoid drift. Persistence is local-only
using UserDefaults. There is no login or networking in V1.

## High-level component flow
```
TimersListView (Home)
  └─> SetupView (create/edit preset)
        └─> RunView (active workout)
              ├─> TimerEngine (state machine)
              ├─> AudioCueManager (beep + voice)
              └─> GymPulseLiveActivityManager (ActivityKit)
                    └─> GymPulseTimerLiveActivityWidget (lock screen + Dynamic Island)

PresetStore (UserDefaults) ← SetupView / TimersListView
AppTheme (@AppStorage) ← GymPulseTimerApp / SetupAppearanceSectionView
```

## State management
- Timer state lives in `TimerEngine` (`@Published state: TimerSessionState?`).
- `RunView` owns the engine as `@StateObject` and drives updates with a
  `Timer.publish` tick every 0.25 seconds.
- On each tick, `RunView` calls `engine.advanceIfNeeded(now:)` which transitions
  phases automatically when `phaseEndDate` is crossed.
- Phase transitions are detected by comparing prior phase to new state.
  `RunView` tracks `lastPhase` and `lastRemainingSeconds` to ensure audio cues
  fire once per phase and countdown beeps play for the last 3 seconds.
- `TimerSessionState.remainingSeconds(now:)` derives the countdown from
  `phaseEndDate` and a paused snapshot to avoid drift.

## Persistence
### Presets
- Persisted via `PresetStore` using `UserDefaults` with JSON encoding
  (key: `GymPulseTimer.presets`).
- Model is `Preset` (id, name, durations, sets/rounds, sound/voice, updatedAt).
- Presets sorted by `updatedAt` descending (most recent first).
- `PresetStore` provides `upsert`, `rename`, and `delete` operations.

### Appearance
- `AppTheme` enum (system/light/dark) stored via `@AppStorage("appTheme")`.
- `GymPulseTimerApp` applies `preferredColorScheme` from the stored theme.
- `SetupAppearanceSectionView` exposes a segmented picker to change theme.

## Audio and voice
- `AudioCueManager` is an `ObservableObject` that manages beep + voice cues.
- Beeps use `AudioToolbox` system sounds (`AudioServicesPlaySystemSound`).
- Voice uses `AVSpeechSynthesizer` with `AVSpeechUtterance` (en-US).
- Audio session configured with `.playback` category and `.mixWithOthers` option.
- Cues: "Get ready" / "Work" / "Rest" / "Workout complete" at phase starts;
  countdown beeps + number voice for the last 3 seconds of each phase.

## Live Activities (ActivityKit)
### Architecture
- **Attributes**: `GymPulseLiveActivityAttributes` defines fixed data (sessionId,
  totalSets, totalRounds, deepLinkURL) and dynamic `ContentState` (phase,
  phaseEndDate, phaseDurationSeconds, setIndex, roundIndex, isPaused,
  pausedRemainingSeconds).
- **Manager**: `GymPulseLiveActivityManager` (singleton, `@MainActor`) handles
  the ActivityKit lifecycle — `startActivity`, `updateActivity`, `endActivity`.
  It converts `TimerSessionState` + `TimerConfiguration` into `ContentState`.
- **Widget UI**: `GymPulseTimerLiveActivityWidget` renders the Live Activity on
  lock screen and Dynamic Island.

### Real-time updates
- Uses `Text(timerInterval:countsDown:)` for countdown text — the system renders
  this natively so it updates every second on the lock screen without app updates.
- Uses `ProgressView(timerInterval:countsDown:)` for the progress bar — also
  system-rendered and auto-updating.
- When paused, falls back to static `Text` and `ProgressView(value:)`.
- `phaseDurationSeconds` is passed in the content state so the widget can compute
  `phaseStartDate = phaseEndDate - phaseDurationSeconds` for the timer intervals.

### Update moments
- **Start**: When `RunView` appears and timer begins.
- **Phase change**: On every phase transition (get ready → work → rest → etc.).
- **Pause/Resume**: Updates content state with `isPaused` and frozen remaining time.
- **End**: When workout completes or user taps Stop.

### Dynamic Island
- **Expanded**: Phase name, set/round info, countdown text with phase color,
  summary line, and linear progress bar.
- **Compact**: Phase label (leading) + circular progress ring (trailing).
- **Minimal**: Circular progress ring with phase color.
- Phase colors match the app: orange (getReady), green (work), blue (rest),
  gray (complete).

### Deep linking
- Live Activity includes a `widgetURL` with scheme `gympulsetimer://`.
- `GymPulseDeepLink` generates session-specific URLs.

## Key paths
```
GymPulseTimer/GymPulseTimerApp.swift                    # App entry point
GymPulseTimer/ContentView.swift                         # Root navigation
GymPulseTimer/TimerEngine.swift                         # Timer state machine
GymPulseTimer/TimerModels.swift                         # Core data types
GymPulseTimer/Core/Audio/AudioCueManager.swift          # Audio + voice cues
GymPulseTimer/Core/Models/Preset.swift                  # Preset model
GymPulseTimer/Core/Persistence/PresetStore.swift        # UserDefaults persistence
GymPulseTimer/Core/Theme/AppTheme.swift                 # Theme enum
GymPulseTimer/Features/Presets/TimersListView.swift     # Home preset list
GymPulseTimer/Features/Setup/SetupView.swift            # Preset configuration
GymPulseTimer/Features/Run/RunView.swift                # Active workout screen
GymPulseTimer/Features/Run/ProgressRingView.swift       # Circular progress ring
GymPulseTimer/GymPulseLiveActivityAttributes.swift      # ActivityKit attributes
GymPulseTimer/GymPulseLiveActivityManager.swift         # Live Activity manager
GymPulseTimer/GymPulseTimerLiveActivityWidget.swift     # Live Activity UI
GymPulseTimerWidget/GymPulseTimerWidgetBundle.swift     # Widget bundle
GymPulseTimerWidget/GymPulseTimerWidget.swift           # Home screen widget (template)
docs/Plan.md, PRD.md, Architecture.md, QA.md, AppStoreNotes.md
```
