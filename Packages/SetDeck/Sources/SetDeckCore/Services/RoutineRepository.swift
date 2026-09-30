//
//  RoutineRepository.swift
//  SetDeckCore
//
//  The routine/exercise/set data boundary (the old ExerciseManager's CRUD, minus the
//  presentation coupling). `DefaultRoutineRepository` in SetDeckData owns the
//  ModelContext, keeps `orderIndex` contiguous, stamps `routine.lastUpdated`, and
//  notifies the workout change stream after every successful save. Each verb gets a thin
//  single-verb use-case so view models depend on exactly what they use. Failures are
//  typed (`throws(PersistenceError)`) — the old manager silently swallowed them.
//

import Foundation

@MainActor
public protocol RoutineRepository: AnyObject {
    /// All routines, sorted by day (0 = Sunday … 6 = Saturday).
    func routines() throws(PersistenceError) -> [SetDeckRoutine]

    /// The routine for a day, created (and persisted) if missing.
    @discardableResult
    func routine(forDay day: Int) throws(PersistenceError) -> SetDeckRoutine

    /// Exercises for a day, ordered by `orderIndex`.
    func exercises(forDay day: Int) throws(PersistenceError) -> [SetDeckExercise]

    /// Exercises for a routine, ordered by `orderIndex`.
    func exercises(for routine: SetDeckRoutine) throws(PersistenceError) -> [SetDeckExercise]

    /// Appends a new exercise (with one default set) to a day's routine.
    @discardableResult
    func addExercise(named name: String, toDay day: Int, isWarmup: Bool, note: String?) throws(PersistenceError) -> SetDeckExercise

    /// Applies edits to an exercise and persists.
    func updateExercise(_ exercise: SetDeckExercise, configure: (SetDeckExercise) -> Void) throws(PersistenceError)

    /// Applies a drag-to-reorder move and renumbers `orderIndex` to match.
    func reorderExercises(in routine: SetDeckRoutine, newOrder: [SetDeckExercise]) throws(PersistenceError)

    /// Deletes an exercise (cascades to its sets) and renumbers the remainder.
    func deleteExercise(_ exercise: SetDeckExercise) throws(PersistenceError)

    /// Sets for an exercise, ordered by `orderIndex`.
    func sets(for exercise: SetDeckExercise) throws(PersistenceError) -> [SetDeckSet]

    /// Appends a new set to an exercise.
    @discardableResult
    func addSet(
        to exercise: SetDeckExercise,
        setType: SetType,
        targetReps: Int?,
        weight: Double?,
        targetDuration: TimeInterval?,
        setDescription: String?,
        rpe: Int?
    ) throws(PersistenceError) -> SetDeckSet

    /// Applies edits to a set and persists.
    func updateSet(_ set: SetDeckSet, configure: (SetDeckSet) -> Void) throws(PersistenceError)

    /// Applies a drag-to-reorder move and renumbers `orderIndex` to match.
    func reorderSets(in exercise: SetDeckExercise, newOrder: [SetDeckSet]) throws(PersistenceError)

    /// Deletes a set (cascades to its history) and renumbers the remainder.
    func deleteSet(_ set: SetDeckSet) throws(PersistenceError)

    /// Deletes every routine, exercise, set, and history record.
    func deleteAllRoutines() throws(PersistenceError)
}

// MARK: - Use cases

@MainActor
public protocol LoadRoutines {
    func callAsFunction() throws(PersistenceError) -> [SetDeckRoutine]
}

public struct LoadRoutinesUseCase: LoadRoutines {
    private let repository: any RoutineRepository
    public init(repository: any RoutineRepository) { self.repository = repository }
    public func callAsFunction() throws(PersistenceError) -> [SetDeckRoutine] {
        try repository.routines()
    }
}

@MainActor
public protocol LoadRoutine {
    @discardableResult
    func callAsFunction(forDay day: Int) throws(PersistenceError) -> SetDeckRoutine
}

public struct LoadRoutineUseCase: LoadRoutine {
    private let repository: any RoutineRepository
    public init(repository: any RoutineRepository) { self.repository = repository }
    @discardableResult
    public func callAsFunction(forDay day: Int) throws(PersistenceError) -> SetDeckRoutine {
        try repository.routine(forDay: day)
    }
}

@MainActor
public protocol LoadExercises {
    func callAsFunction(forDay day: Int) throws(PersistenceError) -> [SetDeckExercise]
    func callAsFunction(for routine: SetDeckRoutine) throws(PersistenceError) -> [SetDeckExercise]
}

public struct LoadExercisesUseCase: LoadExercises {
    private let repository: any RoutineRepository
    public init(repository: any RoutineRepository) { self.repository = repository }
    public func callAsFunction(forDay day: Int) throws(PersistenceError) -> [SetDeckExercise] {
        try repository.exercises(forDay: day)
    }
    public func callAsFunction(for routine: SetDeckRoutine) throws(PersistenceError) -> [SetDeckExercise] {
        try repository.exercises(for: routine)
    }
}

@MainActor
public protocol AddExercise {
    @discardableResult
    func callAsFunction(named name: String, toDay day: Int, isWarmup: Bool, note: String?) throws(PersistenceError) -> SetDeckExercise
}

extension AddExercise {
    @discardableResult
    public func callAsFunction(named name: String, toDay day: Int) throws(PersistenceError) -> SetDeckExercise {
        try callAsFunction(named: name, toDay: day, isWarmup: false, note: nil)
    }
}

public struct AddExerciseUseCase: AddExercise {
    private let repository: any RoutineRepository
    public init(repository: any RoutineRepository) { self.repository = repository }
    @discardableResult
    public func callAsFunction(named name: String, toDay day: Int, isWarmup: Bool, note: String?) throws(PersistenceError) -> SetDeckExercise {
        try repository.addExercise(named: name, toDay: day, isWarmup: isWarmup, note: note)
    }
}

@MainActor
public protocol UpdateExercise {
    func callAsFunction(_ exercise: SetDeckExercise, configure: (SetDeckExercise) -> Void) throws(PersistenceError)
}

public struct UpdateExerciseUseCase: UpdateExercise {
    private let repository: any RoutineRepository
    public init(repository: any RoutineRepository) { self.repository = repository }
    public func callAsFunction(_ exercise: SetDeckExercise, configure: (SetDeckExercise) -> Void) throws(PersistenceError) {
        try repository.updateExercise(exercise, configure: configure)
    }
}

@MainActor
public protocol ReorderExercises {
    func callAsFunction(in routine: SetDeckRoutine, newOrder: [SetDeckExercise]) throws(PersistenceError)
}

public struct ReorderExercisesUseCase: ReorderExercises {
    private let repository: any RoutineRepository
    public init(repository: any RoutineRepository) { self.repository = repository }
    public func callAsFunction(in routine: SetDeckRoutine, newOrder: [SetDeckExercise]) throws(PersistenceError) {
        try repository.reorderExercises(in: routine, newOrder: newOrder)
    }
}

@MainActor
public protocol DeleteExercise {
    func callAsFunction(_ exercise: SetDeckExercise) throws(PersistenceError)
}

public struct DeleteExerciseUseCase: DeleteExercise {
    private let repository: any RoutineRepository
    public init(repository: any RoutineRepository) { self.repository = repository }
    public func callAsFunction(_ exercise: SetDeckExercise) throws(PersistenceError) {
        try repository.deleteExercise(exercise)
    }
}

@MainActor
public protocol LoadSets {
    func callAsFunction(for exercise: SetDeckExercise) throws(PersistenceError) -> [SetDeckSet]
}

public struct LoadSetsUseCase: LoadSets {
    private let repository: any RoutineRepository
    public init(repository: any RoutineRepository) { self.repository = repository }
    public func callAsFunction(for exercise: SetDeckExercise) throws(PersistenceError) -> [SetDeckSet] {
        try repository.sets(for: exercise)
    }
}

@MainActor
public protocol AddSet {
    @discardableResult
    func callAsFunction(
        to exercise: SetDeckExercise,
        setType: SetType,
        targetReps: Int?,
        weight: Double?,
        targetDuration: TimeInterval?,
        setDescription: String?,
        rpe: Int?
    ) throws(PersistenceError) -> SetDeckSet
}

extension AddSet {
    @discardableResult
    public func callAsFunction(to exercise: SetDeckExercise) throws(PersistenceError) -> SetDeckSet {
        try callAsFunction(to: exercise, setType: .reps, targetReps: 10, weight: 0, targetDuration: nil, setDescription: nil, rpe: 6)
    }
}

public struct AddSetUseCase: AddSet {
    private let repository: any RoutineRepository
    public init(repository: any RoutineRepository) { self.repository = repository }
    @discardableResult
    public func callAsFunction(
        to exercise: SetDeckExercise,
        setType: SetType,
        targetReps: Int?,
        weight: Double?,
        targetDuration: TimeInterval?,
        setDescription: String?,
        rpe: Int?
    ) throws(PersistenceError) -> SetDeckSet {
        try repository.addSet(
            to: exercise,
            setType: setType,
            targetReps: targetReps,
            weight: weight,
            targetDuration: targetDuration,
            setDescription: setDescription,
            rpe: rpe
        )
    }
}

@MainActor
public protocol UpdateSet {
    func callAsFunction(_ set: SetDeckSet, configure: (SetDeckSet) -> Void) throws(PersistenceError)
}

public struct UpdateSetUseCase: UpdateSet {
    private let repository: any RoutineRepository
    public init(repository: any RoutineRepository) { self.repository = repository }
    public func callAsFunction(_ set: SetDeckSet, configure: (SetDeckSet) -> Void) throws(PersistenceError) {
        try repository.updateSet(set, configure: configure)
    }
}

@MainActor
public protocol ReorderSets {
    func callAsFunction(in exercise: SetDeckExercise, newOrder: [SetDeckSet]) throws(PersistenceError)
}

public struct ReorderSetsUseCase: ReorderSets {
    private let repository: any RoutineRepository
    public init(repository: any RoutineRepository) { self.repository = repository }
    public func callAsFunction(in exercise: SetDeckExercise, newOrder: [SetDeckSet]) throws(PersistenceError) {
        try repository.reorderSets(in: exercise, newOrder: newOrder)
    }
}

@MainActor
public protocol DeleteSet {
    func callAsFunction(_ set: SetDeckSet) throws(PersistenceError)
}

public struct DeleteSetUseCase: DeleteSet {
    private let repository: any RoutineRepository
    public init(repository: any RoutineRepository) { self.repository = repository }
    public func callAsFunction(_ set: SetDeckSet) throws(PersistenceError) {
        try repository.deleteSet(set)
    }
}

@MainActor
public protocol DeleteAllRoutines {
    func callAsFunction() throws(PersistenceError)
}

public struct DeleteAllRoutinesUseCase: DeleteAllRoutines {
    private let repository: any RoutineRepository
    public init(repository: any RoutineRepository) { self.repository = repository }
    public func callAsFunction() throws(PersistenceError) {
        try repository.deleteAllRoutines()
    }
}
