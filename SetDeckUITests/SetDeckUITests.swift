//
//  SetDeckUITests.swift
//  SetDeckUITests
//
//  Created by Nick Molargik on 11/7/25.
//

import XCTest

final class SetDeckUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tab Navigation Tests

    @MainActor
    func testTabBarExists() throws {
        // Verify the tab bar is present
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")
    }

    @MainActor
    func testNavigateToStatsTab() throws {
        let statsTab = app.tabBars.buttons["Stats"]
        XCTAssertTrue(statsTab.waitForExistence(timeout: 5), "Stats tab should exist")

        statsTab.tap()

        // Verify we're on the Stats screen
        let statsTitle = app.navigationBars["Stats"]
        XCTAssertTrue(statsTitle.waitForExistence(timeout: 3), "Should navigate to Stats view")
    }

    @MainActor
    func testNavigateToHealthTab() throws {
        let healthTab = app.tabBars.buttons["Health"]
        XCTAssertTrue(healthTab.waitForExistence(timeout: 5), "Health tab should exist")

        healthTab.tap()

        // Verify we're on the Health screen
        let healthTitle = app.navigationBars["Health"]
        XCTAssertTrue(healthTitle.waitForExistence(timeout: 3), "Should navigate to Health view")
    }

    @MainActor
    func testNavigateToSettingsTab() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab should exist")

        settingsTab.tap()

        // Verify we're on the Settings screen
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3), "Should navigate to Settings view")
    }

    @MainActor
    func testNavigateBackToRoutineTab() throws {
        // Navigate away first
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Navigate back to Routine
        let routineTab = app.tabBars.buttons["Routine"]
        XCTAssertTrue(routineTab.waitForExistence(timeout: 5), "Routine tab should exist")

        routineTab.tap()

        // Verify we're on the Routine screen
        let routineTitle = app.navigationBars["SetDeck"]
        XCTAssertTrue(routineTitle.waitForExistence(timeout: 3), "Should navigate to Routine view")
    }

    // MARK: - Routine View Tests

    @MainActor
    func testDayPickerExists() throws {
        // The day picker should be visible on the main routine view
        // Look for day buttons (S, M, T, W, T, F, S)
        let mondayButton = app.buttons["M"]
        XCTAssertTrue(mondayButton.waitForExistence(timeout: 5), "Day picker should have Monday button")
    }

    @MainActor
    func testEditRoutineButtonExists() throws {
        let editRoutineButton = app.buttons["Edit Routine"]
        XCTAssertTrue(editRoutineButton.waitForExistence(timeout: 5), "Edit Routine button should exist")
    }

    @MainActor
    func testNavigateToEditRoutine() throws {
        let editRoutineButton = app.buttons["Edit Routine"]
        XCTAssertTrue(editRoutineButton.waitForExistence(timeout: 5))

        editRoutineButton.tap()

        // Should navigate to Edit Routine view
        let editTitle = app.navigationBars["Edit Routine"]
        XCTAssertTrue(editTitle.waitForExistence(timeout: 3), "Should navigate to Edit Routine view")
    }

    @MainActor
    func testCanNavigateBackFromEditRoutine() throws {
        let editRoutineButton = app.buttons["Edit Routine"]
        editRoutineButton.tap()

        // Wait for Edit Routine view
        let editTitle = app.navigationBars["Edit Routine"]
        XCTAssertTrue(editTitle.waitForExistence(timeout: 3))

        // Tap back button
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
        }

        // Should be back on main view
        let mainTitle = app.navigationBars["SetDeck"]
        XCTAssertTrue(mainTitle.waitForExistence(timeout: 3), "Should navigate back to main view")
    }

    // MARK: - Settings View Tests

    @MainActor
    func testSettingsTogglesExist() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Check for the toggle switches
        let waterToggle = app.switches["Display Water in Liters"]
        let dateToggle = app.switches["Use Day–Month–Year Dates"]

        XCTAssertTrue(waterToggle.waitForExistence(timeout: 5), "Water units toggle should exist")
        XCTAssertTrue(dateToggle.exists, "Date format toggle should exist")
    }

    @MainActor
    func testCanToggleSettings() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        let waterToggle = app.switches["Display Water in Liters"]
        XCTAssertTrue(waterToggle.waitForExistence(timeout: 5))

        // Get initial state
        let initialValue = waterToggle.value as? String

        // Toggle
        waterToggle.tap()

        // Verify state changed
        let newValue = waterToggle.value as? String
        XCTAssertNotEqual(initialValue, newValue, "Toggle value should change after tap")
    }

    @MainActor
    func testDangerZoneButtonsExist() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Scroll down to find danger zone buttons if needed
        let clearHistoryButton = app.buttons["Clear Set History"]
        let deleteRoutinesButton = app.buttons["Delete All Routines"]

        // These might need scrolling to find
        if !clearHistoryButton.exists {
            app.swipeUp()
        }

        XCTAssertTrue(clearHistoryButton.waitForExistence(timeout: 5), "Clear History button should exist")
        XCTAssertTrue(deleteRoutinesButton.exists, "Delete Routines button should exist")
    }

    // MARK: - Health View Tests

    @MainActor
    func testHealthViewLoads() throws {
        let healthTab = app.tabBars.buttons["Health"]
        healthTab.tap()

        // Health view should load (we can't test HealthKit interaction in UI tests)
        let healthTitle = app.navigationBars["Health"]
        XCTAssertTrue(healthTitle.waitForExistence(timeout: 5), "Health view should load")
    }

    // MARK: - Stats View Tests

    @MainActor
    func testStatsViewLoads() throws {
        let statsTab = app.tabBars.buttons["Stats"]
        statsTab.tap()

        // Stats view should load
        let statsTitle = app.navigationBars["Stats"]
        XCTAssertTrue(statsTitle.waitForExistence(timeout: 5), "Stats view should load")
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testMainViewAccessibilityElements() throws {
        // Check that key accessibility elements exist
        XCTAssertTrue(app.tabBars.firstMatch.exists, "Tab bar should be accessible")
    }

    // MARK: - Launch Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

// MARK: - Edit Routine UI Tests

final class SetDeckEditRoutineUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        // Navigate to Edit Routine
        let editRoutineButton = app.buttons["Edit Routine"]
        if editRoutineButton.waitForExistence(timeout: 5) {
            editRoutineButton.tap()
        }
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testAddExerciseButtonExists() throws {
        let addExerciseButton = app.buttons["Add Exercise"]
        XCTAssertTrue(addExerciseButton.waitForExistence(timeout: 5), "Add Exercise button should exist")
    }

    @MainActor
    func testDayPickerInEditRoutine() throws {
        // Day picker should also exist in edit routine view
        let mondayButton = app.buttons["M"]
        XCTAssertTrue(mondayButton.waitForExistence(timeout: 5), "Day picker should exist in Edit Routine")
    }
}
