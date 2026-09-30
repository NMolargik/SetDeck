//
//  SetDeckCommands.swift
//  SetDeck
//
//  Menu-bar / hardware-keyboard commands (surfaced on iPadOS and Mac). Navigation is
//  driven through the same deep-link staging the app already uses for widgets and
//  App Intents.
//

import AppIntents
import SwiftUI
import SetDeckComposition
import SetDeckCore
import SetDeckServices

struct SetDeckCommands: Commands {
    let session: SessionController

    /// Read for live state (e.g. Start vs. Stop Workout) and to drive the HealthKit
    /// actions, mirroring the in-app flow including Siri donation.
    private var healthManager: HealthManager { session.healthManager }

    var body: some Commands {
        CommandMenu("Workout") {
            // Navigation — drives the same deep-link staging widgets/App Intents use.
            Button("Today's Routine") { session.pendingDeepLink = .routine }
                .keyboardShortcut("1", modifiers: .command)
            Button("Stats") { session.pendingDeepLink = .stats }
                .keyboardShortcut("2", modifiers: .command)
            Button("Health") { session.pendingDeepLink = .health }
                .keyboardShortcut("3", modifiers: .command)

            Divider()

            Button("Edit Routine…") { session.pendingDeepLink = .editRoutine }
                .keyboardShortcut("e", modifiers: .command)

            // Start/Stop the strength workout, matching HealthView's behavior.
            if healthManager.isStrengthTrainingActive {
                Button("Stop Workout") {
                    Task {
                        await healthManager.stopStrengthTrainingWorkoutIfSupported()
                        _ = try? await IntentDonationManager.shared.donate(intent: StopWorkoutIntent())
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
            } else {
                Button("Start Workout") {
                    Task {
                        await healthManager.startStrengthTrainingWorkoutIfSupported()
                        _ = try? await IntentDonationManager.shared.donate(intent: StartWorkoutIntent())
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            Menu("Log Water") {
                Button("250 ml") {
                    Task { await healthManager.addWaterIntakeIfSupported(amountML: 250, date: Date()) }
                }
                Button("500 ml") {
                    Task { await healthManager.addWaterIntakeIfSupported(amountML: 500, date: Date()) }
                }
            }

            Divider()

            Button("Settings") { session.pendingDeepLink = .settings }
                .keyboardShortcut(",", modifiers: .command)
        }
    }
}
