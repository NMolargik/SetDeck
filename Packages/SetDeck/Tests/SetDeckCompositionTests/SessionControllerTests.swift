//
//  SessionControllerTests.swift
//  SetDeckCompositionTests
//
//  Composition-root behavior: graph wiring, deep-link staging, Spotlight reindex
//  observation, and the achievement celebration flow — over a real (on-disk,
//  CloudKit-free) container and fake seams.
//

import Foundation
import SwiftData
import Testing
import SetDeckCore
@testable import SetDeckComposition

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

@MainActor
private final class FakeIndexer: ExerciseIndexing {
    private(set) var reindexCalls: [[SetDeckExercise]] = []
    func reindex(exercises: [SetDeckExercise]) {
        reindexCalls.append(exercises)
    }
}

/// Serialized: each test owns a SwiftData container.
@Suite("SessionController", .serialized)
@MainActor
struct SessionControllerTests {

    private func makeContainer() throws -> ModelContainer {
        let storeURL = URL.temporaryDirectory.appending(path: "setdeck-test-\(UUID().uuidString).store")
        let config = ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
        return try ModelContainer(
            for: SetDeckRoutine.self, SetDeckExercise.self, SetDeckSet.self, SetDeckSetHistory.self,
            configurations: config
        )
    }

    private func makeSession(
        container: ModelContainer? = nil,
        defaults: FakeKeyValueStore = FakeKeyValueStore(),
        indexer: FakeIndexer? = nil,
        indexDebounce: Duration = .milliseconds(750)
    ) throws -> SessionController {
        let container = try container ?? makeContainer()
        return SessionController(
            container: container,
            defaults: defaults,
            indexer: indexer,
            indexDebounce: indexDebounce
        )
    }

    // MARK: - Deep links

    @Test("URLs stage a pending deep link; junk does not")
    func urlHandling() throws {
        let session = try makeSession()

        session.handle(url: URL(string: "setdeck://stats")!)
        #expect(session.pendingDeepLink == .stats)

        session.pendingDeepLink = nil
        session.handle(url: URL(string: "https://example.com")!)
        #expect(session.pendingDeepLink == nil)
    }

    // MARK: - Graph wiring

    @Test("writes through the shared model reach the use-cases and bump the change stamp")
    func sharedModelWiring() async throws {
        let session = try makeSession()
        let before = session.workoutData.changeStamp

        let exercise = session.workoutData.addExercise(named: "Squat", toDay: 0)

        #expect(exercise != nil)
        #expect(try session.loadExercises(forDay: 0).count == 1)

        // The change stream bump is delivered asynchronously; a follow-up write keeps
        // the stream hot in case the first event raced the subscription.
        for _ in 0..<100 where session.workoutData.changeStamp == before {
            _ = session.workoutData.addExercise(named: "Bench", toDay: 1)
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(session.workoutData.changeStamp > before)
    }

    @Test("logging a set unlocks and celebrates the first achievement")
    func achievementCelebrationFlow() async throws {
        let session = try makeSession()
        let exercise = try #require(session.workoutData.addExercise(named: "Squat", toDay: 0))
        let set = try #require(session.workoutData.sets(for: exercise).first)

        session.workoutData.update(set: set, withReps: 10, weight: 100, rpe: 7)

        // The achievement check rides the async change stream; nudge it if the first
        // event raced the subscription.
        for _ in 0..<100 where session.achievements.pendingCelebration == nil {
            session.achievements.checkAchievements()
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(session.achievements.pendingCelebration != nil)
        #expect(session.achievements.unlockedAchievements.contains(Achievement.firstWorkout.rawValue))

        session.achievements.dismissCelebration()
        #expect(session.achievements.pendingCelebration == nil)
    }

    @Test("a fresh install whose store already holds history celebrates nothing")
    func restoredInstallHasNoCelebrationBacklog() async throws {
        let container = try makeContainer()

        // A previous install earned achievements; the store (iCloud) carries the history.
        let earlier = try makeSession(container: container, defaults: FakeKeyValueStore())
        let exercise = try #require(earlier.workoutData.addExercise(named: "Squat", toDay: 0))
        let set = try #require(earlier.workoutData.sets(for: exercise).first)
        earlier.workoutData.update(set: set, withReps: 10, weight: 100, rpe: 7)
        earlier.achievements.checkAchievements()
        #expect(!earlier.achievements.unlockedAchievements.isEmpty)

        // Fresh install: empty UserDefaults, same store.
        let restored = try makeSession(container: container, defaults: FakeKeyValueStore())
        #expect(restored.achievements.pendingCelebration == nil)
        #expect(restored.achievements.unlockedAchievements.contains(Achievement.firstWorkout.rawValue))

        // Later local activity must not replay the old unlocks either.
        _ = restored.workoutData.addExercise(named: "Bench", toDay: 1)
        for _ in 0..<20 {
            restored.achievements.checkAchievements()
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(restored.achievements.pendingCelebration == nil)
    }

    // MARK: - Spotlight

    @Test("reindexExercises hands every exercise to the indexer seam")
    func spotlightReindex() throws {
        let indexer = FakeIndexer()
        let session = try makeSession(indexer: indexer)
        _ = session.workoutData.addExercise(named: "Bench", toDay: 1)
        _ = session.workoutData.addExercise(named: "Row", toDay: 2)

        session.reindexExercises()

        let last = try #require(indexer.reindexCalls.last)
        #expect(last.count == 2)
    }

    @Test("a burst of change events collapses into one debounced reindex")
    func spotlightReindexIsDebounced() async throws {
        let indexer = FakeIndexer()
        let session = try makeSession(indexer: indexer, indexDebounce: .milliseconds(50))

        // Each add fires a change-stream event; none should reindex synchronously.
        _ = session.workoutData.addExercise(named: "Bench", toDay: 1)
        _ = session.workoutData.addExercise(named: "Row", toDay: 2)
        _ = session.workoutData.addExercise(named: "Squat", toDay: 3)
        #expect(indexer.reindexCalls.isEmpty)

        try await Task.sleep(for: .milliseconds(400))

        #expect(indexer.reindexCalls.count == 1)
        #expect(indexer.reindexCalls.last?.count == 3)
    }

    @Test("change events that don't touch indexed fields skip the reindex")
    func spotlightReindexSkipsUnchangedContent() async throws {
        let indexer = FakeIndexer()
        let session = try makeSession(indexer: indexer, indexDebounce: .milliseconds(50))
        _ = session.workoutData.addExercise(named: "Bench", toDay: 1)
        try await Task.sleep(for: .milliseconds(400))
        #expect(indexer.reindexCalls.count == 1)

        // History-only write: notifies the change stream, but no exercise field changed.
        session.workoutData.clearAllHistory()
        try await Task.sleep(for: .milliseconds(400))
        #expect(indexer.reindexCalls.count == 1)

        // Renaming is an indexed field, so this one must rebuild.
        let bench = try #require(session.workoutData.exercises(forDay: 1).first)
        session.workoutData.updateExercise(bench) { $0.name = "Incline Bench" }
        try await Task.sleep(for: .milliseconds(400))
        #expect(indexer.reindexCalls.count == 2)
        #expect(indexer.reindexCalls.last?.first?.name == "Incline Bench")
    }
}
