//
//  RoutineEditorSupport.swift
//  SetDeckFeatureRoutine
//
//  Pure helpers for the routine editor: muscle-group and set-type presentation, the
//  routine "at a glance" summary, and compact set formatting for the pills on cards.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckServices

// MARK: - Muscle group presentation

/// Muscle groups are coloured by body region so a day's chips read as "push / pull / legs / core".
enum MuscleRegion {
    case push, pull, legs, core, whole

    init(_ group: MuscleGroup) {
        switch group {
        case .chest, .shoulders, .triceps: self = .push
        case .back, .lats, .traps, .biceps, .forearms, .rotatorCuff: self = .pull
        case .quads, .hamstrings, .glutes, .calves: self = .legs
        case .abs, .obliques, .lowerBack, .serratus, .neck: self = .core
        case .fullBody, .cardio: self = .whole
        }
    }

    var color: Color {
        switch self {
        case .push: .orangeStart
        case .pull: .blueStart
        case .legs: .greenStart
        case .core: .purpleStart
        case .whole: Color(red: 0xF2 / 255, green: 0x6B / 255, blue: 0x8A / 255)
        }
    }

    var icon: String {
        switch self {
        case .push: "figure.strengthtraining.traditional"
        case .pull: "figure.rower"
        case .legs: "figure.run"
        case .core: "figure.core.training"
        case .whole: "figure.mixed.cardio"
        }
    }

    var title: String {
        switch self {
        case .push: String(localized: "Push")
        case .pull: String(localized: "Pull")
        case .legs: String(localized: "Legs")
        case .core: String(localized: "Core")
        case .whole: String(localized: "Full Body")
        }
    }
}

extension MuscleGroup {
    var region: MuscleRegion { MuscleRegion(self) }
    var editorColor: Color { region.color }
    var editorIcon: String { region.icon }
}

/// One presentation of an exercise (muscle groups -> icon and colour) shared by the deck card
/// and the routine editor, so the same exercise always looks the same.
extension SetDeckExercise {
    /// The exercise's own muscle groups, else a best guess from its name.
    var presentationGroups: [MuscleGroup] {
        muscleGroups.isEmpty ? (ExerciseMuscleHeuristics.groups(for: name) ?? []) : muscleGroups
    }
    func presentationTint(fallback: Color = .blueStart) -> Color {
        presentationGroups.first?.editorColor ?? fallback
    }
    var presentationIcon: String {
        presentationGroups.first?.editorIcon ?? (isWarmup ? "flame.fill" : "dumbbell.fill")
    }
}

extension SetType {
    var editorColor: Color {
        switch self {
        case .reps: .blueStart
        case .amap: .orangeStart
        case .duration: .greenStart
        case .freeform: .purpleStart
        }
    }

    var editorIcon: String {
        switch self {
        case .reps: "repeat"
        case .amap: "infinity"
        case .duration: "timer"
        case .freeform: "pencil.and.scribble"
        }
    }

    var editorTitle: String {
        switch self {
        case .reps: String(localized: "Reps")
        case .amap: String(localized: "AMAP")
        case .duration: String(localized: "Timed")
        case .freeform: String(localized: "Freeform")
        }
    }
}

// MARK: - Formatting

enum EditorFormat {
    static let poundsPerKilogram = 2.20462262185

    /// Weights are stored in pounds; this returns the value in the user's unit.
    static func displayWeight(_ lbs: Double, metric: Bool) -> Double {
        metric ? lbs / poundsPerKilogram : lbs
    }

    static func weightString(_ value: Double) -> String {
        value.rounded() == value ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }

    static func unit(metric: Bool) -> String { metric ? "kg" : "lbs" }

    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60, s = total % 60
        return s == 0 ? String(localized: "\(m) min") : String(format: "%d:%02d", m, s)
    }

    /// Short text for a set pill, e.g. "10 × 135", "12+ × 25", "1 min", "Freeform".
    static func pillText(for set: SetDeckSet, metric: Bool) -> String {
        switch set.setType {
        case .reps, .amap:
            let reps = set.targetReps ?? 10
            let repsText = set.setType == .amap ? "\(reps)+" : "\(reps)"
            if let w = set.weight, w > 0 {
                return "\(repsText) × \(weightString(displayWeight(w, metric: metric)))"
            }
            return String(localized: "\(repsText) reps")
        case .duration:
            return duration(set.targetDuration ?? 60)
        case .freeform:
            return String(localized: "Freeform")
        }
    }

    /// Spoken description of a set for VoiceOver.
    static func spokenText(for set: SetDeckSet, number: Int, metric: Bool) -> String {
        let kind = set.setType.editorTitle
        var parts = [String(localized: "Set \(number)"), kind, pillText(for: set, metric: metric)]
        if let rpe = set.rpe, set.setType != .freeform || rpe > 0 { parts.append(String(localized: "RPE \(rpe)")) }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Routine summary

/// The numbers shown in the editor header. Time is an estimate: rep sets are ~4 s per rep plus
/// 90 s rest, timed sets run their duration plus 60 s rest, freeform sets count as 2 minutes.
struct RoutineSummary: Equatable {
    var exerciseCount = 0
    var setCount = 0
    var warmupCount = 0
    /// Total reps × weight, in pounds (the stored unit).
    var volumeLbs: Double = 0
    var estimatedSeconds: TimeInterval = 0
    /// Muscle groups covered, most frequently trained first.
    var muscleGroups: [MuscleGroup] = []

    init() {}

    init(exercises: [SetDeckExercise],
         sets: [UUID: [SetDeckSet]],
         inferred: [UUID: [MuscleGroup]] = [:]) {
        exerciseCount = exercises.count
        var counts: [MuscleGroup: Int] = [:]
        for exercise in exercises {
            if exercise.isWarmup { warmupCount += 1 }
            let exerciseSets = sets[exercise.uuid] ?? []
            setCount += exerciseSets.count
            let groups = exercise.muscleGroups.isEmpty ? (inferred[exercise.uuid] ?? []) : exercise.muscleGroups
            for g in groups { counts[g, default: 0] += max(1, exerciseSets.count) }
            for set in exerciseSets {
                switch set.setType {
                case .reps, .amap:
                    let reps = Double(set.targetReps ?? 10)
                    volumeLbs += reps * (set.weight ?? 0)
                    estimatedSeconds += reps * 4 + 90
                case .duration:
                    estimatedSeconds += (set.targetDuration ?? 60) + 60
                case .freeform:
                    estimatedSeconds += 120
                }
            }
        }
        muscleGroups = counts
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key.rawValue < $1.key.rawValue }
            .map(\.key)
    }

    var estimatedMinutes: Int { Int((estimatedSeconds / 60).rounded()) }

    /// The dominant body region, used for a subtitle like "Push focus".
    var focus: MuscleRegion? {
        var tally: [MuscleRegion: Int] = [:]
        for g in muscleGroups { tally[g.region, default: 0] += 1 }
        return tally.max { $0.value < $1.value }?.key
    }
}

extension MuscleRegion: Hashable {}

enum EditorDay {
    static let fullNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    static func name(_ day: Int) -> String {
        fullNames[min(max(day, 0), 6)]
    }
}
#endif
