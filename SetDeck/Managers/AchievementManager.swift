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
        let allHistory = exerciseManager.allHistoryEntries()
        let allRoutines = exerciseManager.allRoutines()
        let celebrated = loadCelebrated()

        var newlyUnlocked: [Achievement] = []

        for achievement in Achievement.allCases {
            let key = achievement.rawValue
            guard !celebrated.contains(key) else { continue }
            if isAchievementMet(achievement, history: allHistory, routines: allRoutines) {
                unlockedAchievements.insert(key)
                newlyUnlocked.append(achievement)
            }
        }

        guard !newlyUnlocked.isEmpty else { return }

        // Pick the highest-tier (highest sortOrder) newly unlocked achievement to celebrate
        let toastAchievement = newlyUnlocked.max(by: { $0.sortOrder < $1.sortOrder })!

        // Mark all newly unlocked as celebrated
        var updatedCelebrated = celebrated
        for a in newlyUnlocked {
            updatedCelebrated.insert(a.rawValue)
        }
        saveCelebrated(updatedCelebrated)

        pendingCelebration = toastAchievement
        logger.info("Achievement unlocked: \(toastAchievement.displayName)")
    }

    /// Clears the pending celebration.
    func dismissCelebration() {
        pendingCelebration = nil
    }

    /// Refreshes the unlocked set without triggering celebrations.
    func refreshUnlockedAchievements() {
        let allHistory = exerciseManager.allHistoryEntries()
        let allRoutines = exerciseManager.allRoutines()

        var unlocked = Set<String>()
        for achievement in Achievement.allCases {
            if isAchievementMet(achievement, history: allHistory, routines: allRoutines) {
                unlocked.insert(achievement.rawValue)
            }
        }
        unlockedAchievements = unlocked
    }

    /// Resets all achievement progress.
    func resetAllAchievements() {
        saveCelebrated([])
        unlockedAchievements = []
        pendingCelebration = nil
        logger.info("All achievements reset")
    }

    // MARK: - Evaluation

    private func isAchievementMet(_ achievement: Achievement,
                                   history: [SetDeckSetHistory],
                                   routines: [SetDeckRoutine]) -> Bool {
        switch achievement {
        // Consistency
        case .firstWorkout:
            return !history.isEmpty
        case .weekWarrior:
            return hasWeekWithNDays(history: history, n: 5)
        case .fullWeek:
            return hasWeekWithNDays(history: history, n: 7)
        case .twoWeekStreak:
            return longestConsecutiveDayStreak(history: history) >= 14
        case .monthStrong:
            return longestConsecutiveDayStreak(history: history) >= 30

        // Volume
        case .gettingStarted:
            return history.count >= 10
        case .century:
            return history.count >= 100
        case .fiveHundredClub:
            return history.count >= 500
        case .thousandStrong:
            return history.count >= 1_000
        case .setMachine:
            return history.count >= 5_000

        // Routine
        case .buildingBlocks:
            return daysWithExercises(routines: routines) >= 5
        case .fullRoster:
            return daysWithExercises(routines: routines) >= 7

        // Variety
        case .explorer:
            return uniqueExercisesWithHistory(history: history) >= 5
        case .wellRounded:
            return uniqueExercisesWithHistory(history: history) >= 10
        case .renaissanceLifter:
            return uniqueExercisesWithHistory(history: history) >= 20

        // Strength
        case .onePlate:
            return maxWeightLogged(history: history) >= 135
        case .twoPlates:
            return maxWeightLogged(history: history) >= 225
        case .threePlates:
            return maxWeightLogged(history: history) >= 315
        case .fourPlates:
            return maxWeightLogged(history: history) >= 405
        }
    }

    // MARK: - Private Helpers

    private func longestConsecutiveDayStreak(history: [SetDeckSetHistory]) -> Int {
        guard !history.isEmpty else { return 0 }
        let calendar = Calendar.current
        let days = Set(history.map { calendar.startOfDay(for: $0.completedDate) })
        let sorted = days.sorted()
        guard !sorted.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        for i in 1..<sorted.count {
            if calendar.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    private func hasWeekWithNDays(history: [SetDeckSetHistory], n: Int) -> Bool {
        guard !history.isEmpty else { return false }
        let calendar = Calendar.current

        // Group by ISO week-year
        var weekDays: [String: Set<Int>] = [:]
        for entry in history {
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.completedDate)
            let key = "\(components.yearForWeekOfYear ?? 0)-\(components.weekOfYear ?? 0)"
            let dayOfWeek = calendar.component(.weekday, from: entry.completedDate)
            weekDays[key, default: []].insert(dayOfWeek)
        }

        return weekDays.values.contains { $0.count >= n }
    }

    private func daysWithExercises(routines: [SetDeckRoutine]) -> Int {
        var daysWithContent = Set<Int>()
        for routine in routines {
            let exercises = exerciseManager.exercises(for: routine)
            if !exercises.isEmpty {
                daysWithContent.insert(routine.day)
            }
        }
        return daysWithContent.count
    }

    private func uniqueExercisesWithHistory(history: [SetDeckSetHistory]) -> Int {
        var names = Set<String>()
        for entry in history {
            if let name = entry.set?.exercise?.name {
                names.insert(name)
            }
        }
        return names.count
    }

    private func maxWeightLogged(history: [SetDeckSetHistory]) -> Double {
        history.compactMap { $0.actualWeight }.max() ?? 0
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
