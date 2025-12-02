//
//  WorkoutSummary.swift
//  SetDeck
//
//  Created by Nick Molargik on 12/2/25.
//

import Foundation
import HealthKit

struct WorkoutSummary: Identifiable, Hashable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let activityType: HKWorkoutActivityType
    let totalEnergyBurnedKCal: Double?

    var title: String { activityType.displayName }

    var subtitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let when = formatter.string(from: startDate)
        if let kcal = totalEnergyBurnedKCal {
            return "\(when) · \(Int(kcal)) kcal"
        } else {
            return when
        }
    }

    var durationString: String {
        let secs = max(0, Int(endDate.timeIntervalSince(startDate)))
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        if h > 0 { return String(format: "%dh %dm", h, m) }
        if m > 0 { return String(format: "%dm %ds", m, s) }
        return String(format: "%ds", s)
    }
}
