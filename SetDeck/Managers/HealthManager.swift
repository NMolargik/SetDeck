//
//  HealthManager.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/12/25.
//

import Foundation
import HealthKit
import WidgetKit
import ActivityKit
import os.log

private let logger = Logger(subsystem: "com.molargiksoftware.SetDeck", category: "HealthManager")

@MainActor
@Observable
class HealthManager: NSObject {
    // MARK: - HealthKit
    @ObservationIgnored
    private let healthStore = HKHealthStore()
    
    convenience init(forWidget: Bool = false) {
        self.init()
        if forWidget {
            // No need to request auth here; it's shared
            Task { await refreshTodayTotals() }
        }
    }

    // MARK: - Authorization
    var isAuthorized: Bool = false

    // MARK: - Daily totals (for convenience UI)
    var todayWaterML: Double = 0
    var todayCaloriesKCal: Double = 0

    // MARK: - Time Series (last 14 days by default)
    var waterIntakeSeries: [TimeSeriesSample] = []
    var calorieIntakeSeries: [TimeSeriesSample] = []
    var calorieBurnSeries: [TimeSeriesSample] = []

    // MARK: - Workout history
    var workoutHistory: [WorkoutSummary] = []

    // MARK: - Workout session state
    @ObservationIgnored
    private var workoutSession: HKWorkoutSession?
    @ObservationIgnored
    private var workoutBuilder: HKLiveWorkoutBuilder?

    var workoutState: HKWorkoutSessionState = .notStarted
    var workoutStartDate: Date?

    // MARK: - Live Activity
    @ObservationIgnored
    private var currentActivity: Activity<StrengthTrainingActivityAttributes>?
    @ObservationIgnored
    private var accumulatedPauseTime: TimeInterval = 0
    @ObservationIgnored
    private var lastPauseDate: Date?

    // Convenience accessors used by HealthView
    var isStrengthTrainingActive: Bool {
        workoutState == .running || workoutState == .paused
    }

    var currentWorkoutStartDate: Date? {
        workoutStartDate
    }

    var isWorkoutOngoing: Bool {
        workoutState == .running || workoutState == .paused
    }

    // MARK: - Authorization
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            isAuthorized = false
            return
        }

        guard
            let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater),
            let dietaryEnergy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        else {
            isAuthorized = false
            return
        }

        let workoutType = HKObjectType.workoutType()

        let toShare: Set<HKSampleType> = [waterType, dietaryEnergy, activeEnergy, workoutType]
        let toRead: Set<HKObjectType> = [waterType, dietaryEnergy, activeEnergy, workoutType]

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.requestAuthorization(toShare: toShare, read: toRead) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: ())
                }
            }
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    // MARK: - Water (ml)
    func addWater(ml: Double, date: Date = Date()) async throws {
        guard ml >= 0, let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        let quantity = HKQuantity(unit: HKUnit.literUnit(with: .milli), doubleValue: ml)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await save(sample: sample)
    }

    func refreshWaterToday() async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        if let sum = try? await sumToday(for: type, unit: HKUnit.literUnit(with: .milli)) {
            todayWaterML = sum
        }
    }

    // MARK: - Calories (kcal)
    func addCalories(kcal: Double, date: Date = Date()) async throws {
        guard kcal >= 0, let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else { return }
        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await save(sample: sample)
    }

    func refreshCaloriesToday() async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else { return }
        if let sum = try? await sumToday(for: type, unit: .kilocalorie()) {
            todayCaloriesKCal = sum
        }
    }

    // MARK: - Active Energy (kcal burn)
    func addActiveEnergy(kcal: Double, date: Date = Date()) async throws {
        guard kcal >= 0, let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await save(sample: sample)
    }

    // Convenience used by HealthView (safe attempts)
    func addWaterIntakeIfSupported(amountML: Double, date: Date) async {
        do {
            try await addWater(ml: amountML, date: date)
            await refreshWaterToday()
            await refreshWaterSeries(days: 14)
            WidgetCenter.shared.reloadTimelines(ofKind: "WaterWidgetLiter")
            WidgetCenter.shared.reloadTimelines(ofKind: "WaterWidgetOZ")
        } catch {
            logger.error("Failed to add water intake: \(error.localizedDescription)")
        }
    }

    func addCalorieIntakeIfSupported(amount: Double, date: Date) async {
        do {
            try await addCalories(kcal: amount, date: date)
            await refreshCaloriesToday()
            await refreshCalorieIntakeSeries(days: 14)
            WidgetCenter.shared.reloadTimelines(ofKind: "EnergyWidget")
        } catch {
            logger.error("Failed to add calorie intake: \(error.localizedDescription)")
        }
    }

    func addCalorieBurnIfSupported(amount: Double, date: Date) async {
        do {
            try await addActiveEnergy(kcal: amount, date: date)
            await refreshCalorieBurnSeries(days: 14)
        } catch {
            logger.error("Failed to add calorie burn: \(error.localizedDescription)")
        }
    }

    func refreshTodayTotals() async {
        await refreshWaterToday()
        await refreshCaloriesToday()
    }

    // MARK: - Bulk refresh (used by HealthView)
    func refreshIfSupported(days: Int = 14) async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        if !isAuthorized { await requestAuthorization() }
        await refreshTodayTotals()
        await refreshSeries(days: days)
        await refreshWorkouts(limit: 20)
    }

    private func refreshSeries(days: Int = 14) async {
        // Water (mL per day)
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
            let unit = HKUnit.literUnit(with: .milli)
            let series = await dailySums(for: type, unit: unit, days: days)
            self.waterIntakeSeries = series
        }
        // Calorie intake (kcal per day)
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let unit = HKUnit.kilocalorie()
            let series = await dailySums(for: type, unit: unit, days: days)
            self.calorieIntakeSeries = series
        }
        // Calorie burn (kcal per day)
        if let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let unit = HKUnit.kilocalorie()
            let series = await dailySums(for: type, unit: unit, days: days)
            self.calorieBurnSeries = series
        }
    }

    private func refreshWaterSeries(days: Int = 14) async {
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
            let unit = HKUnit.literUnit(with: .milli)
            let series = await dailySums(for: type, unit: unit, days: days)
            self.waterIntakeSeries = series
        }
    }

    private func refreshCalorieIntakeSeries(days: Int = 14) async {
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let unit = HKUnit.kilocalorie()
            let series = await dailySums(for: type, unit: unit, days: days)
            self.calorieIntakeSeries = series
        }
    }

    private func refreshCalorieBurnSeries(days: Int = 14) async {
        if let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let unit = HKUnit.kilocalorie()
            let series = await dailySums(for: type, unit: unit, days: days)
            self.calorieBurnSeries = series
        }
    }

    private func dailySums(for type: HKQuantityType, unit: HKUnit, days: Int) async -> [TimeSeriesSample] {
        var results: [TimeSeriesSample] = []
        let cal = Calendar.current
        for offset in stride(from: days - 1, through: 0, by: -1) {
            let dayStart = cal.startOfDay(for: cal.date(byAdding: .day, value: -offset, to: Date()) ?? Date())
            let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) ?? Date()
            let amount = (try? await sum(for: type, unit: unit, start: dayStart, end: dayEnd)) ?? 0
            results.append(TimeSeriesSample(date: dayStart, amount: amount))
        }
        return results
    }

    // MARK: - Workout (Strength Training)
    func startStrengthTraining() async throws {
        guard workoutSession == nil else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

        session.delegate = self
        builder.delegate = self

        workoutSession = session
        workoutBuilder = builder

        let start = Date()
        workoutStartDate = start
        accumulatedPauseTime = 0
        lastPauseDate = nil

        session.startActivity(with: start)
        try await builder.beginCollection(at: start)

        // Start Live Activity
        startLiveActivity(startDate: start)
    }

    func pauseWorkout() {
        guard let session = workoutSession, workoutState == .running else { return }
        session.pause()
        updateLiveActivityForPause()
    }

    func resumeWorkout() {
        guard let session = workoutSession, workoutState == .paused else { return }
        session.resume()
        updateLiveActivityForResume()
    }

    func endWorkout() async {
        guard let session = workoutSession, let builder = workoutBuilder else { return }

        // End Live Activity before resetting state
        endLiveActivity()

        session.end()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            builder.endCollection(withEnd: Date()) { _, _ in
                builder.finishWorkout { _, _ in
                    Task { @MainActor in
                        self.resetWorkoutState()
                    }
                    continuation.resume()
                }
            }
        }
    }

    // Convenience wrappers used by HealthView (safe attempts)
    func startStrengthTrainingWorkoutIfSupported() async {
        do {
            try await startStrengthTraining()
        } catch {
            // ignore
        }
    }

    func stopStrengthTrainingWorkoutIfSupported() async {
        await endWorkout()
        await refreshWorkouts(limit: 20)
    }

    private func resetWorkoutState() {
        workoutSession = nil
        workoutBuilder = nil
        workoutStartDate = nil
        workoutState = .ended
        // Reset Live Activity state
        accumulatedPauseTime = 0
        lastPauseDate = nil
        currentActivity = nil
    }

    // MARK: - Live Activity Management
    private func startLiveActivity(startDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.info("Live Activities not enabled")
            return
        }

        let attributes = StrengthTrainingActivityAttributes()
        let initialState = StrengthTrainingActivityAttributes.ContentState(
            startDate: startDate,
            accumulatedPause: 0,
            lastPauseDate: nil,
            isPaused: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            logger.info("Live Activity started: \(activity.id)")
        } catch {
            logger.error("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    private func updateLiveActivityForPause() {
        guard let activity = currentActivity, let start = workoutStartDate else { return }

        lastPauseDate = Date()
        let state = StrengthTrainingActivityAttributes.ContentState(
            startDate: start,
            accumulatedPause: accumulatedPauseTime,
            lastPauseDate: lastPauseDate,
            isPaused: true
        )

        Task {
            await activity.update(.init(state: state, staleDate: nil))
            logger.info("Live Activity updated for pause")
        }
    }

    private func updateLiveActivityForResume() {
        guard let activity = currentActivity, let start = workoutStartDate else { return }

        // Add time paused to accumulated pause time
        if let pauseStart = lastPauseDate {
            accumulatedPauseTime += Date().timeIntervalSince(pauseStart)
        }
        lastPauseDate = nil

        let state = StrengthTrainingActivityAttributes.ContentState(
            startDate: start,
            accumulatedPause: accumulatedPauseTime,
            lastPauseDate: nil,
            isPaused: false
        )

        Task {
            await activity.update(.init(state: state, staleDate: nil))
            logger.info("Live Activity updated for resume")
        }
    }

    private func endLiveActivity() {
        guard let activity = currentActivity, let start = workoutStartDate else { return }

        // Calculate final elapsed time
        if let pauseStart = lastPauseDate {
            accumulatedPauseTime += Date().timeIntervalSince(pauseStart)
        }

        let finalState = StrengthTrainingActivityAttributes.ContentState(
            startDate: start,
            accumulatedPause: accumulatedPauseTime,
            lastPauseDate: nil,
            isPaused: false
        )

        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .default)
            logger.info("Live Activity ended")
        }
    }

    // MARK: - Helpers
    private func save(sample: HKSample) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(sample) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }

    private func sumToday(for type: HKQuantityType, unit: HKUnit) async throws -> Double {
        let (start, end) = todayRange()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let total = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: total)
            }
            healthStore.execute(query)
        }
    }

    private func sum(for type: HKQuantityType, unit: HKUnit, start: Date, end: Date) async throws -> Double {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let total = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: total)
            }
            self.healthStore.execute(query)
        }
    }

    private func todayRange() -> (Date, Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
        return (start, end)
    }

    // MARK: - Workout history
    private func refreshWorkouts(limit: Int = 20) async {
        let workoutType = HKObjectType.workoutType()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: limit, sortDescriptors: [sort]) { _, samples, _ in
                let workouts = (samples as? [HKWorkout]) ?? []
                let summaries: [WorkoutSummary] = workouts.map { wk in
                    let kcal: Double? = {
                        if #available(iOS 18.0, *) {
                            if let activeType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
                               let stats = wk.statistics(for: activeType),
                               let sum = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                                return sum
                            } else {
                                return nil
                            }
                        } else {
                            return wk.totalEnergyBurned?.doubleValue(for: .kilocalorie())
                        }
                    }()
                    return WorkoutSummary(id: wk.uuid, startDate: wk.startDate, endDate: wk.endDate, activityType: wk.workoutActivityType, totalEnergyBurnedKCal: kcal)
                }
                Task { @MainActor in
                    self.workoutHistory = summaries
                    continuation.resume()
                }
            }
            self.healthStore.execute(query)
        }
    }
}

// MARK: - Delegates
extension HealthManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // Update observable state on main thread
        self.workoutState = toState
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        self.resetWorkoutState()
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) { }
}

