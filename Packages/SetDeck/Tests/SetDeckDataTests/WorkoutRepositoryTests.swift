//
//  WorkoutRepositoryTests.swift
//  SetDeckDataTests
//
//  Behavior tests for the SwiftData-backed routine/history repositories, ported from
//  the old ExerciseManagerTests. Serialized because each test owns a SwiftData
//  container; each gets a unique on-disk temp store — parallel in-memory containers
//  share a /dev/null SQLite identity and crash the host under load.
//

import Foundation
import SwiftData
import Testing
import SetDeckCore
@testable import SetDeckData

@Suite("Workout repositories", .serialized)
@MainActor
struct WorkoutRepositoryTests {

    private struct Harness {
        let container: ModelContainer
        let changeCenter = WorkoutChangeCenter()
        let routines: DefaultRoutineRepository
        let history: DefaultHistoryRepository

        init() throws {
            let storeURL = URL.temporaryDirectory.appending(path: "setdeck-test-\(UUID().uuidString).store")
            let config = ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
            container = try ModelContainer(
                for: SetDeckRoutine.self, SetDeckExercise.self, SetDeckSet.self, SetDeckSetHistory.self,
                configurations: config
            )
            routines = DefaultRoutineRepository(container: container, changeCenter: changeCenter)
            history = DefaultHistoryRepository(container: container, changeCenter: changeCenter)
        }
    }

    // MARK: - Routines

    @Test("routines initially empty; routine(forDay:) creates on demand")
    func routineForDayCreatesOnDemand() throws {
        let h = try Harness()
        #expect(try h.routines.routines().isEmpty)

        let routine = try h.routines.routine(forDay: 0)

        #expect(routine.day == 0)
        #expect(try h.routines.routines().count == 1)

        // Second call returns the same routine, not a duplicate.
        _ = try h.routines.routine(forDay: 0)
        #expect(try h.routines.routines().count == 1)
    }

    @Test("routines sort by day ascending")
    func routinesSortByDay() throws {
        let h = try Harness()
        _ = try h.routines.routine(forDay: 2)
        _ = try h.routines.routine(forDay: 0)
        _ = try h.routines.routine(forDay: 1)

        #expect(try h.routines.routines().map(\.day) == [0, 1, 2])
    }

    // MARK: - Exercises

    @Test("addExercise creates the default set with the expected targets")
    func addExerciseCreatesDefaultSet() throws {
        let h = try Harness()

        let exercise = try h.routines.addExercise(named: "Squat", toDay: 0, isWarmup: false, note: nil)

        #expect(exercise.name == "Squat")
        #expect(try h.routines.exercises(forDay: 0).count == 1)
        let sets = try h.routines.sets(for: exercise)
        #expect(sets.count == 1)
        let defaultSet = try #require(sets.first)
        #expect(defaultSet.setType == .reps)
        #expect(defaultSet.targetReps == 10)
        #expect(defaultSet.rpe == 6)
        #expect(defaultSet.weight == 0)
    }

    @Test("added exercises get incrementing order indexes")
    func addExerciseIncrementsOrderIndex() throws {
        let h = try Harness()
        _ = try h.routines.addExercise(named: "Bench", toDay: 0, isWarmup: false, note: nil)
        _ = try h.routines.addExercise(named: "Row", toDay: 0, isWarmup: false, note: nil)

        let third = try h.routines.addExercise(named: "Deadlift", toDay: 0, isWarmup: false, note: nil)

        #expect(third.orderIndex == 2)
        #expect(try h.routines.exercises(forDay: 0).count == 3)
    }

    @Test("updateExercise persists edits")
    func updateExercisePersistsEdits() throws {
        let h = try Harness()
        let exercise = try h.routines.addExercise(named: "Old Name", toDay: 0, isWarmup: false, note: nil)

        try h.routines.updateExercise(exercise) { $0.name = "New Name" }

        #expect(exercise.name == "New Name")
    }

    @Test("reorderExercises renumbers order indexes")
    func reorderExercisesRenumbers() throws {
        let h = try Harness()
        let routine = try h.routines.routine(forDay: 0)
        let ex1 = try h.routines.addExercise(named: "A", toDay: 0, isWarmup: false, note: nil)
        let ex2 = try h.routines.addExercise(named: "B", toDay: 0, isWarmup: false, note: nil)
        let ex3 = try h.routines.addExercise(named: "C", toDay: 0, isWarmup: false, note: nil)

        try h.routines.reorderExercises(in: routine, newOrder: [ex3, ex1, ex2])

        #expect(ex3.orderIndex == 0)
        #expect(ex1.orderIndex == 1)
        #expect(ex2.orderIndex == 2)
    }

    @Test("deleteExercise removes and reindexes the remainder")
    func deleteExerciseReindexes() throws {
        let h = try Harness()
        let routine = try h.routines.routine(forDay: 0)
        _ = try h.routines.addExercise(named: "A", toDay: 0, isWarmup: false, note: nil)
        let ex2 = try h.routines.addExercise(named: "B", toDay: 0, isWarmup: false, note: nil)
        _ = try h.routines.addExercise(named: "C", toDay: 0, isWarmup: false, note: nil)

        try h.routines.deleteExercise(ex2)

        let remaining = try h.routines.exercises(for: routine)
        #expect(remaining.count == 2)
        #expect(remaining.map(\.orderIndex) == [0, 1])
        #expect(!remaining.contains { $0.uuid == ex2.uuid })
    }

    // MARK: - Sets

    @Test("addSet appends with the next order index")
    func addSetAppends() throws {
        let h = try Harness()
        let exercise = try h.routines.addExercise(named: "Test", toDay: 0, isWarmup: false, note: nil)

        let newSet = try h.routines.addSet(
            to: exercise, setType: .duration, targetReps: nil, weight: nil,
            targetDuration: 30, setDescription: nil, rpe: nil
        )

        #expect(try h.routines.sets(for: exercise).count == 2)
        #expect(newSet.orderIndex == 1)
        #expect(newSet.setType == .duration)
        #expect(newSet.targetDuration == 30)
    }

    @Test("reorderSets renumbers; deleteSet reindexes the remainder")
    func setReorderAndDelete() throws {
        let h = try Harness()
        let exercise = try h.routines.addExercise(named: "Test", toDay: 0, isWarmup: false, note: nil)
        let set1 = try #require(try h.routines.sets(for: exercise).first)
        let set2 = try h.routines.addSet(
            to: exercise, setType: .reps, targetReps: 10, weight: 0,
            targetDuration: nil, setDescription: nil, rpe: 6
        )
        let set3 = try h.routines.addSet(
            to: exercise, setType: .reps, targetReps: 10, weight: 0,
            targetDuration: nil, setDescription: nil, rpe: 6
        )

        try h.routines.reorderSets(in: exercise, newOrder: [set3, set1, set2])
        #expect(set3.orderIndex == 0)
        #expect(set1.orderIndex == 1)
        #expect(set2.orderIndex == 2)

        try h.routines.deleteSet(set1)
        let remaining = try h.routines.sets(for: exercise)
        #expect(remaining.count == 2)
        #expect(remaining.map(\.orderIndex) == [0, 1])
    }

    // MARK: - History

    @Test("recordHistory attaches the entry to set and exercise")
    func recordHistoryAttaches() throws {
        let h = try Harness()
        let exercise = try h.routines.addExercise(named: "Test", toDay: 0, isWarmup: false, note: nil)
        let set = try #require(try h.routines.sets(for: exercise).first)

        let entry = try h.history.recordHistory(
            for: set, completedDate: Date(), actualReps: 12, actualWeight: 100,
            actualWeightUnit: nil, actualDuration: nil, actualDescription: nil,
            actualRpe: 8, note: nil
        )

        #expect(entry.actualReps == 12)
        #expect(entry.actualWeight == 100)
        #expect(entry.actualRpe == 8)
        #expect(try h.history.history(for: exercise).count == 1)
        #expect(try h.history.allHistory().count == 1)
        #expect(set.history?.contains { $0.uuid == entry.uuid } ?? false)
    }

    @Test("LogSet updates targets and records a matching history entry")
    func logSetUpdatesAndRecords() throws {
        let h = try Harness()
        let exercise = try h.routines.addExercise(named: "Test", toDay: 0, isWarmup: false, note: nil)
        let set = try #require(try h.routines.sets(for: exercise).first)
        let logSet = LogSetUseCase(routines: h.routines, history: h.history)

        try logSet(set, reps: 12, weight: 100, rpe: 8)

        #expect(set.targetReps == 12)
        #expect(set.weight == 100)
        #expect(set.rpe == 8)
        let recorded = try #require(try h.history.history(for: exercise).first)
        #expect(recorded.actualReps == 12)
        #expect(recorded.actualWeight == 100)
        #expect(recorded.actualRpe == 8)
        #expect(abs(recorded.completedDate.timeIntervalSinceNow) <= 1.0)
    }

    @Test("clearAllHistory removes every entry and detaches from sets")
    func clearAllHistoryRemoves() throws {
        let h = try Harness()
        let exercise = try h.routines.addExercise(named: "Test", toDay: 0, isWarmup: false, note: nil)
        let set = try #require(try h.routines.sets(for: exercise).first)
        _ = try h.history.recordHistory(
            for: set, completedDate: Date(), actualReps: nil, actualWeight: nil,
            actualWeightUnit: nil, actualDuration: nil, actualDescription: nil,
            actualRpe: nil, note: nil
        )
        _ = try h.history.recordHistory(
            for: set, completedDate: Date(), actualReps: nil, actualWeight: nil,
            actualWeightUnit: nil, actualDuration: nil, actualDescription: nil,
            actualRpe: nil, note: nil
        )
        #expect(try h.history.allHistory().count == 2)

        try h.history.clearAllHistory()

        #expect(try h.history.allHistory().isEmpty)
        #expect(set.history?.isEmpty ?? true)
    }

    @Test("workoutStats snapshots history and routine coverage")
    func workoutStatsSnapshot() throws {
        let h = try Harness()
        let exercise = try h.routines.addExercise(named: "Squat", toDay: 3, isWarmup: false, note: nil)
        let set = try #require(try h.routines.sets(for: exercise).first)
        _ = try h.history.recordHistory(
            for: set, completedDate: Date(), actualReps: 5, actualWeight: 225,
            actualWeightUnit: "lb", actualDuration: nil, actualDescription: nil,
            actualRpe: 9, note: nil
        )

        let stats = try h.history.workoutStats()

        #expect(stats.totalSetsLogged == 1)
        #expect(stats.maxWeightLogged == 225)
        #expect(stats.uniqueExerciseNames == ["Squat"])
        #expect(stats.daysWithExercises == [3])
    }

    @Test("mutations notify the change stream")
    func mutationsNotifyChangeStream() async throws {
        let h = try Harness()
        var iterator = h.changeCenter.changes().makeAsyncIterator()

        _ = try h.routines.addExercise(named: "Squat", toDay: 0, isWarmup: false, note: nil)

        // At least one change event lands (routine creation + exercise + default set).
        let event: Void? = await iterator.next()
        #expect(event != nil)
    }

    // MARK: - Sample data (DEBUG)

    @Test("sample generator seeds a program and 30 days of history, then aborts on rerun")
    func sampleGeneratorSeedsAndAborts() throws {
        let h = try Harness()
        let generator = SampleWorkoutData(routines: h.routines, history: h.history)

        try generator.generateLast30Days()

        let count = try h.history.allHistory().count
        #expect(count > 400)
        #expect(count < 800)
        #expect(try h.routines.routines().count == 7)
        #expect(try h.routines.exercises(forDay: 0).count > 7)

        // Rerun aborts without adding anything.
        try generator.generateLast30Days()
        #expect(try h.history.allHistory().count == count)
    }
}
