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
        await registerCategory()
        await removeAllReminders()

        let settings = WaterReminderSettings.load(from: defaults)
        guard settings.isEnabled else { return }

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        for slot in settings.plan.slots {
            let (hour, minute) = WaterReminderPlan.hourAndMinute(fromMinute: slot)
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Time for some water 💧")
            content.body = String(localized: "A glass now keeps you going. Tap to log it.")
            content.sound = .default
            content.categoryIdentifier = WaterReminderKeys.categoryIdentifier

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
