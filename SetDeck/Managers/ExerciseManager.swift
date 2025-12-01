//
//  ExerciseManager.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/12/25.
//

import Foundation
import SwiftData
import os.log

@MainActor
@Observable
class ExerciseManager {
    // MARK: - Dependencies
    let context: ModelContext

    // Observed change token to trigger SwiftUI updates when data mutates
    var changeStamp: Int = 0

    // MARK: - Init
    init(context: ModelContext) {
        print("[ExerciseManager] Initializing with context: \(ObjectIdentifier(context))")
        self.context = context

        cleanupDuplicateRoutines()
            
        let histories = self.allHistoryEntries()
        print("[ExerciseManager] Init complete. History count: \(histories.count)")
    }

    // MARK: - Routines
    /// Returns all routines, sorted by day (0...6)
    func allRoutines() -> [SetDeckRoutine] {
        let descriptor = FetchDescriptor<SetDeckRoutine>(
            sortBy: [SortDescriptor(\.day, order: .forward)]
        )
        let results = (try? context.fetch(descriptor)) ?? []
        return results
    }

    /// Returns the routine for a given day. Creates it if missing.
    @discardableResult
    func routine(for day: Int) -> SetDeckRoutine {
        let descriptor = FetchDescriptor<SetDeckRoutine>(
            predicate: #Predicate { $0.day == day },
            sortBy: []
        )
        let fetched = (try? context.fetch(descriptor)) ?? []
        if let routine = fetched.first {
            return routine
        }
        let routine = SetDeckRoutine(day: day)
        context.insert(routine)
        saveContext()
        return routine
    }

    // MARK: - Exercises
    /// Returns exercises for a given day, ordered by orderIndex
    func exercises(forDay day: Int) -> [SetDeckExercise] {
        let predicate = #Predicate<SetDeckExercise> { ex in
            ex.routine?.day == day
        }
        let descriptor = FetchDescriptor<SetDeckExercise>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )
        let results = (try? context.fetch(descriptor)) ?? []
        return results.sorted { lhs, rhs in
            lhs.orderIndex < rhs.orderIndex
        }
    }

    /// Returns exercises for a specific routine, ordered by orderIndex
    func exercises(for routine: SetDeckRoutine) -> [SetDeckExercise] {
        let routineID = routine.uuid
        let predicate = #Predicate<SetDeckExercise> { ex in
            ex.routine?.uuid == routineID
        }
        let descriptor = FetchDescriptor<SetDeckExercise>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )
        let results = (try? context.fetch(descriptor)) ?? []
        return results.sorted { lhs, rhs in
            lhs.orderIndex < rhs.orderIndex
        }
    }

    /// Adds a new exercise to the routine for the specified day
    @discardableResult
    func addExercise(named name: String, toDay day: Int, isWarmup: Bool = false, note: String? = nil) -> SetDeckExercise {
        let routine = routine(for: day)
        let exercise = addExercise(named: name, to: routine, isWarmup: isWarmup, note: note)
        return exercise
    }

    /// Adds a new exercise to the provided routine
    @discardableResult
    func addExercise(named name: String, to routine: SetDeckRoutine, isWarmup: Bool = false, note: String? = nil) -> SetDeckExercise {
        let current = exercises(for: routine)
        let nextIndex = (current.map { $0.orderIndex }.max() ?? -1) + 1
        
        let exercise = SetDeckExercise(name: name, note: note, isWarmup: isWarmup, orderIndex: nextIndex)
        exercise.routine = routine
        
        if routine.exercises == nil { routine.exercises = [] }
        routine.exercises?.append(exercise)
        
        context.insert(exercise)
        routine.lastUpdated = Date()
        
        // Ensure at least one set exists for a new exercise
        _ = addSet(to: exercise,
                   setType: .reps,
                   targetReps: 10,
                   weight: 0,
                   weightUnit: "lb",
                   targetDuration: nil,
                   setDescription: nil,
                   rpe: 6)
        
        return exercise
    }
    
    func updateExercise(_ exercise: SetDeckExercise, configure: (SetDeckExercise) -> Void) {
        configure(exercise)
        if let routine = exercise.routine {
            routine.lastUpdated = Date()
        }
        saveContext()
    }

    /// Renames an exercise
    func renameExercise(_ exercise: SetDeckExercise, to newName: String) {
        exercise.name = newName
        if let routine = exercise.routine {
            routine.lastUpdated = Date()
        }
        saveContext()
    }

    /// Reorders the exercises within a routine, updating each exercise's orderIndex.
    func reorderExercises(in routine: SetDeckRoutine, newOrder: [SetDeckExercise]) {
        for (idx, ex) in newOrder.enumerated() {
            ex.orderIndex = idx
        }
        routine.lastUpdated = Date()
        saveContext()
    }

    /// Deletes an exercise (cascades to its sets)
    func deleteExercise(_ exercise: SetDeckExercise) {
        if let routine = exercise.routine {
            routine.exercises = routine.exercises?.filter { $0.uuid != exercise.uuid }
            routine.lastUpdated = Date()
            // Reindex remaining exercises
            let ordered = exercises(for: routine)
            for (idx, ex) in ordered.enumerated() {
                ex.orderIndex = idx
            }
        }
        context.delete(exercise)
        saveContext()
    }

    // MARK: - Sets
    /// Returns sets for an exercise, ordered by orderIndex
    func sets(for exercise: SetDeckExercise) -> [SetDeckSet] {
        let exerciseID = exercise.uuid
        let predicate = #Predicate<SetDeckSet> { set in
            set.exercise?.uuid == exerciseID
        }
        let descriptor = FetchDescriptor<SetDeckSet>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )
        let results = (try? context.fetch(descriptor)) ?? []
        return results.sorted { lhs, rhs in
            lhs.orderIndex < rhs.orderIndex
        }
    }

    /// Adds a new set to an exercise
    @discardableResult
    func addSet(to exercise: SetDeckExercise,
                setType: SetType = .reps,
                targetReps: Int? = nil,
                weight: Double? = nil,
                weightUnit: String? = nil,
                targetDuration: TimeInterval? = nil,
                setDescription: String? = nil,
                rpe: Int? = nil) -> SetDeckSet {
        let current = sets(for: exercise)
        let nextIndex = (current.map { $0.orderIndex }.max() ?? -1) + 1
        
        let set = SetDeckSet(setType: setType,
                             targetReps: targetReps,
                             weight: weight,
                             targetDuration: targetDuration,
                             setDescription: setDescription,
                             rpe: rpe,
                             orderIndex: nextIndex)
        set.exercise = exercise
        if exercise.sets == nil { exercise.sets = [] }
        exercise.sets?.append(set)
        
        context.insert(set)
        if let routine = exercise.routine {
            routine.lastUpdated = Date()
        }
        saveContext()
        return set
    }

    /// Updates a set using a configuration closure and persists changes
    func updateSet(_ set: SetDeckSet, configure: (SetDeckSet) -> Void) {
        configure(set)
        if let routine = set.exercise?.routine {
            routine.lastUpdated = Date()
        }
        saveContext()
    }

    /// Reorders sets within an exercise
    func reorderSets(in exercise: SetDeckExercise, newOrder: [SetDeckSet]) {
        for (idx, s) in newOrder.enumerated() {
            s.orderIndex = idx
        }
        if let routine = exercise.routine {
            routine.lastUpdated = Date()
        }
        saveContext()
    }

    /// Deletes a set (cascades to its history)
    func deleteSet(_ set: SetDeckSet) {
        if let ex = set.exercise {
            ex.sets = ex.sets?.filter { $0.uuid != set.uuid }
            if let routine = ex.routine {
                routine.lastUpdated = Date()
            }
            // Reindex remaining sets
            let ordered = sets(for: ex)
            for (idx, s) in ordered.enumerated() {
                s.orderIndex = idx
            }
        }
        context.delete(set)
        saveContext()
    }

    // MARK: - History

    /// Returns all SetDeckSetHistory entries, sorted by completion date.
    /// This is useful for analytics and trend views such as StatsView.
    func allHistoryEntries() -> [SetDeckSetHistory] {
        let descriptor = FetchDescriptor<SetDeckSetHistory>(
            sortBy: [SortDescriptor(\.completedDate, order: .forward)]
        )
        let results = (try? context.fetch(descriptor)) ?? []
        return results
    }

    /// Returns history entries for all sets belonging to the given exercise,
    /// sorted by completion date.
    func history(for exercise: SetDeckExercise) -> [SetDeckSetHistory] {
        let exerciseID = exercise.uuid
        let predicate = #Predicate<SetDeckSetHistory> { history in
            history.set?.exercise?.uuid == exerciseID
        }
        let descriptor = FetchDescriptor<SetDeckSetHistory>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.completedDate, order: .forward)]
        )
        let results = (try? context.fetch(descriptor)) ?? []
        return results
    }

    /// Records a history entry for a set (e.g., when completing a workout)
    @discardableResult
    func recordHistory(for set: SetDeckSet,
                       completedDate: Date = Date(),
                       actualReps: Int? = nil,
                       actualWeight: Double? = nil,
                       actualWeightUnit: String? = nil,
                       actualDuration: TimeInterval? = nil,
                       actualDescription: String? = nil,
                       actualRpe: Int? = nil,
                       note: String? = nil) -> SetDeckSetHistory {
        let history = SetDeckSetHistory(completedDate: completedDate,
                                        actualReps: actualReps,
                                        actualWeight: actualWeight,
                                        actualWeightUnit: actualWeightUnit,
                                        actualDuration: actualDuration,
                                        actualDescription: actualDescription,
                                        actualRpe: actualRpe,
                                        note: note)
        history.set = set
        if set.history == nil { set.history = [] }
        set.history?.append(history)
        context.insert(history)
        if let routine = set.exercise?.routine {
            routine.lastUpdated = Date()
        }
        saveContext()
        return history
    }

    /// Updates a set with the provided values and records a history entry.
    /// This is called from UI when a user taps Save on a set edit.
    func update(set: SetDeckSet, withReps reps: Int?, weight: Double?, rpe: Int?) {
        // Update the set's target values first and persist
        updateSet(set) { s in
            if let reps = reps {
                s.targetReps = reps
            }
            if let weight = weight {
                s.weight = weight
            }
            if let rpe = rpe {
                let clamped = max(0, rpe)
                s.rpe = clamped
            }
        }

        // Record a history entry using the values just entered.
        // For duration-based sets, also capture the current targetDuration as the actualDuration.
        _ = recordHistory(
            for: set,
            completedDate: Date(),
            actualReps: reps,
            actualWeight: weight,
            actualWeightUnit: nil,
            actualDuration: (set.setType == .duration ? set.targetDuration : nil),
            actualDescription: nil,
            actualRpe: rpe,
            note: nil
        )
    }

    // MARK: - Bulk Operations
    /// Clears all historical set data from the store.
    /// This removes all `SetDeckSetHistory` entries and detaches them from their parent sets.
    func clearAllHistory() {
        let descriptor = FetchDescriptor<SetDeckSetHistory>()
        let allHistory = (try? context.fetch(descriptor)) ?? []

        guard !allHistory.isEmpty else {
            return
        }

        for history in allHistory {
            if let set = history.set {
                set.history = set.history?.filter { $0.uuid != history.uuid }
            }
            context.delete(history)
        }

        // Persist changes
        saveContext()
    }

    // MARK: - Sample Data Generation (Development / Previews)
    /// Generates ~30 days of realistic-looking routines, sets, and history data.
    /// - Note: This function is intended for development / preview use only.
    /// It will:
    ///   • Ensure each of the 7 routines (0–6) has ~8–12 exercises.
    ///   • Ensure each exercise has between 1 and 3 sets.
    ///   • Generate one workout per day for the last 30 days, mapping dayIndex % 7 → routine day.
    ///   • For every set, create history entries that slowly increase reps/weight over time.
    func generateSampleDataForLast30Days() {
        print("[ExerciseManager] Starting sample data generation for last 30 days…")

        // Avoid exploding data if this function is called multiple times.
        // If you want to regenerate from scratch, clearAllHistory() and/or delete routines first.
        let existingHistory = allHistoryEntries()
        if !existingHistory.isEmpty {
            print("[ExerciseManager] Sample generation aborted: history already exists (\(existingHistory.count) entries).")
            return
        }

        // 1. Ensure we have a baseline program: 7 routines (0–6), each with ~8–12 exercises,
        //    and each exercise has 1–3 sets configured with reasonable starting targets.
        let baseExerciseNames: [String] = [
            "Back Squat", "Front Squat", "Romanian Deadlift", "Deadlift",
            "Bench Press", "Incline Bench Press", "Overhead Press", "Dumbbell Press",
            "Barbell Row", "Seated Cable Row", "Lat Pulldown", "Pull-Up",
            "Hip Thrust", "Leg Press", "Bulgarian Split Squat", "Lunge",
            "Bicep Curl", "Hammer Curl", "Tricep Pushdown", "Skullcrusher",
            "Face Pull", "Lateral Raise", "Plank", "Hanging Leg Raise",
            "Farmer Carry", "Kettlebell Swing", "Calf Raise"
        ]

        func configureBaselineProgramIfNeeded() {
            for day in 0...6 {
                let routine = routine(for: day)
                let currentExercises = exercises(for: routine)
                guard currentExercises.isEmpty else {
                    // Respect any existing program the user may have set up.
                    continue
                }

                // Make 8–12 exercises depending on the day to vary things slightly.
                let exerciseCount = 8 + (day % 5)  // 8–12
                for index in 0..<exerciseCount {
                    let nameIndex = (index + day * 3) % baseExerciseNames.count
                    let exerciseName = baseExerciseNames[nameIndex]
                    let isWarmup = (index == 0)

                    let exercise = addExercise(
                        named: exerciseName,
                        to: routine,
                        isWarmup: isWarmup,
                        note: isWarmup ? "Warm-up focus, lighter weight" : nil
                    )

                    // Ensure each exercise has 1–3 sets (addExercise creates 1 default set).
                    var currentSets = sets(for: exercise)
                    let desiredSetCount = 1 + ((index + day) % 3) // 1–3 sets

                    if currentSets.count < desiredSetCount {
                        for _ in currentSets.count..<desiredSetCount {
                            _ = addSet(
                                to: exercise,
                                setType: .reps,
                                targetReps: 8,
                                weight: 45,
                                weightUnit: "lb",
                                targetDuration: nil,
                                setDescription: nil,
                                rpe: 6
                            )
                        }
                    }

                    // Configure reasonable starting targets for each set.
                    currentSets = sets(for: exercise)
                    let baseWeight = 40.0 + Double(day * 5 + index * 3) // e.g. 40–100 lb range
                    for (setIndex, set) in currentSets.enumerated() {
                        let startingReps = 6 + ((setIndex + index) % 5) // 6–10 reps
                        let startingWeight = baseWeight + Double(setIndex * 5)
                        let startingRpe = 6 + ((setIndex + day) % 3)    // RPE 6–8

                        updateSet(set) { s in
                            s.setType = .reps
                            s.targetReps = startingReps
                            s.weight = startingWeight
                            s.rpe = startingRpe
                        }
                    }
                }
            }
        }

        configureBaselineProgramIfNeeded()

        // 2. Build a stable list of sets we will train by routine/day-of-week.
        struct RoutineSets {
            let routine: SetDeckRoutine
            let exercises: [SetDeckExercise]
            let sets: [SetDeckSet]
        }

        var perDayRoutineSets: [Int: RoutineSets] = [:] // key: day 0–6
        for day in 0...6 {
            let routine = routine(for: day)
            let dayExercises = exercises(for: routine)
            let daySets = dayExercises.flatMap { sets(for: $0) }
            let routineSets = RoutineSets(routine: routine, exercises: dayExercises, sets: daySets)
            perDayRoutineSets[day] = routineSets
        }

        // 3. For each of the last 30 days, pick the routine based on dayIndex % 7 and
        //    create a history entry for each set, slowly increasing reps/weight over time.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -29, to: today) else {
            print("[ExerciseManager] Failed to compute start date for sample data.")
            return
        }

        for dayOffset in 0..<30 {
            guard let workoutDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }

            let routineDayIndex = dayOffset % 7
            guard let routineSets = perDayRoutineSets[routineDayIndex] else { continue }

            for set in routineSets.sets {
                // Use the number of past history entries for this set as a "session index"
                // to drive slow, progressive overload.
                let previousSessions = set.history?.count ?? 0
                let sessionIndex = previousSessions // 0, 1, 2, ...

                let baseReps = set.targetReps ?? 8
                let baseWeight = set.weight ?? 40.0
                let baseRpe = set.rpe ?? 6

                // Progression: add up to +3 reps and +15 lb over the month,
                // with slightly higher RPE as sessions accumulate.
                let repsIncrement = min(3, sessionIndex)
                let weightIncrement = min(15.0, Double(sessionIndex) * 2.5)
                let rpeIncrement = min(3, sessionIndex / 2)

                let actualReps = baseReps + repsIncrement
                let actualWeight = baseWeight + weightIncrement
                let actualRpe = min(10, baseRpe + rpeIncrement)

                let note: String?
                switch sessionIndex % 4 {
                case 0: note = "Felt solid today."
                case 1: note = "A bit challenging, but manageable."
                case 2: note = "Great energy, strong sets."
                default: note = "Slight fatigue, kept form tight."
                }

                _ = recordHistory(
                    for: set,
                    completedDate: workoutDate,
                    actualReps: actualReps,
                    actualWeight: actualWeight,
                    actualWeightUnit: "lb",
                    actualDuration: nil,
                    actualDescription: nil,
                    actualRpe: actualRpe,
                    note: note
                )

                // Optionally nudge the set's targets toward the most recent performance
                // to make the base program itself slowly improve over time.
                updateSet(set) { s in
                    s.targetReps = actualReps
                    s.weight = actualWeight
                    s.rpe = actualRpe
                }
            }
        }

        print("[ExerciseManager] Sample data generation complete. History count: \(allHistoryEntries().count)")
    }

    // MARK: - Private helpers
    private func ensureSevenRoutines() {
        let existing = (try? context.fetch(FetchDescriptor<SetDeckRoutine>())) ?? []
        let have = Set(existing.map { $0.day })
        var created = false
        for day in 0...6 {
            if !have.contains(day) {
                let r = SetDeckRoutine(day: day)
                context.insert(r)
                created = true
            }
        }
        if created {
            saveContext()
        }
    }

    private func saveContext() {
        do {
            try context.save()
            // Bump change stamp so SwiftUI views depending on ExerciseManager refresh
            changeStamp &+= 1
        } catch {
            // Non-fatal in SwiftData; log for debugging
            print("[ExerciseManager] Failed to save context: \(error)")
        }
    }
    
    private func cleanupDuplicateRoutines() {
        let allRoutinesDesc = FetchDescriptor<SetDeckRoutine>(sortBy: [SortDescriptor(\.day)])
        guard let allRoutines = try? context.fetch(allRoutinesDesc), allRoutines.count > 7 else { return }
        
        var primaryRoutines: [Int: SetDeckRoutine] = [:]
        var toDelete: [SetDeckRoutine] = []
        
        // Group by day, pick first as primary
        for routine in allRoutines {
            if primaryRoutines[routine.day] == nil {
                primaryRoutines[routine.day] = routine
            } else {
                toDelete.append(routine)
            }
        }
        
        // For each duplicate: Reassign exercises to primary, then delete
        for dupe in toDelete {
            guard let primary = primaryRoutines[dupe.day] else { continue }
            
            // Reassign exercises
            let dupeExercises = exercises(for: dupe)  // Uses UUID predicate
            for ex in dupeExercises {
                ex.routine = primary
            }
            
            // Cascade delete dupe (exercises now safe)
            context.delete(dupe)
        }
        
        saveContext()
    }
}
