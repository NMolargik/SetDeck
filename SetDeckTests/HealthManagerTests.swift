//
//  HealthManagerTests.swift
//  SetDeckTests
//
//  Created by Nick Molargik on 12/2/25.
//

import Testing
@testable import SetDeck
import HealthKit

@Suite("HealthManager Tests")
@MainActor
struct HealthManagerTests {

    // MARK: - Test Double

    /// A spy subclass that overrides HealthKit-touching methods so tests
    /// can assert behavior without actually talking to HealthKit.
    final class Spy: HealthManager {
        // MARK: Call tracking

        var refreshWaterTodayCallCount = 0
        var refreshCaloriesTodayCallCount = 0

        var addWaterCalls: [(ml: Double, date: Date)] = []
        var addCaloriesCalls: [(kcal: Double, date: Date)] = []

        // We don’t care about series/workouts here, so we leave those methods alone
        // and only intercept the pieces we want to assert.

        // MARK: Overrides

        override func refreshWaterToday() async {
            refreshWaterTodayCallCount += 1
            // Don’t call super: avoid HealthKit queries in tests
        }

        override func refreshCaloriesToday() async {
            refreshCaloriesTodayCallCount += 1
            // Don’t call super: avoid HealthKit queries in tests
        }

        override func addWater(ml: Double, date: Date = Date()) async throws {
            addWaterCalls.append((ml, date))
            // Don’t call super: skip HealthKit write
        }

        override func addCalories(kcal: Double, date: Date = Date()) async throws {
            addCaloriesCalls.append((kcal, date))
            // Don’t call super: skip HealthKit write
        }
    }

    // MARK: - Tests

    @Test("initial state has no authorization and zeroed totals")
    func initialState_defaults() {
        let sut = HealthManager()

        #expect(sut.isAuthorized == false)
        #expect(sut.todayWaterML == 0)
        #expect(sut.todayCaloriesKCal == 0)
        #expect(sut.waterIntakeSeries.isEmpty)
        #expect(sut.calorieIntakeSeries.isEmpty)
        #expect(sut.calorieBurnSeries.isEmpty)
        #expect(sut.workoutHistory.isEmpty)
        #expect(sut.workoutState == .notStarted)
        #expect(sut.currentWorkoutStartDate == nil)
        #expect(sut.isStrengthTrainingActive == false)
        #expect(sut.isWorkoutOngoing == false)
    }

    @Test("refreshTodayTotals calls both water and calorie refresh")
    func refreshTodayTotals_CallsSubtasks() async {
        let sut = Spy()

        await sut.refreshTodayTotals()

        #expect(sut.refreshWaterTodayCallCount == 1)
        #expect(sut.refreshCaloriesTodayCallCount == 1)
    }

    @Test("addWaterIntakeIfSupported calls addWater and triggers refresh")
    func addWaterIntakeIfSupported_CallsAddAndRefresh() async {
        let sut = Spy()
        let amount: Double = 250
        let date = Date()

        await sut.addWaterIntakeIfSupported(amountML: amount, date: date)

        // We expect one HealthKit write attempt via our spy
        #expect(sut.addWaterCalls.count == 1)
        #expect(sut.addWaterCalls.first?.ml == amount)

        // And that the 'today' total refresh was attempted
        #expect(sut.refreshWaterTodayCallCount == 1)

        // We don’t assert on series or WidgetCenter here because those are
        // more integration concerns.
    }

    @Test("addCalorieIntakeIfSupported calls addCalories and triggers refresh")
    func addCalorieIntakeIfSupported_CallsAddAndRefresh() async {
        let sut = Spy()
        let amount: Double = 600
        let date = Date()

        await sut.addCalorieIntakeIfSupported(amount: amount, date: date)

        #expect(sut.addCaloriesCalls.count == 1)
        #expect(sut.addCaloriesCalls.first?.kcal == amount)

        #expect(sut.refreshCaloriesTodayCallCount == 1)
    }

    @Test("isStrengthTrainingActive and isWorkoutOngoing reflect workoutState")
    func strengthTrainingFlagsReflectState() {
        let sut = HealthManager()

        sut.workoutState = .notStarted
        #expect(sut.isStrengthTrainingActive == false)
        #expect(sut.isWorkoutOngoing == false)

        sut.workoutState = .running
        #expect(sut.isStrengthTrainingActive == true)
        #expect(sut.isWorkoutOngoing == true)

        sut.workoutState = .paused
        #expect(sut.isStrengthTrainingActive == true)
        #expect(sut.isWorkoutOngoing == true)

        sut.workoutState = .ended
        #expect(sut.isStrengthTrainingActive == false)
        #expect(sut.isWorkoutOngoing == false)
    }

    @Test("convenience init(forWidget:) does not crash")
    func widgetInit_doesNotCrash() {
        // This mostly ensures the convenience init path is safe to call.
        // The Task it kicks off will run on the main actor and hit the spy
        // implementations if you swap in Spy(forWidget:).
        _ = HealthManager(forWidget: true)
        #expect(true) // If we got here, init didn't blow up.
    }
}
