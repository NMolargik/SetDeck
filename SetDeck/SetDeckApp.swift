//
//  SetDeckApp.swift
//  SetDeck
//
//  Created by Nicholas Molargik on 4/10/24.
//

import SwiftUI
import SwiftData

@main
struct SetDeckApp: App {
    //    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        
    @Environment(\.scenePhase) var scenePhase

    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false
    @AppStorage(AppStorageKeys.useMetricUnits, store: UserDefaults(suiteName: "group.nickmolargik.ReadySet")) private var useMetricUnits: Bool = false
    
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
        
        // watchOS
//        ComplicationSync.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                resetApplication: self.resetApplication
            )
            .modelContainer(sharedModelContainer)
            .environment(exerciseManager)
            .preferredColorScheme(.dark)
                
        }
    }
    
    private func resetApplication() {
        useMetricUnits = false
        useDayMonthYearDates = false
    }
}
