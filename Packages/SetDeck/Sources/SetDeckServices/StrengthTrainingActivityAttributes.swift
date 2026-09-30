//
//  StrengthTrainingActivityAttributes.swift
//  SetDeckServices
//

#if canImport(ActivityKit) && !os(macOS)
import Foundation
import ActivityKit

nonisolated public struct StrengthTrainingActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        // The absolute start date of the workout
        public var startDate: Date
        // Total time spent paused (seconds) accumulated up to the last resume
        public var accumulatedPause: TimeInterval
        // If currently paused, when the pause started; otherwise nil
        public var lastPauseDate: Date?
        // Convenience flag for UI
        public var isPaused: Bool

        public init(startDate: Date, accumulatedPause: TimeInterval, lastPauseDate: Date?, isPaused: Bool) {
            self.startDate = startDate
            self.accumulatedPause = accumulatedPause
            self.lastPauseDate = lastPauseDate
            self.isPaused = isPaused
        }
    }

    public init() {}
}
#endif
