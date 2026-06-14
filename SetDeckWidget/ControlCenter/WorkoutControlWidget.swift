//
//  WorkoutControlWidget.swift
//  SetDeckWidget
//
//  Created by Nick Molargik on 1/9/26.
//

import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Workout Toggle Intent for Control Center
struct ToggleWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Workout"
    static let description = IntentDescription("Start or stop a strength training workout")

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager(forWidget: true)
        await healthManager.requestAuthorization()

        if await healthManager.isWorkoutOngoing {
            await healthManager.stopStrengthTrainingWorkoutIfSupported()
        } else {
            await healthManager.startStrengthTrainingWorkoutIfSupported()
        }

        return .result()
    }
}

// MARK: - Control Center Widget (iOS 18+)
@available(iOS 18.0, *)
struct WorkoutControlWidget: ControlWidget {
    static let kind: String = "WorkoutControlWidget"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: ToggleWorkoutIntent()) {
                Label {
                    Text("Workout")
                } icon: {
                    Image(systemName: "figure.strengthtraining.traditional")
                }
            }
        }
        .displayName("Workout Toggle")
        .description("Start or stop a strength training workout")
    }
}

// MARK: - Start Workout Control (iOS 18+)
@available(iOS 18.0, *)
struct StartWorkoutControl: ControlWidget {
    static let kind: String = "StartWorkoutControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: StartWorkoutIntent()) {
                Label {
                    Text("Start Workout")
                } icon: {
                    Image(systemName: "play.fill")
                }
            }
        }
        .displayName("Start Workout")
        .description("Start a strength training workout")
    }
}

// MARK: - Start Workout Intent
struct StartWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Workout"
    static let description = IntentDescription("Start a strength training workout")

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager(forWidget: true)
        await healthManager.requestAuthorization()

        if await !healthManager.isWorkoutOngoing {
            await healthManager.startStrengthTrainingWorkoutIfSupported()
        }

        return .result()
    }
}

// MARK: - Stop Workout Control (iOS 18+)
@available(iOS 18.0, *)
struct StopWorkoutControl: ControlWidget {
    static let kind: String = "StopWorkoutControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: StopWorkoutIntent()) {
                Label {
                    Text("Stop Workout")
                } icon: {
                    Image(systemName: "stop.fill")
                }
            }
        }
        .displayName("Stop Workout")
        .description("Stop the current workout")
    }
}

// MARK: - Stop Workout Intent
struct StopWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Workout"
    static let description = IntentDescription("Stop the current workout")

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager(forWidget: true)
        await healthManager.requestAuthorization()

        if await healthManager.isWorkoutOngoing {
            await healthManager.stopStrengthTrainingWorkoutIfSupported()
        }

        return .result()
    }
}
