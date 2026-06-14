//
//  AchievementManager.swift
//  SetDeck
//
//  Created by Nick Molargik on 2/16/26.
//

import Foundation
import os.log

private let logger = Logger(subsystem: "com.molargiksoftware.SetDeck", category: "AchievementManager")

@MainActor
@Observable
class AchievementManager {
    // MARK: - Dependencies
    private let exerciseManager: ExerciseManager

    // MARK: - State
    var pendingCelebration: Achievement?
    private(set) var unlockedAchievements: Set<String> = []

    // MARK: - Init
    init(exerciseManager: ExerciseManager) {
        self.exerciseManager = exerciseManager
        refreshUnlockedAchievements()

        exerciseManager.onDataMutated = { [weak self] in
            self?.checkAchievements()
        }
    }

    // MARK: - Public

    /// Evaluates all achievements and fires a celebration for the highest-tier newly unlocked one.
    func checkAchievements() {
        let unlocked = AchievementEvaluator.unlockedAchievements(from: currentStats())
        unlockedAchievements = Set(unlocked.map(\.rawValue))

        let celebrated = loadCelebrated()
        let newlyUnlocked = unlocked.filter { !celebrated.contains($0.rawValue) }
        guard !newlyUnlocked.isEmpty else { return }

        // Pick the highest-tier (highest sortOrder) newly unlocked achievement to celebrate
        let toastAchievement = newlyUnlocked.max(by: { $0.sortOrder < $1.sortOrder })!

        // Mark all newly unlocked as celebrated
        saveCelebrated(celebrated.union(newlyUnlocked.map(\.rawValue)))

        pendingCelebration = toastAchievement
        logger.info("Achievement unlocked: \(toastAchievement.displayName)")
    }

    /// Clears the pending celebration.
    func dismissCelebration() {
        pendingCelebration = nil
    }

    /// Refreshes the unlocked set without triggering celebrations.
    func refreshUnlockedAchievements() {
        let unlocked = AchievementEvaluator.unlockedAchievements(from: currentStats())
        unlockedAchievements = Set(unlocked.map(\.rawValue))
    }

    /// Resets all achievement progress.
    func resetAllAchievements() {
        saveCelebrated([])
        unlockedAchievements = []
        pendingCelebration = nil
        logger.info("All achievements reset")
    }

    // MARK: - Evaluation

    /// Builds a pure `WorkoutStats` snapshot from the current SwiftData state,
    /// which `AchievementEvaluator` then evaluates.
    private func currentStats() -> WorkoutStats {
        let history = exerciseManager.allHistoryEntries()
        let routines = exerciseManager.allRoutines()

        var daysWithExercises = Set<Int>()
        for routine in routines where !exerciseManager.exercises(for: routine).isEmpty {
            daysWithExercises.insert(routine.day)
        }

        return WorkoutStats(
            completionDates: history.map(\.completedDate),
            totalSetsLogged: history.count,
            maxWeightLogged: history.compactMap(\.actualWeight).max() ?? 0,
            uniqueExerciseNames: Set(history.compactMap { $0.set?.exercise?.name }),
            daysWithExercises: daysWithExercises
        )
    }

    // MARK: - UserDefaults Persistence

    private func loadCelebrated() -> Set<String> {
        guard let array = UserDefaults.standard.array(forKey: AppStorageKeys.celebratedAchievements) as? [String] else {
            return []
        }
        return Set(array)
    }

    private func saveCelebrated(_ celebrated: Set<String>) {
        UserDefaults.standard.set(Array(celebrated), forKey: AppStorageKeys.celebratedAchievements)
    }
}
