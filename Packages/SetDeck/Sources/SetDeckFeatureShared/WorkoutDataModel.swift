//
//  WorkoutDataModel.swift
//  SetDeckFeatureShared
//
//  The environment-injected data surface feature views share (successor to the old
//  ExerciseManager environment object). Every read/write goes through use-case
//  protocols; failures surface as error toasts instead of being silently swallowed;
//  `changeStamp` bumps on every mutation (local or CloudKit import) so SwiftUI views
//  that compute from fetches re-evaluate.
//

import Foundation
import Observation
import SetDeckCore
import SetDeckDesignSystem
import os

@MainActor
@Observable
public final class WorkoutDataModel {

    // MARK: - Dependencies

    @ObservationIgnored private let loadRoutines: any LoadRoutines
    @ObservationIgnored private let loadRoutine: any LoadRoutine
    @ObservationIgnored private let loadExercises: any LoadExercises
    @ObservationIgnored private let addExerciseUseCase: any AddExercise
    @ObservationIgnored private let updateExerciseUseCase: any UpdateExercise
    @ObservationIgnored private let reorderExercisesUseCase: any ReorderExercises
    @ObservationIgnored private let deleteExerciseUseCase: any DeleteExercise
    @ObservationIgnored private let loadSets: any LoadSets
    @ObservationIgnored private let addSetUseCase: any AddSet
    @ObservationIgnored private let updateSetUseCase: any UpdateSet
    @ObservationIgnored private let reorderSetsUseCase: any ReorderSets
    @ObservationIgnored private let deleteSetUseCase: any DeleteSet
    @ObservationIgnored private let deleteAllRoutinesUseCase: any DeleteAllRoutines
    @ObservationIgnored private let loadHistory: any LoadHistory
    @ObservationIgnored private let logSetUseCase: any LogSet
    @ObservationIgnored private let clearHistoryUseCase: any ClearHistory
    @ObservationIgnored private let observeChanges: any ObserveWorkoutChanges
    #if DEBUG
    @ObservationIgnored private let generateSampleDataUseCase: (any GenerateSampleData)?
    #endif
    private let toastManager: ToastManager

    /// Bumped after every mutation so views recompute derived fetches.
    public private(set) var changeStamp: Int = 0

    @ObservationIgnored private var observationTask: Task<Void, Never>?

    #if DEBUG
    public init(
        loadRoutines: any LoadRoutines,
        loadRoutine: any LoadRoutine,
        loadExercises: any LoadExercises,
        addExercise: any AddExercise,
        updateExercise: any UpdateExercise,
        reorderExercises: any ReorderExercises,
        deleteExercise: any DeleteExercise,
        loadSets: any LoadSets,
        addSet: any AddSet,
        updateSet: any UpdateSet,
        reorderSets: any ReorderSets,
        deleteSet: any DeleteSet,
        deleteAllRoutines: any DeleteAllRoutines,
        loadHistory: any LoadHistory,
        logSet: any LogSet,
        clearHistory: any ClearHistory,
        observeChanges: any ObserveWorkoutChanges,
        generateSampleData: (any GenerateSampleData)? = nil,
        toastManager: ToastManager
    ) {
        self.loadRoutines = loadRoutines
        self.loadRoutine = loadRoutine
        self.loadExercises = loadExercises
        self.addExerciseUseCase = addExercise
        self.updateExerciseUseCase = updateExercise
        self.reorderExercisesUseCase = reorderExercises
        self.deleteExerciseUseCase = deleteExercise
        self.loadSets = loadSets
        self.addSetUseCase = addSet
        self.updateSetUseCase = updateSet
        self.reorderSetsUseCase = reorderSets
        self.deleteSetUseCase = deleteSet
        self.deleteAllRoutinesUseCase = deleteAllRoutines
        self.loadHistory = loadHistory
        self.logSetUseCase = logSet
        self.clearHistoryUseCase = clearHistory
        self.observeChanges = observeChanges
        self.generateSampleDataUseCase = generateSampleData
        self.toastManager = toastManager
        startObserving()
    }
    #else
    public init(
        loadRoutines: any LoadRoutines,
        loadRoutine: any LoadRoutine,
        loadExercises: any LoadExercises,
        addExercise: any AddExercise,
        updateExercise: any UpdateExercise,
        reorderExercises: any ReorderExercises,
        deleteExercise: any DeleteExercise,
        loadSets: any LoadSets,
        addSet: any AddSet,
        updateSet: any UpdateSet,
        reorderSets: any ReorderSets,
        deleteSet: any DeleteSet,
        deleteAllRoutines: any DeleteAllRoutines,
        loadHistory: any LoadHistory,
        logSet: any LogSet,
        clearHistory: any ClearHistory,
        observeChanges: any ObserveWorkoutChanges,
        toastManager: ToastManager
    ) {
        self.loadRoutines = loadRoutines
        self.loadRoutine = loadRoutine
        self.loadExercises = loadExercises
        self.addExerciseUseCase = addExercise
        self.updateExerciseUseCase = updateExercise
        self.reorderExercisesUseCase = reorderExercises
        self.deleteExerciseUseCase = deleteExercise
        self.loadSets = loadSets
        self.addSetUseCase = addSet
        self.updateSetUseCase = updateSet
        self.reorderSetsUseCase = reorderSets
        self.deleteSetUseCase = deleteSet
        self.deleteAllRoutinesUseCase = deleteAllRoutines
        self.loadHistory = loadHistory
        self.logSetUseCase = logSet
        self.clearHistoryUseCase = clearHistory
        self.observeChanges = observeChanges
        self.toastManager = toastManager
        startObserving()
    }
    #endif

    deinit {
        observationTask?.cancel()
    }

    /// Every mutation (including CloudKit imports relayed by CloudSyncManager) bumps
    /// the change stamp through the one multicast stream.
    private func startObserving() {
        observationTask = Task { [weak self] in
            guard let stream = self?.observeChanges() else { return }
            for await _ in stream {
                guard let self else { return }
                self.changeStamp &+= 1
            }
        }
    }

    // MARK: - Reads (stale-tolerant: failures toast and return empty)

    public func allRoutines() -> [SetDeckRoutine] {
        surfacing(fallback: []) { try loadRoutines() }
    }

    public func routine(for day: Int) -> SetDeckRoutine? {
        surfacing(fallback: nil) { try loadRoutine(forDay: day) }
    }

    public func exercises(forDay day: Int) -> [SetDeckExercise] {
        surfacing(fallback: []) { try loadExercises(forDay: day) }
    }

    public func exercises(for routine: SetDeckRoutine) -> [SetDeckExercise] {
        surfacing(fallback: []) { try loadExercises(for: routine) }
    }

    public func sets(for exercise: SetDeckExercise) -> [SetDeckSet] {
        surfacing(fallback: []) { try loadSets(for: exercise) }
    }

    public func allHistoryEntries() -> [SetDeckSetHistory] {
        surfacing(fallback: []) { try loadHistory() }
    }

    public func history(for exercise: SetDeckExercise) -> [SetDeckSetHistory] {
        surfacing(fallback: []) { try loadHistory(for: exercise) }
    }

    // MARK: - Writes (failures toast; nothing is silently dropped)

    @discardableResult
    public func addExercise(named name: String, toDay day: Int, isWarmup: Bool = false, note: String? = nil) -> SetDeckExercise? {
        surfacing(fallback: nil) { try addExerciseUseCase(named: name, toDay: day, isWarmup: isWarmup, note: note) }
    }

    public func updateExercise(_ exercise: SetDeckExercise, configure: (SetDeckExercise) -> Void) {
        surfacing(fallback: ()) { try updateExerciseUseCase(exercise, configure: configure) }
    }

    public func reorderExercises(in routine: SetDeckRoutine, newOrder: [SetDeckExercise]) {
        surfacing(fallback: ()) { try reorderExercisesUseCase(in: routine, newOrder: newOrder) }
    }

    public func deleteExercise(_ exercise: SetDeckExercise) {
        surfacing(fallback: ()) { try deleteExerciseUseCase(exercise) }
    }

    @discardableResult
    public func addSet(
        to exercise: SetDeckExercise,
        setType: SetType = .reps,
        targetReps: Int? = nil,
        weight: Double? = nil,
        targetDuration: TimeInterval? = nil,
        setDescription: String? = nil,
        rpe: Int? = nil
    ) -> SetDeckSet? {
        surfacing(fallback: nil) {
            try addSetUseCase(
                to: exercise, setType: setType, targetReps: targetReps, weight: weight,
                targetDuration: targetDuration, setDescription: setDescription, rpe: rpe
            )
        }
    }

    public func updateSet(_ set: SetDeckSet, configure: (SetDeckSet) -> Void) {
        surfacing(fallback: ()) { try updateSetUseCase(set, configure: configure) }
    }

    /// "I did this set": updates targets and records a history entry.
    public func update(set: SetDeckSet, withReps reps: Int?, weight: Double?, rpe: Int?) {
        surfacing(fallback: ()) { try logSetUseCase(set, reps: reps, weight: weight, rpe: rpe) }
    }

    public func reorderSets(in exercise: SetDeckExercise, newOrder: [SetDeckSet]) {
        surfacing(fallback: ()) { try reorderSetsUseCase(in: exercise, newOrder: newOrder) }
    }

    public func deleteSet(_ set: SetDeckSet) {
        surfacing(fallback: ()) { try deleteSetUseCase(set) }
    }

    public func deleteAllRoutines() {
        surfacing(fallback: ()) { try deleteAllRoutinesUseCase() }
    }

    public func clearAllHistory() {
        surfacing(fallback: ()) { try clearHistoryUseCase() }
    }

    #if DEBUG
    public func generateSampleDataForLast30Days() {
        guard let generateSampleDataUseCase else { return }
        surfacing(fallback: ()) { try generateSampleDataUseCase() }
    }
    #endif

    // MARK: - Error surfacing

    private func surfacing<T>(fallback: T, _ body: () throws -> T) -> T {
        do {
            return try body()
        } catch let error as PersistenceError {
            Log.workouts.error("Workout data operation failed: \(error.localizedDescription)")
            toastManager.show(error: error)
            return fallback
        } catch {
            Log.workouts.error("Workout data operation failed: \(error.localizedDescription)")
            toastManager.show(message: error.localizedDescription, style: .error)
            return fallback
        }
    }
}
