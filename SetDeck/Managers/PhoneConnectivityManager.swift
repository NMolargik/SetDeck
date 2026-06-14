//
//  PhoneConnectivityManager.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/9/26.
//
//  Handles communication between iPhone and Watch via WatchConnectivity.
//

import Foundation
import WatchConnectivity
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.molargiksoftware.SetDeck", category: "PhoneConnectivity")

@MainActor
@Observable
class PhoneConnectivityManager: NSObject {
    // MARK: - Public State
    var isReachable: Bool = false
    var isPaired: Bool = false
    var isWatchAppInstalled: Bool = false

    // MARK: - Dependencies
    var exerciseManager: ExerciseManager?

    // MARK: - Private
    private var session: WCSession?

    // MARK: - Init
    override init() {
        super.init()
    }

    // MARK: - Activation
    func activate() {
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
    func sendTodayRoutineToWatch() {
        guard let session = session else {
            logger.warning("Cannot send routine: WCSession not initialized")
            return
        }

        guard session.isPaired else {
            logger.debug("Cannot send routine: Watch not paired")
            return
        }

        guard session.isWatchAppInstalled else {
            logger.debug("Cannot send routine: Watch app not installed")
            return
        }

        guard let exerciseManager = exerciseManager else {
            logger.warning("Cannot send routine: ExerciseManager not set")
            return
        }

        let todayIndex = getTodayDayIndex()
        let routine = exerciseManager.routine(for: todayIndex)
        let exercises = exerciseManager.exercises(for: routine)

        logger.info("Preparing to send routine for day \(todayIndex) with \(exercises.count) exercises")

        // Log each exercise for debugging
        for (index, exercise) in exercises.enumerated() {
            let sets = exerciseManager.sets(for: exercise)
            logger.debug("  Exercise \(index + 1): \(exercise.name) with \(sets.count) sets")
        }

        let watchRoutine = convertToWatchRoutine(routine: routine, exercises: exercises, exerciseManager: exerciseManager)

        do {
            let data = try JSONEncoder().encode(watchRoutine)
            logger.debug("Encoded routine to \(data.count) bytes")

            // Always update application context so Watch has cached data
            try session.updateApplicationContext([WatchMessageKey.routineData: data])
            logger.info("Updated application context with routine (\(watchRoutine.exercises.count) exercises)")

            // Also send immediately if reachable for faster sync
            if session.isReachable {
                let message: [String: Any] = [WatchMessageKey.routineData: data]
                session.sendMessage(message, replyHandler: nil) { error in
                    logger.error("Failed to send routine via message: \(error.localizedDescription)")
                }
                logger.debug("Sent routine to Watch via direct message")
            } else {
                logger.debug("Watch not reachable, routine cached in application context")
            }
        } catch {
            logger.error("Failed to encode/send routine: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Set Completion from Watch
    private func handleSetCompletion(from data: Data) {
        guard let exerciseManager = exerciseManager else {
            logger.warning("Cannot handle set completion: ExerciseManager not set")
            return
        }

        do {
            let completion = try JSONDecoder().decode(SetCompletionMessage.self, from: data)

            // Find the set and record history. Bind setId to a local Sendable
            // UUID so the #Predicate macro doesn't capture a key path through
            // the main-actor-isolated SetCompletionMessage type.
            let setId = completion.setId
            let setsDescriptor = FetchDescriptor<SetDeckSet>(
                predicate: #Predicate { $0.uuid == setId }
            )

            if let sets = try? exerciseManager.context.fetch(setsDescriptor),
               let set = sets.first {
                _ = exerciseManager.recordHistory(
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
                logger.info("Recorded set completion from Watch: \(set.exercise?.name ?? "Unknown")")
            } else {
                logger.warning("Could not find set with ID: \(completion.setId)")
            }
        } catch {
            logger.error("Failed to decode set completion: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers
    private func getTodayDayIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday - 1 + 7) % 7
    }

    private func convertToWatchRoutine(routine: SetDeckRoutine, exercises: [SetDeckExercise], exerciseManager: ExerciseManager) -> WatchRoutine {
        let watchExercises = exercises.map { exercise -> WatchExercise in
            let sets = exerciseManager.sets(for: exercise)
            let watchSets = sets.map { set -> WatchSet in
                WatchSet(
                    id: set.uuid,
                    setType: WatchSetType(from: set.setType),
                    targetReps: set.targetReps,
                    weight: set.weight,
                    weightUnit: "lb", // TODO: Get from user preferences
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

        return WatchRoutine(
            id: routine.uuid,
            day: routine.day,
            exercises: watchExercises
        )
    }
}

// MARK: - WCSessionDelegate
extension PhoneConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
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

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            logger.debug("WatchConnectivity session became inactive")
        }
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            logger.debug("WatchConnectivity session deactivated")
            // Reactivate for switching watches
            self.activate()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable
        Task { @MainActor in
            self.isReachable = isReachable
            logger.debug("Watch reachability changed: \(isReachable)")
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        let isPaired = session.isPaired
        let isWatchAppInstalled = session.isWatchAppInstalled
        Task { @MainActor in
            self.isPaired = isPaired
            self.isWatchAppInstalled = isWatchAppInstalled
            logger.debug("Watch state changed - paired: \(isPaired), installed: \(isWatchAppInstalled)")
        }
    }

    // Handle messages from Watch
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
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
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        let hasRoutineRequest = message[WatchMessageKey.routineRequest] != nil
        // WCSession reply handlers are invoked once; box to transfer safely.
        let replyBox = UncheckedSendableBox(value: replyHandler)
        Task { @MainActor in
            // Handle routine request with reply
            if hasRoutineRequest {
                guard let exerciseManager = self.exerciseManager else {
                    replyBox.value([:])
                    return
                }

                let todayIndex = self.getTodayDayIndex()
                let routine = exerciseManager.routine(for: todayIndex)
                let exercises = exerciseManager.exercises(for: routine)
                let watchRoutine = self.convertToWatchRoutine(routine: routine, exercises: exercises, exerciseManager: exerciseManager)

                do {
                    let data = try JSONEncoder().encode(watchRoutine)
                    replyBox.value([WatchMessageKey.routineData: data])
                } catch {
                    logger.error("Failed to encode routine for reply: \(error.localizedDescription)")
                    replyBox.value([:])
                }
            } else {
                replyBox.value([:])
            }
        }
    }

    // Handle application context updates
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let setCompletionData = applicationContext[WatchMessageKey.setCompletion] as? Data
        Task { @MainActor in
            if let setCompletionData {
                self.handleSetCompletion(from: setCompletionData)
            }
        }
    }
}

// MARK: - Watch Message Keys (shared)
nonisolated enum WatchMessageKey {
    static let routineRequest = "routineRequest"
    static let routineData = "routineData"
    static let setCompletion = "setCompletion"
    static let workoutStarted = "workoutStarted"
    static let workoutEnded = "workoutEnded"
}

// MARK: - Watch Models (shared for encoding)
struct WatchRoutine: Codable, Identifiable {
    let id: UUID
    let day: Int
    let dayName: String
    let exercises: [WatchExercise]

    static let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    init(id: UUID = UUID(), day: Int, exercises: [WatchExercise]) {
        self.id = id
        self.day = day
        self.dayName = Self.dayNames[day % 7]
        self.exercises = exercises
    }
}

struct WatchExercise: Codable, Identifiable {
    let id: UUID
    let name: String
    let isWarmup: Bool
    let note: String?
    let orderIndex: Int
    let sets: [WatchSet]
}

struct WatchSet: Codable, Identifiable {
    let id: UUID
    let setType: WatchSetType
    let targetReps: Int?
    let weight: Double?
    let weightUnit: String
    let targetDuration: TimeInterval?
    let rpe: Int?
    let orderIndex: Int
}

enum WatchSetType: String, Codable {
    case reps, amap, duration, freeform

    init(from setType: SetType) {
        switch setType {
        case .reps: self = .reps
        case .amap: self = .amap
        case .duration: self = .duration
        case .freeform: self = .freeform
        }
    }
}

struct SetCompletionMessage: Codable {
    let setId: UUID
    let exerciseId: UUID
    let completedDate: Date
    let actualReps: Int?
    let actualWeight: Double?
    let actualRpe: Int?
}
