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

    /// A tracker that has already done its silent first evaluation on an empty store.
    private func baselinedTracker() -> AchievementTracker {
        let tracker = AchievementTracker(defaults: FakeKeyValueStore())
        tracker.markUnlockedAsSeen(from: WorkoutStats())
        return tracker
    }

    @Test("first unlock produces a celebration and is marked celebrated")
    func firstUnlockCelebrates() {
        let tracker = baselinedTracker()

        let celebration = tracker.celebrationForNewUnlocks(from: stats())

        #expect(celebration != nil)
        #expect(tracker.celebratedAchievements().contains(Achievement.firstWorkout.rawValue))
    }

    @Test("celebrated achievements are not re-triggered")
    func celebratedNotRetriggered() {
        let tracker = baselinedTracker()

        #expect(tracker.celebrationForNewUnlocks(from: stats()) != nil)
        // Same stats again — nothing newly unlocked.
        #expect(tracker.celebrationForNewUnlocks(from: stats()) == nil)
    }

    @Test("the highest-tier newly unlocked achievement wins the toast")
    func highestTierWins() {
        let tracker = baselinedTracker()

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
        let tracker = baselinedTracker()
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

    @Test("the first evaluation on a fresh install silently marks earned achievements as seen")
    func firstEvaluationIsSilent() {
        let tracker = AchievementTracker(defaults: FakeKeyValueStore())
        #expect(!tracker.isBaselineEstablished)

        // A returning install: iCloud history is already present at first launch.
        #expect(tracker.celebrationForNewUnlocks(from: stats(sets: 10, maxWeight: 135)) == nil)
        #expect(tracker.isBaselineEstablished)
        #expect(tracker.celebratedAchievements().isSuperset(of: [
            Achievement.firstWorkout.rawValue,
            Achievement.gettingStarted.rawValue,
            Achievement.onePlate.rawValue,
        ]))

        // Same history again: still nothing.
        #expect(tracker.celebrationForNewUnlocks(from: stats(sets: 10, maxWeight: 135)) == nil)
        // New activity on this device crosses a new threshold: that celebrates.
        #expect(tracker.celebrationForNewUnlocks(from: stats(sets: 10, maxWeight: 225)) == .twoPlates)
    }

    @Test("markUnlockedAsSeen suppresses already-earned achievements but not later ones")
    func markUnlockedAsSeenIsSilent() {
        let tracker = baselinedTracker()
        tracker.markUnlockedAsSeen(from: stats(sets: 10, maxWeight: 135))
        #expect(tracker.celebrationForNewUnlocks(from: stats(sets: 10, maxWeight: 135)) == nil)
        #expect(tracker.celebrationForNewUnlocks(from: stats(sets: 100, maxWeight: 135)) == .century)
    }

    @Test("installs that already celebrated under an earlier version count as baselined")
    func existingCelebrationsImplyBaseline() {
        let defaults = FakeKeyValueStore()
        defaults.set([Achievement.firstWorkout.rawValue], forKey: AppStorageKeys.celebratedAchievements)
        let tracker = AchievementTracker(defaults: defaults)
        #expect(tracker.isBaselineEstablished)
        #expect(tracker.celebrationForNewUnlocks(from: stats(sets: 10, maxWeight: 135)) == .onePlate)
    }
}
