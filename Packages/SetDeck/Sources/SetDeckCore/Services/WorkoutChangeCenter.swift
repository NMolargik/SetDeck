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

/// Why the store changed. Local writes come from this device's own activity; a remote
/// import is history CloudKit merged in from another install of the same account.
nonisolated public enum WorkoutChange: Sendable, Equatable {
    case local
    case remoteImport
}

@MainActor
public final class WorkoutChangeCenter {

    private var continuations: [UUID: AsyncStream<WorkoutChange>.Continuation] = [:]

    public init() {}

    /// A stream that yields after every successful mutation of workout data.
    public func changes() -> AsyncStream<WorkoutChange> {
        let (stream, continuation) = AsyncStream<WorkoutChange>.makeStream()
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
    public func notify(_ change: WorkoutChange = .local) {
        for continuation in continuations.values {
            continuation.yield(change)
        }
    }
}

// MARK: - Use case

@MainActor
public protocol ObserveWorkoutChanges {
    func callAsFunction() -> AsyncStream<WorkoutChange>
}

public struct ObserveWorkoutChangesUseCase: ObserveWorkoutChanges {
    private let center: WorkoutChangeCenter
    public init(center: WorkoutChangeCenter) { self.center = center }
    public func callAsFunction() -> AsyncStream<WorkoutChange> {
        center.changes()
    }
}
