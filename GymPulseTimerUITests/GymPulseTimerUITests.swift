//
//  GymPulseTimerUITests.swift
//  GymPulseTimerUITests
//
//  Created by web3bit on 26.01.26.
//

import XCTest

final class GymPulseTimerUITests: XCTestCase {

    private var app: XCUIApplication!

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITest"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    /// Waits for an element to exist within the given timeout.
    @discardableResult
    private func waitForElement(
        _ element: XCUIElement,
        timeout: TimeInterval = 5
    ) -> XCUIElement {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, "Expected element \(element) to exist within \(timeout)s")
        return element
    }

    /// Navigates from the Setup screen to the Run screen by tapping "Start Workout".
    private func navigateToRunScreen() {
        let startButton = app.buttons["Start Workout"]
        // The button may be off-screen; scroll down to find it.
        if !startButton.isHittable {
            app.swipeUp()
        }
        waitForElement(startButton)
        startButton.tap()
    }

    // MARK: - 1. App Launch

    func testAppLaunchShowsSetupScreen() throws {
        // The app opens to SetupView inside a NavigationStack with title "Gym Pulse Timer".
        let navTitle = app.navigationBars["Gym Pulse Timer"]
        waitForElement(navTitle)
    }

    func testAppLaunchShowsIntervalsSectionHeader() throws {
        // The Intervals section header should be visible on launch.
        let intervalsHeader = app.staticTexts["Intervals"]
        waitForElement(intervalsHeader)
    }

    // MARK: - 2. Setup Screen Sections

    func testSetupScreenShowsIntervalLabels() throws {
        // Verify the three interval labels exist.
        waitForElement(app.staticTexts["Get Ready"])
        waitForElement(app.staticTexts["Work"])
        waitForElement(app.staticTexts["Rest"])
    }

    func testSetupScreenShowsWorkoutStructureSection() throws {
        // Scroll to ensure Workout Structure is visible.
        app.swipeUp()
        waitForElement(app.staticTexts["Workout Structure"])
        waitForElement(app.staticTexts["Sets"])
        waitForElement(app.staticTexts["Rounds"])
    }

    func testSetupScreenShowsAudioSection() throws {
        app.swipeUp()
        waitForElement(app.staticTexts["Audio"])

        // The Sound and Voice toggles should be present.
        let soundToggle = app.switches["Sound"]
        let voiceToggle = app.switches["Voice (EN)"]
        waitForElement(soundToggle)
        waitForElement(voiceToggle)
    }

    func testSetupScreenShowsAppearanceSection() throws {
        app.swipeUp()
        waitForElement(app.staticTexts["Appearance"])
    }

    func testSetupScreenShowsPresetsSection() throws {
        // Scroll down far enough to reveal the Presets section.
        app.swipeUp()
        app.swipeUp()
        waitForElement(app.staticTexts["Presets"])
    }

    func testSetupScreenShowsStartWorkoutButton() throws {
        // The Start Workout button should exist (may need scrolling).
        app.swipeUp()
        app.swipeUp()
        let startButton = app.buttons["Start Workout"]
        waitForElement(startButton)
    }

    // MARK: - 3. Preset Flow

    func testPresetsShowsSavePresetButton() throws {
        // Scroll to the Presets section and verify the Save Preset button.
        app.swipeUp()
        app.swipeUp()
        let savePresetButton = app.buttons["Save Preset"]
        waitForElement(savePresetButton)
    }

    // MARK: - 4. Start Workout / Run Screen

    func testStartWorkoutNavigatesToRunScreen() throws {
        navigateToRunScreen()

        // The Run screen should show "Gym Pulse Timer" as a static text title.
        let title = app.staticTexts["Gym Pulse Timer"]
        waitForElement(title)
    }

    func testRunScreenShowsPhaseLabel() throws {
        navigateToRunScreen()

        // The initial phase should be "GET READY".
        let phaseLabel = app.staticTexts["GET READY"]
        waitForElement(phaseLabel)
    }

    func testRunScreenShowsTimerDisplay() throws {
        navigateToRunScreen()

        // A timer string in MM:SS format should be visible (e.g. "00:10").
        // We verify that a time-formatted static text exists by checking for
        // the colon separator pattern. The exact value depends on the default
        // Get Ready interval, so we look for any text matching a time format.
        let timerTexts = app.staticTexts.matching(
            NSPredicate(format: "label MATCHES %@", "\\d{2}:\\d{2}(:\\d{2})?")
        )
        let exists = timerTexts.firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "Expected a timer display in MM:SS or HH:MM:SS format")
    }

    func testRunScreenShowsSetAndRoundInfo() throws {
        navigateToRunScreen()

        // Set and round indicators should be visible.
        let setLabel = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Set ")
        ).firstMatch
        let roundLabel = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Round ")
        ).firstMatch

        waitForElement(setLabel)
        waitForElement(roundLabel)
    }

    // MARK: - 5. Run Screen Controls

    func testRunScreenShowsPauseButton() throws {
        navigateToRunScreen()
        let pauseButton = app.buttons["Pause"]
        waitForElement(pauseButton)
    }

    func testRunScreenShowsRestartButton() throws {
        navigateToRunScreen()
        let restartButton = app.buttons["Restart"]
        waitForElement(restartButton)
    }

    func testRunScreenShowsStopButton() throws {
        navigateToRunScreen()
        let stopButton = app.buttons["Stop"]
        waitForElement(stopButton)
    }

    func testRunScreenPauseButtonToggles() throws {
        navigateToRunScreen()

        // Initially should show "Pause".
        let pauseButton = app.buttons["Pause"]
        waitForElement(pauseButton)
        pauseButton.tap()

        // After tapping, the button label should change to "Resume".
        let resumeButton = app.buttons["Resume"]
        waitForElement(resumeButton)

        // Tap again to go back to "Pause".
        resumeButton.tap()
        waitForElement(app.buttons["Pause"])
    }

    // MARK: - 6. Stop Workout

    func testStopButtonReturnsToSetupScreen() throws {
        navigateToRunScreen()

        // Verify we are on the Run screen.
        waitForElement(app.staticTexts["GET READY"])

        // Tap Stop to dismiss.
        let stopButton = app.buttons["Stop"]
        waitForElement(stopButton)
        stopButton.tap()

        // Should return to the Setup screen with the navigation title.
        let navTitle = app.navigationBars["Gym Pulse Timer"]
        waitForElement(navTitle)
    }

    func testRestartButtonResetsTimer() throws {
        navigateToRunScreen()

        // Wait a moment so the timer progresses slightly, then restart.
        let phaseLabel = app.staticTexts["GET READY"]
        waitForElement(phaseLabel)

        let restartButton = app.buttons["Restart"]
        waitForElement(restartButton)
        restartButton.tap()

        // After restart, the phase should still be "GET READY" (timer resets to beginning).
        waitForElement(app.staticTexts["GET READY"])
    }

    // MARK: - 7. Launch Performance

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
