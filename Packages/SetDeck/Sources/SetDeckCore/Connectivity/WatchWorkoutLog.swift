//
//  WatchWorkoutLog.swift
//  SetDeckCore
//
//  The watch's standalone workout state, kept pure so it is host-tested: which sets are
//  logged, which logs the phone has acknowledged, and what "the next set" is. The watch
//  app persists this as JSON and drives it; nothing here touches WatchConnectivity.
//

import Foundation

nonisolated public struct WatchWorkoutLog: Codable, Equatable, Sendable {
    public var routineId: UUID
    public var startedAt: Date
    /// Latest log per set (re-logging a set edits its log, keeping the completion id).
    public private(set) var logs: [UUID: SetCompletionMessage] = [:]
    /// Completion ids -> the `completedDate` the phone last acknowledged for them.
    public private(set) var acknowledged: [UUID: Date] = [:]
    public var finishedAt: Date?

    public init(routineId: UUID, startedAt: Date) {
        self.routineId = routineId
        self.startedAt = startedAt
    }

    public var isFinished: Bool { finishedAt != nil }
    public var loggedSetCount: Int { logs.count }

    public func isLogged(_ setId: UUID) -> Bool { logs[setId] != nil }

    /// Logs (or re-logs) a set. Re-logging keeps the completion id so the phone merges it
    /// as an edit instead of a duplicate; the timestamp is forced to move forward so
    /// last-write-wins always prefers the edit.
    @discardableResult
    public mutating func record(
        setId: UUID, exerciseId: UUID, reps: Int?, weight: Double?, rpe: Int?, at date: Date = Date()
    ) -> SetCompletionMessage {
        var stamp = date
        let id: UUID
        if let previous = logs[setId] {
            id = previous.completionId
            if stamp <= previous.completedDate { stamp = previous.completedDate.addingTimeInterval(0.001) }
        } else {
            id = UUID()
        }
        let message = SetCompletionMessage(
            completionId: id, setId: setId, exerciseId: exerciseId, completedDate: stamp,
            actualReps: reps, actualWeight: weight, actualRpe: rpe
        )
        logs[setId] = message
        return message
    }

    /// Logs the phone has not acknowledged at their current version, oldest first.
    public var pending: [SetCompletionMessage] {
        logs.values
            .filter { message in
                guard let acked = acknowledged[message.completionId] else { return true }
                return acked < message.completedDate
            }
            .sorted { $0.completedDate < $1.completedDate }
    }

    public mutating func markDelivered(_ message: SetCompletionMessage) {
        if let existing = acknowledged[message.completionId], existing >= message.completedDate { return }
        acknowledged[message.completionId] = message.completedDate
    }

    /// First unlogged set in routine order (exercise order, then set order).
    public func nextSet(in routine: WatchRoutine) -> WatchNextSet? {
        let exercises = routine.exercises.sorted { $0.orderIndex < $1.orderIndex }
        for exercise in exercises {
            let sets = exercise.sets.sorted { $0.orderIndex < $1.orderIndex }
            for (index, set) in sets.enumerated() where logs[set.id] == nil {
                return WatchNextSet(exercise: exercise, set: set, setNumber: index + 1, setsInExercise: sets.count)
            }
        }
        return nil
    }

    public func completedCount(in routine: WatchRoutine) -> Int {
        routine.exercises.reduce(0) { $0 + $1.sets.filter { logs[$0.id] != nil }.count }
    }
}

nonisolated public struct WatchNextSet: Sendable, Equatable {
    public let exercise: WatchExercise
    public let set: WatchSet
    public let setNumber: Int
    public let setsInExercise: Int

    public var label: String { "\(exercise.name) · \(setNumber)/\(setsInExercise)" }
}

// MARK: - Rest timer

/// Deadline-based, so it stays correct when the app is suspended or the screen dims
/// (the failure mode other apps' tick-counting timers have). Pure value type.
nonisolated public struct WatchRestTimer: Codable, Equatable, Sendable {
    public static let defaultDuration: TimeInterval = 90
    public static let extensionStep: TimeInterval = 30

    public private(set) var startedAt: Date
    public private(set) var endDate: Date

    public init(duration: TimeInterval = defaultDuration, now: Date = Date()) {
        self.startedAt = now
        self.endDate = now.addingTimeInterval(max(1, duration))
    }

    public var totalDuration: TimeInterval { endDate.timeIntervalSince(startedAt) }

    public func remaining(at now: Date = Date()) -> TimeInterval { max(0, endDate.timeIntervalSince(now)) }
    public func isFinished(at now: Date = Date()) -> Bool { now >= endDate }
    public func progress(at now: Date = Date()) -> Double {
        totalDuration > 0 ? min(1, max(0, remaining(at: now) / totalDuration)) : 0
    }

    public mutating func extend(by seconds: TimeInterval = extensionStep) {
        endDate = endDate.addingTimeInterval(seconds)
    }
}

/// What the complication / Smart Stack and the phone's Live Activity need to know.
/// `endDate == nil` means "no rest in progress".
nonisolated public struct WatchRestSnapshot: Codable, Equatable, Sendable {
    public static let sharedDefaultsKey = "watchRestSnapshot"

    public var endDate: Date?
    public var nextSetLabel: String?

    public init(endDate: Date?, nextSetLabel: String?) {
        self.endDate = endDate
        self.nextSetLabel = nextSetLabel
    }

    public static let cleared = WatchRestSnapshot(endDate: nil, nextSetLabel: nil)

    public func isResting(at now: Date = Date()) -> Bool { endDate.map { $0 > now } ?? false }
}
