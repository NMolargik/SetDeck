//
//  SessionController.swift
//  SetDeckComposition
//
//  The composition root. Builds the whole dependency graph once (container → change
//  center → repositories → use-cases → shared models → system-framework managers) and
//  owns app-wide policy: deep-link state, Spotlight reindexing, and startup work.
//  Screens read the shared @Observable models from the environment (RootView injects
//  them); App Intents reach persistence through the use-case properties — never a
//  repository directly.
//

import Foundation
import Observation
import SwiftData
import SetDeckCore
import SetDeckData
import SetDeckDesignSystem
import SetDeckFeatureShared
import SetDeckServices
import os

@MainActor
@Observable
public final class SessionController {

    // MARK: - Graph

    public let container: ModelContainer
    public let toastManager: ToastManager
    public let workoutData: WorkoutDataModel
    public let achievements: AchievementModel
    public let cloudSyncManager: CloudSyncManager
    public let muscleGroupInference: MuscleGroupInferenceService

    #if canImport(HealthKit) && !os(macOS)
    public let healthManager: HealthManager
    #endif
    #if canImport(WatchConnectivity)
    public let phoneConnectivity: PhoneConnectivityManager
    #endif

    private let indexer: (any ExerciseIndexing)?

    // Use-cases exposed for App Intents and the watch relay.
    public let loadRoutines: any LoadRoutines
    public let loadRoutine: any LoadRoutine
    public let loadExercises: any LoadExercises
    public let loadSets: any LoadSets
    public let findSet: any FindSet
    public let recordSetCompletion: any RecordSetCompletion
    public let loadWorkoutStats: any LoadWorkoutStats
    public let observeWorkoutChanges: any ObserveWorkoutChanges

    // MARK: - App-wide state

    /// Deep link waiting to be routed (set by onOpenURL, widgets, menu commands,
    /// and App Intents; consumed by MainView).
    public var pendingDeepLink: DeepLink?

    @ObservationIgnored
    private var indexObservationTask: Task<Void, Never>?

    /// Pending coalesced reindex for a burst of change-stream events.
    @ObservationIgnored
    private var pendingIndexTask: Task<Void, Never>?

    /// How long to wait after the last change-stream event before reindexing.
    /// CloudKit imports and local saves arrive in bursts (each save also posts a
    /// remote-change notification), so a single launch could otherwise reindex
    /// dozens of times.
    private let indexDebounce: Duration

    /// Snapshot of what Spotlight last received, so change events that don't touch
    /// the indexed fields (set logging, history clears, CloudKit no-ops) skip the
    /// rebuild entirely.
    @ObservationIgnored
    private var lastIndexFingerprint: [String]?

    // MARK: - Init

    public init(
        container: ModelContainer? = nil,
        defaults: any KeyValueStoring = UserDefaults.standard,
        indexer: (any ExerciseIndexing)? = nil,
        indexDebounce: Duration = .milliseconds(750)
    ) {
        let container = container ?? SetDeckStore.makeContainer()
        self.container = container
        self.indexer = indexer
        self.indexDebounce = indexDebounce

        let toastManager = ToastManager()
        self.toastManager = toastManager

        let changeCenter = WorkoutChangeCenter()
        let routineRepository = DefaultRoutineRepository(container: container, changeCenter: changeCenter)
        let historyRepository = DefaultHistoryRepository(container: container, changeCenter: changeCenter)

        let loadRoutines = LoadRoutinesUseCase(repository: routineRepository)
        let loadRoutine = LoadRoutineUseCase(repository: routineRepository)
        let loadExercises = LoadExercisesUseCase(repository: routineRepository)
        let loadSets = LoadSetsUseCase(repository: routineRepository)
        let findSet = FindSetUseCase(repository: historyRepository)
        let recordSetCompletion = RecordSetCompletionUseCase(repository: historyRepository)
        let loadWorkoutStats = LoadWorkoutStatsUseCase(repository: historyRepository)
        let observeWorkoutChanges = ObserveWorkoutChangesUseCase(center: changeCenter)

        self.loadRoutines = loadRoutines
        self.loadRoutine = loadRoutine
        self.loadExercises = loadExercises
        self.loadSets = loadSets
        self.findSet = findSet
        self.recordSetCompletion = recordSetCompletion
        self.loadWorkoutStats = loadWorkoutStats
        self.observeWorkoutChanges = observeWorkoutChanges

        #if DEBUG
        let sampleData: (any GenerateSampleData)? = SampleWorkoutData(routines: routineRepository, history: historyRepository)
        workoutData = WorkoutDataModel(
            loadRoutines: loadRoutines,
            loadRoutine: loadRoutine,
            loadExercises: loadExercises,
            addExercise: AddExerciseUseCase(repository: routineRepository),
            updateExercise: UpdateExerciseUseCase(repository: routineRepository),
            reorderExercises: ReorderExercisesUseCase(repository: routineRepository),
            deleteExercise: DeleteExerciseUseCase(repository: routineRepository),
            loadSets: loadSets,
            addSet: AddSetUseCase(repository: routineRepository),
            updateSet: UpdateSetUseCase(repository: routineRepository),
            reorderSets: ReorderSetsUseCase(repository: routineRepository),
            deleteSet: DeleteSetUseCase(repository: routineRepository),
            deleteAllRoutines: DeleteAllRoutinesUseCase(repository: routineRepository),
            loadHistory: LoadHistoryUseCase(repository: historyRepository),
            logSet: LogSetUseCase(routines: routineRepository, history: historyRepository),
            clearHistory: ClearHistoryUseCase(repository: historyRepository),
            observeChanges: observeWorkoutChanges,
            generateSampleData: sampleData,
            toastManager: toastManager
        )
        #else
        workoutData = WorkoutDataModel(
            loadRoutines: loadRoutines,
            loadRoutine: loadRoutine,
            loadExercises: loadExercises,
            addExercise: AddExerciseUseCase(repository: routineRepository),
            updateExercise: UpdateExerciseUseCase(repository: routineRepository),
            reorderExercises: ReorderExercisesUseCase(repository: routineRepository),
            deleteExercise: DeleteExerciseUseCase(repository: routineRepository),
            loadSets: loadSets,
            addSet: AddSetUseCase(repository: routineRepository),
            updateSet: UpdateSetUseCase(repository: routineRepository),
            reorderSets: ReorderSetsUseCase(repository: routineRepository),
            deleteSet: DeleteSetUseCase(repository: routineRepository),
            deleteAllRoutines: DeleteAllRoutinesUseCase(repository: routineRepository),
            loadHistory: LoadHistoryUseCase(repository: historyRepository),
            logSet: LogSetUseCase(routines: routineRepository, history: historyRepository),
            clearHistory: ClearHistoryUseCase(repository: historyRepository),
            observeChanges: observeWorkoutChanges,
            toastManager: toastManager
        )
        #endif

        achievements = AchievementModel(
            loadWorkoutStats: loadWorkoutStats,
            tracker: AchievementTracker(defaults: defaults),
            observeChanges: observeWorkoutChanges
        )

        let cloud = CloudSyncManager(changeCenter: changeCenter)
        cloud.configure(with: container.mainContext)
        cloudSyncManager = cloud

        muscleGroupInference = MuscleGroupInferenceService()

        #if canImport(HealthKit) && !os(macOS)
        healthManager = HealthManager()
        #endif

        #if canImport(WatchConnectivity)
        let phone = PhoneConnectivityManager()
        phone.configure(
            loadRoutine: loadRoutine,
            loadExercises: loadExercises,
            loadSets: loadSets,
            findSet: findSet,
            recordSetCompletion: recordSetCompletion
        )
        phoneConnectivity = phone
        #endif

        // UI-test affordance (DEBUG only): skip onboarding/sync and seed
        // deterministic sample data so the main interface is populated
        // immediately. Gated to DEBUG so it can never run in a shipping build.
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            defaults.set(true, forKey: AppStorageKeys.isOnboardingComplete)
            defaults.set(true, forKey: AppStorageKeys.hasCompletedInitialSync)
            workoutData.generateSampleDataForLast30Days()
        }
        #endif

        startIndexObservation()
    }

    deinit {
        indexObservationTask?.cancel()
        pendingIndexTask?.cancel()
    }

    // MARK: - Startup

    /// One-time launch work: watch connectivity + Spotlight seeding (covers items
    /// synced via CloudKit while the app wasn't running).
    public func start() {
        #if canImport(WatchConnectivity)
        phoneConnectivity.activate()
        #endif
        reindexExercises()
    }

    // MARK: - Deep links

    /// Parses and stages an external URL (`setdeck://…`); MainView consumes it.
    public func handle(url: URL) {
        guard let link = DeepLink(url: url) else { return }
        pendingDeepLink = link
    }

    // MARK: - Spotlight

    /// Rebuilds the semantic exercise index unconditionally (launch seeding and
    /// explicit requests). Change-stream events go through `reindexExercisesIfNeeded`.
    public func reindexExercises() {
        guard let indexer else { return }
        do {
            let exercises = try allExercises()
            lastIndexFingerprint = Self.indexFingerprint(of: exercises)
            indexer.reindex(exercises: exercises)
        } catch {
            Log.spotlight.error("Reindex fetch failed: \(error.localizedDescription)")
        }
    }

    /// Rebuilds the index only when an indexed field actually changed since the
    /// last rebuild.
    func reindexExercisesIfNeeded() {
        guard let indexer else { return }
        do {
            let exercises = try allExercises()
            let fingerprint = Self.indexFingerprint(of: exercises)
            guard fingerprint != lastIndexFingerprint else {
                Log.spotlight.debug("Spotlight index unchanged; skipping reindex")
                return
            }
            lastIndexFingerprint = fingerprint
            indexer.reindex(exercises: exercises)
        } catch {
            Log.spotlight.error("Reindex fetch failed: \(error.localizedDescription)")
        }
    }

    private func allExercises() throws(PersistenceError) -> [SetDeckExercise] {
        var exercises: [SetDeckExercise] = []
        for routine in try loadRoutines() {
            exercises.append(contentsOf: try loadExercises(for: routine))
        }
        return exercises
    }

    /// Mirrors the fields `ExerciseEntity` (app target) publishes to Spotlight.
    private static func indexFingerprint(of exercises: [SetDeckExercise]) -> [String] {
        exercises.map { exercise in
            "\(exercise.uuid)|\(exercise.name)|\(exercise.routine?.day ?? -1)|\(exercise.isWarmup)|\(exercise.sets?.count ?? 0)"
        }
    }

    private func startIndexObservation() {
        guard indexer != nil else { return }
        indexObservationTask = Task { [weak self] in
            guard let stream = self?.observeWorkoutChanges() else { return }
            for await _ in stream {
                guard let self else { return }
                self.scheduleReindex()
            }
        }
    }

    /// Coalesces a burst of change events into one reindex after `indexDebounce`.
    private func scheduleReindex() {
        pendingIndexTask?.cancel()
        pendingIndexTask = Task { [weak self, indexDebounce] in
            do {
                try await Task.sleep(for: indexDebounce)
            } catch {
                return // cancelled by a newer event
            }
            guard let self, !Task.isCancelled else { return }
            self.pendingIndexTask = nil
            self.reindexExercisesIfNeeded()
        }
    }
}
