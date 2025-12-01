//
//  SetDeckSet.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/7/25.
//

import Foundation
import SwiftData

@Model
final class SetDeckSet {
    var uuid: UUID = UUID()

    var setType: SetType = SetType.reps

    // reps / amap
    var targetReps: Int?
    var weight: Double?

    // duration
    var targetDuration: TimeInterval?

    // freeform – renamed from `description` (reserved)
    var setDescription: String?

    // common
    var rpe: Int?                 // 0–5
    var orderIndex: Int = 0

    // ONE-WAY: Set → Exercise (inverse defined on Exercise side)
    @Relationship(inverse: \SetDeckExercise.sets)
    var exercise: SetDeckExercise?

    // ONE-WAY: Set → History (no inverse macro here)
    @Relationship(deleteRule: .cascade)
    var history: [SetDeckSetHistory]?

    init(uuid: UUID = UUID(),
         setType: SetType = .reps,
         targetReps: Int? = nil,
         weight: Double? = nil,
         targetDuration: TimeInterval? = nil,
         setDescription: String? = nil,
         rpe: Int? = nil,
         orderIndex: Int = 0) {
        self.uuid = uuid
        self.setType = setType
        self.targetReps = targetReps
        self.weight = weight
        self.targetDuration = targetDuration
        self.setDescription = setDescription
        self.rpe = rpe
        self.orderIndex = orderIndex
    }
}

extension SetDeckSet {
    /// A single randomized sample set for testing and previews
    static func sample(seed: UInt64? = nil) -> SetDeckSet {
        var rng = seed.map { SeededRandomNumberGenerator(seed: $0) }
        func randInt(_ range: ClosedRange<Int>) -> Int {
            if var g = rng { let v = Int.random(in: range, using: &g); rng = g; return v }
            return Int.random(in: range)
        }
        func randDouble(_ range: ClosedRange<Double>) -> Double {
            if var g = rng { let v = Double.random(in: range, using: &g); rng = g; return v }
            return Double.random(in: range)
        }
        func randBool() -> Bool {
            if var g = rng { let v = Bool.random(using: &g); rng = g; return v }
            return Bool.random()
        }

        let typePool: [SetType] = [.reps, .amap, .duration]
        let type: SetType = {
            if var g = rng, let t = typePool.randomElement(using: &g) { rng = g; return t }
            return typePool.randomElement() ?? .reps
        }()
        let reps = (type == .reps || type == .amap) ? randInt(5...15) : nil
        let duration = (type == .duration) ? randDouble(20...90) : nil
        let weight = randBool() ? randDouble(20...225) : nil
        let rpe = randBool() ? randInt(6...10) : nil

        return SetDeckSet(
            setType: type,
            targetReps: reps,
            weight: weight,
            targetDuration: duration,
            setDescription: {
                let options = ["Warmup", "", "Back-off", "Drop set"]
                if var g = rng, let s = options.randomElement(using: &g) { rng = g; return s }
                return options.randomElement()
            }(),
            rpe: rpe,
            orderIndex: randInt(0...10)
        )
    }

    /// Generate multiple randomized sample sets
    static func samples(_ count: Int, seed: UInt64? = nil) -> [SetDeckSet] {
        let baseSeed = seed ?? UInt64.random(in: .min ... .max)
        return (0..<count).map { i in
            SetDeckSet.sample(seed: baseSeed &+ UInt64(i))
        }
    }
}

// MARK: - Deterministic RNG helper
/// A simple deterministic RNG for repeatable samples when a seed is provided
struct SeededRandomNumberGenerator: nonisolated RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xdeadbeef : seed }
    nonisolated mutating func next() -> UInt64 {
        // Xorshift64*
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
