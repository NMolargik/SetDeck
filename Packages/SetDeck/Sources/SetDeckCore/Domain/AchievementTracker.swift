//
//  AchievementTracker.swift
//  SetDeckCore
//
//  Celebration bookkeeping over the pure `AchievementEvaluator`: which achievements were
//  already celebrated (persisted behind `KeyValueStoring`) and which newly unlocked one
//  deserves the celebration toast. Extracted from the old AchievementManager so the
//  logic is host-testable with a fake store.
//

import Foundation

@MainActor
public struct AchievementTracker {

    private let defaults: any KeyValueStoring

    public init(defaults: any KeyValueStoring = UserDefaults.standard) {
        self.defaults = defaults
    }

    /// Every achievement satisfied by `stats`.
    public func unlockedAchievements(from stats: WorkoutStats) -> Set<Achievement> {
        AchievementEvaluator.unlockedAchievements(from: stats)
    }

    /// Evaluates `stats`, marks every newly unlocked achievement as celebrated, and
    /// returns the highest-tier one to celebrate (nil when nothing new unlocked).
    public func celebrationForNewUnlocks(from stats: WorkoutStats) -> Achievement? {
        let unlocked = AchievementEvaluator.unlockedAchievements(from: stats)
        let celebrated = celebratedAchievements()
        let newlyUnlocked = unlocked.filter { !celebrated.contains($0.rawValue) }
        guard let toCelebrate = newlyUnlocked.max(by: { $0.sortOrder < $1.sortOrder }) else {
            return nil
        }
        saveCelebrated(celebrated.union(newlyUnlocked.map(\.rawValue)))
        return toCelebrate
    }

    /// Clears all celebration bookkeeping (Settings' reset).
    public func resetAllCelebrations() {
        saveCelebrated([])
    }

    // MARK: - Persistence

    public func celebratedAchievements() -> Set<String> {
        guard let array = defaults.array(forKey: AppStorageKeys.celebratedAchievements) as? [String] else {
            return []
        }
        return Set(array)
    }

    private func saveCelebrated(_ celebrated: Set<String>) {
        defaults.set(Array(celebrated), forKey: AppStorageKeys.celebratedAchievements)
    }
}
