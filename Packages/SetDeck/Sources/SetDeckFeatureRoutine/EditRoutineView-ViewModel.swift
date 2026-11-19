//
//  EditRoutineView-ViewModel.swift
//  SetDeckFeatureRoutine
//
//  Created by Nick Molargik on 11/25/25.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared

extension EditRoutineView {
    @Observable
    class ViewModel {
        /// Currently selected day index (0 = Sunday)
        var selectedDay: Int = 0

        /// The exercise whose sets are being edited: the trailing pane's subject on iPad / Duo,
        /// the card expanded inline on iPhone. nil means none (compact) or "first" (split).
        var selectedExerciseID: UUID?

        /// Exercise id + name pairs muscle inference already ran for, so removing a chip is not undone.
        var inferenceAttempted: Set<String> = []
        var suggestingIDs: Set<UUID> = []

        /// Index of "today" based on the current calendar weekday
        var todayIndex: Int {
            let weekday = Calendar.current.component(.weekday, from: Date())
            return (weekday - 1 + 7) % 7 // Convert 1...7 (Sun...Sat) to 0...6
        }

        // MARK: - Day Helpers

        func resetToToday() {
            selectedDay = todayIndex
        }

        // MARK: - Data Accessors

        func currentRoutine(using manager: WorkoutDataModel) -> SetDeckRoutine? {
            manager.routine(for: selectedDay)
        }

        func exercises(using manager: WorkoutDataModel) -> [SetDeckExercise] {
            manager.exercises(forDay: selectedDay)
        }

        // MARK: - Exercise Mutations

        /// Adds an exercise (optionally with `sets` default rep sets) and returns it.
        @discardableResult
        func addExercise(named name: String = "New Exercise",
                         sets: Int = 0,
                         using manager: WorkoutDataModel) -> SetDeckExercise? {
            guard let exercise = manager.addExercise(named: name, toDay: selectedDay) else { return nil }
            for _ in 0..<sets { addSet(to: exercise, using: manager) }
            return exercise
        }

        /// Moves one exercise up (-1) or down (+1) and keeps `orderIndex` contiguous.
        func moveExercise(_ exercise: SetDeckExercise,
                          by delta: Int,
                          in exercises: [SetDeckExercise],
                          currentRoutine: SetDeckRoutine?,
                          using manager: WorkoutDataModel) {
            guard let from = exercises.firstIndex(where: { $0.uuid == exercise.uuid }) else { return }
            let to = from + delta
            guard exercises.indices.contains(to) else { return }
            moveExercises(from: IndexSet(integer: from),
                          to: delta > 0 ? to + 1 : to,
                          in: exercises,
                          currentRoutine: currentRoutine,
                          using: manager)
            normalizeOrder(using: manager)
        }

        func deleteExercise(_ exercise: SetDeckExercise, using manager: WorkoutDataModel) {
            if selectedExerciseID == exercise.uuid { selectedExerciseID = nil }
            manager.deleteExercise(exercise)
            normalizeOrder(using: manager)
        }

        /// Renumbers the day's exercises 0…n-1, writing only the ones that changed.
        func normalizeOrder(using manager: WorkoutDataModel) {
            let ordered = exercises(using: manager).sorted { $0.orderIndex < $1.orderIndex }
            for (idx, ex) in ordered.enumerated() where ex.orderIndex != idx {
                manager.updateExercise(ex) { $0.orderIndex = idx }
            }
        }

        func deleteExercises(at offsets: IndexSet,
                             from exercises: [SetDeckExercise],
                             using manager: WorkoutDataModel) {
            let toDelete = offsets.map { exercises[$0] }
            for exercise in toDelete {
                manager.deleteExercise(exercise)
            }
        }

        func moveExercises(from indices: IndexSet,
                           to destination: Int,
                           in exercises: [SetDeckExercise],
                           currentRoutine: SetDeckRoutine?,
                           using manager: WorkoutDataModel) {
            guard let currentRoutine else { return }
            var updated = exercises
            updated.move(fromOffsets: indices, toOffset: destination)
            manager.reorderExercises(in: currentRoutine, newOrder: updated)
        }

        // MARK: - Set Mutations

        func addSet(to exercise: SetDeckExercise,
                    using manager: WorkoutDataModel) {
            // The editor row shows 10 reps for a rep-based set with no target; store it so
            // the card, Watch and history see the same value (otherwise "0 × --" / "Reps").
            _ = manager.addSet(to: exercise, targetReps: 10)
        }

        func deleteSets(at offsets: IndexSet,
                        from sets: [SetDeckSet],
                        using manager: WorkoutDataModel) {
            let toDelete = offsets.map { sets[$0] }
            for set in toDelete {
                manager.deleteSet(set)
            }
        }

        /// Moves the set at `from` to position `to` (both final indices).
        func moveSet(from: Int, to: Int,
                     in sets: [SetDeckSet],
                     exercise: SetDeckExercise,
                     using manager: WorkoutDataModel) {
            guard sets.indices.contains(from), sets.indices.contains(to), from != to else { return }
            moveSets(from: IndexSet(integer: from),
                     to: to > from ? to + 1 : to,
                     in: sets,
                     exercise: exercise,
                     using: manager)
        }

        func moveSets(from indices: IndexSet,
                      to destination: Int,
                      in sets: [SetDeckSet],
                      exercise: SetDeckExercise,
                      using manager: WorkoutDataModel) {
            var updated = sets
            updated.move(fromOffsets: indices, toOffset: destination)
            manager.reorderSets(in: exercise, newOrder: updated)
        }
    }
}
#endif
