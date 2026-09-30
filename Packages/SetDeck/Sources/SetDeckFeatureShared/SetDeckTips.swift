//
//  SetDeckTips.swift
//  SetDeckFeatureShared
//
//  TipKit events and tips shared by onboarding, the main shell, and the routine editor.
//

#if os(iOS)
import TipKit
import SwiftUI

// MARK: - Tip Events

nonisolated public enum TipEvents {
    public static let onboardingCompleted = Tips.Event(id: "onboardingCompleted")
    public static let editRoutineOpened = Tips.Event(id: "editRoutineOpened")
    public static let firstExerciseAdded = Tips.Event(id: "firstExerciseAdded")
}

// MARK: - Tips

public struct EditRoutineTip: Tip {
    public init() {}

    public var title: Text {
        Text("Build Your Routine")
    }

    public var message: Text? {
        Text("Tap here to add exercises and sets to your workout routine.")
    }

    public var image: Image? {
        Image(systemName: "plus.circle.fill")
    }

    public var options: [TipOption] {
        Tips.MaxDisplayCount(3)
    }

    public var rules: [Rule] {
        #Rule(TipEvents.onboardingCompleted) { event in
            event.donations.count >= 1
        }
    }
}

public struct AddExerciseTip: Tip {
    public init() {}

    public var title: Text {
        Text("Add Your First Exercise")
    }

    public var message: Text? {
        Text("Tap 'Add Exercise' to create an exercise for your routine.")
    }

    public var image: Image? {
        Image(systemName: "figure.strengthtraining.traditional")
    }

    public var rules: [Rule] {
        #Rule(TipEvents.onboardingCompleted) { event in
            event.donations.count >= 1
        }
        #Rule(TipEvents.editRoutineOpened) { event in
            event.donations.count >= 1
        }
    }
}

public struct AddSetTip: Tip {
    public init() {}

    public var title: Text {
        Text("Add Sets to Your Exercise")
    }

    public var message: Text? {
        Text("Tap 'Add Set' to define reps, weight, and other details.")
    }

    public var image: Image? {
        Image(systemName: "list.bullet")
    }

    public var rules: [Rule] {
        #Rule(TipEvents.firstExerciseAdded) { event in
            event.donations.count >= 1
        }
    }
}

public struct RecordWorkoutTip: Tip {
    public init() {}

    public var title: Text {
        Text("Record a Workout")
    }

    public var message: Text? {
        Text("Time a workout to record it with Apple Health.")
    }

    public var image: Image? {
        Image(systemName: "figure.strengthtraining.traditional")
    }
}
#endif
