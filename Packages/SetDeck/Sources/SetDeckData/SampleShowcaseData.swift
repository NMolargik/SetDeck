//
//  SampleShowcaseData.swift
//  SetDeckData
//
//  DEBUG-only "showcase" seed for App Store preview videos (`-uiTesting -sdShowcase`):
//  a full week of routines where today is a heavy push day (Bench Press first, five
//  ramping sets), plus ~90 days of rising-volume history so charts climb, records look
//  earned, and most achievements are unlocked. Compiled out of shipping builds.
//

#if DEBUG
import Foundation
import SetDeckCore

extension SampleWorkoutData {

    private struct Lift {
        let name: String
        let muscles: [MuscleGroup]
        let equipment: String
        /// Per-set (reps, fraction of the top weight); a timed lift uses `hold` instead.
        let sets: [(reps: Int, fraction: Double)]
        let top: Double
        var hold: Double? = nil

        static func even(_ name: String, _ muscles: [MuscleGroup], _ equipment: String,
                         sets: Int, reps: Int, top: Double) -> Lift {
            Lift(name: name, muscles: muscles, equipment: equipment,
                 sets: Array(repeating: (reps, 1.0), count: sets), top: top)
        }

        static func ramp(_ name: String, _ muscles: [MuscleGroup], _ equipment: String,
                         reps: [Int], fractions: [Double], top: Double) -> Lift {
            Lift(name: name, muscles: muscles, equipment: equipment,
                 sets: Array(zip(reps, fractions)).map { ($0, $1) }, top: top)
        }

        static func timed(_ name: String, _ muscles: [MuscleGroup], sets: Int, seconds: Double) -> Lift {
            Lift(name: name, muscles: muscles, equipment: "Bodyweight",
                 sets: Array(repeating: (0, 0), count: sets), top: 0, hold: seconds)
        }
    }

    /// Seven day templates, indexed by days after today (0 = today).
    private static let templates: [[Lift]] = [
        // 0: Push (today)
        [
            .ramp("Bench Press", [.chest, .shoulders, .triceps], "Barbell",
                  reps: [8, 5, 5, 5, 5], fractions: [0.65, 0.8, 0.9, 1, 1], top: 225),
            .even("Incline Dumbbell Press", [.chest, .shoulders, .triceps], "Dumbbell", sets: 4, reps: 8, top: 80),
            .even("Overhead Press", [.shoulders, .triceps], "Barbell", sets: 4, reps: 6, top: 135),
            .even("Cable Fly", [.chest], "Cable", sets: 3, reps: 12, top: 40),
            .even("Lateral Raise", [.shoulders], "Dumbbell", sets: 3, reps: 15, top: 25),
            .even("Tricep Pushdown", [.triceps], "Cable", sets: 3, reps: 12, top: 60),
            .even("Skullcrusher", [.triceps], "Barbell", sets: 3, reps: 10, top: 70),
        ],
        // 1: Pull
        [
            .ramp("Deadlift", [.back, .hamstrings, .glutes, .lowerBack], "Barbell",
                  reps: [5, 3, 3, 3, 3], fractions: [0.55, 0.7, 0.85, 1, 1], top: 365),
            .even("Barbell Row", [.back, .lats, .biceps], "Barbell", sets: 4, reps: 8, top: 155),
            .even("Pull-Up", [.lats, .biceps], "Weighted", sets: 4, reps: 8, top: 25),
            .even("Lat Pulldown", [.lats, .biceps], "Cable", sets: 3, reps: 10, top: 130),
            .even("Seated Cable Row", [.back, .lats], "Cable", sets: 3, reps: 12, top: 120),
            .even("Face Pull", [.shoulders, .traps, .rotatorCuff], "Cable", sets: 3, reps: 15, top: 50),
            .even("Hammer Curl", [.biceps, .forearms], "Dumbbell", sets: 3, reps: 10, top: 40),
        ],
        // 2: Legs
        [
            .ramp("Back Squat", [.quads, .glutes, .hamstrings], "Barbell",
                  reps: [8, 5, 5, 5, 5], fractions: [0.55, 0.7, 0.85, 1, 1], top: 315),
            .even("Romanian Deadlift", [.hamstrings, .glutes, .lowerBack], "Barbell", sets: 4, reps: 8, top: 225),
            .even("Leg Press", [.quads, .glutes], "Machine", sets: 4, reps: 12, top: 360),
            .even("Bulgarian Split Squat", [.quads, .glutes], "Dumbbell", sets: 3, reps: 10, top: 60),
            .even("Hip Thrust", [.glutes, .hamstrings], "Barbell", sets: 3, reps: 10, top: 275),
            .even("Calf Raise", [.calves], "Machine", sets: 4, reps: 15, top: 140),
        ],
        // 3: Upper
        [
            .even("Incline Bench Press", [.chest, .shoulders, .triceps], "Barbell", sets: 4, reps: 8, top: 175),
            .even("Pull-Up", [.lats, .biceps], "Weighted", sets: 4, reps: 6, top: 35),
            .even("Dumbbell Press", [.chest, .shoulders, .triceps], "Dumbbell", sets: 3, reps: 10, top: 75),
            .even("Seated Cable Row", [.back, .lats], "Cable", sets: 3, reps: 10, top: 130),
            .even("Bicep Curl", [.biceps], "Dumbbell", sets: 3, reps: 12, top: 35),
            .even("Lateral Raise", [.shoulders], "Dumbbell", sets: 3, reps: 15, top: 25),
        ],
        // 4: Lower + core
        [
            .even("Front Squat", [.quads, .glutes, .abs], "Barbell", sets: 4, reps: 6, top: 205),
            .even("Hip Thrust", [.glutes, .hamstrings], "Barbell", sets: 4, reps: 8, top: 295),
            .even("Lunge", [.quads, .glutes], "Dumbbell", sets: 3, reps: 12, top: 50),
            .even("Hanging Leg Raise", [.abs, .obliques], "Bodyweight", sets: 3, reps: 12, top: 0),
            .timed("Plank", [.abs, .obliques], sets: 3, seconds: 60),
        ],
        // 5: Conditioning
        [
            .even("Kettlebell Swing", [.glutes, .hamstrings, .fullBody], "Kettlebell", sets: 5, reps: 20, top: 53),
            .timed("Farmer Carry", [.forearms, .traps, .fullBody], sets: 4, seconds: 45),
            .even("Face Pull", [.shoulders, .traps, .rotatorCuff], "Cable", sets: 3, reps: 15, top: 45),
            .timed("Plank", [.abs, .obliques], sets: 3, seconds: 60),
        ],
        // 6: Active recovery
        [
            .even("Lateral Raise", [.shoulders], "Dumbbell", sets: 3, reps: 15, top: 20),
            .even("Hammer Curl", [.biceps, .forearms], "Dumbbell", sets: 3, reps: 12, top: 35),
            .even("Face Pull", [.shoulders, .traps, .rotatorCuff], "Cable", sets: 3, reps: 15, top: 40),
            .timed("Plank", [.abs, .obliques], sets: 3, seconds: 45),
        ],
    ]

    private static func rounded(_ w: Double) -> Double { (w / 5).rounded() * 5 }

    /// Builds the showcase program and 90 days of history ending yesterday (today's
    /// deck is untouched so sets can be logged live).
    public func generateShowcase() throws(PersistenceError) {
        guard try history.allHistory().isEmpty else { return }

        let calendar = Calendar.current
        let todayIndex = (calendar.component(.weekday, from: Date()) - 1 + 7) % 7
        let today = calendar.startOfDay(for: Date())

        // Program: templates laid onto the weekdays, today first.
        var setsByTemplate: [[[SetDeckSet]]] = []   // [template][exercise][set]
        for (t, lifts) in Self.templates.enumerated() {
            let day = (todayIndex + t) % 7
            let routine = try routines.routine(forDay: day)
            for exercise in try routines.exercises(for: routine) { try routines.deleteExercise(exercise) }

            var exerciseSets: [[SetDeckSet]] = []
            for lift in lifts {
                let exercise = try routines.addExercise(named: lift.name, toDay: day, isWarmup: false, note: nil)
                try routines.updateExercise(exercise) { e in
                    e.muscleGroups = lift.muscles
                    e.equipment = lift.equipment
                }
                var sets = try routines.sets(for: exercise)
                while sets.count < lift.sets.count {
                    _ = try routines.addSet(to: exercise, setType: .reps, targetReps: 8, weight: 0,
                                            targetDuration: nil, setDescription: nil, rpe: 8)
                    sets = try routines.sets(for: exercise)
                }
                for (i, set) in sets.enumerated() {
                    let spec = lift.sets[i]
                    try routines.updateSet(set) { s in
                        if let hold = lift.hold {
                            s.setType = .duration
                            s.targetReps = nil
                            s.weight = nil
                            s.targetDuration = hold
                        } else {
                            s.setType = .reps
                            s.targetReps = spec.reps
                            s.weight = Self.rounded(lift.top * spec.fraction)
                        }
                        s.rpe = 8
                    }
                }
                exerciseSets.append(sets)
            }
            setsByTemplate.append(exerciseSets)
        }

        // History: 90 days, strength rising from ~62% to ~100% of today's targets.
        for d in stride(from: 90, through: 1, by: -1) {
            if d > 34 && (d % 11 == 0 || d % 13 == 0) { continue }   // a few rest days early on
            guard let date = calendar.date(byAdding: .day, value: -d, to: today) else { continue }
            let t = ((7 - d % 7) % 7)
            let progress = 1 - Double(d) / 90
            let factor = 0.62 + 0.38 * progress
            var minute = 0
            for (li, lift) in Self.templates[t].enumerated() {
                for (si, set) in setsByTemplate[t][li].enumerated() {
                    let when = date.addingTimeInterval(17 * 3600 + Double(minute) * 150)
                    minute += 1
                    let rpe = 7 + (d + si) % 3
                    if let hold = lift.hold {
                        let actual = (hold * (0.75 + 0.25 * progress) / 5).rounded() * 5
                        _ = try history.recordHistory(
                            for: set, completedDate: when, actualReps: nil, actualWeight: nil,
                            actualWeightUnit: nil, actualDuration: actual, actualDescription: nil,
                            actualRpe: rpe, note: nil)
                    } else {
                        let spec = lift.sets[si]
                        let weight = lift.top == 0 ? 0 : Self.rounded(lift.top * spec.fraction * factor)
                        let reps = max(1, spec.reps - ((d + si) % 6 == 0 ? 1 : 0))
                        _ = try history.recordHistory(
                            for: set, completedDate: when, actualReps: reps, actualWeight: weight,
                            actualWeightUnit: "lb", actualDuration: nil, actualDescription: nil,
                            actualRpe: rpe, note: nil)
                    }
                }
            }
        }
    }
}
#endif
