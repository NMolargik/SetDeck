//
//  WorkoutStats.swift
//  SetDeckCore
//
//  Created by Nick Molargik on 6/14/26.
//

import Foundation

/// A pure, value-type snapshot of the workout data needed to evaluate
/// achievements. Decoupling this from SwiftData lets `AchievementEvaluator`
/// be unit-tested without a `ModelContainer`.
nonisolated public struct WorkoutStats: Sendable, Equatable {
    /// One entry per logged set-history record (the completion date).
    public var completionDates: [Date]
    /// Total number of set-history records logged.
    public var totalSetsLogged: Int
    /// Heaviest weight ever logged, in the user's stored unit.
    public var maxWeightLogged: Double
    /// Distinct exercise names that have at least one logged set.
    public var uniqueExerciseNames: Set<String>
    /// Routine day indices (0...6) that have at least one exercise.
    public var daysWithExercises: Set<Int>

    public init(
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
