//
//  AchievementManagerTests.swift
//  SetDeckTests
//
//  Created by Nick Molargik on 2/16/26.
//

import Foundation
import Testing
import SwiftData
@testable import SetDeck

@MainActor
@Suite("AchievementManager Tests")
struct AchievementManagerTests {
    var container: ModelContainer!
    var exerciseManager: ExerciseManager!
    var sut: AchievementManager!

    init() {
        // Clear any leftover celebrated achievements
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.celebratedAchievements)

        do {
            container = try ModelContainer(
                for: SetDeckRoutine.self,
                SetDeckExercise.self,
                SetDeckSet.self,
                SetDeckSetHistory.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        } catch {
            #expect(Bool(false), "Failed to create in-memory ModelContainer: \(error)")
        }

        let context = container.mainContext
        exerciseManager = ExerciseManager(context: context)
        sut = AchievementManager(exerciseManager: exerciseManager)
    }

    // MARK: - First Workout

    @Test("firstWorkout unlocks after recording one history entry")
    func firstWorkout_unlocksAfterOneHistory() throws {
        // Given: no history
        #expect(!sut.unlockedAchievements.contains("firstWorkout"))

        // When: record one set
        let exercise = exerciseManager.addExercise(named: "Squat", toDay: 0)
        let set = try #require(exerciseManager.sets(for: exercise).first)
        _ = exerciseManager.recordHistory(for: set, actualReps: 10, actualWeight: 100)

        // Then
        sut.refreshUnlockedAchievements()
        #expect(sut.unlockedAchievements.contains("firstWorkout"))
    }

    // MARK: - Volume: Getting Started

    @Test("gettingStarted requires 10 sets")
    func gettingStarted_requires10Sets() throws {
        let exercise = exerciseManager.addExercise(named: "Bench", toDay: 0)
        let set = try #require(exerciseManager.sets(for: exercise).first)

        // Record 9 entries
        for _ in 0..<9 {
            _ = exerciseManager.recordHistory(for: set, actualReps: 10, actualWeight: 100)
        }
        sut.refreshUnlockedAchievements()
        #expect(!sut.unlockedAchievements.contains("gettingStarted"))

        // Record 10th
        _ = exerciseManager.recordHistory(for: set, actualReps: 10, actualWeight: 100)
        sut.refreshUnlockedAchievements()
        #expect(sut.unlockedAchievements.contains("gettingStarted"))
    }

    // MARK: - Strength Thresholds

    @Test("onePlate unlocks at 135 lbs")
    func onePlate_unlocksAt135() throws {
        let exercise = exerciseManager.addExercise(named: "Deadlift", toDay: 0)
        let set = try #require(exerciseManager.sets(for: exercise).first)

        // Below threshold
        _ = exerciseManager.recordHistory(for: set, actualReps: 5, actualWeight: 130)
        sut.refreshUnlockedAchievements()
        #expect(!sut.unlockedAchievements.contains("onePlate"))

        // At threshold
        _ = exerciseManager.recordHistory(for: set, actualReps: 5, actualWeight: 135)
        sut.refreshUnlockedAchievements()
        #expect(sut.unlockedAchievements.contains("onePlate"))
    }

    // MARK: - Routine: Building Blocks

    @Test("buildingBlocks unlocks with exercises on 5 days")
    func buildingBlocks_unlocksWithExercisesOn5Days() {
        // Add exercises to 4 days
        for day in 0..<4 {
            _ = exerciseManager.addExercise(named: "Exercise \(day)", toDay: day)
        }
        sut.refreshUnlockedAchievements()
        #expect(!sut.unlockedAchievements.contains("buildingBlocks"))

        // Add exercise to 5th day
        _ = exerciseManager.addExercise(named: "Exercise 4", toDay: 4)
        sut.refreshUnlockedAchievements()
        #expect(sut.unlockedAchievements.contains("buildingBlocks"))
    }

    // MARK: - Celebration & Dismissal

    @Test("checkAchievements fires pending celebration for newly unlocked")
    func checkAchievements_firesCelebration() throws {
        // Clear celebrated state
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.celebratedAchievements)

        let exercise = exerciseManager.addExercise(named: "Squat", toDay: 0)
        let set = try #require(exerciseManager.sets(for: exercise).first)
        _ = exerciseManager.recordHistory(for: set, actualReps: 10, actualWeight: 100)

        // Manually trigger check (onDataMutated already called, but let's be explicit)
        sut.checkAchievements()

        #expect(sut.pendingCelebration != nil)
    }

    @Test("dismissCelebration clears pending")
    func dismissCelebration_clearsPending() throws {
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.celebratedAchievements)

        let exercise = exerciseManager.addExercise(named: "Squat", toDay: 0)
        let set = try #require(exerciseManager.sets(for: exercise).first)
        _ = exerciseManager.recordHistory(for: set, actualReps: 10, actualWeight: 100)
        sut.checkAchievements()
        #expect(sut.pendingCelebration != nil)

        sut.dismissCelebration()
        #expect(sut.pendingCelebration == nil)
    }

    // MARK: - No Re-trigger

    @Test("celebrated achievements are not re-triggered")
    func celebrated_notRetriggered() throws {
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.celebratedAchievements)

        let exercise = exerciseManager.addExercise(named: "Squat", toDay: 0)
        let set = try #require(exerciseManager.sets(for: exercise).first)
        _ = exerciseManager.recordHistory(for: set, actualReps: 10, actualWeight: 100)

        sut.checkAchievements()
        let first = sut.pendingCelebration
        #expect(first != nil)

        sut.dismissCelebration()

        // Check again with no new data changes
        sut.checkAchievements()
        #expect(sut.pendingCelebration == nil)
    }

    // MARK: - Reset

    @Test("resetAllAchievements clears everything")
    func resetAllAchievements_clearsEverything() throws {
        let exercise = exerciseManager.addExercise(named: "Squat", toDay: 0)
        let set = try #require(exerciseManager.sets(for: exercise).first)
        _ = exerciseManager.recordHistory(for: set, actualReps: 10, actualWeight: 100)
        sut.refreshUnlockedAchievements()
        #expect(!sut.unlockedAchievements.isEmpty)

        sut.resetAllAchievements()
        #expect(sut.unlockedAchievements.isEmpty)
        #expect(sut.pendingCelebration == nil)
    }
}
