//
//  AchievementTrackerTests.swift
//  SetDeckCoreTests
//
//  Celebration bookkeeping over a fake key-value store — the semantics the old
//  AchievementManager tests exercised through SwiftData, now on pure WorkoutStats.
//

import Foundation
import Testing
import SetDeckCore

private final class FakeKeyValueStore: KeyValueStoring {
    private(set) var storage: [String: Any] = [:]

    func data(forKey defaultName: String) -> Data? { storage[defaultName] as? Data }
    func string(forKey defaultName: String) -> String? { storage[defaultName] as? String }
    func array(forKey defaultName: String) -> [Any]? { storage[defaultName] as? [Any] }
    func bool(forKey defaultName: String) -> Bool { storage[defaultName] as? Bool ?? false }
    func integer(forKey defaultName: String) -> Int { storage[defaultName] as? Int ?? 0 }
    func set(_ value: Any?, forKey defaultName: String) { storage[defaultName] = value }
    func removeObject(forKey defaultName: String) { storage.removeValue(forKey: defaultName) }
}

@Suite("AchievementTracker")
@MainActor
struct AchievementTrackerTests {

    private func stats(sets: Int = 1, maxWeight: Double = 100) -> WorkoutStats {
        WorkoutStats(
            completionDates: [Date()],
            totalSetsLogged: sets,
            maxWeightLogged: maxWeight,
            uniqueExerciseNames: ["Squat"],
            daysWithExercises: [0]
        )
    }

    @Test("first unlock produces a celebration and is marked celebrated")
    func firstUnlockCelebrates() {
        let tracker = AchievementTracker(defaults: FakeKeyValueStore())

        let celebration = tracker.celebrationForNewUnlocks(from: stats())

        #expect(celebration != nil)
        #expect(tracker.celebratedAchievements().contains(Achievement.firstWorkout.rawValue))
    }

    @Test("celebrated achievements are not re-triggered")
    func celebratedNotRetriggered() {
        let tracker = AchievementTracker(defaults: FakeKeyValueStore())

        #expect(tracker.celebrationForNewUnlocks(from: stats()) != nil)
        // Same stats again — nothing newly unlocked.
        #expect(tracker.celebrationForNewUnlocks(from: stats()) == nil)
    }

    @Test("the highest-tier newly unlocked achievement wins the toast")
    func highestTierWins() {
        let tracker = AchievementTracker(defaults: FakeKeyValueStore())

        // 10 sets at 135 lbs unlocks firstWorkout, gettingStarted, and onePlate at once;
        // onePlate has the highest sortOrder.
        let celebration = tracker.celebrationForNewUnlocks(from: stats(sets: 10, maxWeight: 135))

        #expect(celebration == .onePlate)
        // All of them are marked celebrated, not just the toasted one.
        #expect(tracker.celebratedAchievements().isSuperset(of: [
            Achievement.firstWorkout.rawValue,
            Achievement.gettingStarted.rawValue,
            Achievement.onePlate.rawValue,
        ]))
    }

    @Test("reset clears celebration bookkeeping so unlocks re-celebrate")
    func resetClearsBookkeeping() {
        let tracker = AchievementTracker(defaults: FakeKeyValueStore())
        #expect(tracker.celebrationForNewUnlocks(from: stats()) != nil)

        tracker.resetAllCelebrations()

        #expect(tracker.celebratedAchievements().isEmpty)
        #expect(tracker.celebrationForNewUnlocks(from: stats()) != nil)
    }

    @Test("unlockedAchievements mirrors the evaluator")
    func unlockedMirrorsEvaluator() {
        let tracker = AchievementTracker(defaults: FakeKeyValueStore())
        let unlocked = tracker.unlockedAchievements(from: stats(sets: 100, maxWeight: 225))
        #expect(unlocked.contains(.century))
        #expect(unlocked.contains(.twoPlates))
        #expect(!unlocked.contains(.threePlates))
    }
}
