//
//  AppGlueTests.swift
//  SetDeckTests
//
//  App-target glue only: the real suite lives in Packages/SetDeck/Tests (host-run via
//  `swift test`). Here we cover what only exists in the app target — the Siri day enum
//  and the App Shortcuts surface.
//
//  Deliberately no SwiftData here: the hosted app already owns a CloudKit-backed
//  container for the models, and opening a second container for the same classes
//  in-process crashes SwiftData.
//

import AppIntents
import Foundation
import Testing
@testable import SetDeck

@Suite("App glue")
@MainActor
struct AppGlueTests {

    @Test("WorkoutDay maps day indexes round-trip")
    func workoutDayRoundTrip() {
        for index in 0...6 {
            #expect(WorkoutDay.from(dayIndex: index).dayIndex == index)
        }
        // Out-of-range defaults to Sunday.
        #expect(WorkoutDay.from(dayIndex: 99) == .sunday)
    }

    @Test("Every intent is surfaced as an App Shortcut")
    func shortcutsCoverIntents() {
        #expect(SetDeckShortcuts.appShortcuts.count == 6)
    }

    @Test("WorkoutDayName clamps out-of-range days")
    func workoutDayNameClamps() {
        #expect(WorkoutDayName.name(forDay: 0) == "Sunday")
        #expect(WorkoutDayName.name(forDay: 6) == "Saturday")
        #expect(WorkoutDayName.name(forDay: -1) == "Unscheduled")
        #expect(WorkoutDayName.name(forDay: 7) == "Unscheduled")
    }
}
