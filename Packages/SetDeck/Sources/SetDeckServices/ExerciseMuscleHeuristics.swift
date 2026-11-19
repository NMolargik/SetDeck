//
//  ExerciseMuscleHeuristics.swift
//  SetDeckServices
//
//  A pure, instant keyword lookup for the common lifts. The on-device language model
//  is only asked about names this table cannot place, so the Stats muscle analysis no
//  longer waits on one model call per exercise.
//

import Foundation
import SetDeckCore

nonisolated public enum ExerciseMuscleHeuristics {
    /// Ordered, most specific first: the first rule whose keyword appears in the name wins.
    private static let rules: [(keywords: [String], groups: [MuscleGroup])] = [
        (["romanian deadlift", "rdl", "stiff leg", "good morning"], [.hamstrings, .glutes, .lowerBack]),
        (["hip thrust", "glute bridge", "kickback"], [.glutes, .hamstrings]),
        (["bulgarian", "split squat", "lunge", "step up", "step-up"], [.quads, .glutes]),
        (["leg press", "hack squat", "squat", "leg extension"], [.quads, .glutes]),
        (["leg curl", "hamstring"], [.hamstrings]),
        (["calf"], [.calves]),
        (["deadlift", "rack pull"], [.back, .hamstrings, .glutes]),
        (["kettlebell swing", "swing"], [.glutes, .hamstrings]),
        (["farmer", "carry"], [.forearms, .traps]),
        (["incline"], [.chest, .shoulders, .triceps]),
        (["bench", "chest press", "push-up", "pushup", "push up", "fly", "flye", "pec", "dip"], [.chest, .triceps]),
        (["overhead press", "shoulder press", "military press", "dumbbell press", "arnold"], [.shoulders, .triceps]),
        (["lateral raise", "front raise", "rear delt", "upright row"], [.shoulders]),
        (["face pull"], [.shoulders, .traps]),
        (["shrug"], [.traps]),
        (["pulldown", "pull-up", "pullup", "pull up", "chin-up", "chinup", "chin up"], [.lats, .biceps]),
        (["row"], [.back, .lats, .biceps]),
        (["skullcrusher", "skull crusher", "tricep", "triceps", "pushdown", "extension"], [.triceps]),
        (["curl", "bicep", "biceps"], [.biceps, .forearms]),
        (["wrist", "forearm"], [.forearms]),
        (["hanging leg", "leg raise", "crunch", "sit-up", "situp", "sit up", "plank", "ab wheel", "rollout", "dead bug"], [.abs]),
        (["oblique", "woodchop", "wood chop", "russian twist", "pallof"], [.obliques]),
        (["back extension", "hyperextension"], [.lowerBack, .glutes]),
        (["run", "jog", "bike", "cycle", "row machine", "rower", "elliptical", "treadmill", "jump rope", "swim", "stair"], [.cardio]),
        (["clean", "snatch", "burpee", "thruster"], [.fullBody]),
    ]

    /// Muscle groups for a recognised exercise name, or nil when the name is unfamiliar.
    public static func groups(for exerciseName: String) -> [MuscleGroup]? {
        let name = exerciseName.lowercased()
        for rule in rules where rule.keywords.contains(where: { name.contains($0) }) {
            return rule.groups
        }
        return nil
    }
}
