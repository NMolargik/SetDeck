//
//  WatchConnectivityManager.swift
//  SetDeck Watch App
//
//  Created by Nick Molargik on 1/9/26.
//
//  Handles communication between Watch and iPhone via WatchConnectivity.
//

import Foundation
import WatchConnectivity
import WidgetKit
import os.log

private let logger = Logger(subsystem: "com.molargiksoftware.SetDeck.Watch", category: "WatchConnectivity")

@MainActor
@Observable
class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()

    // MARK: - Public State
    var todayRoutine: WatchRoutine?
    var isReachable: Bool = false
    var isConnected: Bool = false
    var lastSyncDate: Date?

    // MARK: - Private
    private var session: WCSession?

    // MARK: - Init
    private override init() {
        super.init()
    }

    // MARK: - Activation
    func activate() {
        guard WCSession.isSupported() else {
            logger.warning("WatchConnectivity not supported")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()

        logger.info("WatchConnectivity session activating...")
    }

    // MARK: - Request Routine from iPhone
    func requestTodayRoutine() {
        // First, try to load from cached application context
        if todayRoutine == nil, let context = session?.receivedApplicationContext,
           let routineData = context[WatchMessageKey.routineData] as? Data {
            decodeAndSetRoutine(from: routineData)
            logger.debug("Loaded routine from cached application context")
        }

        // Then try to get fresh data from iPhone if reachable
        guard let session = session, session.isReachable else {
            logger.warning("Cannot request routine: iPhone not reachable")
            return
        }

        let message: [String: Any] = [WatchMessageKey.routineRequest: true]

        session.sendMessage(message, replyHandler: { [weak self] reply in
            Task { @MainActor in
                if let routineData = reply[WatchMessageKey.routineData] as? Data {
                    self?.decodeAndSetRoutine(from: routineData)
                }
            }
        }, errorHandler: { [weak self] error in
            logger.error("Failed to request routine: \(error.localizedDescription)")
            // Try application context on error
            Task { @MainActor in
                if self?.todayRoutine == nil,
                   let context = self?.session?.receivedApplicationContext,
                   let routineData = context[WatchMessageKey.routineData] as? Data {
                    self?.decodeAndSetRoutine(from: routineData)
                }
            }
        })

        logger.debug("Requested today's routine from iPhone")
    }

    // MARK: - Send Set Completion to iPhone
    func sendSetCompletion(_ completion: SetCompletionMessage) {
        guard let session = session else {
            logger.warning("Cannot send completion: no session")
            return
        }

        do {
            let data = try JSONEncoder().encode(completion)

            if session.isReachable {
                // Send immediately if reachable
                let message: [String: Any] = [WatchMessageKey.setCompletion: data]
                session.sendMessage(message, replyHandler: nil) { error in
                    logger.error("Failed to send set completion: \(error.localizedDescription)")
                }
                logger.debug("Sent set completion via message")
            } else {
                // Queue for later delivery
                try session.updateApplicationContext([WatchMessageKey.setCompletion: data])
                logger.debug("Queued set completion via application context")
            }
        } catch {
            logger.error("Failed to encode set completion: \(error.localizedDescription)")
        }
    }

    // MARK: - Notify Workout State
    func notifyWorkoutStarted() {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [WatchMessageKey.workoutStarted: Date()]
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        logger.debug("Notified iPhone of workout start")
    }

    func notifyWorkoutEnded() {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [WatchMessageKey.workoutEnded: Date()]
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        logger.debug("Notified iPhone of workout end")
    }

    // MARK: - Private Helpers
    private func decodeAndSetRoutine(from data: Data) {
        do {
            let routine = try JSONDecoder().decode(WatchRoutine.self, from: data)
            self.todayRoutine = routine
            self.lastSyncDate = Date()

            // Save to shared storage for complications
            saveRoutineForComplications(data)

            logger.info("Received routine: \(routine.dayName) with \(routine.exerciseCount) exercises")

            // Log exercise details for debugging
            for (index, exercise) in routine.exercises.enumerated() {
                logger.debug("  Exercise \(index + 1): \(exercise.name) with \(exercise.sets.count) sets")
            }
        } catch let decodingError as DecodingError {
            // Provide detailed decoding error information
            switch decodingError {
            case .keyNotFound(let key, let context):
                logger.error("Decode error: Key '\(key.stringValue)' not found - \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                logger.error("Decode error: Type mismatch for \(type) - \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                logger.error("Decode error: Value not found for \(type) - \(context.debugDescription)")
            case .dataCorrupted(let context):
                logger.error("Decode error: Data corrupted - \(context.debugDescription)")
            @unknown default:
                logger.error("Decode error: Unknown decoding error - \(decodingError.localizedDescription)")
            }
        } catch {
            logger.error("Failed to decode routine: \(error.localizedDescription)")
        }
    }

    private func saveRoutineForComplications(_ data: Data) {
        // Save to App Group shared container for widget access
        if let sharedDefaults = UserDefaults(suiteName: "group.nickmolargik.ReadySet") {
            sharedDefaults.set(data, forKey: "todayRoutine")
            sharedDefaults.synchronize()

            // Reload complications
            WidgetCenter.shared.reloadTimelines(ofKind: "WorkoutComplication")
            logger.debug("Saved routine for complications and reloaded widgets")
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Extract Sendable values before hopping to the main actor; WCSession
        // and Error are not Sendable and must not cross the isolation boundary.
        let isReachable = session.isReachable
        let activated = activationState == .activated
        let stateRawValue = activationState.rawValue
        let errorDescription = error?.localizedDescription
        Task { @MainActor in
            if let errorDescription {
                logger.error("WatchConnectivity activation failed: \(errorDescription)")
                self.isConnected = false
            } else {
                logger.info("WatchConnectivity activated with state: \(stateRawValue)")
                self.isConnected = activated
                self.isReachable = isReachable

                // Request routine on activation
                if self.isReachable {
                    self.requestTodayRoutine()
                }
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable
        Task { @MainActor in
            self.isReachable = isReachable
            logger.debug("Reachability changed: \(isReachable)")

            // Request routine when iPhone becomes reachable
            if isReachable && self.todayRoutine == nil {
                self.requestTodayRoutine()
            }
        }
    }

    // Receive messages from iPhone
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let routineData = message[WatchMessageKey.routineData] as? Data
        Task { @MainActor in
            if let routineData {
                self.decodeAndSetRoutine(from: routineData)
            }
        }
    }

    // Receive application context updates
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let routineData = applicationContext[WatchMessageKey.routineData] as? Data
        Task { @MainActor in
            if let routineData {
                self.decodeAndSetRoutine(from: routineData)
            }
        }
    }
}
