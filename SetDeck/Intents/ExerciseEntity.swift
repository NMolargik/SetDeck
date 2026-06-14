//
//  ExerciseEntity.swift
//  SetDeck
//
//  Created by Nick Molargik on 6/14/26.
//
//  Exposes workout exercises to Siri, Shortcuts, and Spotlight via an
//  IndexedEntity so they are semantically searchable on-device.
//

import AppIntents
import CoreSpotlight
import UniformTypeIdentifiers
import SwiftData

// MARK: - Day naming helper

nonisolated enum WorkoutDayName {
    static let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    static func name(forDay day: Int) -> String {
        guard names.indices.contains(day) else { return "Unscheduled" }
        return names[day]
    }
}

// MARK: - Exercise App Entity

struct ExerciseEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Exercise")
    static let defaultQuery = ExerciseEntityQuery()

    var id: UUID
    var name: String
    var dayName: String
    var isWarmup: Bool
    var setCount: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(dayName)\(isWarmup ? " · Warm-up" : "")",
            image: .init(systemName: isWarmup ? "figure.cooldown" : "figure.strengthtraining.traditional")
        )
    }

    /// Rich metadata that drives Spotlight's semantic indexing.
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = name
        attributes.contentDescription = "\(dayName) workout · \(setCount) set\(setCount == 1 ? "" : "s")"
        attributes.keywords = [name, dayName, "workout", "exercise", "SetDeck"]
        return attributes
    }
}

extension ExerciseEntity {
    @MainActor
    init(_ exercise: SetDeckExercise) {
        self.id = exercise.uuid
        self.name = exercise.name
        self.dayName = WorkoutDayName.name(forDay: exercise.routine?.day ?? -1)
        self.isWarmup = exercise.isWarmup
        self.setCount = exercise.sets?.count ?? 0
    }
}

// MARK: - Entity Query

struct ExerciseEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ExerciseEntity] {
        let wanted = Set(identifiers)
        return allExercises().filter { wanted.contains($0.uuid) }.map(ExerciseEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [ExerciseEntity] {
        allExercises().map(ExerciseEntity.init)
    }

    @MainActor
    private func allExercises() -> [SetDeckExercise] {
        let context = IntentModelContainer.shared.mainContext
        let descriptor = FetchDescriptor<SetDeckExercise>(
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
