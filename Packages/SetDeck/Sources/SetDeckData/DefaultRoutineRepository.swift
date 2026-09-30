//
//  DefaultRoutineRepository.swift
//  SetDeckData
//
//  The SwiftData-backed `RoutineRepository`. Owns orderIndex assignment/renumbering and
//  `routine.lastUpdated` stamping, throws typed failures (the old manager swallowed
//  them with `try?`), and notifies the workout change stream after every successful
//  mutation. Also repairs duplicate routines left behind by CloudKit merges.
//

import Foundation
import SwiftData
import SetDeckCore
import os

@MainActor
public final class DefaultRoutineRepository: RoutineRepository {

    /// Retained on purpose: a `ModelContext` does not keep its container alive.
    private let container: ModelContainer
    private let changeCenter: WorkoutChangeCenter?

    private var context: ModelContext { container.mainContext }

    public init(container: ModelContainer, changeCenter: WorkoutChangeCenter? = nil) {
        self.container = container
        self.changeCenter = changeCenter
        // CloudKit merges can leave more than one routine per day; fold them together.
        try? cleanupDuplicateRoutines()
    }

    // MARK: - Routines

    public func routines() throws(PersistenceError) -> [SetDeckRoutine] {
        let descriptor = FetchDescriptor<SetDeckRoutine>(
            sortBy: [SortDescriptor(\.day, order: .forward)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            Log.workouts.error("Routine fetch failed: \(error.localizedDescription)")
            throw .fetchFailed(error.localizedDescription)
        }
    }

    @discardableResult
    public func routine(forDay day: Int) throws(PersistenceError) -> SetDeckRoutine {
        let descriptor = FetchDescriptor<SetDeckRoutine>(
            predicate: #Predicate { $0.day == day },
            sortBy: []
        )
        let fetched: [SetDeckRoutine]
        do {
            fetched = try context.fetch(descriptor)
        } catch {
            Log.workouts.error("Routine lookup failed: \(error.localizedDescription)")
            throw PersistenceError.fetchFailed(error.localizedDescription)
        }
        if let routine = fetched.first {
            return routine
        }
        let routine = SetDeckRoutine(day: day)
        context.insert(routine)
        try save(operation: "create routine")
        return routine
    }

    // MARK: - Exercises

    public func exercises(forDay day: Int) throws(PersistenceError) -> [SetDeckExercise] {
        let predicate = #Predicate<SetDeckExercise> { ex in
            ex.routine?.day == day
        }
        let descriptor = FetchDescriptor<SetDeckExercise>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            Log.workouts.error("Exercise fetch failed: \(error.localizedDescription)")
            throw .fetchFailed(error.localizedDescription)
        }
    }

    public func exercises(for routine: SetDeckRoutine) throws(PersistenceError) -> [SetDeckExercise] {
        let routineID = routine.uuid
        let predicate = #Predicate<SetDeckExercise> { ex in
            ex.routine?.uuid == routineID
        }
        let descriptor = FetchDescriptor<SetDeckExercise>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            Log.workouts.error("Exercise fetch failed: \(error.localizedDescription)")
            throw .fetchFailed(error.localizedDescription)
        }
    }

    @discardableResult
    public func addExercise(named name: String, toDay day: Int, isWarmup: Bool, note: String?) throws(PersistenceError) -> SetDeckExercise {
        let routine = try routine(forDay: day)
        let current = try exercises(for: routine)
        let nextIndex = (current.map { $0.orderIndex }.max() ?? -1) + 1

        let exercise = SetDeckExercise(name: name, note: note, isWarmup: isWarmup, orderIndex: nextIndex)
        exercise.routine = routine

        if routine.exercises == nil { routine.exercises = [] }
        routine.exercises?.append(exercise)

        context.insert(exercise)
        routine.lastUpdated = Date()

        // Every new exercise starts with one sensible default set.
        try addSet(
            to: exercise,
            setType: .reps,
            targetReps: 10,
            weight: 0,
            targetDuration: nil,
            setDescription: nil,
            rpe: 6
        )
        return exercise
    }

    public func updateExercise(_ exercise: SetDeckExercise, configure: (SetDeckExercise) -> Void) throws(PersistenceError) {
        configure(exercise)
        exercise.routine?.lastUpdated = Date()
        try save(operation: "update exercise")
    }

    public func reorderExercises(in routine: SetDeckRoutine, newOrder: [SetDeckExercise]) throws(PersistenceError) {
        for (idx, ex) in newOrder.enumerated() {
            ex.orderIndex = idx
        }
        routine.lastUpdated = Date()
        try save(operation: "reorder exercises")
    }

    public func deleteExercise(_ exercise: SetDeckExercise) throws(PersistenceError) {
        if let routine = exercise.routine {
            routine.exercises = routine.exercises?.filter { $0.uuid != exercise.uuid }
            routine.lastUpdated = Date()
            let ordered = try exercises(for: routine)
            for (idx, ex) in ordered.enumerated() {
                ex.orderIndex = idx
            }
        }
        context.delete(exercise)
        try save(operation: "delete exercise")
    }

    // MARK: - Sets

    public func sets(for exercise: SetDeckExercise) throws(PersistenceError) -> [SetDeckSet] {
        let exerciseID = exercise.uuid
        let predicate = #Predicate<SetDeckSet> { set in
            set.exercise?.uuid == exerciseID
        }
        let descriptor = FetchDescriptor<SetDeckSet>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            Log.workouts.error("Set fetch failed: \(error.localizedDescription)")
            throw .fetchFailed(error.localizedDescription)
        }
    }

    @discardableResult
    public func addSet(
        to exercise: SetDeckExercise,
        setType: SetType,
        targetReps: Int?,
        weight: Double?,
        targetDuration: TimeInterval?,
        setDescription: String?,
        rpe: Int?
    ) throws(PersistenceError) -> SetDeckSet {
        let current = try sets(for: exercise)
        let nextIndex = (current.map { $0.orderIndex }.max() ?? -1) + 1

        let set = SetDeckSet(
            setType: setType,
            targetReps: targetReps,
            weight: weight,
            targetDuration: targetDuration,
            setDescription: setDescription,
            rpe: rpe,
            orderIndex: nextIndex
        )
        set.exercise = exercise
        if exercise.sets == nil { exercise.sets = [] }
        exercise.sets?.append(set)

        context.insert(set)
        exercise.routine?.lastUpdated = Date()
        try save(operation: "add set")
        return set
    }

    public func updateSet(_ set: SetDeckSet, configure: (SetDeckSet) -> Void) throws(PersistenceError) {
        configure(set)
        set.exercise?.routine?.lastUpdated = Date()
        try save(operation: "update set")
    }

    public func reorderSets(in exercise: SetDeckExercise, newOrder: [SetDeckSet]) throws(PersistenceError) {
        for (idx, s) in newOrder.enumerated() {
            s.orderIndex = idx
        }
        exercise.routine?.lastUpdated = Date()
        try save(operation: "reorder sets")
    }

    public func deleteSet(_ set: SetDeckSet) throws(PersistenceError) {
        if let ex = set.exercise {
            ex.sets = ex.sets?.filter { $0.uuid != set.uuid }
            ex.routine?.lastUpdated = Date()
            let ordered = try sets(for: ex)
            for (idx, s) in ordered.enumerated() {
                s.orderIndex = idx
            }
        }
        context.delete(set)
        try save(operation: "delete set")
    }

    // MARK: - Bulk

    public func deleteAllRoutines() throws(PersistenceError) {
        Log.workouts.info("Deleting all routines, exercises, sets, and history")
        do {
            for history in try context.fetch(FetchDescriptor<SetDeckSetHistory>()) {
                context.delete(history)
            }
            for set in try context.fetch(FetchDescriptor<SetDeckSet>()) {
                context.delete(set)
            }
            for exercise in try context.fetch(FetchDescriptor<SetDeckExercise>()) {
                context.delete(exercise)
            }
            for routine in try context.fetch(FetchDescriptor<SetDeckRoutine>()) {
                context.delete(routine)
            }
        } catch {
            Log.workouts.error("Delete-all fetch failed: \(error.localizedDescription)")
            throw PersistenceError.fetchFailed(error.localizedDescription)
        }
        try save(operation: "delete all routines")
    }

    // MARK: - Repair

    /// Folds duplicate per-day routines (a CloudKit-merge artifact) into one.
    private func cleanupDuplicateRoutines() throws(PersistenceError) {
        let descriptor = FetchDescriptor<SetDeckRoutine>(sortBy: [SortDescriptor(\.day)])
        guard let all = try? context.fetch(descriptor), all.count > 7 else { return }

        var primaryRoutines: [Int: SetDeckRoutine] = [:]
        var toDelete: [SetDeckRoutine] = []

        for routine in all {
            if primaryRoutines[routine.day] == nil {
                primaryRoutines[routine.day] = routine
            } else {
                toDelete.append(routine)
            }
        }

        for dupe in toDelete {
            guard let primary = primaryRoutines[dupe.day] else { continue }
            for ex in try exercises(for: dupe) {
                ex.routine = primary
            }
            context.delete(dupe)
        }

        try save(operation: "cleanup duplicate routines")
    }

    // MARK: - Saving

    private func save(operation: String) throws(PersistenceError) {
        do {
            try context.save()
        } catch {
            Log.workouts.error("Failed to \(operation): \(error.localizedDescription)")
            throw .saveFailed(error.localizedDescription)
        }
        changeCenter?.notify()
    }
}
