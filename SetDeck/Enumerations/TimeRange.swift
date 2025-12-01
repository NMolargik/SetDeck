//
//  TimeRange.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import Foundation

enum TimeRange: CaseIterable {
    case last30Days
    case last90Days
    case allTime

    var title: String {
        switch self {
        case .last30Days: return "30D"
        case .last90Days: return "90D"
        case .allTime:    return "All"
        }
    }

    func lowerBound(relativeTo now: Date = Date()) -> Date? {
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
