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

    /// Day (`yyyy-MM-dd`, device calendar) on which the rest of the reminders were
    /// skipped because the daily water goal was met.
    public static let skippedDay = "waterReminders.skippedDay"
    /// Daily water goal used to quiet reminders: 2 litres (about 68 fl oz).
    public static let dailyGoalML: Double = 2000

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

    /// Slots later than `minuteOfDay` (minutes after midnight): the reminders still to
    /// come today.
    public func remainingSlots(afterMinute minuteOfDay: Int) -> [Int] {
        slots.filter { $0 > minuteOfDay }
    }

    /// Identifier for a one-shot reminder at `slot` that is `dayOffset` days ahead.
    public static func identifier(forSlot minute: Int, dayOffset: Int) -> String {
        identifier(forSlot: minute) + ".d" + String(dayOffset)
    }

    // MARK: - Glass size

    /// One glass: 250 ml in metric, 8 fl oz in imperial.
    public static func glassML(useMetric: Bool) -> Double {
        useMetric ? 250 : 8 * 29.5735
    }
}

// MARK: - Persisted settings

nonisolated public struct WaterReminderSettings: Equatable, Sendable {
    public var isEnabled: Bool
    public var plan: WaterReminderPlan

    public init(isEnabled: Bool = false, plan: WaterReminderPlan = WaterReminderPlan()) {
        self.isEnabled = isEnabled
        self.plan = plan
    }

    /// Reads settings from a key-value store. An interval of 0 means the window was
    /// never written (the integer default), so the whole plan falls back to defaults.
    public static func load(from defaults: any KeyValueStoring) -> WaterReminderSettings {
        let interval = defaults.integer(forKey: WaterReminderKeys.intervalMinutes)
        guard interval > 0 else {
            return WaterReminderSettings(isEnabled: defaults.bool(forKey: WaterReminderKeys.enabled))
        }
        return WaterReminderSettings(
            isEnabled: defaults.bool(forKey: WaterReminderKeys.enabled),
            plan: WaterReminderPlan(
                startMinute: defaults.integer(forKey: WaterReminderKeys.startMinute),
                endMinute: defaults.integer(forKey: WaterReminderKeys.endMinute),
                intervalMinutes: interval
            )
        )
    }
}

// MARK: - Daily goal policy

/// What to do with today's pending reminders given the day's water total.
nonisolated public enum WaterReminderGoalAction: Equatable, Sendable {
    case none
    /// Goal met: drop the rest of today's reminders (tomorrow's stay).
    case skipRestOfToday
    /// Reminders were skipped earlier but should run normally again (new day, or the
    /// total fell back under the goal).
    case restore

    /// - Parameters:
    ///   - skippedDay: the day the reminders were last skipped, if any.
    ///   - today: today's day key (`dayKey(for:)`).
    public static func decide(
        todayML: Double,
        goalML: Double,
        skippedDay: String?,
        today: String
    ) -> WaterReminderGoalAction {
        let goalMet = goalML > 0 && todayML >= goalML
        switch (goalMet, skippedDay) {
        case (true, today): return .none
        case (true, _): return .skipRestOfToday
        case (false, nil): return .none
        case (false, _): return .restore
        }
    }

    /// `yyyy-MM-dd` key for `date` in `calendar`.
    public static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
