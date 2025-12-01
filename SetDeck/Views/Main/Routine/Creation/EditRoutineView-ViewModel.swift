//
//  EditRoutineView-ViewModel.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/25/25.
//

import SwiftUI

extension EditRoutineView {
    @Observable
    class ViewModel {
        /// Currently selected day index (0 = Sunday)
        var selectedDay: Int = 0

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

        func currentRoutine(using manager: ExerciseManager) -> SetDeckRoutine {
            manager.routine(for: selectedDay)
        }

        func exercises(using manager: ExerciseManager) -> [SetDeckExercise] {
            manager.exercises(forDay: selectedDay)
        }

        // MARK: - Exercise Mutations

        func addExercise(named name: String = "New Exercise",
                         using manager: ExerciseManager) {
            _ = manager.addExercise(named: name, toDay: selectedDay)
        }

        func deleteExercises(at offsets: IndexSet,
                             from exercises: [SetDeckExercise],
                             using manager: ExerciseManager) {
            let toDelete = offsets.map { exercises[$0] }
            for exercise in toDelete {
                manager.deleteExercise(exercise)
            }
        }

        func moveExercises(from indices: IndexSet,
                           to destination: Int,
                           in exercises: [SetDeckExercise],
                           currentRoutine: SetDeckRoutine,
                           using manager: ExerciseManager) {
            var updated = exercises
            updated.move(fromOffsets: indices, toOffset: destination)
            manager.reorderExercises(in: currentRoutine, newOrder: updated)
        }

        // MARK: - Set Mutations

        func addSet(to exercise: SetDeckExercise,
                    using manager: ExerciseManager) {
            _ = manager.addSet(to: exercise)
        }

        func deleteSets(at offsets: IndexSet,
                        from sets: [SetDeckSet],
                        using manager: ExerciseManager) {
            let toDelete = offsets.map { sets[$0] }
            for set in toDelete {
                manager.deleteSet(set)
            }
        }

        func moveSets(from indices: IndexSet,
                      to destination: Int,
                      in sets: [SetDeckSet],
                      exercise: SetDeckExercise,
                      using manager: ExerciseManager) {
            var updated = sets
            updated.move(fromOffsets: indices, toOffset: destination)
            manager.reorderSets(in: exercise, newOrder: updated)
        }
    }
}
