# QA Checklist

## Test matrix (minimum)
- iPhone (latest iOS) + one older iOS if available
- Physical device for audio + lock screen behavior
- Simulator for quick UI regressions

## Core timer correctness
- Create a preset with default values, start the workout, and verify the phase order.
- Verify Sets/Rounds advance correctly at the end of each Work+Rest pair.
- Verify `getReady = 0` skips directly to Work.
- Verify Work/Rest of **1 second** each completes correctly without UI glitches.
- Verify end state shows completion UI and stops advancing.

## Pause / resume / restart
- Pause mid‑phase, wait 5–10 seconds, resume, and confirm remaining time is preserved.
- Pause during Rest, resume, and confirm the next phase triggers correctly.
- Restart during Work and verify it resets to the first phase for the current preset.

## Background / foreground
- Start a workout, lock the screen for 10–20 seconds, unlock, and verify remaining time is correct.
- Switch to another app for 10–20 seconds, return, and verify the timer advanced correctly.
- If the system kills the app while backgrounded, verify the app relaunches without crashing.

## Audio / voice cues
- With Sound + Voice enabled, verify beep + voice at phase changes.
- Disable Sound, keep Voice enabled; verify voice only.
- Disable Voice, keep Sound enabled; verify beep only.
- Disable both; verify silent transitions.
- Test with mute switch on/off and volume low/high.
- Repeat multiple phase transitions to ensure no missed cues or duplicate triggers.

## Preset persistence
- Save a new preset and confirm it appears in the list.
- Close and relaunch the app; confirm presets persist.
- Delete a preset and verify it is removed after relaunch.
- Save multiple presets and verify ordering is stable and names are trimmed.

## Theme / appearance
- System mode: toggle device appearance Light/Dark and confirm the app follows.
- If the Appearance picker is present: select System/Light/Dark and verify app updates immediately.
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
- No crashes, no repeated console errors.
