# QA Checklist

## Test matrix (minimum)
- iPhone (latest iOS) + one older iOS if available
- Physical device for audio + lock screen behavior + Live Activity
- Simulator for quick UI regressions

## Core timer correctness
- Create a preset with default values, start the workout, and verify the phase order.
- Verify Sets/Rounds advance correctly at the end of each Work+Rest pair.
- Verify `getReady = 0` skips directly to Work.
- Verify Work/Rest of **1 second** each completes correctly without UI glitches.
- Verify end state shows completion UI and stops advancing.

## Pause / resume / restart
- Pause mid-phase, wait 5-10 seconds, resume, and confirm remaining time is preserved.
- Pause during Rest, resume, and confirm the next phase triggers correctly.
- Restart during Work and verify it resets to the first phase for the current preset.

## Background / foreground
- Start a workout, lock the screen for 10-20 seconds, unlock, and verify remaining time is correct.
- Switch to another app for 10-20 seconds, return, and verify the timer advanced correctly.
- If the system kills the app while backgrounded, verify the app relaunches without crashing.

## Audio / voice cues
- With Sound + Voice enabled, verify beep + voice at phase changes.
- Disable Sound, keep Voice enabled; verify voice only.
- Disable Voice, keep Sound enabled; verify beep only.
- Disable both; verify silent transitions.
- Test with mute switch on/off and volume low/high.
- Repeat multiple phase transitions to ensure no missed cues or duplicate triggers.

## Live Activity — Lock Screen
- Start a workout and lock the phone; verify the Live Activity appears on the lock screen.
- Verify the countdown timer updates in real time (not frozen) on the lock screen.
- Verify the progress bar animates forward in real time on the lock screen.
- Verify the phase label updates when transitioning between phases (e.g., WORK → REST).
- Verify set/round indicators show correct values (e.g., "Set 1/1 - Round 2/4").
- Verify the timer text color matches the current phase (orange=getReady, green=work, blue=rest, gray=complete).
- Verify the progress bar color matches the current phase.
- Pause the timer and verify the lock screen shows "Paused" and a frozen time.
- Resume the timer and verify the lock screen countdown resumes from the correct time.
- Complete the workout and verify the Live Activity ends.
- Tap the Live Activity on the lock screen and verify it deep links back into the app.

## Live Activity — Dynamic Island (Expanded)
- Long-press the Dynamic Island pill to expand; verify it shows phase name, set/round, countdown, and progress bar.
- Verify the expanded countdown text has the correct phase color.
- Verify the progress bar animates and has the correct phase color.
- Verify the summary line shows correct set/round info and "Paused" when paused.

## Live Activity — Dynamic Island (Compact)
- Verify the compact pill shows the phase label on the left (e.g., "W", "R", "GR").
- Verify the compact pill shows a circular progress ring on the right.
- Verify the circular progress ring color matches the current phase.
- Verify the progress ring animates forward as the phase progresses.

## Live Activity — Dynamic Island (Minimal)
- When another Live Activity is active, verify the minimal view shows a circular progress ring.
- Verify the ring color matches the current phase.

## Live Activity — Edge Cases
- Start a workout, lock the phone, and wait for a full phase transition (e.g., work → rest); unlock and verify the Live Activity updated to the new phase.
- Tap Stop in the app; verify the Live Activity is removed from the lock screen and Dynamic Island.
- Start a new workout after stopping a previous one; verify a fresh Live Activity appears.

## Preset persistence
- Save a new preset and confirm it appears in the list.
- Close and relaunch the app; confirm presets persist.
- Delete a preset and verify it is removed after relaunch.
- Save multiple presets and verify ordering is stable and names are trimmed.

## Theme / appearance
- System mode: toggle device appearance Light/Dark and confirm the app follows.
- Select System/Light/Dark in the Appearance picker and verify app updates immediately.
- Relaunch the app and confirm the appearance setting persists.

## UI / usability checks
- Verify text is readable in both Light and Dark modes.
- Ensure ring and buttons remain visible with good contrast.
- Verify segmented controls and list rows look native in both themes.

## Performance sanity
- Watch the Xcode console for repeated warnings or errors.
- Ensure CPU usage stays reasonable during a running session.
- Verify no obvious UI stutter during the countdown.

## Regression checklist (before TestFlight)
- Fresh install → create preset → start workout → complete workout.
- Pause/resume/restart all work.
- Audio/voice toggles work and persist through the session.
- Preset save/delete works across app relaunch.
- Appearance setting behaves as expected.
- Live Activity appears on lock screen with real-time countdown and progress.
- Dynamic Island shows phase, progress, and correct colors.
- Live Activity ends when workout completes or is stopped.
- No crashes, no repeated console errors.
