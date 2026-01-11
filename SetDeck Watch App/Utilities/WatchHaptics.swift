//
//  WatchHaptics.swift
//  SetDeck Watch App
//
//  Created by Nick Molargik on 1/9/26.
//
//  Haptic feedback for Watch interactions.
//

import WatchKit

enum WatchHaptics {
    // MARK: - Workout Events
    static func workoutStarted() {
        WKInterfaceDevice.current().play(.start)
    }

    static func workoutPaused() {
        WKInterfaceDevice.current().play(.stop)
    }

    static func workoutResumed() {
        WKInterfaceDevice.current().play(.start)
    }

    static func workoutEnded() {
        WKInterfaceDevice.current().play(.success)
    }

    // MARK: - Set Logging
    static func setCompleted() {
        WKInterfaceDevice.current().play(.success)
    }

    static func setSkipped() {
        WKInterfaceDevice.current().play(.click)
    }

    // MARK: - Navigation & Selection
    static func selectionChanged() {
        WKInterfaceDevice.current().play(.click)
    }

    static func buttonTapped() {
        WKInterfaceDevice.current().play(.click)
    }

    // MARK: - Rest Timer
    static func restTimerTick() {
        WKInterfaceDevice.current().play(.click)
    }

    static func restTimerWarning() {
        // 10 seconds remaining
        WKInterfaceDevice.current().play(.notification)
    }

    static func restTimerCountdown() {
        // 3, 2, 1 countdown
        WKInterfaceDevice.current().play(.directionUp)
    }

    static func restTimerDone() {
        // Double haptic for completion
        WKInterfaceDevice.current().play(.notification)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            WKInterfaceDevice.current().play(.success)
        }
    }

    // MARK: - Errors & Warnings
    static func error() {
        WKInterfaceDevice.current().play(.failure)
    }

    static func warning() {
        WKInterfaceDevice.current().play(.retry)
    }

    // MARK: - Digital Crown
    static func crownRotated() {
        WKInterfaceDevice.current().play(.click)
    }

    static func crownReachedLimit() {
        WKInterfaceDevice.current().play(.directionDown)
    }
}
