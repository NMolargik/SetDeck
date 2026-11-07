//
//  WatchCompletionMerge.swift
//  SetDeckCore
//
//  The phone-side merge rule for sets logged on the watch while the phone was out of
//  reach. Pure so it is host-tested.
//
//  RULE (identity + last-write-wins):
//   1. Identity is `SetCompletionMessage.completionId`, which the watch keeps stable for
//      a set across edits and redeliveries. The phone stores it as the history uuid.
//   2. No entry with that id            -> insert.
//   3. Entry exists, incoming strictly newer (`completedDate`) -> update it in place.
//   4. Entry exists, incoming same age or older -> ignore (a redelivery or stale edit;
//      ties keep the phone's copy).
//  Different `completionId`s for the same set are distinct entries on purpose (a phone
//  log and a watch log of the same set are both real work).
//

import Foundation

nonisolated public enum WatchCompletionMerge {
    public enum Decision: Equatable, Sendable {
        case insert
        case update
        case ignore
    }

    /// - Parameter existingDate: `completedDate` of the phone's entry with the same id, if any.
    public static func decide(existingDate: Date?, incomingDate: Date) -> Decision {
        guard let existingDate else { return .insert }
        return incomingDate > existingDate ? .update : .ignore
    }
}

// MARK: - Use case

@MainActor
public protocol MergeWatchCompletion {
    @discardableResult
    func callAsFunction(_ completion: SetCompletionMessage) throws(PersistenceError) -> WatchCompletionMerge.Decision
}

public struct MergeWatchCompletionUseCase: MergeWatchCompletion {
    private let repository: any HistoryRepository
    public init(repository: any HistoryRepository) { self.repository = repository }

    @discardableResult
    public func callAsFunction(_ completion: SetCompletionMessage) throws(PersistenceError) -> WatchCompletionMerge.Decision {
        let existing = try repository.history(withID: completion.completionId)
        let decision = WatchCompletionMerge.decide(existingDate: existing?.completedDate, incomingDate: completion.completedDate)
        switch decision {
        case .ignore:
            break
        case .update:
            if let existing {
                try repository.updateHistory(
                    existing,
                    completedDate: completion.completedDate,
                    actualReps: completion.actualReps,
                    actualWeight: completion.actualWeight,
                    actualRpe: completion.actualRpe
                )
            }
        case .insert:
            guard let set = try repository.set(withID: completion.setId) else { break }
            try repository.recordHistory(
                for: set,
                id: completion.completionId,
                completedDate: completion.completedDate,
                actualReps: completion.actualReps,
                actualWeight: completion.actualWeight,
                actualWeightUnit: nil,
                actualDuration: nil,
                actualDescription: nil,
                actualRpe: completion.actualRpe,
                note: "Logged from Apple Watch"
            )
        }
        return decision
    }
}
