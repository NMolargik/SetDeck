//
//  WaterReminderSettingsView.swift
//  SetDeckFeatureSettings
//
//  Settings section for optional water reminders: master toggle, active hours, and
//  interval. Notification permission is requested only when the user turns it on.
//  Drop into a `Form` (or wrap in one for a standalone page).
//

#if os(iOS) && canImport(UserNotifications)
import SwiftUI
import UserNotifications
import SetDeckCore
import SetDeckDesignSystem
import SetDeckServices

public struct WaterReminderSettingsView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(WaterReminderKeys.enabled) private var isEnabled = false
    @AppStorage(WaterReminderKeys.startMinute) private var startMinute = WaterReminderKeys.defaultStartMinute
    @AppStorage(WaterReminderKeys.endMinute) private var endMinute = WaterReminderKeys.defaultEndMinute
    @AppStorage(WaterReminderKeys.intervalMinutes) private var intervalMinutes = WaterReminderKeys.defaultIntervalMinutes
    @AppStorage(WaterReminderKeys.dailyGoalMLKey) private var dailyGoalML = Int(WaterReminderKeys.dailyGoalML)
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false

    @State private var scheduler = WaterReminderScheduler()
    @State private var permissionDenied = false

    public init() {}

    public var body: some View {
        Section {
            Toggle(isOn: enabledBinding) {
                Label {
                    Text("Water Reminders")
                } icon: {
                    Image(systemName: "drop.fill").foregroundStyle(Color.blueStart)
                }
            }
            .tint(.blueStart)

            if permissionDenied {
                VStack(alignment: .leading, spacing: Brand.Space.sm) {
                    Text("Notifications are off for SetDeck. Turn them on in Settings and we'll nudge you to drink up.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button {
                        Haptics.lightImpact()
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                    }
                    .buttonStyle(.bordered)
                    .tint(.blueStart)
                }
                .accessibilityElement(children: .contain)
            }

            if isEnabled {
                DatePicker("From", selection: timeBinding($startMinute, maxMinute: endMinute, isStart: true),
                           displayedComponents: .hourAndMinute)
                DatePicker("Until", selection: timeBinding($endMinute, maxMinute: startMinute, isStart: false),
                           displayedComponents: .hourAndMinute)

                Picker("Remind me", selection: $intervalMinutes) {
                    ForEach(WaterReminderInterval.allCases) { interval in
                        Text(interval.label).tag(interval.minutes)
                    }
                }
                .tint(.blueStart)

                Stepper(value: goalBinding, in: WaterReminderKeys.minGoalML...WaterReminderKeys.maxGoalML,
                        step: WaterReminderKeys.goalStepML) {
                    LabeledContent("Daily Goal", value: goalText)
                }
                .accessibilityIdentifier("waterDailyGoal")
            }
        } header: {
            Text("Hydration")
        } footer: {
            Text("A gentle nudge during your active hours, with a one-tap \"Log a Glass\".")
        }
        .task { await refreshPermission() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshPermission() } }
        }
        .onChange(of: startMinute) { _, _ in reschedule() }
        .onChange(of: endMinute) { _, _ in reschedule() }
        .onChange(of: intervalMinutes) { _, _ in reschedule() }
        .onChange(of: dailyGoalML) { _, _ in reschedule() }
    }

    // MARK: - Bindings

    /// Turning on asks for permission first; the switch only stays on if it's granted.
    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { isEnabled },
            set: { newValue in
                Haptics.lightImpact()
                if newValue {
                    Task { await enable() }
                } else {
                    isEnabled = false
                    reschedule()
                }
            }
        )
    }

    /// The goal clamped to the allowed range (an unset or stale value reads as the default).
    private var goalBinding: Binding<Int> {
        Binding(
            get: { min(max(dailyGoalML, WaterReminderKeys.minGoalML), WaterReminderKeys.maxGoalML) },
            set: { dailyGoalML = $0 }
        )
    }

    private var goalText: String {
        let ml = Double(goalBinding.wrappedValue)
        if useMetricUnits {
            return Measurement(value: ml / 1000, unit: UnitVolume.liters)
                .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0...2))))
        }
        return Measurement(value: ml, unit: UnitVolume.milliliters).converted(to: .fluidOunces)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    private func timeBinding(_ minutes: Binding<Int>, maxMinute: Int, isStart: Bool) -> Binding<Date> {
        Binding(
            get: {
                let calendar = Calendar.current
                let base = calendar.startOfDay(for: Date())
                return calendar.date(byAdding: .minute, value: minutes.wrappedValue, to: base) ?? base
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                var value = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
                // Keep the window valid: start never passes end, end never precedes start.
                value = isStart ? min(value, maxMinute) : max(value, maxMinute)
                minutes.wrappedValue = value
            }
        )
    }

    // MARK: - Actions

    private func enable() async {
        let status = await scheduler.authorizationStatus()
        var granted = status == .authorized || status == .provisional || status == .ephemeral
        if status == .notDetermined {
            granted = await scheduler.requestAuthorization()
        }
        if granted {
            permissionDenied = false
            // Persist the window explicitly so the scheduler never sees unset values.
            let (start, end, interval) = (startMinute, endMinute, intervalMinutes)
            startMinute = start
            endMinute = end
            intervalMinutes = interval
            isEnabled = true
            reschedule()
        } else {
            isEnabled = false
            permissionDenied = true
        }
    }

    private func refreshPermission() async {
        let status = await scheduler.authorizationStatus()
        permissionDenied = status == .denied && (isEnabled || permissionDenied)
        // If permission was revoked in system Settings, reflect that.
        if status == .denied, isEnabled {
            isEnabled = false
            permissionDenied = true
            reschedule()
        }
    }

    private func reschedule() {
        let scheduler = scheduler
        Task { await scheduler.reschedule() }
    }
}
#endif
