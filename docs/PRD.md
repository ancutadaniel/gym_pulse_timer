# PRD: GymPulseTimer (iOS, SwiftUI)

## Overview
Build a simple, polished iOS interval timer app for HIIT workouts. Users create presets with Get Ready, Work, Rest, Sets, and Rounds, then run a session with a large ring UI, timer, and audio cues. Live Activities show progress on the Lock Screen and Dynamic Island. V1 is fully local with no login and no analytics.

## Goals
- Fast setup with wheel pickers and reusable presets.
- Accurate timing with endDate-based countdown and no drift.
- Clear, minimal run experience with audio + voice cues.
- Live Activities for lock screen and Dynamic Island.

## Non-Goals (V1)
- Accounts, cloud sync, analytics, ads, or subscriptions.
- Apple Watch app, HealthKit, workout history/logbook.

## User Stories
- As a user, I can create a timer preset with Get Ready, Work, Rest, Sets, and Rounds.
- As a user, I can start a preset and see a big timer with a progress ring and phase label.
- As a user, I hear a beep and voice cues when phases change.
- As a user, I can pause and resume a running session without losing my place.
- As a user, I can lock my phone and still see the countdown in Live Activities.
- As a user, I can edit or delete a preset without losing other presets.

## Functional Requirements
### Presets
- Presets list is the home screen ("Timers").
- Create, edit, delete presets locally (SwiftData preferred, UserDefaults acceptable).
- Preset fields: name, getReadySeconds, workSeconds, restSeconds, sets, rounds, soundEnabled, voiceEnabled.
- Default values: Get Ready 00:10, Work 01:00, Rest 01:00, Sets 1, Rounds 4.

### Timer Setup (Create/Edit)
- Wheel pickers like iOS Timers for Get Ready, Work, Rest (HH:MM:SS).
- 1-second granularity; seconds wheel ranges 0–59.
- Min duration: Work/Rest 00:00:01; Get Ready 00:00:00 (off); max 00:30:00.
- Get Ready can be 00:00:00 to disable.
- Sets and Rounds use steppers or pickers with integer values.
- Save validates all fields and persists locally.

### Run Session
- Large circular ring, big timer label, phase label (Get Ready / Work / Rest / Complete).
- Set and Round indicators (e.g., "Set 1/3", "Round 2/4").
- Controls: Start, Pause, Resume, Restart, Sound toggle, Voice toggle.
- End behavior: play "Workout complete" and stop.

### Audio
- Beep on phase transitions.
- Voice cues (EN only): "Go" at Work start, "Rest" at Rest start, "Workout complete" at Complete.
- Sound and voice toggles control beep and voice independently.

### Live Activities (ActivityKit)
- Lock Screen and Dynamic Island show remaining time, phase, and set/round.
- Use endDate + timer-style UI to avoid per-second updates.
- Update Live Activity on start, pause, resume, phase change, and end.
- Deep link from Live Activity back into the running session.

### Data and Privacy
- No login, no analytics, no network requests in V1.
- Local-only storage of presets.

## Screen-by-Screen Requirements
### Home: Presets List ("Timers")
- List of presets with name and summary (e.g., "Get Ready 0:10, Work 1:00, Rest 1:00, 4 rounds").
- Primary action: create new preset.
- Tap a preset to start or edit (design choice: start by default, edit via button).
- Empty state with CTA to create a preset.
- Delete preset action.

### Setup: Create/Edit Preset
- Fields: Name, Get Ready, Work, Rest, Sets, Rounds, Sound toggle, Voice toggle.
- Duration pickers are HH:MM:SS wheel pickers with 1-second step (seconds 0–59).
- Save button validates and persists.
- Cancel exits without saving.

### Run Session
- Full-screen focus: ring, time, phase, set/round.
- Buttons: Pause/Resume, Restart, Exit (with confirmation if running).
- When complete, show "Workout complete" state and Restart option.
- If sound/voice toggles change during run, apply immediately to next cue.

### Live Activity UI (Lock Screen + Dynamic Island)
- Show phase, remaining time, and set/round.
- Compact view: time + phase.
- Expanded view: time, phase, set/round.
- Tapping opens the Run screen.

## Timer Model
### Phases
- `getReady`, `work`, `rest`, `complete`.

### Session State
- `phase`
- `setIndex` (1...sets)
- `roundIndex` (1...rounds)
- `phaseEndDate`
- `isPaused`
- `remainingSeconds` computed from `phaseEndDate - now` (0 floor).

## Timer Transition Rules (Canonical)
1. Start at `getReady` if `getReadySeconds > 0`, else start at `work`.
2. `getReady` → `work`.
3. `work` → `rest`.
4. `rest` → next `work`.
5. After each completed `work` + `rest` pair, advance `roundIndex`.
6. If `roundIndex > rounds`, reset `roundIndex = 1` and increment `setIndex`.
7. If `setIndex > sets`, transition to `complete` and stop.
8. On entering `complete`, play "Workout complete" voice cue and stop the timer.

## Edge Cases and Timing Rules
### Pause/Resume
- Pause freezes remaining time for the current phase.
- Resume sets a new `phaseEndDate = now + remainingSeconds`.
- Live Activity should show "Paused" with static remaining time.

### Background/Foreground
- Timer must remain accurate using `phaseEndDate` (no drift).
- If the app returns from background after the phase should have changed, the state must advance to the correct phase based on elapsed time.
- Live Activity should continue countdown based on endDate while the app is backgrounded.

### getReady = 0
- Skip `getReady` and start directly in `work`.
- No "Go" voice cue should play until work starts.

### Invalid or Unexpected Values
- If a duration is 0 for `work` or `rest` due to corrupted data, skip that phase and move to the next valid phase without crashing.
- If sets or rounds are out of range, clamp to valid min/max before starting.

### End Behavior
- On completion, timer stops and UI shows a completed state.
- Live Activity ends when the session is complete.

## Validation Rules
- Duration fields:
  - `getReadySeconds`: 0...1800 seconds.
  - `workSeconds`: 1...1800 seconds.
  - `restSeconds`: 1...1800 seconds.
  - 1-second granularity; seconds 0–59.
  - If allowZero is false, minimum duration is 1 second; if allowZero is true, minimum is 0.
- Sets: integer 1...99.
- Rounds: integer 1...99.
- Preset name: 1...30 characters, trimmed; default to "New Timer" if empty.
- Sound/voice toggles default to enabled.

## Acceptance Criteria (Testable)
- Creating a preset with default values saves and appears in the Home list.
- Duration pickers allow only 1-second increments (seconds 0–59) and enforce min/max.
- When allowZero is false, minimum duration is 00:00:01; when allowZero is true, minimum is 00:00:00.
- Get Ready set to 00:00:00 starts directly in Work.
- Work/Rest transitions follow the canonical rules for sets and rounds.
- Pausing freezes the remaining time; resuming continues from the same remaining time.
- Backgrounding the app does not alter the total elapsed timing.
- If the timer should have advanced while backgrounded, it advances correctly on foreground.
- Beep plays on phase changes when sound is enabled; no beep when disabled.
- Voice cues play at Work start ("Go"), Rest start ("Rest"), and Complete ("Workout complete") when enabled.
- Run screen shows the correct phase label, remaining time, and set/round at all times.
- Live Activity shows phase, remaining time, and set/round, and opens the app on tap.
- Live Activity updates at start, pause, resume, phase change, and end.
- Completing the session plays "Workout complete" and stops the timer.
- No login or analytics screens/requests exist in V1.