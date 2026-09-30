//
//  AchievementModel.swift
//  SetDeckFeatureShared
//
//  The environment-injected achievement surface (successor to AchievementManager):
//  evaluates unlocks from the pure `WorkoutStats` snapshot, fires celebrations for new
//  ones via `AchievementTracker`, and re-checks on every workout-data change through
//  the multicast stream (the old version hooked a single-subscriber callback).
//

import Foundation
import Observation
import SetDeckCore
import os

@MainActor
@Observable
public final class AchievementModel {

    @ObservationIgnored private let loadWorkoutStats: any LoadWorkoutStats
    @ObservationIgnored private let tracker: AchievementTracker
    @ObservationIgnored private let observeChanges: any ObserveWorkoutChanges

    /// The achievement to celebrate right now (drives the celebration overlay).
    public var pendingCelebration: Achievement?
    /// Raw values of every currently-unlocked achievement.
    public private(set) var unlockedAchievements: Set<String> = []

    @ObservationIgnored private var observationTask: Task<Void, Never>?

    public init(
        loadWorkoutStats: any LoadWorkoutStats,
        tracker: AchievementTracker,
        observeChanges: any ObserveWorkoutChanges
    ) {
        self.loadWorkoutStats = loadWorkoutStats
        self.tracker = tracker
        self.observeChanges = observeChanges
        refreshUnlockedAchievements()
        startObserving()
    }

    deinit {
        observationTask?.cancel()
    }

    private func startObserving() {
        observationTask = Task { [weak self] in
            guard let stream = self?.observeChanges() else { return }
            for await _ in stream {
                guard let self else { return }
                self.checkAchievements()
            }
        }
    }

    // MARK: - Public

    /// Evaluates all achievements and fires a celebration for the highest-tier newly
    /// unlocked one.
    public func checkAchievements() {
        guard let stats = currentStats() else { return }
        unlockedAchievements = Set(tracker.unlockedAchievements(from: stats).map(\.rawValue))

        if let toCelebrate = tracker.celebrationForNewUnlocks(from: stats) {
            pendingCelebration = toCelebrate
            Log.achievements.info("Achievement unlocked: \(toCelebrate.displayName)")
        }
    }

    /// Clears the pending celebration.
    public func dismissCelebration() {
        pendingCelebration = nil
    }

    /// Refreshes the unlocked set without triggering celebrations.
    public func refreshUnlockedAchievements() {
        guard let stats = currentStats() else { return }
        unlockedAchievements = Set(tracker.unlockedAchievements(from: stats).map(\.rawValue))
    }

    /// Resets all achievement progress.
    public func resetAllAchievements() {
        tracker.resetAllCelebrations()
        unlockedAchievements = []
        pendingCelebration = nil
        Log.achievements.info("All achievements reset")
    }

    // MARK: - Private

    private func currentStats() -> WorkoutStats? {
        do {
            return try loadWorkoutStats()
        } catch {
            Log.achievements.error("Stats snapshot failed: \(error.localizedDescription)")
            return nil
        }
    }
}
