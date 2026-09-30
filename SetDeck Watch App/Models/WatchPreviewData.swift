//
//  WatchPreviewData.swift
//  SetDeck Watch App
//
//  Preview fixtures for the shared connectivity DTOs (which live in SetDeckCore).
//

import Foundation
import SetDeckCore

extension WatchRoutine {
    static var sample: WatchRoutine {
        WatchRoutine(
            day: 1, // Monday
            exercises: [
                WatchExercise(
                    id: UUID(),
                    name: "Bench Press",
                    isWarmup: false,
                    note: nil,
                    orderIndex: 0,
                    sets: [
                        WatchSet(id: UUID(), setType: .reps, targetReps: 10, weight: 135, weightUnit: "lb", targetDuration: nil, rpe: 7, orderIndex: 0),
                        WatchSet(id: UUID(), setType: .reps, targetReps: 8, weight: 155, weightUnit: "lb", targetDuration: nil, rpe: 8, orderIndex: 1),
                        WatchSet(id: UUID(), setType: .reps, targetReps: 6, weight: 175, weightUnit: "lb", targetDuration: nil, rpe: 9, orderIndex: 2)
                    ]
                ),
                WatchExercise(
                    id: UUID(),
                    name: "Incline Dumbbell Press",
                    isWarmup: false,
                    note: "Focus on squeeze at top",
                    orderIndex: 1,
                    sets: [
                        WatchSet(id: UUID(), setType: .reps, targetReps: 12, weight: 50, weightUnit: "lb", targetDuration: nil, rpe: 7, orderIndex: 0),
                        WatchSet(id: UUID(), setType: .reps, targetReps: 10, weight: 55, weightUnit: "lb", targetDuration: nil, rpe: 8, orderIndex: 1)
                    ]
                ),
                WatchExercise(
                    id: UUID(),
                    name: "Cable Flyes",
                    isWarmup: false,
                    note: nil,
                    orderIndex: 2,
                    sets: [
                        WatchSet(id: UUID(), setType: .reps, targetReps: 15, weight: 30, weightUnit: "lb", targetDuration: nil, rpe: 6, orderIndex: 0),
                        WatchSet(id: UUID(), setType: .amap, targetReps: nil, weight: 25, weightUnit: "lb", targetDuration: nil, rpe: 8, orderIndex: 1)
                    ]
                )
            ]
        )
    }

    static var empty: WatchRoutine {
        WatchRoutine(day: 0, exercises: [])
    }
}
