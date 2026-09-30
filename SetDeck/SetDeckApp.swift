//
//  SetDeckApp.swift
//  SetDeck
//
//  Thin shell: builds the SessionController (composition root in SetDeckComposition),
//  registers it for App Intents, and hosts the window. All feature code lives in
//  Packages/SetDeck.
//

import AppIntents
import SwiftData
import SwiftUI
import TipKit
import SetDeckComposition
import SetDeckCore
import SetDeckServices

@main
struct SetDeckApp: App {
    private let session: SessionController

    init() {
        let session = SessionController(indexer: SpotlightIndexer())
        self.session = session

        // Expose the session to App Intents (Siri, Shortcuts, Spotlight).
        AppDependencyManager.shared.add(dependency: session)

        // Configure TipKit
        try? Tips.configure([
            .displayFrequency(.immediate)
        ])
    }

    var body: some Scene {
        WindowGroup {
            RootView(session: session)
                .modelContainer(session.container)
                .onOpenURL { url in
                    session.handle(url: url)
                }
                .task {
                    session.start()
                }
        }
        .commands {
            SetDeckCommands(session: session)
        }
    }
}
