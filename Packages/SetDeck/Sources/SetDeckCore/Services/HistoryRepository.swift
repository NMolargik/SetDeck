//
//  HistoryRepository.swift
//  SetDeckCore
//
//  The set-completion audit trail boundary. Recording history is the app's core write
//  path (in-app logging, the watch relay, and DEBUG sample data all go through it).
//

import Foundation

@MainActor
public protocol HistoryRepository: AnyObject {
    /// Every history entry, sorted by completion date ascending.
    func allHistory() throws(PersistenceError) -> [SetDeckSetHistory]

    /// History entries for all sets of one exercise, sorted by completion date.
    func history(for exercise: SetDeckExercise) throws(PersistenceError) -> [SetDeckSetHistory]

    /// Records a completed set.
    @discardableResult
    func recordHistory(
        for set: SetDeckSet,
        completedDate: Date,
        actualReps: Int?,
        actualWeight: Double?,
        actualWeightUnit: String?,
        actualDuration: TimeInterval?,
        actualDescription: String?,
        actualRpe: Int?,
        note: String?
    ) throws(PersistenceError) -> SetDeckSetHistory

    /// The set with `uuid`, if it still exists (watch relay, intents).
    func set(withID uuid: UUID) throws(PersistenceError) -> SetDeckSet?

    /// Removes every history entry (routines/sets stay).
    func clearAllHistory() throws(PersistenceError)

    /// A pure snapshot of the workout data used by achievements and stats.
    func workoutStats() throws(PersistenceError) -> WorkoutStats
}

// MARK: - Use cases

@MainActor
public protocol LoadHistory {
    func callAsFunction() throws(PersistenceError) -> [SetDeckSetHistory]
    func callAsFunction(for exercise: SetDeckExercise) throws(PersistenceError) -> [SetDeckSetHistory]
}

public struct LoadHistoryUseCase: LoadHistory {
    private let repository: any HistoryRepository
    public init(repository: any HistoryRepository) { self.repository = repository }
    public func callAsFunction() throws(PersistenceError) -> [SetDeckSetHistory] {
        try repository.allHistory()
    }
    public func callAsFunction(for exercise: SetDeckExercise) throws(PersistenceError) -> [SetDeckSetHistory] {
        try repository.history(for: exercise)
    }
}

@MainActor
public protocol RecordSetCompletion {
    @discardableResult
    func callAsFunction(
        for set: SetDeckSet,
        completedDate: Date,
        actualReps: Int?,
        actualWeight: Double?,
        actualWeightUnit: String?,
        actualDuration: TimeInterval?,
        actualDescription: String?,
        actualRpe: Int?,
        note: String?
    ) throws(PersistenceError) -> SetDeckSetHistory
}

extension RecordSetCompletion {
    /// The common in-app logging shape: update targets happened separately; this records
    /// what the user actually did right now.
    @discardableResult
    public func callAsFunction(
        for set: SetDeckSet,
        actualReps: Int?,
        actualWeight: Double?,
        actualRpe: Int?
    ) throws(PersistenceError) -> SetDeckSetHistory {
        try callAsFunction(
            for: set,
            completedDate: Date(),
            actualReps: actualReps,
            actualWeight: actualWeight,
            actualWeightUnit: nil,
            actualDuration: nil,
            actualDescription: nil,
            actualRpe: actualRpe,
            note: nil
        )
    }
}

public struct RecordSetCompletionUseCase: RecordSetCompletion {
    private let repository: any HistoryRepository
    public init(repository: any HistoryRepository) { self.repository = repository }
    @discardableResult
    public func callAsFunction(
        for set: SetDeckSet,
        completedDate: Date,
        actualReps: Int?,
        actualWeight: Double?,
        actualWeightUnit: String?,
        actualDuration: TimeInterval?,
        actualDescription: String?,
        actualRpe: Int?,
        note: String?
    ) throws(PersistenceError) -> SetDeckSetHistory {
        try repository.recordHistory(
            for: set,
            completedDate: completedDate,
            actualReps: actualReps,
            actualWeight: actualWeight,
            actualWeightUnit: actualWeightUnit,
            actualDuration: actualDuration,
            actualDescription: actualDescription,
            actualRpe: actualRpe,
            note: note
        )
    }
}

@MainActor
public protocol FindSet {
    func callAsFunction(withID uuid: UUID) throws(PersistenceError) -> SetDeckSet?
}

public struct FindSetUseCase: FindSet {
    private let repository: any HistoryRepository
    public init(repository: any HistoryRepository) { self.repository = repository }
    public func callAsFunction(withID uuid: UUID) throws(PersistenceError) -> SetDeckSet? {
        try repository.set(withID: uuid)
    }
}

@MainActor
public protocol ClearHistory {
    func callAsFunction() throws(PersistenceError)
}

public struct ClearHistoryUseCase: ClearHistory {
    private let repository: any HistoryRepository
    public init(repository: any HistoryRepository) { self.repository = repository }
    public func callAsFunction() throws(PersistenceError) {
        try repository.clearAllHistory()
    }
}

@MainActor
public protocol LoadWorkoutStats {
    func callAsFunction() throws(PersistenceError) -> WorkoutStats
}

public struct LoadWorkoutStatsUseCase: LoadWorkoutStats {
    private let repository: any HistoryRepository
    public init(repository: any HistoryRepository) { self.repository = repository }
    public func callAsFunction() throws(PersistenceError) -> WorkoutStats {
        try repository.workoutStats()
    }
}

// MARK: - Sample data (DEBUG)

#if DEBUG
/// Seeds demo routines + 30 days of history (Settings' debug menu). The concrete
/// generator lives in SetDeckData.
@MainActor
public protocol GenerateSampleData {
    func callAsFunction() throws(PersistenceError)
}
#endif
