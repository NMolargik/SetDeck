//
//  SpotlightIndexer.swift
//  SetDeck
//
//  Indexes exercises into Spotlight so the system can semantically search them.
//  Conforms to the package's `ExerciseIndexing` seam (the AppEntity types can't live in
//  the package).
//

import AppIntents
import CoreSpotlight
import Foundation
import SetDeckCore
import os

struct SpotlightIndexer: ExerciseIndexing {
    nonisolated init() {}

    /// Re-indexes every exercise. Safe to call repeatedly; CoreSpotlight dedupes by
    /// identifier.
    func reindex(exercises: [SetDeckExercise]) {
        guard CSSearchableIndex.isIndexingAvailable() else { return }
        let entities = exercises.map(ExerciseEntity.init)
        guard !entities.isEmpty else { return }

        Task.detached(priority: .utility) {
            do {
                try await CSSearchableIndex.default().indexAppEntities(entities)
                Log.spotlight.info("Indexed \(entities.count) exercises into Spotlight")
            } catch {
                Log.spotlight.error("Spotlight indexing failed: \(error.localizedDescription)")
            }
        }
    }
}
