//
//  LogSet.swift
//  SetDeckCore
//
//  The primary user action: "I did this set." Updates the set's targets to what was
//  just performed and records a history entry — the two-step the old
//  `ExerciseManager.update(set:withReps:weight:rpe:)` bundled.
//

import Foundation

@MainActor
public protocol LogSet {
    func callAsFunction(_ set: SetDeckSet, reps: Int?, weight: Double?, rpe: Int?) throws(PersistenceError)
}

public struct LogSetUseCase: LogSet {
    private let routines: any RoutineRepository
    private let history: any HistoryRepository

    public init(routines: any RoutineRepository, history: any HistoryRepository) {
        self.routines = routines
        self.history = history
    }

    public func callAsFunction(_ set: SetDeckSet, reps: Int?, weight: Double?, rpe: Int?) throws(PersistenceError) {
        try routines.updateSet(set) { s in
            if let reps {
                s.targetReps = reps
            }
            if let weight {
                s.weight = weight
            }
            if let rpe {
                s.rpe = max(0, rpe)
            }
        }

        // Record what was actually performed. Duration sets capture the current target
        // duration as the actual.
        _ = try history.recordHistory(
            for: set,
            completedDate: Date(),
            actualReps: reps,
            actualWeight: weight,
            actualWeightUnit: nil,
            actualDuration: (set.setType == .duration ? set.targetDuration : nil),
            actualDescription: nil,
            actualRpe: rpe,
            note: nil
        )
    }
}
