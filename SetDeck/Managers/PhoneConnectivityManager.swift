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
    static let shared = PhoneConnectivityManager()

    // MARK: - Public State
    var isReachable: Bool = false
    var isPaired: Bool = false
    var isWatchAppInstalled: Bool = false

    // MARK: - Dependencies
    var exerciseManager: ExerciseManager?

    // MARK: - Private
    private var session: WCSession?

    // MARK: - Init
    private override init() {
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

            // Find the set and record history
            let setsDescriptor = FetchDescriptor<SetDeckSet>(
                predicate: #Predicate { $0.uuid == completion.setId }
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
        Task { @MainActor in
            if let error = error {
                logger.error("WatchConnectivity activation failed: \(error.localizedDescription)")
            } else {
                logger.info("WatchConnectivity activated with state: \(activationState.rawValue)")
                self.isPaired = session.isPaired
                self.isWatchAppInstalled = session.isWatchAppInstalled
                self.isReachable = session.isReachable

                // Send routine on activation if Watch is reachable
                if session.isReachable {
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
        Task { @MainActor in
            self.isReachable = session.isReachable
            logger.debug("Watch reachability changed: \(session.isReachable)")
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            logger.debug("Watch state changed - paired: \(session.isPaired), installed: \(session.isWatchAppInstalled)")
        }
    }

    // Handle messages from Watch
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            // Handle routine request
            if message[WatchMessageKey.routineRequest] != nil {
                self.sendTodayRoutineToWatch()
            }

            // Handle set completion
            if let data = message[WatchMessageKey.setCompletion] as? Data {
                self.handleSetCompletion(from: data)
            }

            // Handle workout notifications
            if message[WatchMessageKey.workoutStarted] != nil {
                logger.info("Watch started a workout")
            }
            if message[WatchMessageKey.workoutEnded] != nil {
                logger.info("Watch ended a workout")
            }
        }
    }

    // Handle messages with reply
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            // Handle routine request with reply
            if message[WatchMessageKey.routineRequest] != nil {
                guard let exerciseManager = self.exerciseManager else {
                    replyHandler([:])
                    return
                }

                let todayIndex = self.getTodayDayIndex()
                let routine = exerciseManager.routine(for: todayIndex)
                let exercises = exerciseManager.exercises(for: routine)
                let watchRoutine = self.convertToWatchRoutine(routine: routine, exercises: exercises, exerciseManager: exerciseManager)

                do {
                    let data = try JSONEncoder().encode(watchRoutine)
                    replyHandler([WatchMessageKey.routineData: data])
                } catch {
                    logger.error("Failed to encode routine for reply: \(error.localizedDescription)")
                    replyHandler([:])
                }
            } else {
                replyHandler([:])
            }
        }
    }

    // Handle application context updates
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            if let data = applicationContext[WatchMessageKey.setCompletion] as? Data {
                self.handleSetCompletion(from: data)
            }
        }
    }
}

// MARK: - Watch Message Keys (shared)
enum WatchMessageKey {
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
