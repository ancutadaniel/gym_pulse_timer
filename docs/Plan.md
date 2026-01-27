# GymPulseTimer (iOS) — PLAN

## Next up
1. [ ] Add in-app Appearance preference (System/Light/Dark) with local persistence and app-wide override (does not touch `#Preview` settings).
2. [ ] Epic 7: ActivityKit lifecycle (start/update/end, pause/resume) using endDate-based timing.
3. [ ] Epic 7: Live Activity UI for Lock Screen + Dynamic Island (compact/expanded) + deep link.
4. [ ] Epic 8: Run QA checklist (timing, background/foreground, audio/voice, Live Activity) and fix issues.
5. [ ] Epic 8: App Store prep (privacy labels, TestFlight notes, screenshots, submission checklist).

## Milestones
- [ ] Milestone: App builds + runs, no console warnings, basic flow working.
- [ ] Milestone: System light/dark theme support (semantic colors) + previews.
- [ ] Milestone: In-app appearance selector (System/Light/Dark) implemented + persisted.
- [ ] Milestone: Live Activities shipped (Lock Screen + Dynamic Island).
- [ ] Milestone: V1 QA + App Store submission ready.

## Goal
Build an iOS interval timer app (App Store-ready) that is extremely simple:
- user configures Get Ready, Work, Rest, Sets, Rounds
- big ring UI + big timer
- beep + voice cues (“Go”, “Rest”, “Workout complete”)
- works on Lock Screen + Dynamic Island via Live Activities
- presets (save timers)
- no login, no analytics in V1
- iOS first; Android later

## V1 Scope
### Must-have
- [ ] Presets list (Home: “Timers”)
- [ ] Create/Edit preset (Setup)
- [ ] Run session screen (ring + pause/resume/restart)
- [ ] Timer engine (endDate-based timing, no drift)
- [ ] Audio cues: beep + voice (EN only)
- [ ] Live Activities: Lock Screen + Dynamic Island
- [ ] End behavior: “Workout complete” cue + stop
- [ ] Local persistence for presets (SwiftData or UserDefaults)

### Nice-to-have (only if fast)
- [ ] Duplicate preset
- [ ] Simple “Keep screen on” toggle while running

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
- Preset name: 1–30 chars, trimmed; default to “New Timer” if empty
- Sound/voice defaults: enabled

## UX Reference
Match common HIIT timer apps:
- Setup uses wheel pickers (HH:MM:SS) like iOS Clock timers
- Running screen: big circular ring + phase label + set/round indicator
- Minimal controls

## Theme / Appearance
- [ ] System light/dark theme support via semantic colors; light/dark previews added.
- [ ] In-app appearance selector: System (default), Light, Dark.
- [ ] Persist appearance preference locally and apply it app-wide at the root level.
- [ ] Ensure appearance override does not affect `#Preview`-only settings.

## V1 Remaining Work (ordered)
1. [ ] Appearance preference toggle (System/Light/Dark) with persistence + app-wide override.
2. [ ] Epic 7: ActivityKit lifecycle (start/update/end, pause/resume) using endDate-based timing.
3. [ ] Epic 7: Live Activity UI for Lock Screen + Dynamic Island (compact/expanded) + deep link.
4. [ ] Epic 8: QA pass using `docs/QA.md` + edge cases; fix issues.
5. [ ] Epic 8: App Store prep (privacy labels, TestFlight notes, screenshots, submission checklist).

### Nice-to-have (clearly separated)
- [ ] Duplicate preset
- [ ] Simple “Keep screen on” toggle while running

## Architecture (iOS)
- SwiftUI + MVVM
- Timer engine uses endDate computations
- Live Activities with ActivityKit for lock screen + Dynamic Island
- Avoid per-second Live Activity updates; use endDate + timer styling
- Persistence: Prefer SwiftData (clean preset list), fallback UserDefaults

## File / Folder structure
- docs/
  - PLAN.md
  - PRD.md
  - Architecture.md
  - QA.md
  - AppStoreNotes.md
- ios/
  - App/
  - Features/
    - Presets/
    - Setup/
    - Run/
  - Core/
    - Models/
    - TimerEngine/
    - Audio/
    - Persistence/
  - LiveActivity/ (Widget extension code may live in separate target folder)
- assets/
  - sounds/
  - icons/

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
- remainingSeconds computed from phaseEndDate - now
- transitions driven by endDate crossings + app lifecycle events

## Epics & Tasks
### Epic 1 — PRD + Acceptance Criteria
- [ ] Write PRD (features, edge cases, acceptance criteria)
- [ ] Define exact transition rules for sets/rounds
- [ ] Define Live Activity display requirements

### Epic 2 — App Skeleton
- [ ] Create Xcode project (SwiftUI)
- [ ] Navigation (Home → Setup → Run)
- [ ] System light/dark theme support (semantic colors) + previews

### Epic 3 — Presets
- [ ] Persistence layer
- [ ] Home list UI + empty state
- [ ] Create/edit preset UI
- [ ] Save/update/delete preset actions
- [ ] Duplicate preset (nice-to-have)

### Epic 4 — Timer Engine
- [ ] State machine (Get Ready → Work ↔ Rest → Complete)
- [ ] Sets & Rounds progression
- [ ] Pause/resume/restart
- [ ] Unit tests for transitions/edge cases

### Epic 5 — Run UI
- [ ] Circular progress ring
- [ ] Big time text + phase label
- [ ] Set/Round display
- [ ] Controls: pause/resume/restart/sound toggle

### Epic 6 — Audio & Voice
- [ ] Beep on phase transitions
- [ ] Voice: “Go” at Work start, “Rest” at Rest start
- [ ] End: “Workout complete”
- [ ] Audio session behavior

### Epic 7 — Live Activities
- [ ] ActivityKit integration (start/update/end)
- [ ] Lock screen widget UI
- [ ] Dynamic Island compact/expanded UI
- [ ] Deep link to app

### Epic 8 — QA + App Store
- [ ] QA checklist
- [ ] Privacy labels (no data collected in V1)
- [ ] TestFlight build steps + submission notes

## Agent prompts
### Agent A — PRD
Write a complete PRD for an iOS interval timer app (SwiftUI) with presets.
Features: Setup with duration wheel pickers like iOS Timers, Sets+Rounds, sound beep + voice cues (“Go”, “Rest”, “Workout complete”), Run screen with circular ring + big timer, Live Activities for lock screen + Dynamic Island, no login, local-only storage, iOS first.
Include: edge cases, validation rules (min 1s max 30m; Get Ready allows 0), acceptance criteria, and transition rules for sets/rounds.

### Agent B — Timer Engine
Implement a robust timer state machine for interval training with Sets and Rounds:
Get Ready → Work → Rest repeating across rounds and sets, then Complete.
Use endDate-based timing (no drift), support pause/resume/restart.
Expose observable state for SwiftUI. Provide clean code + unit tests.
Output as multiple files with paths.

### Agent C — Live Activities
Implement ActivityKit Live Activity + Widget extension for lock screen + Dynamic Island.
Store phase + endDate and use timer-style UI so countdown updates smoothly.
Provide code for start/update/end activity and widget UI.
Include deep link behavior. Output as multiple files with paths.

### Agent D — SwiftUI UI
Build SwiftUI UI for:
Home presets list (“Timers”), Setup screen with iOS-style wheel duration picker,
Run screen with circular progress ring, big time label, phase label,
set/round indicators, pause/resume/restart controls.
Keep minimal. Output as multiple files with paths.

### Agent E — QA
Create a full QA checklist: lock/unlock, Live Activity correctness, pause/resume,
audio/voice cues timing, low power mode, background/foreground, timer accuracy.

## Handoff rules (how agents interact)
1) After Agent A, paste key rules into docs/PRD.md.
2) Before Agent B, paste:
   - transition rules
   - model fields
   - acceptance criteria for timing
3) Before Agent C, paste:
   - the Session state fields (phase, endDate, set/round)
   - update moments (phase change, pause/resume, restart)
4) Before Agent D, paste:
   - public API of TimerEngine view model
   - UI requirements and screen routes
5) Every agent output must be saved into repo as files.

## Transition rules (canonical)
- Start: Get Ready (if getReadySeconds > 0) else Work
- Work → Rest
- Rest → next Work
- After each Work+Rest completes: advance round
- When round > rounds: reset round=1 and advance set
- When set > sets: Complete
- “Workout complete” cue when entering Complete phase
