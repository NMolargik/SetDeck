//
//  DefaultHistoryRepository.swift
//  SetDeckData
//
//  The SwiftData-backed `HistoryRepository`: the set-completion audit trail plus the
//  pure `WorkoutStats` snapshot achievements and stats read.
//

import Foundation
import SwiftData
import SetDeckCore
import os

@MainActor
public final class DefaultHistoryRepository: HistoryRepository {

    private let container: ModelContainer
    private let changeCenter: WorkoutChangeCenter?

    private var context: ModelContext { container.mainContext }

    public init(container: ModelContainer, changeCenter: WorkoutChangeCenter? = nil) {
        self.container = container
        self.changeCenter = changeCenter
    }

    public func allHistory() throws(PersistenceError) -> [SetDeckSetHistory] {
        let descriptor = FetchDescriptor<SetDeckSetHistory>(
            sortBy: [SortDescriptor(\.completedDate, order: .forward)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            Log.workouts.error("History fetch failed: \(error.localizedDescription)")
            throw .fetchFailed(error.localizedDescription)
        }
    }

    public func history(for exercise: SetDeckExercise) throws(PersistenceError) -> [SetDeckSetHistory] {
        // Fetch all sorted, then filter in-memory: Core Data can't compile the
        // optional-chained set?.exercise?.uuid keypath into SQL (TERNARY).
        let exerciseID = exercise.uuid
        return try allHistory().filter { history in
            history.set?.exercise?.uuid == exerciseID
        }
    }

    @discardableResult
    public func recordHistory(
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
        let history = SetDeckSetHistory(
            completedDate: completedDate,
            actualReps: actualReps,
            actualWeight: actualWeight,
            actualWeightUnit: actualWeightUnit,
            actualDuration: actualDuration,
            actualDescription: actualDescription,
            actualRpe: actualRpe,
            note: note
        )
        history.set = set
        if set.history == nil { set.history = [] }
        set.history?.append(history)
        context.insert(history)
        set.exercise?.routine?.lastUpdated = Date()
        try save(operation: "record history")
        return history
    }

    public func set(withID uuid: UUID) throws(PersistenceError) -> SetDeckSet? {
        var descriptor = FetchDescriptor<SetDeckSet>(predicate: #Predicate { $0.uuid == uuid })
        descriptor.fetchLimit = 1
        do {
            return try context.fetch(descriptor).first
        } catch {
            Log.workouts.error("Set lookup failed: \(error.localizedDescription)")
            throw .fetchFailed(error.localizedDescription)
        }
    }

    public func clearAllHistory() throws(PersistenceError) {
        let all = try allHistory()
        guard !all.isEmpty else { return }

        for history in all {
            if let set = history.set {
                set.history = set.history?.filter { $0.uuid != history.uuid }
            }
            context.delete(history)
        }
        try save(operation: "clear history")
    }

    public func workoutStats() throws(PersistenceError) -> WorkoutStats {
        let history = try allHistory()

        var daysWithExercises = Set<Int>()
        do {
            let routines = try context.fetch(FetchDescriptor<SetDeckRoutine>())
            for routine in routines where !(routine.exercises?.isEmpty ?? true) {
                daysWithExercises.insert(routine.day)
            }
        } catch {
            Log.workouts.error("Routine fetch for stats failed: \(error.localizedDescription)")
            throw PersistenceError.fetchFailed(error.localizedDescription)
        }

        return WorkoutStats(
            completionDates: history.map(\.completedDate),
            totalSetsLogged: history.count,
            maxWeightLogged: history.compactMap(\.actualWeight).max() ?? 0,
            uniqueExerciseNames: Set(history.compactMap { $0.set?.exercise?.name }),
            daysWithExercises: daysWithExercises
        )
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
