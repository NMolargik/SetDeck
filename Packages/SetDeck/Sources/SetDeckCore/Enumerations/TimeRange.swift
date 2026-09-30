//
//  TimeRange.swift
//  SetDeckCore
//
//  Created by Nick Molargik on 11/29/25.
//

import Foundation

nonisolated public enum TimeRange: CaseIterable, Sendable {
    case last30Days
    case last90Days
    case allTime

    public var title: String {
        switch self {
        case .last30Days: return "30D"
        case .last90Days: return "90D"
        case .allTime:    return "All"
        }
    }

    public func lowerBound(relativeTo now: Date = Date()) -> Date? {
        let cal = Calendar.current
        switch self {
        case .last30Days:
            return cal.date(byAdding: .day, value: -30, to: now)
        case .last90Days:
            return cal.date(byAdding: .day, value: -90, to: now)
        case .allTime:
            return nil
        }
    }
}
