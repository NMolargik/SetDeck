//
//  SetDeck_WatchApp.swift
//  SetDeck Watch App
//
//  Created by Nick Molargik on 1/9/26.
//

import SwiftUI

@main
struct SetDeckWatchApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var healthManager = WatchHealthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(healthManager)
                .environment(WatchConnectivityManager.shared)
                .onAppear {
                    // Activate WatchConnectivity (synchronous, safe)
                    WatchConnectivityManager.shared.activate()
                }
                .task {
                    // Delay HealthKit authorization slightly
                    try? await Task.sleep(for: .milliseconds(500))
                    await healthManager.requestAuthorization()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // Request fresh routine data when app becomes active
                        WatchConnectivityManager.shared.requestTodayRoutine()
                    }
                }
        }
    }
}
