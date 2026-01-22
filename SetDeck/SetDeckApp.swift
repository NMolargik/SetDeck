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
    private let sharedModelContainer: ModelContainer
    
    init() {
        let cloudKitContainerID = "iCloud.com.molargiksoftware.SetDeck"
        
        do {
            let config = ModelConfiguration(cloudKitDatabase: .private(cloudKitContainerID))
            
            sharedModelContainer = try ModelContainer(
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
                .modelContainer(sharedModelContainer)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "setdeck" else { return }
        
        switch url.host {
        case "routine":
            pendingDeepLink = .routine
        case "stats":
            pendingDeepLink = .stats
        case "settings":
            pendingDeepLink = .settings
        default:
            break
        }
    }
}
