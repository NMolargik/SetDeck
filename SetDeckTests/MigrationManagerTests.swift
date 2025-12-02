//
//  MigrationManagerTests.swift
//  SetDeckTests
//
//  Created by Nick Molargik on 12/2/25.
//

import Testing
@testable import SetDeck
import SwiftData
import Foundation

@Suite("MigrationManager Tests")
@MainActor
struct MigrationManagerTests {

    // MARK: - Helpers

    /// Creates an in-memory SwiftData stack for testing.
    private func makeInMemoryContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Exercise.self,
                SetDeckRoutine.self,
                SetDeckExercise.self,
                SetDeckSet.self,
            configurations: config
        )
        return ModelContext(container)
    }

    /// Convenience to fetch all instances of a model type from the context.
    private func fetchAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws -> [T] {
        try context.fetch(FetchDescriptor<T>())
    }

    // MARK: - Tests

    @Test("performMigration is a no-op if already running")
    func performMigration_IgnoresWhenAlreadyRunning() async throws {
        let context = try makeInMemoryContext()
        let sut = MigrationManager(context: context)

        sut.status = .running("Already migrating…", 0.4)

        try await sut.performMigration()

        // Status should remain running and no routines should have been created.
        #expect({
            if case .running(let message, let progress) = sut.status {
                return message == "Already migrating…" && progress == 0.4
            }
            return false
        }())

        let routines = try fetchAll(SetDeckRoutine.self, in: context)
        #expect(routines.isEmpty)
    }

    @Test("existing new data causes migration to be skipped")
    func existingNewData_SkipsMigration() async throws {
        let context = try makeInMemoryContext()

        // Seed one legacy Exercise so we don't early-return on “no legacy data”.
        let legacyExercise = Exercise(
            weekday: 1, orderIndex: 0, name: "Legacy Squat"
            // Add any other required initialiser parameters here.
        )
        context.insert(legacyExercise)

        // Seed a new-model routine to simulate “migration already done”.
        let existingRoutine = SetDeckRoutine(day: 1, lastUpdated: Date())
        context.insert(existingRoutine)

        try context.save()

        let sut = MigrationManager(context: context)
        try await sut.performMigration()

        // We should have returned early and not created any *additional* routines.
        let routines = try fetchAll(SetDeckRoutine.self, in: context)
        #expect(routines.count == 1)
        #expect(routines.first?.day == 1)

        #expect({
            if case .completed = sut.status { return true }
            return false
        }())
    }
}
