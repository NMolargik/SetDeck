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
    @Environment(\.scenePhase) var scenePhase

    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false

    private let sharedModelContainer: ModelContainer
    private let exerciseManager: ExerciseManager

    init() {
        let cloudKitContainerID = "iCloud.com.molargiksoftware.SetDeck"

        do {
            let config = ModelConfiguration(
                cloudKitDatabase: .private(cloudKitContainerID)
            )

            sharedModelContainer = try ModelContainer(
                for:
                    Exercise.self,
                    SetDeckExercise.self,
                    SetDeckRoutine.self,
                    SetDeckSet.self,
                    SetDeckSetHistory.self,
                configurations: config
            )
        } catch {
            fatalError("[SetDeck] Failed to initialize ModelContainer: \(error)")
        }

        exerciseManager = ExerciseManager(context: sharedModelContainer.mainContext)

        try? Tips.configure([.displayFrequency(.immediate)])

        // Setup Watch connectivity
        setupWatchConnectivity()
    }

    private func setupWatchConnectivity() {
        let connectivityManager = PhoneConnectivityManager.shared
        connectivityManager.exerciseManager = exerciseManager
        connectivityManager.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                resetApplication: self.resetApplication
            )
            .modelContainer(sharedModelContainer)
            .environment(exerciseManager)
            .preferredColorScheme(.dark)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    // Send updated routine to Watch when app becomes active
                    PhoneConnectivityManager.shared.sendTodayRoutineToWatch()
                }
            }
        }
    }

    private func resetApplication() {
        useMetricUnits = false
        useDayMonthYearDates = false
    }
}
