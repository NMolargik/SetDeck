//
//  LogNextSetIntent.swift
//  SetDeck Watch App
//
//  Lets the Action Button (Settings > Action Button > Shortcut > "Log Next Set"), Siri
//  and Shortcuts log the next set at its targets and start the rest timer — without
//  opening the app UI.
//

import AppIntents
import SetDeckCore

struct LogNextSetIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Next Set"
    static let description = IntentDescription("Logs your next set at its target weight and reps and starts the rest timer.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let session = WatchWorkoutSession.shared
        guard let logged = session.logNextSet() else {
            return .result(dialog: "No set to log. Start a workout in SetDeck first.")
        }
        return .result(dialog: "Logged \(logged.exercise.name), set \(logged.setNumber).")
    }
}

struct SetDeckWatchShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogNextSetIntent(),
            phrases: ["Log my next set in \(.applicationName)"],
            shortTitle: "Log Next Set",
            systemImageName: "checkmark.circle"
        )
    }
}
