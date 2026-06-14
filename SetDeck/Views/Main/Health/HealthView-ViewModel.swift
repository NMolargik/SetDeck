//
//  HealthView-ViewModel.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import Foundation
import AppIntents

extension HealthView {
    @Observable
    class ViewModel {
        // Dependency is provided by the view at runtime
        var healthManager: HealthManager?

        // Timer-driven time source for elapsed display
        private var timer: Timer?
        var now: Date = Date()

        // MARK: - Workout state
        var isWorkoutActive: Bool {
            healthManager?.isStrengthTrainingActive ?? false
        }

        var workoutStartDate: Date? {
            healthManager?.currentWorkoutStartDate
        }

        var workoutElapsedString: String {
            workoutStartDate?.elapsedString(to: now) ?? "00:00:00"
        }

        // MARK: - Binding & lifecycle
        func bind(_ manager: HealthManager) {
            self.healthManager = manager
        }

        func onAppear() {
            startTimer()
        }

        func onDisappear() {
            stopTimer()
        }

        private func startTimer() {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                // Scheduled timers fire on the main run loop, so this body is
                // already on the main actor; assert it to satisfy Swift 6.
                MainActor.assumeIsolated { self?.now = Date() }
            }
        }

        private func stopTimer() {
            timer?.invalidate()
            timer = nil
        }

        // MARK: - Actions (wrappers)
        func refresh() async {
            await healthManager?.refreshIfSupported()
        }

        func addWaterIntake(amountML: Double, date: Date) async {
            await healthManager?.addWaterIntakeIfSupported(amountML: amountML, date: date)
        }

        func addCalorieIntake(amount: Double, date: Date) async {
            await healthManager?.addCalorieIntakeIfSupported(amount: amount, date: date)
        }

        func addCalorieBurn(amount: Double, date: Date) async {
            await healthManager?.addCalorieBurnIfSupported(amount: amount, date: date)
        }

        func startStrengthTraining() async {
            await healthManager?.startStrengthTrainingWorkoutIfSupported()
            // Donate to Siri so it can predict/suggest starting a workout.
            try? await IntentDonationManager.shared.donate(intent: StartWorkoutIntent())
        }

        func stopStrengthTraining() async {
            await healthManager?.stopStrengthTrainingWorkoutIfSupported()
            try? await IntentDonationManager.shared.donate(intent: StopWorkoutIntent())
        }
    }
}
