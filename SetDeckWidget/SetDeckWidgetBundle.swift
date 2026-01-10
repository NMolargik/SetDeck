//
//  SetDeckWidgetBundle.swift
//  SetDeckWidget
//
//  Created by Nick Molargik on 12/2/25.
//

import WidgetKit
import SwiftUI

@main
struct SetDeckWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen Widgets
        WaterWidgetOZ()
        WaterWidgetLiter()
        EnergyWidget()

        // Live Activity
        StrengthTrainingLiveActivity()
    }
}

// Separate bundle for iOS 18+ Control Center widgets
// Add to main bundle when targeting iOS 18+ minimum
@available(iOS 18.0, *)
struct SetDeckControlWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkoutControlWidget()
        StartWorkoutControl()
        StopWorkoutControl()
    }
}
