//
//  WatchDemo.swift
//  SetDeck Watch App
//
//  DEBUG-only demo data and state for App Store screenshots. Launch with
//  `-sdWatchDemo <routine|exercise|log|rest|workout>` (needs no phone sync).
//

#if DEBUG
import Foundation
import SetDeckCore

enum WatchDemo {
    /// The requested demo screen, or nil when the flag is absent.
    static let screen: String? = UserDefaults.standard.string(forKey: "sdWatchDemo")
    static var isOn: Bool { screen != nil }

    /// A push day: Bench Press with five ramping sets, plus accessories.
    static let routine: WatchRoutine = {
        func sets(_ rows: [(Int, Double, Int)]) -> [WatchSet] {
            rows.enumerated().map { i, r in
                WatchSet(id: UUID(), setType: .reps, targetReps: r.0, weight: r.1, weightUnit: "lb", targetDuration: nil, rpe: r.2, orderIndex: i)
            }
        }
        func ex(_ i: Int, _ name: String, _ rows: [(Int, Double, Int)]) -> WatchExercise {
            WatchExercise(id: UUID(), name: name, isWarmup: false, note: nil, orderIndex: i, sets: sets(rows))
        }
        let weekday = Calendar.current.component(.weekday, from: Date()) - 1
        return WatchRoutine(day: weekday, exercises: [
            ex(0, "Bench Press", [(10, 135, 6), (8, 155, 7), (6, 175, 8), (5, 185, 9), (3, 195, 9)]),
            ex(1, "Incline Dumbbell Press", [(10, 60, 7), (10, 65, 8), (8, 70, 9)]),
            ex(2, "Overhead Press", [(8, 95, 7), (8, 105, 8), (6, 115, 9)]),
            ex(3, "Cable Flyes", [(12, 30, 7), (12, 35, 8), (12, 35, 8)]),
            ex(4, "Triceps Pushdown", [(12, 50, 7), (12, 55, 8), (10, 60, 9)])
        ])
    }()

    /// Number of Bench Press sets already logged for the in-progress scenarios.
    static let loggedSets = 2
}
#endif
