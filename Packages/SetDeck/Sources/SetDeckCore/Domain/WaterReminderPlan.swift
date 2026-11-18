//
//  WaterReminderPlan.swift
//  SetDeckCore
//
//  Pure time-slot math and constants for optional water reminders. No
//  UserNotifications here — the scheduler in SetDeckServices turns slots into requests.
//

import Foundation

nonisolated public enum WaterReminderKeys {
    public static let enabled = "waterReminders.enabled"
    /// Minutes after midnight.
    public static let startMinute = "waterReminders.startMinute"
    public static let endMinute = "waterReminders.endMinute"
    /// Interval in minutes (60, 90, 120, 180).
    public static let intervalMinutes = "waterReminders.intervalMinutes"

    public static let defaultStartMinute = 8 * 60
    public static let defaultEndMinute = 20 * 60
    public static let defaultIntervalMinutes = 120

    public static let requestIdentifierPrefix = "setdeck.waterReminder."
    public static let categoryIdentifier = "setdeck.waterReminder.category"
    public static let logGlassActionIdentifier = "setdeck.waterReminder.logGlass"
}

nonisolated public enum WaterReminderInterval: Int, CaseIterable, Sendable, Identifiable {
    case oneHour = 60
    case ninetyMinutes = 90
    case twoHours = 120
    case threeHours = 180

    public var id: Int { rawValue }
    public var minutes: Int { rawValue }

    public var label: String {
        switch self {
        case .oneHour: return "Every hour"
        case .ninetyMinutes: return "Every 1.5 hours"
        case .twoHours: return "Every 2 hours"
        case .threeHours: return "Every 3 hours"
        }
    }
}

nonisolated public struct WaterReminderPlan: Equatable, Sendable {
    public var startMinute: Int
    public var endMinute: Int
    public var intervalMinutes: Int

    public init(
        startMinute: Int = WaterReminderKeys.defaultStartMinute,
        endMinute: Int = WaterReminderKeys.defaultEndMinute,
        intervalMinutes: Int = WaterReminderKeys.defaultIntervalMinutes
    ) {
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.intervalMinutes = intervalMinutes
    }

    /// Reminder times as minutes after midnight: start, start+interval, … up to and
    /// including `endMinute`. Values are clamped to 0…1439; an interval under 15
    /// minutes or an end before the start yields no slots.
    public var slots: [Int] {
        let start = max(0, min(startMinute, 1439))
        let end = max(0, min(endMinute, 1439))
        guard intervalMinutes >= 15, end >= start else { return [] }
        return Array(stride(from: start, through: end, by: intervalMinutes))
    }

    public static func hourAndMinute(fromMinute minute: Int) -> (hour: Int, minute: Int) {
        (minute / 60, minute % 60)
    }

    public static func identifier(forSlot minute: Int) -> String {
        WaterReminderKeys.requestIdentifierPrefix + String(minute)
    }

    public static func isReminderIdentifier(_ identifier: String) -> Bool {
        identifier.hasPrefix(WaterReminderKeys.requestIdentifierPrefix)
    }

    // MARK: - Glass size

    /// One glass: 250 ml in metric, 8 fl oz in imperial.
    public static func glassML(useMetric: Bool) -> Double {
        useMetric ? 250 : 8 * 29.5735
    }
}
