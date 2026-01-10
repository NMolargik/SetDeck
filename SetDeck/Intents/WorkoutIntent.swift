//
//  WorkoutIntent.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/9/26.
//

import AppIntents

/// App Intent to toggle workout session
struct ToggleWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Workout"
    static var description = IntentDescription("Start or stop a strength training workout")

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
    static var title: LocalizedStringResource = "Start Workout"
    static var description = IntentDescription("Start a strength training workout")

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
    static var title: LocalizedStringResource = "Stop Workout"
    static var description = IntentDescription("Stop the current workout")

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager()
        await healthManager.requestAuthorization()

        if await healthManager.isWorkoutOngoing {
            await healthManager.stopStrengthTrainingWorkoutIfSupported()
        }

        return .result()
    }
}
