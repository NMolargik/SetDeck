//
//  WorkoutDataModelTests.swift
//  SetDeckFeatureSharedTests
//
//  Behavior tests for the shared view-facing models over fake use-cases: verb routing,
//  change-stream stamping, error toasting (never silent), and celebration flow.
//

import Foundation
import Testing
import SetDeckCore
import SetDeckDesignSystem
@testable import SetDeckFeatureShared

// MARK: - Fakes

@MainActor
private final class FakeWorkoutStore {
    var errorToThrow: PersistenceError?
    var exercisesByDay: [Int: [SetDeckExercise]] = [:]
    private(set) var addedExercises: [(name: String, day: Int)] = []
    private(set) var deleteAllCalls = 0
    let changeCenter = WorkoutChangeCenter()
    var stats = WorkoutStats()

    struct LoadRoutinesFake: LoadRoutines {
        let store: FakeWorkoutStore
        func callAsFunction() throws(PersistenceError) -> [SetDeckRoutine] {
            if let e = store.errorToThrow { throw e }
            return []
        }
    }
    struct LoadRoutineFake: LoadRoutine {
        let store: FakeWorkoutStore
        @discardableResult
        func callAsFunction(forDay day: Int) throws(PersistenceError) -> SetDeckRoutine {
            if let e = store.errorToThrow { throw e }
            return SetDeckRoutine(day: day)
        }
    }
    struct LoadExercisesFake: LoadExercises {
        let store: FakeWorkoutStore
        func callAsFunction(forDay day: Int) throws(PersistenceError) -> [SetDeckExercise] {
            if let e = store.errorToThrow { throw e }
            return store.exercisesByDay[day] ?? []
        }
        func callAsFunction(for routine: SetDeckRoutine) throws(PersistenceError) -> [SetDeckExercise] {
            if let e = store.errorToThrow { throw e }
            return store.exercisesByDay[routine.day] ?? []
        }
    }
    struct AddExerciseFake: AddExercise {
        let store: FakeWorkoutStore
        @discardableResult
        func callAsFunction(named name: String, toDay day: Int, isWarmup: Bool, note: String?) throws(PersistenceError) -> SetDeckExercise {
            if let e = store.errorToThrow { throw e }
            store.addedExercises.append((name, day))
            let ex = SetDeckExercise(name: name)
            store.exercisesByDay[day, default: []].append(ex)
            store.changeCenter.notify()
            return ex
        }
    }
    struct DeleteAllFake: DeleteAllRoutines {
        let store: FakeWorkoutStore
        func callAsFunction() throws(PersistenceError) {
            if let e = store.errorToThrow { throw e }
            store.deleteAllCalls += 1
        }
    }
    struct NoopUpdateExercise: UpdateExercise {
        func callAsFunction(_ exercise: SetDeckExercise, configure: (SetDeckExercise) -> Void) throws(PersistenceError) { configure(exercise) }
    }
    struct NoopReorderExercises: ReorderExercises {
        func callAsFunction(in routine: SetDeckRoutine, newOrder: [SetDeckExercise]) throws(PersistenceError) {}
    }
    struct NoopDeleteExercise: DeleteExercise {
        func callAsFunction(_ exercise: SetDeckExercise) throws(PersistenceError) {}
    }
    struct NoopLoadSets: LoadSets {
        func callAsFunction(for exercise: SetDeckExercise) throws(PersistenceError) -> [SetDeckSet] { [] }
    }
    struct NoopAddSet: AddSet {
        @discardableResult
        func callAsFunction(to exercise: SetDeckExercise, setType: SetType, targetReps: Int?, weight: Double?, targetDuration: TimeInterval?, setDescription: String?, rpe: Int?) throws(PersistenceError) -> SetDeckSet {
            SetDeckSet()
        }
    }
    struct NoopUpdateSet: UpdateSet {
        func callAsFunction(_ set: SetDeckSet, configure: (SetDeckSet) -> Void) throws(PersistenceError) { configure(set) }
    }
    struct NoopReorderSets: ReorderSets {
        func callAsFunction(in exercise: SetDeckExercise, newOrder: [SetDeckSet]) throws(PersistenceError) {}
    }
    struct NoopDeleteSet: DeleteSet {
        func callAsFunction(_ set: SetDeckSet) throws(PersistenceError) {}
    }
    struct NoopLoadHistory: LoadHistory {
        func callAsFunction() throws(PersistenceError) -> [SetDeckSetHistory] { [] }
        func callAsFunction(for exercise: SetDeckExercise) throws(PersistenceError) -> [SetDeckSetHistory] { [] }
    }
    struct NoopLogSet: LogSet {
        func callAsFunction(_ set: SetDeckSet, reps: Int?, weight: Double?, rpe: Int?) throws(PersistenceError) {}
    }
    struct NoopClearHistory: ClearHistory {
        func callAsFunction() throws(PersistenceError) {}
    }
    struct LoadStatsFake: LoadWorkoutStats {
        let store: FakeWorkoutStore
        func callAsFunction() throws(PersistenceError) -> WorkoutStats {
            if let e = store.errorToThrow { throw e }
            return store.stats
        }
    }

    func makeModel(toastManager: ToastManager = ToastManager()) -> WorkoutDataModel {
        WorkoutDataModel(
            loadRoutines: LoadRoutinesFake(store: self),
            loadRoutine: LoadRoutineFake(store: self),
            loadExercises: LoadExercisesFake(store: self),
            addExercise: AddExerciseFake(store: self),
            updateExercise: NoopUpdateExercise(),
            reorderExercises: NoopReorderExercises(),
            deleteExercise: NoopDeleteExercise(),
            loadSets: NoopLoadSets(),
            addSet: NoopAddSet(),
            updateSet: NoopUpdateSet(),
            reorderSets: NoopReorderSets(),
            deleteSet: NoopDeleteSet(),
            deleteAllRoutines: DeleteAllFake(store: self),
            loadHistory: NoopLoadHistory(),
            logSet: NoopLogSet(),
            clearHistory: NoopClearHistory(),
            observeChanges: ObserveWorkoutChangesUseCase(center: changeCenter),
            toastManager: toastManager
        )
    }
}

// MARK: - WorkoutDataModel

@Suite("WorkoutDataModel")
@MainActor
struct WorkoutDataModelTests {

    @Test("verbs route through their use-cases")
    func verbsRoute() {
        let store = FakeWorkoutStore()
        let model = store.makeModel()

        let exercise = model.addExercise(named: "Squat", toDay: 2)

        #expect(exercise != nil)
        #expect(store.addedExercises.map(\.name) == ["Squat"])
        #expect(model.exercises(forDay: 2).count == 1)

        model.deleteAllRoutines()
        #expect(store.deleteAllCalls == 1)
    }

    @Test("failures surface as error toasts, never silently")
    func failuresToast() {
        let store = FakeWorkoutStore()
        let toastManager = ToastManager()
        let model = store.makeModel(toastManager: toastManager)

        store.errorToThrow = .saveFailed("disk full")
        let exercise = model.addExercise(named: "Squat", toDay: 0)

        #expect(exercise == nil)
        #expect(toastManager.currentToast != nil)
        #expect(toastManager.currentToast?.style == .error)
    }

    @Test("change-stream events bump the change stamp")
    func changeStreamBumpsStamp() async {
        let store = FakeWorkoutStore()
        let model = store.makeModel()
        let before = model.changeStamp

        // The observer task subscribes asynchronously; keep notifying until the
        // event lands (each notify is idempotent for this assertion).
        for _ in 0..<100 where model.changeStamp == before {
            store.changeCenter.notify()
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(model.changeStamp > before)
    }
}

// MARK: - AchievementModel

@Suite("AchievementModel (shared)")
@MainActor
struct SharedAchievementModelTests {

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

    @Test("data changes trigger evaluation and celebration exactly once")
    func changeTriggersCelebration() async {
        let store = FakeWorkoutStore()
        let model = AchievementModel(
            loadWorkoutStats: FakeWorkoutStore.LoadStatsFake(store: store),
            tracker: AchievementTracker(defaults: FakeKeyValueStore()),
            observeChanges: ObserveWorkoutChangesUseCase(center: store.changeCenter)
        )
        #expect(model.pendingCelebration == nil)

        store.stats = WorkoutStats(
            completionDates: [Date()], totalSetsLogged: 1, maxWeightLogged: 100,
            uniqueExerciseNames: ["Squat"], daysWithExercises: [0]
        )
        for _ in 0..<100 where model.pendingCelebration == nil {
            store.changeCenter.notify()
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(model.pendingCelebration == .firstWorkout)
        #expect(model.unlockedAchievements.contains(Achievement.firstWorkout.rawValue))

        model.dismissCelebration()
        for _ in 0..<5 {
            store.changeCenter.notify()
            try? await Task.sleep(for: .milliseconds(10))
        }
        // Already celebrated — no re-trigger.
        #expect(model.pendingCelebration == nil)
    }

    @Test("reset clears unlocks and pending celebration")
    func resetClears() {
        let store = FakeWorkoutStore()
        store.stats = WorkoutStats(
            completionDates: [Date()], totalSetsLogged: 1, maxWeightLogged: 0,
            uniqueExerciseNames: [], daysWithExercises: []
        )
        let model = AchievementModel(
            loadWorkoutStats: FakeWorkoutStore.LoadStatsFake(store: store),
            tracker: AchievementTracker(defaults: FakeKeyValueStore()),
            observeChanges: ObserveWorkoutChangesUseCase(center: store.changeCenter)
        )
        model.checkAchievements()
        #expect(!model.unlockedAchievements.isEmpty)

        model.resetAllAchievements()

        #expect(model.unlockedAchievements.isEmpty)
        #expect(model.pendingCelebration == nil)
    }
}
