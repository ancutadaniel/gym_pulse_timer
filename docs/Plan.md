# GymPulseTimer (iOS) — PLAN

## Next up
1. [ ] Epic 8: Run QA checklist (timing, background/foreground, audio/voice, Live Activity) and fix issues.
2. [ ] Epic 8: App Store prep (privacy labels, TestFlight notes, screenshots, submission checklist).

## Milestones
- [x] Milestone: App builds + runs, no console warnings, basic flow working.
- [x] Milestone: System light/dark theme support (semantic colors) + previews.
- [x] Milestone: In-app appearance selector (System/Light/Dark) implemented + persisted.
- [x] Milestone: Live Activities shipped (Lock Screen + Dynamic Island).
- [ ] Milestone: V1 QA + App Store submission ready.

## Goal
Build an iOS interval timer app (App Store-ready) that is extremely simple:
- user configures Get Ready, Work, Rest, Sets, Rounds
- big ring UI + big timer
- beep + voice cues ("Go", "Rest", "Workout complete")
- works on Lock Screen + Dynamic Island via Live Activities
- presets (save timers)
- no login, no analytics in V1
- iOS first; Android later

## V1 Scope
### Must-have
- [x] Presets list (Home: "Timers")
- [x] Create/Edit preset (Setup)
- [x] Run session screen (ring + pause/resume/restart)
- [x] Timer engine (endDate-based timing, no drift)
- [x] Audio cues: beep + voice (EN only)
- [x] Live Activities: Lock Screen + Dynamic Island
- [x] End behavior: "Workout complete" cue + stop
- [x] Local persistence for presets (UserDefaults)

### Nice-to-have (only if fast)
- [ ] Duplicate preset
- [ ] Simple "Keep screen on" toggle while running

## Out of scope (V1)
- Apple Watch app
- HealthKit integration
- Accounts / cloud sync
- History/logbook
- Ads (do later)
- Subscription model

## Default values & constraints
- Get Ready: 00:10 (allow 00:00 to disable)
- Work: 01:00
- Rest: 01:00
- Sets: 1 (range 1...99)
- Rounds: 4 (range 1...99)
- Duration limits: Work/Rest 00:00:01 → 00:30:00; Get Ready 00:00:00 → 00:30:00
- Duration step: 1 second (seconds 0–59, picker like iOS Timers)
- Preset name: 1–30 chars, trimmed; default to "New Timer" if empty
- Sound/voice defaults: enabled

## UX Reference
Match common HIIT timer apps:
- Setup uses wheel pickers (HH:MM:SS) like iOS Clock timers
- Running screen: big circular ring + phase label + set/round indicator
- Minimal controls

## Theme / Appearance
- [x] System light/dark theme support via semantic colors; light/dark previews added.
- [x] In-app appearance selector: System (default), Light, Dark.
- [x] Persist appearance preference locally and apply it app-wide at the root level.
- [x] Ensure appearance override does not affect `#Preview`-only settings.

## V1 Remaining Work (ordered)
1. [x] Appearance preference toggle (System/Light/Dark) with persistence + app-wide override.
2. [x] Epic 7: ActivityKit lifecycle (start/update/end, pause/resume) using endDate-based timing.
3. [x] Epic 7: Live Activity UI for Lock Screen + Dynamic Island (compact/expanded) + deep link.
4. [ ] Epic 8: QA pass using `docs/QA.md` + edge cases; fix issues.
5. [ ] Epic 8: App Store prep (privacy labels, TestFlight notes, screenshots, submission checklist).

### Nice-to-have (clearly separated)
- [ ] Duplicate preset
- [ ] Simple "Keep screen on" toggle while running

## Architecture (iOS)
- SwiftUI + MVVM
- Timer engine uses endDate computations
- Live Activities with ActivityKit for lock screen + Dynamic Island
- Uses `Text(timerInterval:countsDown:)` and `ProgressView(timerInterval:countsDown:)` for real-time lock screen updates
- Persistence: UserDefaults with JSON encoding via `PresetStore`

## File / Folder structure (actual)
```
GymPulseTimer/
  GymPulseTimerApp.swift              # App entry point
  ContentView.swift                   # Root navigation
  TimerEngine.swift                   # Timer state machine
  TimerModels.swift                   # TimerPhase, TimerConfiguration, TimerSessionState
  GymPulseLiveActivityAttributes.swift # ActivityKit attributes & content state
  GymPulseLiveActivityManager.swift   # Live Activity lifecycle manager
  GymPulseTimerLiveActivityWidget.swift # Live Activity UI (lock screen + Dynamic Island)
  Core/
    Audio/
      AudioCueManager.swift           # Beep + voice cue manager
    Models/
      Preset.swift                    # Preset data model
    Persistence/
      PresetStore.swift               # UserDefaults preset persistence
    Theme/
      AppTheme.swift                  # System/Light/Dark theme enum
  Features/
    Presets/
      TimersListView.swift            # Home screen preset list
    Setup/
      SetupView.swift                 # Preset create/edit screen
      Sections/
        SetupSectionCard.swift        # Reusable section card container
        SetupIntervalsSectionView.swift    # Duration wheel pickers
        SetupWorkoutStructureSectionView.swift # Sets & Rounds steppers
        SetupAudioSectionView.swift   # Sound & Voice toggles
        SetupAppearanceSectionView.swift   # Theme picker
        SetupPresetsSectionView.swift # Preset list & management
    Run/
      RunView.swift                   # Active workout screen
      ProgressRingView.swift          # Circular progress ring
GymPulseTimerWidget/
  GymPulseTimerWidgetBundle.swift     # Widget bundle entry
  GymPulseTimerWidget.swift           # Home screen widget (template)
  GymPulseTimerWidgetLiveActivity.swift # Widget extension live activity (template)
docs/
  Plan.md
  PRD.md
  Architecture.md
  QA.md
  AppStoreNotes.md
```

## Data model
### Preset
- id: UUID
- name: String
- getReadySeconds: Int
- workSeconds: Int
- restSeconds: Int
- sets: Int
- rounds: Int
- soundEnabled: Bool
- voiceEnabled: Bool
- updatedAt: Date

### Session state (runtime)
- phase: getReady | work | rest | complete
- setIndex (1..sets), roundIndex (1..rounds)
- phaseEndDate: Date
- isPaused: Bool
- pausedRemainingSeconds: TimeInterval? (snapshot when paused)
- remainingSeconds computed from phaseEndDate - now
- transitions driven by endDate crossings + app lifecycle events

### Live Activity content state
- phase: LiveActivityPhase
- phaseEndDate: Date
- phaseDurationSeconds: TimeInterval (for progress calculation)
- setIndex, roundIndex: Int
- isPaused: Bool
- pausedRemainingSeconds: TimeInterval?

## Epics & Tasks
### Epic 1 — PRD + Acceptance Criteria
- [x] Write PRD (features, edge cases, acceptance criteria)
- [x] Define exact transition rules for sets/rounds
- [x] Define Live Activity display requirements

### Epic 2 — App Skeleton
- [x] Create Xcode project (SwiftUI)
- [x] Navigation (Home → Setup → Run)
- [x] System light/dark theme support (semantic colors) + previews

### Epic 3 — Presets
- [x] Persistence layer (UserDefaults + JSON)
- [x] Home list UI + empty state
- [x] Create/edit preset UI
- [x] Save/update/delete preset actions
- [ ] Duplicate preset (nice-to-have)

### Epic 4 — Timer Engine
- [x] State machine (Get Ready → Work ↔ Rest → Complete)
- [x] Sets & Rounds progression
- [x] Pause/resume/restart
- [ ] Unit tests for transitions/edge cases

### Epic 5 — Run UI
- [x] Circular progress ring
- [x] Big time text + phase label
- [x] Set/Round display
- [x] Controls: pause/resume/restart/stop

### Epic 6 — Audio & Voice
- [x] Beep on phase transitions
- [x] Voice: "Go" at Work start, "Rest" at Rest start
- [x] End: "Workout complete"
- [x] Audio session behavior

### Epic 7 — Live Activities
- [x] ActivityKit integration (start/update/end)
- [x] Lock screen widget UI (real-time countdown + progress bar)
- [x] Dynamic Island compact/expanded UI (circular progress + phase colors)
- [x] Deep link to app
- [x] NSSupportsLiveActivities entitlement enabled
- [x] Phase-specific colors matching app (orange/green/blue/gray)

### Epic 8 — QA + App Store
- [ ] QA checklist pass
- [ ] Privacy labels (no data collected in V1)
- [ ] TestFlight build steps + submission notes
- [ ] Home screen widget integration (currently template placeholder)

## Transition rules (canonical)
- Start: Get Ready (if getReadySeconds > 0) else Work
- Work → Rest
- Rest → next Work
- After each Work+Rest completes: advance round
- When round > rounds: reset round=1 and advance set
- When set > sets: Complete
- "Workout complete" cue when entering Complete phase
