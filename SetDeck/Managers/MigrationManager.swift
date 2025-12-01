//
//  MigrationManager.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/12/25.
//

import Foundation
import SwiftData

@Observable
class MigrationManager {
    @ObservationIgnored
    let context: ModelContext
    
    var status: MigrationStatus = .idle
    
    init(context: ModelContext) {
        self.context = context
    }
    
    @MainActor func performMigration() async throws {
        // Prevent re-entrancy: if already running, ignore
        switch status {
        case .running(_, _):
            return
        default:
            break
        }

        status = .preparing("Scanning legacy data…")

        // Fetch legacy exercises
        let fetch = FetchDescriptor<Exercise>(
            sortBy: [
                SortDescriptor(\.weekday, order: .forward),
                SortDescriptor(\.orderIndex, order: .forward)
            ]
        )

        let legacyExercises: [Exercise]
        do {
            legacyExercises = try context.fetch(fetch)
        } catch {
            status = .failed("Failed to read legacy data: \(error.localizedDescription)")
            throw error
        }

        guard !legacyExercises.isEmpty else {
            status = .completed
            return
        }

        // If any SetDeckRoutine already exists, assume migration was already performed
        let existingNewData = try? context.fetch(FetchDescriptor<SetDeckRoutine>())
        if let existingNewData, !existingNewData.isEmpty {
            status = .completed
            return
        }

        // Group by weekday to form routines
        let grouped = Dictionary(grouping: legacyExercises, by: { $0.weekday })

        // Count total work units (routines + exercises + sets)
        let totalRoutines = grouped.keys.count
        let totalExercises = legacyExercises.count
        let totalSets = legacyExercises.reduce(0) { $0 + ($1.exerciseSets?.count ?? 0) }
        let totalUnits = max(1, totalRoutines + totalExercises + totalSets)
        var processed = 0

        func updateProgress(message: String) {
            let progress = min(1.0, Double(processed) / Double(totalUnits))
            status = .running(message, progress)
        }

        updateProgress(message: "Creating routines…")

        // Cache routines by weekday
        var routinesByDay: [Int: SetDeckRoutine] = [:]
        for day in grouped.keys.sorted() {
            let routine = SetDeckRoutine(day: day, lastUpdated: Date())
            context.insert(routine)
            routinesByDay[day] = routine
            processed += 1
            updateProgress(message: "Created routine for day \(day)")
        }

        updateProgress(message: "Migrating exercises…")

        print("Found \(legacyExercises.count) exercises to migrate")
        for exercise in legacyExercises {
            guard let routine = routinesByDay[exercise.weekday] else { continue }

            let newExercise = SetDeckExercise(
                name: exercise.name,
                note: nil,
                videoURL: nil,
                isWarmup: false,
                muscleGroups: [],
                equipment: nil,
                orderIndex: exercise.orderIndex
            )
            newExercise.routine = routine
            context.insert(newExercise)
            processed += 1
            updateProgress(message: "Migrating exercise: \(exercise.name)")

            // Migrate sets for this exercise
            let legacySets = exercise.exerciseSets ?? []
            for (idx, eset) in legacySets.enumerated() {
                let newSet = SetDeckSet()

                switch eset.goalType {
                case .weight:
                    newSet.setType = .reps
                    newSet.targetReps = eset.repetitionsToDo
                    newSet.weight = Double(eset.weightToLift)
                    newSet.targetDuration = nil
                case .duration:
                    newSet.setType = .duration
                    newSet.targetDuration = TimeInterval(eset.durationToDo)
                    newSet.targetReps = nil
                    newSet.weight = nil
                }

                newSet.orderIndex = idx
                newSet.exercise = newExercise

                context.insert(newSet)
                processed += 1
                updateProgress(message: "Added set #\(idx + 1) for \(exercise.name)")
            }
        }

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: AppStorageKeys.hasMigratedFromReadySet)
            status = .completed
        } catch {
            status = .failed("Failed to save migrated data: \(error.localizedDescription)")
            throw error
        }
    }
}

