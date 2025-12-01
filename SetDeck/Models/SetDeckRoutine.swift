//
//  SetDeckRoutine.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/7/25.
//

import Foundation
import SwiftData

@Model
final class SetDeckRoutine {
    var uuid: UUID = UUID()
    var day: Int = 0
    
    var lastUpdated: Date?

    @Relationship(deleteRule: .cascade, inverse: \SetDeckExercise.routine)
    var exercises: [SetDeckExercise]?

    init(uuid: UUID = UUID(), day: Int, lastUpdated: Date? = Date()) {
        self.uuid = uuid
        self.day = day
        self.lastUpdated = lastUpdated
    }
}

extension SetDeckRoutine {
    /// A single randomized sample routine (a full day's workout) for testing and previews
    static func sample(seed: UInt64? = nil, day: Int = 1, exerciseCount: Int = 4, setsPerExercise: Int = 3) -> SetDeckRoutine {
        var rng = seed.map { SeededRandomNumberGenerator(seed: $0) }
        func randInt(_ range: ClosedRange<Int>) -> Int {
            if var g = rng { let v = Int.random(in: range, using: &g); rng = g; return v }
            return Int.random(in: range)
        }
        func randBool() -> Bool {
            if var g = rng { let v = Bool.random(using: &g); rng = g; return v }
            return Bool.random()
        }

        let routine = SetDeckRoutine(
            day: day,
            lastUpdated: Date()
        )

        // Generate exercises and wire relationships
        let baseSeed = seed ?? UInt64.random(in: .min ... .max)
        let count = max(1, exerciseCount)
        let exercises: [SetDeckExercise] = (0..<count).map { i in
            let ex = SetDeckExercise.sample(seed: baseSeed &+ UInt64(i), setCount: max(1, setsPerExercise))
            ex.routine = routine
            return ex
        }.sorted { $0.orderIndex < $1.orderIndex }

        routine.exercises = exercises
        return routine
    }

    /// Generate multiple randomized sample routines
    static func samples(_ count: Int, seed: UInt64? = nil, startDay: Int = 1, exerciseCount: Int = 4, setsPerExercise: Int = 3) -> [SetDeckRoutine] {
        let baseSeed = seed ?? UInt64.random(in: .min ... .max)
        return (0..<count).map { i in
            SetDeckRoutine.sample(
                seed: baseSeed &+ UInt64(i),
                day: startDay + i,
                exerciseCount: exerciseCount,
                setsPerExercise: setsPerExercise
            )
        }
    }
}

