//
//  WorkoutStats.swift
//  SetDeck
//
//  Created by Nick Molargik on 6/14/26.
//

import Foundation

/// A pure, value-type snapshot of the workout data needed to evaluate
/// achievements. Decoupling this from SwiftData lets `AchievementEvaluator`
/// be unit-tested without a `ModelContainer`.
nonisolated struct WorkoutStats: Sendable, Equatable {
    /// One entry per logged set-history record (the completion date).
    var completionDates: [Date]
    /// Total number of set-history records logged.
    var totalSetsLogged: Int
    /// Heaviest weight ever logged, in the user's stored unit.
    var maxWeightLogged: Double
    /// Distinct exercise names that have at least one logged set.
    var uniqueExerciseNames: Set<String>
    /// Routine day indices (0...6) that have at least one exercise.
    var daysWithExercises: Set<Int>

    init(
        completionDates: [Date] = [],
        totalSetsLogged: Int = 0,
        maxWeightLogged: Double = 0,
        uniqueExerciseNames: Set<String> = [],
        daysWithExercises: Set<Int> = []
    ) {
        self.completionDates = completionDates
        self.totalSetsLogged = totalSetsLogged
        self.maxWeightLogged = maxWeightLogged
        self.uniqueExerciseNames = uniqueExerciseNames
        self.daysWithExercises = daysWithExercises
    }
}
