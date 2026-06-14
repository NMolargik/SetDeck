//
//  WorkoutIntent.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/9/26.
//

import AppIntents

/// App Intent to toggle workout session
struct ToggleWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Workout"
    static let description = IntentDescription("Start or stop a strength training workout")

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager()
        await healthManager.requestAuthorization()

        if await healthManager.isWorkoutOngoing {
            await healthManager.stopStrengthTrainingWorkoutIfSupported()
        } else {
            await healthManager.startStrengthTrainingWorkoutIfSupported()
        }

        return .result()
    }
}

/// Start workout intent
struct StartWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Workout"
    static let description = IntentDescription("Start a strength training workout")

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager()
        await healthManager.requestAuthorization()

        if await !healthManager.isWorkoutOngoing {
            await healthManager.startStrengthTrainingWorkoutIfSupported()
        }

        return .result()
    }
}

/// Stop workout intent
struct StopWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Workout"
    static let description = IntentDescription("Stop the current workout")

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager()
        await healthManager.requestAuthorization()

        if await healthManager.isWorkoutOngoing {
            await healthManager.stopStrengthTrainingWorkoutIfSupported()
        }

        return .result()
    }
}
