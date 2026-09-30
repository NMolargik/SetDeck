//
//  WatchTransfer.swift
//  SetDeckCore
//
//  The phone↔watch wire protocol: lightweight Codable DTOs plus the message keys.
//  Both the phone-side relay (SetDeckServices) and the watch app link this one
//  definition — the old code kept two hand-synced copies.
//

import Foundation

// MARK: - Message keys

/// Plain string constants shared with the nonisolated WatchConnectivity delegate
/// callbacks, so the enum opts out of the module's default main-actor isolation.
nonisolated public enum WatchMessageKey {
    public static let routineRequest = "routineRequest"
    public static let routineData = "routineData"
    public static let setCompletion = "setCompletion"
    public static let workoutStarted = "workoutStarted"
    public static let workoutEnded = "workoutEnded"
}

// MARK: - Routine payload

nonisolated public struct WatchRoutine: Codable, Identifiable, Sendable {
    public let id: UUID
    public let day: Int
    public let dayName: String
    public let exercises: [WatchExercise]

    public var exerciseCount: Int { exercises.count }
    public var totalSetCount: Int { exercises.reduce(0) { $0 + $1.sets.count } }

    public static let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    public init(id: UUID = UUID(), day: Int, exercises: [WatchExercise]) {
        self.id = id
        self.day = day
        self.dayName = Self.dayNames[day % 7]
        self.exercises = exercises
    }
}

nonisolated public struct WatchExercise: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let isWarmup: Bool
    public let note: String?
    public let orderIndex: Int
    public let sets: [WatchSet]

    public var setCount: Int { sets.count }

    public init(id: UUID, name: String, isWarmup: Bool, note: String?, orderIndex: Int, sets: [WatchSet]) {
        self.id = id
        self.name = name
        self.isWarmup = isWarmup
        self.note = note
        self.orderIndex = orderIndex
        self.sets = sets
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: WatchExercise, rhs: WatchExercise) -> Bool {
        lhs.id == rhs.id
    }
}

nonisolated public struct WatchSet: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let setType: WatchSetType
    public let targetReps: Int?
    public let weight: Double?
    public let weightUnit: String
    public let targetDuration: TimeInterval?
    public let rpe: Int?
    public let orderIndex: Int

    /// Local completion state on the watch — never sent from the phone.
    public var isCompleted: Bool = false
    public var actualReps: Int?
    public var actualWeight: Double?

    public var displayWeight: String {
        guard let w = weight else { return "--" }
        return "\(Int(w)) \(weightUnit)"
    }

    public var displayReps: String {
        guard let r = targetReps else { return "--" }
        return "\(r) reps"
    }

    public var displayTarget: String {
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

    /// Tolerant decoder: the phone payload omits the local completion fields.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        setType = try container.decode(WatchSetType.self, forKey: .setType)
        targetReps = try container.decodeIfPresent(Int.self, forKey: .targetReps)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        weightUnit = try container.decode(String.self, forKey: .weightUnit)
        targetDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .targetDuration)
        rpe = try container.decodeIfPresent(Int.self, forKey: .rpe)
        orderIndex = try container.decode(Int.self, forKey: .orderIndex)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        actualReps = try container.decodeIfPresent(Int.self, forKey: .actualReps)
        actualWeight = try container.decodeIfPresent(Double.self, forKey: .actualWeight)
    }

    public init(
        id: UUID,
        setType: WatchSetType,
        targetReps: Int?,
        weight: Double?,
        weightUnit: String,
        targetDuration: TimeInterval?,
        rpe: Int?,
        orderIndex: Int,
        isCompleted: Bool = false,
        actualReps: Int? = nil,
        actualWeight: Double? = nil
    ) {
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

nonisolated public enum WatchSetType: String, Codable, Sendable {
    case reps, amap, duration, freeform

    public init(from setType: SetType) {
        switch setType {
        case .reps: self = .reps
        case .amap: self = .amap
        case .duration: self = .duration
        case .freeform: self = .freeform
        }
    }
}

// MARK: - Watch → phone completion

nonisolated public struct SetCompletionMessage: Codable, Sendable {
    public let setId: UUID
    public let exerciseId: UUID
    public let completedDate: Date
    public let actualReps: Int?
    public let actualWeight: Double?
    public let actualRpe: Int?

    public init(setId: UUID, exerciseId: UUID, completedDate: Date, actualReps: Int?, actualWeight: Double?, actualRpe: Int?) {
        self.setId = setId
        self.exerciseId = exerciseId
        self.completedDate = completedDate
        self.actualReps = actualReps
        self.actualWeight = actualWeight
        self.actualRpe = actualRpe
    }
}
