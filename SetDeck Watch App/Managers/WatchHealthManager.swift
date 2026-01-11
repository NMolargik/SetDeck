//
//  WatchHealthManager.swift
//  SetDeck Watch App
//
//  Created by Nick Molargik on 1/9/26.
//
//  Simplified HealthKit manager for Watch, focused on workout control.
//

import Foundation
import HealthKit
import os.log

private let logger = Logger(subsystem: "com.molargiksoftware.SetDeck.Watch", category: "WatchHealthManager")

// MARK: - Watch Health Errors
enum WatchHealthError: Error {
    case workoutAlreadyRunning
    case noActiveWorkout
    case notAuthorized
}

@MainActor
@Observable
class WatchHealthManager: NSObject {
    // MARK: - Public State
    var workoutState: HKWorkoutSessionState = .notStarted
    var workoutStartDate: Date?
    var elapsedTime: TimeInterval = 0
    var isPaused: Bool = false
    var isAuthorized: Bool = false

    var isWorkoutActive: Bool {
        workoutState == .running || workoutState == .paused
    }

    // MARK: - Private State
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var accumulatedPauseTime: TimeInterval = 0
    private var lastPauseDate: Date?
    private var elapsedTimer: Timer?

    // MARK: - Init
    override init() {
        super.init()
        logger.debug("WatchHealthManager initialized")
    }

    // MARK: - Authorization
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.warning("HealthKit not available on this device")
            return
        }

        let workoutType = HKObjectType.workoutType()

        let typesToShare: Set<HKSampleType> = [workoutType]
        var typesToRead: Set<HKObjectType> = [workoutType]

        // Safely add optional types
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            typesToRead.insert(activeEnergy)
        }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            typesToRead.insert(heartRate)
        }

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            isAuthorized = true
            logger.info("HealthKit authorization granted")
        } catch {
            logger.error("HealthKit authorization failed: \(error.localizedDescription)")
            isAuthorized = false
        }
    }

    // MARK: - Workout Control
    func startWorkout() async throws {
        guard workoutSession == nil else {
            logger.warning("Workout already in progress")
            throw WatchHealthError.workoutAlreadyRunning
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()

            workoutSession?.delegate = self
            workoutBuilder?.delegate = self

            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            let startDate = Date()
            workoutSession?.startActivity(with: startDate)
            try await workoutBuilder?.beginCollection(at: startDate)

            workoutStartDate = startDate
            workoutState = .running
            accumulatedPauseTime = 0
            lastPauseDate = nil

            startElapsedTimer()

            logger.info("Workout started at \(startDate)")
        } catch {
            logger.error("Failed to start workout: \(error.localizedDescription)")
            throw error
        }
    }

    func pauseWorkout() {
        guard let session = workoutSession, workoutState == .running else {
            logger.warning("Cannot pause: no active workout or already paused")
            return
        }

        session.pause()
        lastPauseDate = Date()
        isPaused = true
        stopElapsedTimer()

        logger.info("Workout paused")
    }

    func resumeWorkout() {
        guard let session = workoutSession, workoutState == .paused else {
            logger.warning("Cannot resume: no paused workout")
            return
        }

        if let pauseDate = lastPauseDate {
            accumulatedPauseTime += Date().timeIntervalSince(pauseDate)
        }
        lastPauseDate = nil

        session.resume()
        isPaused = false
        startElapsedTimer()

        logger.info("Workout resumed")
    }

    func endWorkout() async {
        guard let session = workoutSession, let builder = workoutBuilder else {
            logger.warning("Cannot end: no active workout")
            return
        }

        stopElapsedTimer()

        let endDate = Date()
        session.end()

        do {
            try await builder.endCollection(at: endDate)
            try await builder.finishWorkout()
            logger.info("Workout saved to HealthKit")
        } catch {
            logger.error("Failed to save workout: \(error.localizedDescription)")
        }

        // Reset state
        workoutSession = nil
        workoutBuilder = nil
        workoutStartDate = nil
        workoutState = .notStarted
        elapsedTime = 0
        accumulatedPauseTime = 0
        lastPauseDate = nil
        isPaused = false

        logger.info("Workout ended")
    }

    // MARK: - Elapsed Time
    private func startElapsedTimer() {
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.updateElapsedTime()
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    private func updateElapsedTime() {
        guard let startDate = workoutStartDate, workoutState == .running else { return }
        elapsedTime = Date().timeIntervalSince(startDate) - accumulatedPauseTime
    }

    // MARK: - Formatting
    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WatchHealthManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                     didChangeTo toState: HKWorkoutSessionState,
                                     from fromState: HKWorkoutSessionState,
                                     date: Date) {
        Task { @MainActor in
            self.workoutState = toState
            logger.debug("Workout state changed: \(fromState.rawValue) -> \(toState.rawValue)")
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            logger.error("Workout session failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WatchHealthManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events if needed
    }

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                     didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // Handle collected data if needed (heart rate, calories, etc.)
    }
}
