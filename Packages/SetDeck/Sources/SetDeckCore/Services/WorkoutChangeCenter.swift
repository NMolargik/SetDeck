//
//  WorkoutChangeCenter.swift
//  SetDeckCore
//
//  One multicast change stream for the workout store. Repositories notify after every
//  successful write and CloudSyncManager notifies on CloudKit imports, so screens,
//  achievements, and Spotlight observe a single stream instead of per-screen callbacks
//  (replaces the old `changeStamp`/`onDataMutated` pair on ExerciseManager).
//

import Foundation

@MainActor
public final class WorkoutChangeCenter {

    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    public init() {}

    /// A stream that yields after every successful mutation of workout data.
    public func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let id = UUID()
        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.continuations.removeValue(forKey: id)
            }
        }
        return stream
    }

    /// Broadcasts a change to every subscriber.
    public func notify() {
        for continuation in continuations.values {
            continuation.yield()
        }
    }
}

// MARK: - Use case

@MainActor
public protocol ObserveWorkoutChanges {
    func callAsFunction() -> AsyncStream<Void>
}

public struct ObserveWorkoutChangesUseCase: ObserveWorkoutChanges {
    private let center: WorkoutChangeCenter
    public init(center: WorkoutChangeCenter) { self.center = center }
    public func callAsFunction() -> AsyncStream<Void> {
        center.changes()
    }
}
