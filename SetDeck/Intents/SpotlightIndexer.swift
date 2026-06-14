//
//  SpotlightIndexer.swift
//  SetDeck
//
//  Created by Nick Molargik on 6/14/26.
//

import AppIntents
import CoreSpotlight
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.molargiksoftware.SetDeck", category: "Spotlight")

/// Indexes app entities into Spotlight so the system can semantically search
/// the user's exercises.
enum SpotlightIndexer {
    /// Re-indexes every exercise. Safe to call repeatedly; CoreSpotlight
    /// dedupes by identifier.
    @MainActor
    static func indexExercises(in container: ModelContainer) async {
        guard CSSearchableIndex.isIndexingAvailable() else { return }

        let descriptor = FetchDescriptor<SetDeckExercise>(
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )
        let exercises = (try? container.mainContext.fetch(descriptor)) ?? []
        let entities = exercises.map(ExerciseEntity.init)

        guard !entities.isEmpty else { return }

        do {
            try await CSSearchableIndex.default().indexAppEntities(entities)
            logger.info("Indexed \(entities.count) exercises into Spotlight")
        } catch {
            logger.error("Spotlight indexing failed: \(error.localizedDescription)")
        }
    }
}
