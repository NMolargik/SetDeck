//
//  SetDeckExercise.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/7/25.
//

import Foundation
import SwiftData

@Model
final class SetDeckExercise {
    var uuid: UUID = UUID()
    var name: String = "New Exercise"
    var note: String?
    var videoURL: URL?
    var isWarmup: Bool = false

    var muscleGroups: [MuscleGroup] = []
    var equipment: String?
    var orderIndex: Int = 0

    // One-to-many: Exercise → Sets (no inverse here; inverse on SetDeckSet.exercise)
    @Relationship(deleteRule: .cascade)
    var sets: [SetDeckSet]?

    // Many-to-one: Exercise → Routine (no inverse here; inverse declared on Routine.exercises)
    @Relationship(deleteRule: .nullify)
    var routine: SetDeckRoutine?

    init(uuid: UUID = UUID(),
         name: String,
         note: String? = nil,
         videoURL: URL? = nil,
         isWarmup: Bool = false,
         muscleGroups: [MuscleGroup] = [],
         equipment: String? = nil,
         orderIndex: Int = 0) {
        self.uuid = uuid
        self.name = name
        self.note = note
        self.videoURL = videoURL
        self.isWarmup = isWarmup
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.orderIndex = orderIndex
    }
}

extension SetDeckExercise {
    /// A single randomized sample exercise for testing and previews
    static func sample(seed: UInt64? = nil, name: String? = nil, setCount: Int = 3) -> SetDeckExercise {
        var rng = seed.map { SeededRandomNumberGenerator(seed: $0) }
        func randInt(_ range: ClosedRange<Int>) -> Int {
            if var g = rng { let v = Int.random(in: range, using: &g); rng = g; return v }
            return Int.random(in: range)
        }
        func randBool() -> Bool {
            if var g = rng { let v = Bool.random(using: &g); rng = g; return v }
            return Bool.random()
        }

        let exerciseName: String = name ?? {
            let options = ["Bench Press", "Squat", "Deadlift", "Overhead Press", "Pull-Up", "Row", "Lunge", "Dip"]
            if var g = rng, let s = options.randomElement(using: &g) { rng = g; return s }
            return options.randomElement() ?? "Exercise"
        }()

        let ex = SetDeckExercise(
            name: exerciseName,
            note: randBool() ? "Focus on form" : nil,
            videoURL: nil,
            isWarmup: randBool(),
            muscleGroups: [],
            equipment: randBool() ? "Barbell" : nil,
            orderIndex: randInt(0...10)
        )

        // Generate sample sets and assign back-references
        let baseSeed = seed ?? UInt64.random(in: .min ... .max)
        let count = max(1, setCount)
        let generatedSets = (0..<count).map { i -> SetDeckSet in
            let set = SetDeckSet.sample(seed: baseSeed &+ UInt64(i))
            set.exercise = ex
            return set
        }.sorted { ($0.orderIndex) < ($1.orderIndex) }

        ex.sets = generatedSets
        return ex
    }

    /// Generate multiple randomized sample exercises
    static func samples(_ count: Int, seed: UInt64? = nil, setCount: Int = 3) -> [SetDeckExercise] {
        let baseSeed = seed ?? UInt64.random(in: .min ... .max)
        return (0..<count).map { i in
            SetDeckExercise.sample(seed: baseSeed &+ UInt64(i), setCount: setCount)
        }
    }
}
