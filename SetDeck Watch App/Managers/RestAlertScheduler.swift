//
//  RestAlertScheduler.swift
//  SetDeck Watch App
//
//  Guarantees the end-of-rest haptic fires with the wrist down. Two layers:
//   1. While a workout session is running the app keeps executing in the background, so
//      `WatchWorkoutSession` plays the haptic itself at the deadline.
//   2. A local notification scheduled for the same deadline is the safety net for when
//      the app is suspended anyway (no workout session, low-power mode, a crash): the
//      system delivers its haptic with no app code running. The in-process layer removes
//      the pending request a second before the deadline so the wrist only taps once.
//

import Foundation
import UserNotifications

@MainActor
final class RestAlertScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = RestAlertScheduler()

    private let center = UNUserNotificationCenter.current()
    private let requestId = "setdeck.rest.end"

    func configure() {
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func schedule(endDate: Date, body: String) {
        center.removePendingNotificationRequests(withIdentifiers: [requestId])
        let interval = endDate.timeIntervalSinceNow
        guard interval > 1 else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Rest over")
        content.body = body
        content.sound = .default
        content.interruptionLevel = .active
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: requestId, content: content, trigger: trigger))
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [requestId])
        center.removeDeliveredNotifications(withIdentifiers: [requestId])
    }

    // The in-process layer owns the foreground; don't double-tap.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        []
    }
}
