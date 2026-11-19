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
import SetDeckCore

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
    private static let cachedRoutineKey = "cachedTodayRoutine"

    private override init() {
        super.init()
        // Standalone use: the last routine the phone sent survives relaunches.
        if let data = UserDefaults.standard.data(forKey: Self.cachedRoutineKey),
           let routine = try? JSONDecoder().decode(WatchRoutine.self, from: data) {
            todayRoutine = routine
        }
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
        #if DEBUG
        if WatchDemo.isOn { todayRoutine = WatchDemo.routine; return }
        #endif
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

        // WCSession invokes these handlers on a background queue. Under MainActor default
        // isolation an un-annotated closure is inferred @MainActor and traps at runtime
        // (libdispatch main-queue assertion), so they are explicitly @Sendable and only
        // hop to the main actor with Sendable values.
        session.sendMessage(message, replyHandler: { @Sendable reply in
            let routineData = reply[WatchMessageKey.routineData] as? Data
            Task { @MainActor [weak self] in
                if let routineData {
                    self?.decodeAndSetRoutine(from: routineData)
                }
            }
        }, errorHandler: { @Sendable error in
            let description = error.localizedDescription
            Task { @MainActor [weak self] in
                logger.error("Failed to request routine: \(description)")
                // Try application context on error
                if self?.todayRoutine == nil,
                   let context = self?.session?.receivedApplicationContext,
                   let routineData = context[WatchMessageKey.routineData] as? Data {
                    self?.decodeAndSetRoutine(from: routineData)
                }
            }
        })

        logger.debug("Requested today's routine from iPhone")
    }

    // MARK: - Send Set Completions to iPhone
    /// Queued with `transferUserInfo`: delivered in order, survives the phone being out of
    /// reach and app relaunches. (The old applicationContext path kept only the *latest*
    /// payload, silently dropping earlier sets.) The phone merge is idempotent, so
    /// re-queueing is always safe.
    func sendCompletions(_ completions: [SetCompletionMessage]) {
        guard let session, !completions.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(completions)
            session.transferUserInfo([WatchMessageKey.completionBatch: data])
            // Also deliver immediately while the phone is reachable (live merge, no waiting on
            // the transfer queue). Same payload, same completion ids: the phone merge is idempotent.
            if session.isReachable {
                session.sendMessage([WatchMessageKey.completionBatch: data], replyHandler: nil, errorHandler: nil)
            }
            logger.debug("Queued \(completions.count) set completion(s) for the iPhone")
        } catch {
            logger.error("Failed to encode set completions: \(error.localizedDescription)")
        }
    }

    /// Live-only (a stale rest countdown is worse than none), so no queued transfer.
    func sendRest(_ snapshot: WatchRestSnapshot) {
        guard let session, session.isReachable, let data = try? JSONEncoder().encode(snapshot) else { return }
        session.sendMessage([WatchMessageKey.restTimer: data], replyHandler: nil, errorHandler: nil)
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
            UserDefaults.standard.set(data, forKey: Self.cachedRoutineKey)

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

                // Re-queue any logs the phone hasn't acknowledged (idempotent there).
                WatchWorkoutSession.shared.flushPending()

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

            // Hand over logs recorded while the phone was away (idempotent on the phone).
            if isReachable {
                WatchWorkoutSession.shared.flushPending()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        guard error == nil,
              let data = userInfoTransfer.userInfo[WatchMessageKey.completionBatch] as? Data,
              let delivered = try? JSONDecoder().decode([SetCompletionMessage].self, from: data)
        else { return }
        Task { @MainActor in
            WatchWorkoutSession.shared.markDelivered(delivered)
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
