//
//  WatchModels.swift
//  SetDeck Watch App
//
//  Created by Nick Molargik on 1/9/26.
//
//  Lightweight Codable models for WatchConnectivity transfer.
//  SwiftData models cannot be directly sent via WatchConnectivity.
//

import Foundation

// MARK: - Watch Routine
struct WatchRoutine: Codable, Identifiable {
    let id: UUID
    let day: Int
    let dayName: String
    let exercises: [WatchExercise]

    var exerciseCount: Int { exercises.count }
    var totalSetCount: Int { exercises.reduce(0) { $0 + $1.sets.count } }

    static let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    init(id: UUID = UUID(), day: Int, exercises: [WatchExercise]) {
        self.id = id
        self.day = day
        self.dayName = Self.dayNames[day % 7]
        self.exercises = exercises
    }
}

// MARK: - Watch Exercise
struct WatchExercise: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let isWarmup: Bool
    let note: String?
    let orderIndex: Int
    let sets: [WatchSet]

    var setCount: Int { sets.count }

    // Hashable conformance (only use id for hashing)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WatchExercise, rhs: WatchExercise) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Watch Set
struct WatchSet: Codable, Identifiable {
    let id: UUID
    let setType: WatchSetType
    let targetReps: Int?
    let weight: Double?
    let weightUnit: String
    let targetDuration: TimeInterval?
    let rpe: Int?
    let orderIndex: Int

    // Completed state (updated when user logs) - not sent from iPhone
    var isCompleted: Bool = false
    var actualReps: Int?
    var actualWeight: Double?

    var displayWeight: String {
        guard let w = weight else { return "--" }
        return "\(Int(w)) \(weightUnit)"
    }

    var displayReps: String {
        guard let r = targetReps else { return "--" }
        return "\(r) reps"
    }

    var displayTarget: String {
        switch setType {
        case .reps:
            return "\(targetReps ?? 0) × \(displayWeight)"
        case .amap:
            return "AMAP × \(displayWeight)"
        case .duration:
            let mins = Int((targetDuration ?? 0) / 60)
            let secs = Int((targetDuration ?? 0).truncatingRemainder(dividingBy: 60))
            return mins > 0 ? "\(mins)m \(secs)s" : "\(secs)s"
        case .freeform:
            return "Freeform"
        }
    }

    // Custom decoder to handle missing keys from iPhone (isCompleted, actualReps, actualWeight)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        setType = try container.decode(WatchSetType.self, forKey: .setType)
        targetReps = try container.decodeIfPresent(Int.self, forKey: .targetReps)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        weightUnit = try container.decode(String.self, forKey: .weightUnit)
        targetDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .targetDuration)
        rpe = try container.decodeIfPresent(Int.self, forKey: .rpe)
        orderIndex = try container.decode(Int.self, forKey: .orderIndex)

        // These are not sent from iPhone, so use defaults
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        actualReps = try container.decodeIfPresent(Int.self, forKey: .actualReps)
        actualWeight = try container.decodeIfPresent(Double.self, forKey: .actualWeight)
    }

    // Memberwise init for local construction
    init(id: UUID, setType: WatchSetType, targetReps: Int?, weight: Double?, weightUnit: String, targetDuration: TimeInterval?, rpe: Int?, orderIndex: Int, isCompleted: Bool = false, actualReps: Int? = nil, actualWeight: Double? = nil) {
        self.id = id
        self.setType = setType
        self.targetReps = targetReps
        self.weight = weight
        self.weightUnit = weightUnit
        self.targetDuration = targetDuration
        self.rpe = rpe
        self.orderIndex = orderIndex
        self.isCompleted = isCompleted
        self.actualReps = actualReps
        self.actualWeight = actualWeight
    }
}

// MARK: - Watch Set Type
enum WatchSetType: String, Codable {
    case reps
    case amap
    case duration
    case freeform
}

// MARK: - Set Completion (sent from Watch to iPhone)
struct SetCompletionMessage: Codable {
    let setId: UUID
    let exerciseId: UUID
    let completedDate: Date
    let actualReps: Int?
    let actualWeight: Double?
    let actualRpe: Int?
}

// MARK: - Message Keys
enum WatchMessageKey {
    static let routineRequest = "routineRequest"
    static let routineData = "routineData"
    static let setCompletion = "setCompletion"
    static let workoutStarted = "workoutStarted"
    static let workoutEnded = "workoutEnded"
}

// MARK: - Sample Data for Previews
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
