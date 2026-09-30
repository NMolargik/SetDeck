//
//  SampleWorkoutData.swift
//  SetDeckData
//
//  DEBUG-only generator of ~30 days of realistic routines, sets, and progressive
//  history — used by the Settings debug menu, previews, and screenshots.
//

#if DEBUG
import Foundation
import SetDeckCore
import os

@MainActor
public struct SampleWorkoutData: GenerateSampleData {

    private let routines: any RoutineRepository
    private let history: any HistoryRepository

    public init(routines: any RoutineRepository, history: any HistoryRepository) {
        self.routines = routines
        self.history = history
    }

    private static let baseExerciseNames: [String] = [
        "Back Squat", "Front Squat", "Romanian Deadlift", "Deadlift",
        "Bench Press", "Incline Bench Press", "Overhead Press", "Dumbbell Press",
        "Barbell Row", "Seated Cable Row", "Lat Pulldown", "Pull-Up",
        "Hip Thrust", "Leg Press", "Bulgarian Split Squat", "Lunge",
        "Bicep Curl", "Hammer Curl", "Tricep Pushdown", "Skullcrusher",
        "Face Pull", "Lateral Raise", "Plank", "Hanging Leg Raise",
        "Farmer Carry", "Kettlebell Swing", "Calf Raise",
    ]

    /// Generates one workout per day for the last 30 days with slow progressive
    /// overload. Aborts (without change) when any history already exists.
    public func callAsFunction() throws(PersistenceError) {
        try generateLast30Days()
    }

    public func generateLast30Days() throws(PersistenceError) {
        Log.workouts.info("Starting sample data generation for last 30 days")

        guard try history.allHistory().isEmpty else {
            Log.workouts.info("Sample generation aborted: history already exists")
            return
        }

        try configureBaselineProgramIfNeeded()

        var perDaySets: [Int: [SetDeckSet]] = [:]
        for day in 0...6 {
            let routine = try routines.routine(forDay: day)
            let dayExercises = try routines.exercises(for: routine)
            var daySets: [SetDeckSet] = []
            for exercise in dayExercises {
                daySets.append(contentsOf: try routines.sets(for: exercise))
            }
            perDaySets[day] = daySets
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -29, to: today) else {
            Log.workouts.error("Failed to compute start date for sample data")
            return
        }

        for dayOffset in 0..<30 {
            guard let workoutDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate),
                  let daySets = perDaySets[dayOffset % 7]
            else { continue }

            for set in daySets {
                let sessionIndex = set.history?.count ?? 0

                let baseReps = set.targetReps ?? 8
                let baseWeight = set.weight ?? 40.0
                let baseRpe = set.rpe ?? 6

                // Progression: up to +3 reps and +15 lb over the month, RPE creeping up.
                let actualReps = baseReps + min(3, sessionIndex)
                let actualWeight = baseWeight + min(15.0, Double(sessionIndex) * 2.5)
                let actualRpe = min(10, baseRpe + min(3, sessionIndex / 2))

                let note: String? = switch sessionIndex % 4 {
                case 0: "Felt solid today."
                case 1: "A bit challenging, but manageable."
                case 2: "Great energy, strong sets."
                default: "Slight fatigue, kept form tight."
                }

                _ = try history.recordHistory(
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

                // Nudge targets toward the latest performance so the base program improves.
                try routines.updateSet(set) { s in
                    s.targetReps = actualReps
                    s.weight = actualWeight
                    s.rpe = actualRpe
                }
            }
        }

        Log.workouts.info("Sample data generation complete")
    }

    /// 7 routines (0–6) with ~8–12 exercises each and 1–3 configured sets, respecting
    /// any program the user already built.
    private func configureBaselineProgramIfNeeded() throws(PersistenceError) {
        for day in 0...6 {
            let routine = try routines.routine(forDay: day)
            guard try routines.exercises(for: routine).isEmpty else { continue }

            let exerciseCount = 8 + (day % 5)  // 8–12
            for index in 0..<exerciseCount {
                let nameIndex = (index + day * 3) % Self.baseExerciseNames.count
                let isWarmup = (index == 0)

                let exercise = try routines.addExercise(
                    named: Self.baseExerciseNames[nameIndex],
                    toDay: day,
                    isWarmup: isWarmup,
                    note: isWarmup ? "Warm-up focus, lighter weight" : nil
                )

                // Each exercise gets 1–3 sets (addExercise created 1 default).
                var currentSets = try routines.sets(for: exercise)
                let desiredSetCount = 1 + ((index + day) % 3)
                if currentSets.count < desiredSetCount {
                    for _ in currentSets.count..<desiredSetCount {
                        _ = try routines.addSet(
                            to: exercise,
                            setType: .reps,
                            targetReps: 8,
                            weight: 45,
                            targetDuration: nil,
                            setDescription: nil,
                            rpe: 6
                        )
                    }
                }

                currentSets = try routines.sets(for: exercise)
                let baseWeight = 40.0 + Double(day * 5 + index * 3)
                for (setIndex, set) in currentSets.enumerated() {
                    try routines.updateSet(set) { s in
                        s.setType = .reps
                        s.targetReps = 6 + ((setIndex + index) % 5)
                        s.weight = baseWeight + Double(setIndex * 5)
                        s.rpe = 6 + ((setIndex + day) % 3)
                    }
                }
            }
        }
    }
}
#endif
