//
//  WatchWorkoutSession.swift
//  SetDeck Watch App
//
//  The watch's standalone workout: start today's cached routine, log sets, run the
//  auto rest timer, finish — all without the phone. Logs are queued to the phone with
//  guaranteed delivery and merged idempotently there (see WatchCompletionMerge).
//  The pure state lives in SetDeckCore (WatchWorkoutLog / WatchRestTimer).
//

import Foundation
import Observation
import WidgetKit
import os.log
import SetDeckCore

private let logger = Logger(subsystem: "com.molargiksoftware.SetDeck.Watch", category: "WatchWorkoutSession")

@MainActor
@Observable
final class WatchWorkoutSession {
    static let shared = WatchWorkoutSession()

    private static let logKey = "watchWorkoutLog"
    private static let restDurationKey = "watchRestDuration"
    private static let appGroup = "group.nickmolargik.ReadySet"

    // MARK: - State
    private(set) var log: WatchWorkoutLog?
    private(set) var rest: WatchRestTimer?

    let health = WatchHealthManager()
    @ObservationIgnored private let connectivity = WatchConnectivityManager.shared
    @ObservationIgnored private var restTask: Task<Void, Never>?
    @ObservationIgnored private let defaults = UserDefaults.standard

    /// Rest length used after each logged set (adjustable on the rest tab).
    var restDuration: TimeInterval {
        didSet { defaults.set(restDuration, forKey: Self.restDurationKey) }
    }

    var routine: WatchRoutine? { connectivity.todayRoutine }
    var isActive: Bool { log.map { !$0.isFinished } ?? false }

    var nextSet: WatchNextSet? {
        guard let routine, let log, !log.isFinished else { return nil }
        return log.nextSet(in: routine)
    }

    var allSetsLogged: Bool {
        guard let routine, let log else { return false }
        return log.nextSet(in: routine) == nil && log.loggedSetCount > 0
    }

    func isLogged(_ setId: UUID) -> Bool { log?.isLogged(setId) ?? false }

    // MARK: - Init
    private init() {
        let stored = UserDefaults.standard.double(forKey: Self.restDurationKey)
        restDuration = stored > 0 ? stored : WatchRestTimer.defaultDuration
        if let data = defaults.data(forKey: Self.logKey),
           let restored = try? JSONDecoder().decode(WatchWorkoutLog.self, from: data),
           Date().timeIntervalSince(restored.startedAt) < 12 * 3600 {
            log = restored
        }
    }

    // MARK: - Workout lifecycle
    /// Starts today's cached routine: a fresh log plus the HealthKit workout.
    func startRoutine() async {
        guard let routine else {
            // No cached routine yet: still track the workout in HealthKit.
            await startHealthIfNeeded()
            return
        }
        guard !isActive else { return }
        flushPending()
        log = WatchWorkoutLog(routineId: routine.id, startedAt: Date())
        persist()
        publishSnapshot()
        await startHealthIfNeeded()
        connectivity.notifyWorkoutStarted()
        WatchHaptics.workoutStarted()
    }

    func finish() async {
        guard var current = log else {
            await health.endWorkout()
            return
        }
        cancelRest()
        current.finishedAt = Date()
        log = current
        persist()
        flushPending()
        await health.endWorkout()
        connectivity.notifyWorkoutEnded()
        publishSnapshot(clear: true)
        WatchHaptics.workoutEnded()
    }

    private func startHealthIfNeeded() async {
        guard !health.isWorkoutActive else { return }
        do { try await health.startWorkout() } catch { logger.error("HealthKit start failed: \(error.localizedDescription)") }
    }

    // MARK: - Logging
    /// Logs a set at the given values and starts the rest timer. Safe to call from the
    /// UI, Double Tap, or the Action Button intent (even in a freshly launched process).
    func log(set: WatchSet, exerciseId: UUID, reps: Int?, weight: Double?) {
        if log == nil || log?.isFinished == true, let routine {
            log = WatchWorkoutLog(routineId: routine.id, startedAt: Date())
            Task { await startHealthIfNeeded() }
        }
        guard var current = log else { return }
        let message = current.record(setId: set.id, exerciseId: exerciseId, reps: reps, weight: weight, rpe: set.rpe)
        log = current
        persist()
        connectivity.sendCompletions([message])
        WatchHaptics.setCompleted()

        if nextSet != nil {
            startRest(duration: restDuration)
        } else {
            cancelRest()
            publishSnapshot()
        }
    }

    /// Logs the next unlogged set at its targets (Double Tap / Action Button path).
    @discardableResult
    func logNextSet() -> WatchNextSet? {
        guard let next = nextSet else { return nil }
        log(
            set: next.set,
            exerciseId: next.exercise.id,
            reps: next.set.targetReps,
            weight: next.set.weight
        )
        return next
    }

    func markDelivered(_ messages: [SetCompletionMessage]) {
        guard var current = log else { return }
        for message in messages { current.markDelivered(message) }
        log = current
        persist()
    }

    /// Re-queues anything the phone has not acknowledged (idempotent on the phone).
    func flushPending() {
        guard let pending = log?.pending, !pending.isEmpty else { return }
        connectivity.sendCompletions(pending)
    }

    // MARK: - Rest timer
    func startRest(duration: TimeInterval) {
        let timer = WatchRestTimer(duration: duration)
        rest = timer
        scheduleRestAlert(for: timer)
        publishSnapshot()
        runRestTask()
    }

    func extendRest() {
        guard var timer = rest else { return }
        timer.extend()
        rest = timer
        scheduleRestAlert(for: timer)
        publishSnapshot()
        runRestTask()
        WatchHaptics.selectionChanged()
    }

    func skipRest() {
        cancelRest()
        publishSnapshot()
        WatchHaptics.buttonTapped()
    }

    private func cancelRest() {
        restTask?.cancel()
        restTask = nil
        rest = nil
        RestAlertScheduler.shared.cancel()
    }

    private func scheduleRestAlert(for timer: WatchRestTimer) {
        let label = nextSet?.label ?? String(localized: "Finish your workout")
        RestAlertScheduler.shared.schedule(endDate: timer.endDate, body: label)
    }

    /// Deadline-driven, never tick-counting: correct after suspension or a dimmed screen.
    private func runRestTask() {
        restTask?.cancel()
        restTask = Task { [weak self] in
            var alertRetired = false
            while !Task.isCancelled {
                guard let self, let timer = self.rest else { return }
                let left = timer.remaining()
                if left <= 0 {
                    self.restFinished()
                    return
                }
                if left <= 1, !alertRetired {
                    // We're alive at the deadline: retire the safety-net notification so
                    // the wrist taps once.
                    RestAlertScheduler.shared.cancel()
                    alertRetired = true
                }
                try? await Task.sleep(for: .seconds(left > 1 ? left - 1 : left))
            }
        }
    }

    private func restFinished() {
        rest = nil
        restTask = nil
        WatchHaptics.restTimerDone()
        publishSnapshot()
    }

    // MARK: - Publishing (complication / Smart Stack, phone Live Activity)
    private func publishSnapshot(clear: Bool = false) {
        let snapshot = clear
            ? WatchRestSnapshot.cleared
            : WatchRestSnapshot(endDate: rest?.endDate, nextSetLabel: nextSet?.label)
        if let data = try? JSONEncoder().encode(snapshot),
           let shared = UserDefaults(suiteName: Self.appGroup) {
            shared.set(data, forKey: WatchRestSnapshot.sharedDefaultsKey)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "WorkoutComplication")
        connectivity.sendRest(snapshot)
    }

    private func persist() {
        if let log, let data = try? JSONEncoder().encode(log) {
            defaults.set(data, forKey: Self.logKey)
        } else {
            defaults.removeObject(forKey: Self.logKey)
        }
    }
}
