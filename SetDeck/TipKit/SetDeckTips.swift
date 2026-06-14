//
//  SetDeckTips.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/9/26.
//

import TipKit
import SwiftUI

// MARK: - Tip Events

nonisolated enum TipEvents {
    static let onboardingCompleted = Tips.Event(id: "onboardingCompleted")
    static let editRoutineOpened = Tips.Event(id: "editRoutineOpened")
    static let firstExerciseAdded = Tips.Event(id: "firstExerciseAdded")
}

// MARK: - Tips

struct EditRoutineTip: Tip {
    var title: Text {
        Text("Build Your Routine")
    }

    var message: Text? {
        Text("Tap here to add exercises and sets to your workout routine.")
    }

    var image: Image? {
        Image(systemName: "plus.circle.fill")
    }

    var options: [TipOption] {
        Tips.MaxDisplayCount(3)
    }

    var rules: [Rule] {
        #Rule(TipEvents.onboardingCompleted) { event in
            event.donations.count >= 1
        }
    }
}

struct AddExerciseTip: Tip {
    var title: Text {
        Text("Add Your First Exercise")
    }

    var message: Text? {
        Text("Tap 'Add Exercise' to create an exercise for your routine.")
    }

    var image: Image? {
        Image(systemName: "figure.strengthtraining.traditional")
    }

    var rules: [Rule] {
        #Rule(TipEvents.onboardingCompleted) { event in
            event.donations.count >= 1
        }
        #Rule(TipEvents.editRoutineOpened) { event in
            event.donations.count >= 1
        }
    }
}

struct AddSetTip: Tip {
    var title: Text {
        Text("Add Sets to Your Exercise")
    }

    var message: Text? {
        Text("Tap 'Add Set' to define reps, weight, and other details.")
    }

    var image: Image? {
        Image(systemName: "list.bullet")
    }

    var rules: [Rule] {
        #Rule(TipEvents.firstExerciseAdded) { event in
            event.donations.count >= 1
        }
    }
}

struct RecordWorkoutTip: Tip {
    var title: Text {
        Text("Record a Workout")
    }

    var message: Text? {
        Text("Time a workout to record it with Apple Health.")
    }

    var image: Image? {
        Image(systemName: "figure.strengthtraining.traditional")
    }
}
