//
//  Date-elapsedString.swift
//  SetDeckCore
//

import Foundation

extension Date {
    /// Returns elapsed time from this date to `now` formatted as HH:MM:SS
    public func elapsedString(to now: Date = Date()) -> String {
        let interval = Int(now.timeIntervalSince(self))
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
