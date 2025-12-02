//
//  SetDeckTests.swift
//  SetDeckTests
//
//  Created by Nick Molargik on 11/7/25.
//

import Foundation
import Testing
import SwiftData
@testable import SetDeck

@MainActor
@Suite("ExerciseManager Tests")
struct ExerciseManagerTests {
    // Shared test context
    var container: ModelContainer!
    var sut: ExerciseManager!  // System under test
    
    init() {
        do {
            // In-memory container for isolated, non-persistent tests.
            // Include all relevant models; add more if your schema has additional entities.
            container = try ModelContainer(
                for: SetDeckRoutine.self,
                SetDeckExercise.self,
                SetDeckSet.self,
                SetDeckSetHistory.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        } catch {
            // In Swift Testing, use #expect with .failure to mark test failure
            #expect(Bool(false), "Failed to create in-memory ModelContainer: \(error)")
        }
        
        let context = container.mainContext
        sut = ExerciseManager(context: context)
    }
    
    // MARK: - Routine Tests
    
    @Test("allRoutines initially returns empty array")
    func allRoutines_InitiallyReturnsEmptyArray() {
        // Given: Fresh manager with empty store
        
        // When
        let routines = sut.allRoutines()
        
        // Then
        #expect(routines.count == 0)
    }
    
    @Test("routine(for:) creates new routine when none exists")
    func routineForDay_CreatesNewRoutineWhenNoneExists() {
        // Given: No routine for day 0
        
        // When
        let routine = sut.routine(for: 0)
        
        // Then
        #expect(routine.day == 0)
        #expect(sut.allRoutines().count == 1)
        #expect(sut.allRoutines().contains { $0.day == 0 })
    }
    
    @Test("routine(for:) returns existing routine")
    func routineForDay_ReturnsExistingRoutine() {
        // Given: Routine already created for day 1
        _ = sut.routine(for: 1)
        
        // When
        let routine = sut.routine(for: 1)
        
        // Then
        #expect(routine.day == 1)
        #expect(sut.allRoutines().count == 1)
    }
    
    @Test("allRoutines sorts by day ascending")
    func allRoutines_SortsByDayAscending() {
        // Given: Routines for days 2, 0, 1 created
        _ = sut.routine(for: 2)
        _ = sut.routine(for: 0)
        _ = sut.routine(for: 1)
        
        // When
        let routines = sut.allRoutines()
        
        // Then
        #expect(routines.count == 3)
        let days = routines.map { $0.day }
        #expect(days == [0, 1, 2])
    }
    
    // MARK: - Exercise Tests
    
    @Test("exercises(forDay:) initially returns empty array")
    func exercisesForDay_InitiallyReturnsEmptyArray() {
        // Given: Routine exists but no exercises
        
        // When
        let exercises = sut.exercises(forDay: 0)
        
        // Then
        #expect(exercises.count == 0)
    }
    
    @Test("addExercise(toDay:) creates exercise with default set")
    func addExerciseToDay_CreatesExerciseWithDefaultSet() {
        // Given: Routine for day 0
        
        // When
        let exercise = sut.addExercise(named: "Squat", toDay: 0)
        
        // Then
        #expect(exercise.name == "Squat")
        #expect(sut.exercises(forDay: 0).count == 1)
        #expect(sut.sets(for: exercise).count == 1)  // Default set added
        let defaultSet = sut.sets(for: exercise).first!
        #expect(defaultSet.setType == .reps)
        #expect(defaultSet.targetReps == 10)
        #expect(defaultSet.rpe == 6)
        #expect(defaultSet.weight == 0)
    }
    
    @Test("addExercise(to:) sets correct order index")
    func addExerciseToRoutine_SetsCorrectOrderIndex() {
        // Given: Routine with two existing exercises
        let routine = sut.routine(for: 0)
        _ = sut.addExercise(named: "Bench", to: routine)
        _ = sut.addExercise(named: "Row", to: routine)
        
        // When
        let newExercise = sut.addExercise(named: "Deadlift", to: routine)
        
        // Then
        let exercises = sut.exercises(for: routine)
        #expect(exercises.count == 3)
        #expect(newExercise.orderIndex == 2)  // Next index after 0,1
    }
    
    @Test("renameExercise updates name and saves")
    func renameExercise_UpdatesNameAndSaves() {
        // Given: Existing exercise
        let exercise = sut.addExercise(named: "Old Name", toDay: 0)
        
        // When
        sut.renameExercise(exercise, to: "New Name")
        
        // Then
        #expect(exercise.name == "New Name")
    }
    
    @Test("reorderExercises updates order indices")
    func reorderExercises_UpdatesOrderIndices() {
        // Given: Three exercises in order 0,1,2
        let routine = sut.routine(for: 0)
        let ex1 = sut.addExercise(named: "A", to: routine)
        let ex2 = sut.addExercise(named: "B", to: routine)
        let ex3 = sut.addExercise(named: "C", to: routine)
        
        // When: Reorder to [ex3, ex1, ex2]
        let newOrder = [ex3, ex1, ex2]
        sut.reorderExercises(in: routine, newOrder: newOrder)
        
        // Then
        #expect(ex3.orderIndex == 0)
        #expect(ex1.orderIndex == 1)
        #expect(ex2.orderIndex == 2)
    }
    
    @Test("deleteExercise removes exercise and reindexes remaining")
    func deleteExercise_RemovesExerciseAndReindexesRemaining() {
        // Given: Three exercises
        let routine = sut.routine(for: 0)
        let _ = sut.addExercise(named: "A", to: routine)
        let ex2 = sut.addExercise(named: "B", to: routine)
        _ = sut.addExercise(named: "C", to: routine)
        
        // When: Delete middle one
        sut.deleteExercise(ex2)
        
        // Then
        let remaining = sut.exercises(for: routine)
        #expect(remaining.count == 2)
        #expect(remaining[0].orderIndex == 0)  // ex1
        #expect(remaining[1].orderIndex == 1)  // ex3, reindexed
        #expect(remaining.contains { $0.uuid == ex2.uuid } == false)
    }
    
    // MARK: - Set Tests
    
    @Test("sets(for:) initially returns default set")
    func setsForExercise_InitiallyReturnsDefaultSet() {
        // Given: New exercise (which adds one default set)
        let exercise = sut.addExercise(named: "Test", toDay: 0)
        
        // When
        let sets = sut.sets(for: exercise)
        
        // Then
        #expect(sets.count == 1)
    }
    
    @Test("addSet(to:) sets correct order index")
    func addSetToExercise_SetsCorrectOrderIndex() {
        // Given: Exercise with one set
        let exercise = sut.addExercise(named: "Test", toDay: 0)
        _ = sut.sets(for: exercise)  // Confirm initial
        
        // When: Add second set
        let newSet = sut.addSet(to: exercise, setType: .duration, targetDuration: 30)
        
        // Then
        let sets = sut.sets(for: exercise)
        #expect(sets.count == 2)
        #expect(newSet.orderIndex == 1)
        #expect(newSet.setType == .duration)
        #expect(newSet.targetDuration == 30)
    }
    
    @Test("reorderSets updates order indices")
    func reorderSets_UpdatesOrderIndices() {
        // Given: Exercise with three sets
        let exercise = sut.addExercise(named: "Test", toDay: 0)
        let set1 = sut.addSet(to: exercise)
        let set2 = sut.addSet(to: exercise)
        let set3 = sut.addSet(to: exercise)
        
        // When: Reorder to [set3, set1, set2]
        let newOrder = [set3, set1, set2]
        sut.reorderSets(in: exercise, newOrder: newOrder)
        
        // Then
        #expect(set3.orderIndex == 0)
        #expect(set1.orderIndex == 1)
        #expect(set2.orderIndex == 2)
    }
    
    @Test("deleteSet removes set and reindexes remaining")
    func deleteSet_RemovesSetAndReindexesRemaining() {
        // Given: Three sets (default + 2 added)
        let exercise = sut.addExercise(named: "Test", toDay: 0) // default set1
        let set2 = sut.addSet(to: exercise)                      // set2 (middle)
        _ = sut.addSet(to: exercise)                             // set3
        
        // When: Delete middle one
        sut.deleteSet(set2)
        
        // Then
        let remaining = sut.sets(for: exercise)
        #expect(remaining.count == 2)
        #expect(remaining[0].orderIndex == 0)  // set1
        #expect(remaining[1].orderIndex == 1)  // set3, reindexed
        #expect(remaining.contains { $0.uuid == set2.uuid } == false)
    }
    
    // MARK: - History Tests
    
    @Test("allHistoryEntries initially returns empty array")
    func allHistoryEntries_InitiallyReturnsEmptyArray() {
        // Given: Fresh manager
        
        // When
        let histories = sut.allHistoryEntries()
        
        // Then
        #expect(histories.count == 0)
    }
    
    @Test("history(for:) initially returns empty array")
    func historyForExercise_InitiallyReturnsEmptyArray() {
        // Given: Exercise with no history
        let exercise = sut.addExercise(named: "Test", toDay: 0)
        
        // When
        let histories = sut.history(for: exercise)
        
        // Then
        #expect(histories.count == 0)
    }
    
    @Test("recordHistory adds entry to set and exercise history")
    func recordHistory_AddsEntryToSetAndExerciseHistory() {
        // Given: Exercise and set
        let exercise = sut.addExercise(named: "Test", toDay: 0)
        let set = sut.sets(for: exercise).first!
        
        // When
        let history = sut.recordHistory(for: set, actualReps: 12, actualWeight: 100, actualRpe: 8)
        
        // Then
        #expect(history.actualReps == 12)
        #expect(history.actualWeight == 100)
        #expect(history.actualRpe == 8)
        #expect(sut.history(for: exercise).count == 1)
        #expect(sut.allHistoryEntries().count == 1)
        #expect(set.history?.contains { $0.uuid == history.uuid } ?? false)
    }
    
    @Test("update(set:withReps:weight:rpe:) updates targets and records history")
    func updateSetWithValues_UpdatesTargetsAndRecordsHistory() {
        // Given: Set
        let exercise = sut.addExercise(named: "Test", toDay: 0)
        let set = sut.sets(for: exercise).first!
        
        // When
        sut.update(set: set, withReps: 12, weight: 100, rpe: 8)
        
        // Then
        #expect(set.targetReps == 12)
        #expect(set.weight == 100)
        #expect(set.rpe == 8)
        #expect(sut.history(for: exercise).count == 1)
        let recorded = sut.history(for: exercise).first!
        #expect(recorded.actualReps == 12)
        #expect(recorded.actualWeight == 100)
        #expect(recorded.actualRpe == 8)
        #expect(abs(recorded.completedDate.timeIntervalSinceNow) <= 1.0)  // Recent
    }
    
    @Test("clearAllHistory removes all entries")
    func clearAllHistory_RemovesAllEntries() {
        // Given: Some history exists
        let exercise = sut.addExercise(named: "Test", toDay: 0)
        let set = sut.sets(for: exercise).first!
        _ = sut.recordHistory(for: set)
        _ = sut.recordHistory(for: set)
        #expect(sut.allHistoryEntries().count == 2)
        
        // When
        sut.clearAllHistory()
        
        // Then
        #expect(sut.allHistoryEntries().count == 0)
        #expect((set.history?.isEmpty ?? true) == true)
    }
    
    // MARK: - Sample Data Tests (Development Only)
    
    @Test("generateSampleDataForLast30Days creates expected history volume")
    func generateSampleDataForLast30Days_CreatesExpectedHistoryVolume() {
        // Given: Empty store (fresh init)
        
        // When
        sut.generateSampleDataForLast30Days()
        
        // Then: Expect ~30 days * ~7 routines * ~10 exercises * ~2 sets = ~4200 history entries
        // Exact count varies due to randomization, but should be in ballpark (e.g., 3000-5000)
        let histories = sut.allHistoryEntries()
        #expect(histories.count > 400)
        #expect(histories.count < 800)
        
        // Verify routines and exercises were populated
        #expect(sut.allRoutines().count == 7)
        let day0Exercises = sut.exercises(forDay: 0)
        #expect(day0Exercises.count > 7)  // ~8-12
    }
    
    @Test("generateSampleDataForLast30Days aborts if history exists")
    func generateSampleDataForLast30Days_AbortsIfHistoryExists() {
        // Given: Existing history
        let exercise = sut.addExercise(named: "Test", toDay: 0)
        let set = sut.sets(for: exercise).first!
        _ = sut.recordHistory(for: set)
        
        // When
        sut.generateSampleDataForLast30Days()
        
        // Then: History count unchanged
        #expect(sut.allHistoryEntries().count == 1)
    }
}

