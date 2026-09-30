//
//  WorkoutSummary.swift
//  SetDeckServices
//
//  Snapshot of a completed HealthKit workout for history lists and complications.
//

#if canImport(HealthKit)
import Foundation
import HealthKit

nonisolated public struct WorkoutSummary: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let activityType: HKWorkoutActivityType
    public let totalEnergyBurnedKCal: Double?

    public init(id: UUID, startDate: Date, endDate: Date, activityType: HKWorkoutActivityType, totalEnergyBurnedKCal: Double?) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.activityType = activityType
        self.totalEnergyBurnedKCal = totalEnergyBurnedKCal
    }

    public var title: String { activityType.displayName }

    public var subtitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let when = formatter.string(from: startDate)
        if let kcal = totalEnergyBurnedKCal {
            return "\(when) · \(Int(kcal)) cal"
        } else {
            return when
        }
    }

    public var durationString: String {
        let secs = max(0, Int(endDate.timeIntervalSince(startDate)))
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        if h > 0 { return String(format: "%dh %dm", h, m) }
        if m > 0 { return String(format: "%dm %ds", m, s) }
        return String(format: "%ds", s)
    }
}

nonisolated extension HKWorkoutActivityType {
    public var displayName: String {
        switch self {
        case .traditionalStrengthTraining: return "Strength Training"
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .yoga: return "Yoga"
        case .highIntensityIntervalTraining: return "HIIT"
        default: return String(describing: self)
        }
    }
}
#endif
