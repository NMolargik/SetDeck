//
//  StrengthTrainingActivityAttributes.swift
//  SetDeck
//
//  Created by Nick Molargik on 12/2/25.
//

import Foundation
import ActivityKit

struct StrengthTrainingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // The absolute start date of the workout
        var startDate: Date
        // Total time spent paused (seconds) accumulated up to the last resume
        var accumulatedPause: TimeInterval
        // If currently paused, when the pause started; otherwise nil
        var lastPauseDate: Date?
        // Convenience flag for UI
        var isPaused: Bool
    }
    // No fixed attributes for now
}
