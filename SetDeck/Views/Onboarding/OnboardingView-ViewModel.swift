//
//  OnboardingView-ViewModel.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI

extension OnboardingView {
    @Observable
    class ViewModel {
        var currentStep: OnboardingStep = .privacy
        var isRequestingPermission: Bool = false
        
        func canContinue(exerciseManager: ExerciseManager?) -> Bool {
            switch currentStep {
            case .privacy, .health, .complete:
                return !isRequestingPermission
            case .builder:
                return hasAtLeastOneExercise(exerciseManager: exerciseManager)
            }
        }

        private func hasAtLeastOneExercise(exerciseManager: ExerciseManager?) -> Bool {
            // Safely unwrap the optional manager; if unavailable, criteria isn't met
            guard let manager = exerciseManager else { return false }

            // Read changeStamp to establish SwiftUI dependency - triggers re-evaluation when data changes
            _ = manager.changeStamp

            for day in 0..<7 {
                if !manager.exercises(forDay: day).isEmpty {
                    return true
                }
            }
            return false
        }
        
        @MainActor
        func handleContinueTapped(
            healthManager: HealthManager
        ) async {
            switch currentStep {
            case .privacy:
                currentStep = .health
            case .health:
                let hasBeenRequested = healthManager.isAuthorized || healthManager.lastError != nil
                if !hasBeenRequested {
                    // Request permission - user must tap Continue again after dialog
                    isRequestingPermission = true
                    await healthManager.requestAuthorization()
                    isRequestingPermission = false
                    // Stay on page - user will see updated UI and tap Continue again
                } else {
                    // Already requested (authorized or denied), move forward
                    currentStep = .complete
                }
            case .builder, .complete:
                break
            }
        }
    }
}
