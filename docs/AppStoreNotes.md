# App Store Notes — GymPulseTimer

## App description
**Short (App Store subtitle or summary):**
Simple HIIT interval timer with presets, Live Activities, and voice cues.

**Long (App Store description):**
GymPulseTimer is a focused, no-nonsense workout timer. Create presets with Get Ready, Work, Rest, Sets, and Rounds, then run them with a large ring and easy-to-read countdown.

Track your workout right from the Lock Screen and Dynamic Island with Live Activities — see your countdown, progress bar, and current phase without unlocking your phone.

Get clear audio cues for phase changes, optional voice prompts, and quick controls to pause, resume, restart, or stop. Everything stays on device — no accounts, no analytics, no cloud sync.

## Keywords (draft)
hiit, interval timer, workout timer, tabata, fitness, training, rounds, sets, cardio, stopwatch, timer, workout, live activity, dynamic island

## Category
- Primary: Health & Fitness
- Suggested secondary: Lifestyle (optional)

## Privacy stance / Nutrition Label notes
- **Data Not Collected:** The app does not collect data from the user.
- **No tracking:** No third‑party analytics or ads.
- **Local‑only:** Presets are stored on device; no network requests in V1.
- **Accounts:** No login or account system.

## Monetization
- **V1:** Free (no ads, no subscriptions, no in‑app purchases).
- **Future:** TBD; avoid mentioning until implemented.

## App Store submission checklist (V1)
- **Bundle ID:** Confirm final identifier (e.g., `com.company.gympulsetimer`).
- **Versioning:** Set marketing version (1.0) + build number.
- **App name + subtitle:** Finalize copy.
- **Description + keywords:** Use the text above; keep keywords within App Store limits.
- **Category:** Health & Fitness (secondary optional).
- **Screenshots:** Provide required iPhone sizes per App Store Connect (usually 6.7" and 6.5").
- **App Icon:** 1024×1024 marketing icon.
- **Support URL / Privacy Policy URL:** Provide links (privacy policy still recommended even if no data).
- **Review notes:** Note there is no login; mention audio cues, Live Activities, and how to start a timer. Mention the app uses `NSSupportsLiveActivities` for Lock Screen and Dynamic Island.
- **Export compliance:** No encryption beyond standard OS APIs (confirm in App Store Connect).
- **Content rights / health claims:** Avoid claims of medical benefits.

## TestFlight steps (high‑level)
1. Increment build number in Xcode.
2. Archive and upload via Xcode Organizer.
3. Wait for App Store Connect processing to finish.
4. Add internal testers and validate the build.
5. For external testers, submit for beta review with test notes.

## Common rejection pitfalls (relevant to this app)
- Claiming features not in the build (e.g., background audio or health metrics).
- Misleading health/medical claims (avoid “guaranteed weight loss” or medical language).
- Missing/incorrect privacy labels or privacy policy link.
- Screenshot/metadata mismatch with the actual UI.
- Stating background functionality without the required background modes/behavior.
