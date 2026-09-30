//
//  PhoneConnectivityManager.swift
//  SetDeckServices
//
//  The phone side of WatchConnectivity: sends today's routine, records set completions
//  the watch logs. Reads/writes go through use-cases (the old version reached into
//  ExerciseManager and kept its own copy of the wire DTOs — those now live once in
//  SetDeckCore). Delegate callbacks are nonisolated and extract Sendable values before
//  hopping to the main actor.
//

#if canImport(WatchConnectivity)
import Foundation
import WatchConnectivity
import SetDeckCore
import os

private let logger = Logger(subsystem: "com.molargiksoftware.SetDeck", category: "PhoneConnectivity")

@MainActor
@Observable
public final class PhoneConnectivityManager: NSObject {
    // MARK: - Public State
    public private(set) var isReachable: Bool = false
    public private(set) var isPaired: Bool = false
    public private(set) var isWatchAppInstalled: Bool = false

    // MARK: - Dependencies (injected after the graph is built)
    @ObservationIgnored
    private var loadRoutine: (any LoadRoutine)?
    @ObservationIgnored
    private var loadExercises: (any LoadExercises)?
    @ObservationIgnored
    private var loadSets: (any LoadSets)?
    @ObservationIgnored
    private var findSet: (any FindSet)?
    @ObservationIgnored
    private var recordSetCompletion: (any RecordSetCompletion)?

    // MARK: - Private
    private var session: WCSession?

    public override init() {
        super.init()
    }

    /// Wires the use-cases the relay needs (composition root calls this once).
    public func configure(
        loadRoutine: any LoadRoutine,
        loadExercises: any LoadExercises,
        loadSets: any LoadSets,
        findSet: any FindSet,
        recordSetCompletion: any RecordSetCompletion
    ) {
        self.loadRoutine = loadRoutine
        self.loadExercises = loadExercises
        self.loadSets = loadSets
        self.findSet = findSet
        self.recordSetCompletion = recordSetCompletion
    }

    // MARK: - Activation
    public func activate() {
        guard WCSession.isSupported() else {
            logger.warning("WatchConnectivity not supported on this device")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()

        logger.info("WatchConnectivity session activating...")
    }

    // MARK: - Send Routine to Watch
    public func sendTodayRoutineToWatch() {
        guard let session = session else {
            logger.warning("Cannot send routine: WCSession not initialized")
            return
        }
        guard session.isPaired, session.isWatchAppInstalled else {
            logger.debug("Cannot send routine: Watch not paired or app not installed")
            return
        }

        guard let watchRoutine = try? buildTodayRoutine() else {
            logger.warning("Cannot send routine: use-cases unavailable or fetch failed")
            return
        }

        do {
            let data = try JSONEncoder().encode(watchRoutine)

            // Always update application context so Watch has cached data
            try session.updateApplicationContext([WatchMessageKey.routineData: data])
            logger.info("Updated application context with routine (\(watchRoutine.exercises.count) exercises)")

            // Also send immediately if reachable for faster sync
            if session.isReachable {
                session.sendMessage([WatchMessageKey.routineData: data], replyHandler: nil) { error in
                    logger.error("Failed to send routine via message: \(error.localizedDescription)")
                }
            }
        } catch {
            logger.error("Failed to encode/send routine: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Set Completion from Watch
    private func handleSetCompletion(from data: Data) {
        guard let findSet, let recordSetCompletion else {
            logger.warning("Cannot handle set completion: use-cases not configured")
            return
        }

        do {
            let completion = try JSONDecoder().decode(SetCompletionMessage.self, from: data)

            guard let set = try findSet(withID: completion.setId) else {
                logger.warning("Could not find set with ID: \(completion.setId)")
                return
            }
            _ = try recordSetCompletion(
                for: set,
                completedDate: completion.completedDate,
                actualReps: completion.actualReps,
                actualWeight: completion.actualWeight,
                actualWeightUnit: nil,
                actualDuration: nil,
                actualDescription: nil,
                actualRpe: completion.actualRpe,
                note: "Logged from Apple Watch"
            )
            logger.info("Recorded set completion from Watch")
        } catch {
            logger.error("Failed to record set completion: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers
    private func getTodayDayIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday - 1 + 7) % 7
    }

    private func buildTodayRoutine() throws -> WatchRoutine? {
        guard let loadRoutine, let loadExercises, let loadSets else { return nil }

        let todayIndex = getTodayDayIndex()
        let routine = try loadRoutine(forDay: todayIndex)
        let exercises = try loadExercises(for: routine)

        let watchExercises: [WatchExercise] = try exercises.map { exercise in
            let sets = try loadSets(for: exercise)
            let watchSets = sets.map { set in
                WatchSet(
                    id: set.uuid,
                    setType: WatchSetType(from: set.setType),
                    targetReps: set.targetReps,
                    weight: set.weight,
                    weightUnit: "lb",
                    targetDuration: set.targetDuration,
                    rpe: set.rpe,
                    orderIndex: set.orderIndex
                )
            }

            return WatchExercise(
                id: exercise.uuid,
                name: exercise.name,
                isWarmup: exercise.isWarmup,
                note: exercise.note,
                orderIndex: exercise.orderIndex,
                sets: watchSets
            )
        }

        return WatchRoutine(id: routine.uuid, day: routine.day, exercises: watchExercises)
    }
}

// MARK: - WCSessionDelegate
extension PhoneConnectivityManager: WCSessionDelegate {
    nonisolated public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Extract Sendable values before hopping to the main actor; WCSession
        // and Error are not Sendable and must not cross the isolation boundary.
        let isPaired = session.isPaired
        let isWatchAppInstalled = session.isWatchAppInstalled
        let isReachable = session.isReachable
        let stateRawValue = activationState.rawValue
        let errorDescription = error?.localizedDescription
        Task { @MainActor in
            if let errorDescription {
                logger.error("WatchConnectivity activation failed: \(errorDescription)")
            } else {
                logger.info("WatchConnectivity activated with state: \(stateRawValue)")
                self.isPaired = isPaired
                self.isWatchAppInstalled = isWatchAppInstalled
                self.isReachable = isReachable

                // Send routine on activation if Watch is reachable
                if isReachable {
                    self.sendTodayRoutineToWatch()
                }
            }
        }
    }

    nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            logger.debug("WatchConnectivity session became inactive")
        }
    }

    nonisolated public func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            logger.debug("WatchConnectivity session deactivated")
            // Reactivate for switching watches
            self.activate()
        }
    }

    nonisolated public func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable
        Task { @MainActor in
            self.isReachable = isReachable
            logger.debug("Watch reachability changed: \(isReachable)")
        }
    }

    nonisolated public func sessionWatchStateDidChange(_ session: WCSession) {
        let isPaired = session.isPaired
        let isWatchAppInstalled = session.isWatchAppInstalled
        Task { @MainActor in
            self.isPaired = isPaired
            self.isWatchAppInstalled = isWatchAppInstalled
            logger.debug("Watch state changed - paired: \(isPaired), installed: \(isWatchAppInstalled)")
        }
    }

    // Handle messages from Watch
    nonisolated public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Extract Sendable values from the non-Sendable message before hopping.
        let hasRoutineRequest = message[WatchMessageKey.routineRequest] != nil
        let setCompletionData = message[WatchMessageKey.setCompletion] as? Data
        let hasWorkoutStarted = message[WatchMessageKey.workoutStarted] != nil
        let hasWorkoutEnded = message[WatchMessageKey.workoutEnded] != nil
        Task { @MainActor in
            if hasRoutineRequest {
                self.sendTodayRoutineToWatch()
            }
            if let setCompletionData {
                self.handleSetCompletion(from: setCompletionData)
            }
            if hasWorkoutStarted {
                logger.info("Watch started a workout")
            }
            if hasWorkoutEnded {
                logger.info("Watch ended a workout")
            }
        }
    }

    // Handle messages with reply
    nonisolated public func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        let hasRoutineRequest = message[WatchMessageKey.routineRequest] != nil
        // WCSession reply handlers are invoked once; box to transfer safely.
        let replyBox = UncheckedSendableBox(value: replyHandler)
        Task { @MainActor in
            guard hasRoutineRequest,
                  let watchRoutine = try? self.buildTodayRoutine(),
                  let data = try? JSONEncoder().encode(watchRoutine)
            else {
                replyBox.value([:])
                return
            }
            replyBox.value([WatchMessageKey.routineData: data])
        }
    }

    // Handle application context updates
    nonisolated public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let setCompletionData = applicationContext[WatchMessageKey.setCompletion] as? Data
        Task { @MainActor in
            if let setCompletionData {
                self.handleSetCompletion(from: setCompletionData)
            }
        }
    }
}
#endif
