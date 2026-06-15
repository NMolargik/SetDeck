//
//  SetDeckApp.swift
//  SetDeck
//
//  Created by Nicholas Molargik on 4/10/24.
//

import SwiftUI
import SwiftData
import TipKit
import WatchConnectivity

@main
struct SetDeckApp: App {
    /// Composition root: the model container and every manager are built here
    /// once and injected into the environment, so views never construct their
    /// own dependencies.
    private let sharedModelContainer: ModelContainer
    @State private var exerciseManager: ExerciseManager
    @State private var achievementManager: AchievementManager
    @State private var healthManager: HealthManager
    @State private var cloudSyncManager: CloudSyncManager
    @State private var phoneConnectivityManager: PhoneConnectivityManager
    @State private var toastManager: ToastManager

    init() {
        let cloudKitContainerID = "iCloud.com.molargiksoftware.SetDeck"

        let container: ModelContainer
        do {
            let config = ModelConfiguration(cloudKitDatabase: .private(cloudKitContainerID))
            container = try ModelContainer(
                for:
                    SetDeckExercise.self,
                    SetDeckRoutine.self,
                    SetDeckSet.self,
                    SetDeckSetHistory.self,
                configurations: config
            )
        } catch {
            fatalError("[SetDeck] Failed to initialize ModelContainer: \(error)")
        }
        sharedModelContainer = container

        // Build the manager graph against the container's main context.
        let exercise = ExerciseManager(context: container.mainContext)
        let cloud = CloudSyncManager()
        cloud.configure(with: container.mainContext)
        let phone = PhoneConnectivityManager()
        phone.exerciseManager = exercise

        // UI-test affordance (DEBUG only): skip onboarding/sync and seed
        // deterministic sample data so the main interface is populated
        // immediately. Gated to DEBUG so it can never run in a shipping build.
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            UserDefaults.standard.set(true, forKey: AppStorageKeys.isOnboardingComplete)
            UserDefaults.standard.set(true, forKey: AppStorageKeys.hasCompletedInitialSync)
            exercise.generateSampleDataForLast30Days()
        }
        #endif

        _exerciseManager = State(initialValue: exercise)
        _achievementManager = State(initialValue: AchievementManager(exerciseManager: exercise))
        _healthManager = State(initialValue: HealthManager())
        _cloudSyncManager = State(initialValue: cloud)
        _phoneConnectivityManager = State(initialValue: phone)
        _toastManager = State(initialValue: ToastManager())

        // Configure TipKit
        try? Tips.configure([
            .displayFrequency(.immediate)
        ])
    }

    @State private var pendingDeepLink: DeepLink?

    var body: some Scene {
        WindowGroup {
            ContentView(pendingDeepLink: $pendingDeepLink)
                .colorScheme(.dark)
                .toastContainer()
                .modelContainer(sharedModelContainer)
                .environment(exerciseManager)
                .environment(achievementManager)
                .environment(healthManager)
                .environment(cloudSyncManager)
                .environment(phoneConnectivityManager)
                .environment(toastManager)
                .onOpenURL { url in
                    if let link = DeepLink(url: url) {
                        pendingDeepLink = link
                    }
                }
                .task {
                    phoneConnectivityManager.activate()
                    await SpotlightIndexer.indexExercises(in: sharedModelContainer)
                }
        }
        .commands {
            SetDeckCommands(pendingDeepLink: $pendingDeepLink)
        }
    }
}

/// Menu-bar / hardware-keyboard commands (surfaced on iPadOS and Mac).
/// Navigation is driven through the same deep-link binding the app already
/// uses for widgets and App Intents.
struct SetDeckCommands: Commands {
    @Binding var pendingDeepLink: DeepLink?

    var body: some Commands {
        CommandMenu("Workout") {
            Button("Today's Routine") { pendingDeepLink = .routine }
                .keyboardShortcut("1", modifiers: .command)
            Button("Stats") { pendingDeepLink = .stats }
                .keyboardShortcut("2", modifiers: .command)
            Divider()
            Button("Settings") { pendingDeepLink = .settings }
                .keyboardShortcut(",", modifiers: .command)
        }
    }
}
