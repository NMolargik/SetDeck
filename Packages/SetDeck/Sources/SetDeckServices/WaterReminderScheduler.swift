//
//  WaterReminderScheduler.swift
//  SetDeckServices
//
//  Optional water-intake reminders as repeating daily local notifications inside the
//  user's active window. The scheduler owns only requests whose identifiers carry
//  `WaterReminderKeys.requestIdentifierPrefix`; it never touches anything else.
//  `WaterReminderNotificationHandler` is the notification-center delegate that handles
//  the "Log a Glass" action and foreground presentation.
//

#if canImport(UserNotifications)
import Foundation
import UserNotifications
import SetDeckCore
import os

public final class WaterReminderScheduler {
    private let center: UNUserNotificationCenter
    private let defaults: any KeyValueStoring

    public init(
        center: UNUserNotificationCenter = .current(),
        defaults: any KeyValueStoring = UserDefaults.standard
    ) {
        self.center = center
        self.defaults = defaults
    }

    // MARK: - Authorization

    public func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Asks for notification permission (system prompt shows only the first time).
    /// Returns whether reminders may be delivered.
    public func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            Log.app.error("Water reminder authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Category

    /// Registers the "Log a Glass" action category, merging with any existing ones.
    public func registerCategory() async {
        let action = UNNotificationAction(
            identifier: WaterReminderKeys.logGlassActionIdentifier,
            title: String(localized: "Log a Glass"),
            options: []
        )
        let category = UNNotificationCategory(
            identifier: WaterReminderKeys.categoryIdentifier,
            actions: [action],
            intentIdentifiers: [],
            options: []
        )
        var categories = await center.notificationCategories()
        categories = categories.filter { $0.identifier != category.identifier }
        categories.insert(category)
        center.setNotificationCategories(categories)
    }

    // MARK: - Scheduling

    /// Brings pending requests in line with the stored settings: removes this feature's
    /// requests, then (if enabled and permitted) adds one repeating daily trigger per slot.
    public func reschedule() async {
        defaults.removeObject(forKey: WaterReminderKeys.skippedDay)
        await registerCategory()
        await removeAllReminders()

        let settings = WaterReminderSettings.load(from: defaults)
        guard settings.isEnabled else { return }

        let status = await authorizationStatus()
        #if os(macOS)
        guard status == .authorized || status == .provisional else { return }
        #else
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }
        #endif

        for slot in settings.plan.slots {
            let (hour, minute) = WaterReminderPlan.hourAndMinute(fromMinute: slot)
            let content = makeContent()

            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: WaterReminderPlan.identifier(forSlot: slot),
                content: content,
                trigger: trigger
            )
            do {
                try await center.add(request)
            } catch {
                Log.app.error("Failed to schedule water reminder \(slot): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Daily goal

    /// Days of one-shot reminders laid down after skipping the rest of today. The app
    /// restores the repeating schedule the next time it becomes active.
    private static let skipHorizonDays = 3

    /// Quiets reminders once today's water total meets the daily goal: today's remaining
    /// repeating reminders are removed and replaced by one-shot reminders for the next
    /// few days, and the repeating schedule is restored on the next day's first call.
    /// Safe to call often (app active, after logging water).
    public func applyDailyGoal(todayML: Double, now: Date = Date(), calendar: Calendar = .current) async {
        let settings = WaterReminderSettings.load(from: defaults)
        guard settings.isEnabled else { return }

        let today = WaterReminderGoalAction.dayKey(for: now, calendar: calendar)
        let action = WaterReminderGoalAction.decide(
            todayML: todayML,
            goalML: WaterReminderKeys.dailyGoal(from: defaults),
            skippedDay: defaults.string(forKey: WaterReminderKeys.skippedDay),
            today: today
        )

        switch action {
        case .none:
            return
        case .restore:
            defaults.removeObject(forKey: WaterReminderKeys.skippedDay)
            await reschedule()
        case .skipRestOfToday:
            let comps = calendar.dateComponents([.hour, .minute], from: now)
            let minuteOfDay = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            let remaining = settings.plan.remainingSlots(afterMinute: minuteOfDay)
            guard !remaining.isEmpty else {
                defaults.set(today, forKey: WaterReminderKeys.skippedDay)
                return
            }
            center.removePendingNotificationRequests(
                withIdentifiers: remaining.map { WaterReminderPlan.identifier(forSlot: $0) }
            )
            for offset in 1...Self.skipHorizonDays {
                guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
                let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
                for slot in remaining {
                    var components = dayComponents
                    (components.hour, components.minute) = WaterReminderPlan.hourAndMinute(fromMinute: slot)
                    let request = UNNotificationRequest(
                        identifier: WaterReminderPlan.identifier(forSlot: slot, dayOffset: offset),
                        content: makeContent(),
                        trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    )
                    do { try await center.add(request) } catch {
                        Log.app.error("Failed to schedule post-goal reminder: \(error.localizedDescription)")
                    }
                }
            }
            defaults.set(today, forKey: WaterReminderKeys.skippedDay)
        }
    }

    private func makeContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Time for some water 💧")
        content.body = String(localized: "A glass now keeps you going. Tap to log it.")
        content.sound = .default
        content.categoryIdentifier = WaterReminderKeys.categoryIdentifier
        return content
    }

    public func removeAllReminders() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter(WaterReminderPlan.isReminderIdentifier)
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}

// MARK: - Delegate

/// Notification-center delegate: logs a glass for the "Log a Glass" action and lets
/// reminders show as banners while the app is open. Install it before launch finishes
/// (SessionController does this in `init`) so actions on a cold launch are delivered.
public final class WaterReminderNotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    private let defaults: any KeyValueStoring
    private let logWater: (Double) async -> Void

    /// - Parameter logWater: logs the given millilitres through the app's water path.
    public init(
        defaults: any KeyValueStoring = UserDefaults.standard,
        logWater: @escaping (Double) async -> Void
    ) {
        self.defaults = defaults
        self.logWater = logWater
        super.init()
    }

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionID = response.actionIdentifier
        guard actionID == WaterReminderKeys.logGlassActionIdentifier else { return }
        await logGlass()
    }

    private func logGlass() async {
        let ml = WaterReminderPlan.glassML(useMetric: defaults.bool(forKey: AppStorageKeys.useMetricUnits))
        await logWater(ml)
    }
}
#endif
