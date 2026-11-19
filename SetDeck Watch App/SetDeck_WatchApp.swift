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
    @State private var session = WatchWorkoutSession.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(session)
                .environment(session.health)
                .environment(WatchConnectivityManager.shared)
                .onAppear {
                    #if DEBUG
                    if WatchDemo.isOn {
                        WatchConnectivityManager.shared.requestTodayRoutine()
                        let screen = WatchDemo.screen
                        if screen != "routine" { session.seedDemo(rest: screen == "rest" || screen == "restbanner") }
                        return
                    }
                    #endif
                    // Activate WatchConnectivity (synchronous, safe)
                    WatchConnectivityManager.shared.activate()
                    RestAlertScheduler.shared.configure()
                }
                .task {
                    // Delay HealthKit authorization slightly
                    #if DEBUG
                    if WatchDemo.isOn { return }
                    #endif
                    try? await Task.sleep(for: .milliseconds(500))
                    await session.health.requestAuthorization()
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
