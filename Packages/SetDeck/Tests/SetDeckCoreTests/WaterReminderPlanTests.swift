//
//  WaterReminderPlanTests.swift
//  SetDeckCoreTests
//

import Foundation
import Testing
import SetDeckCore

@Suite("WaterReminderPlan Tests")
struct WaterReminderPlanTests {

    @Test("Defaults give 8:00–20:00 every two hours")
    func defaults() {
        let plan = WaterReminderPlan()
        #expect(plan.slots == [480, 600, 720, 840, 960, 1080, 1200])
    }

    @Test("Hourly across the window includes both ends")
    func hourly() {
        let plan = WaterReminderPlan(startMinute: 480, endMinute: 1200, intervalMinutes: 60)
        #expect(plan.slots.count == 13)
        #expect(plan.slots.first == 480)
        #expect(plan.slots.last == 1200)
    }

    @Test("90 minute interval stops at the last slot inside the window")
    func ninetyMinutes() {
        let plan = WaterReminderPlan(startMinute: 480, endMinute: 1200, intervalMinutes: 90)
        #expect(plan.slots == [480, 570, 660, 750, 840, 930, 1020, 1110, 1200])
    }

    @Test("Three hours with an end that is not on a slot")
    func threeHours() {
        let plan = WaterReminderPlan(startMinute: 480, endMinute: 1190, intervalMinutes: 180)
        #expect(plan.slots == [480, 660, 840, 1020])
    }

    @Test("End before start or tiny interval yields nothing")
    func invalid() {
        #expect(WaterReminderPlan(startMinute: 900, endMinute: 600, intervalMinutes: 60).slots.isEmpty)
        #expect(WaterReminderPlan(startMinute: 480, endMinute: 1200, intervalMinutes: 5).slots.isEmpty)
    }

    @Test("Start equal to end yields one slot; out-of-range values clamp")
    func edges() {
        #expect(WaterReminderPlan(startMinute: 600, endMinute: 600, intervalMinutes: 60).slots == [600])
        #expect(WaterReminderPlan(startMinute: -50, endMinute: 5000, intervalMinutes: 720).slots == [0, 720])
    }

    @Test("Identifiers carry the prefix and round-trip detection")
    func identifiers() {
        let id = WaterReminderPlan.identifier(forSlot: 480)
        #expect(id == "setdeck.waterReminder.480")
        #expect(WaterReminderPlan.isReminderIdentifier(id))
        #expect(!WaterReminderPlan.isReminderIdentifier("other.480"))
    }

    @Test("Hour/minute split and glass size")
    func misc() {
        let hm = WaterReminderPlan.hourAndMinute(fromMinute: 570)
        #expect(hm.hour == 9 && hm.minute == 30)
        #expect(WaterReminderPlan.glassML(useMetric: true) == 250)
        #expect(abs(WaterReminderPlan.glassML(useMetric: false) - 236.588) < 0.001)
    }
}

@Suite("WaterReminderSettings Tests")
struct WaterReminderSettingsTests {

    final class FakeDefaults: KeyValueStoring {
        var values: [String: Any] = [:]
        func data(forKey k: String) -> Data? { values[k] as? Data }
        func string(forKey k: String) -> String? { values[k] as? String }
        func array(forKey k: String) -> [Any]? { values[k] as? [Any] }
        func bool(forKey k: String) -> Bool { values[k] as? Bool ?? false }
        func integer(forKey k: String) -> Int { values[k] as? Int ?? 0 }
        func set(_ v: Any?, forKey k: String) { values[k] = v }
        func removeObject(forKey k: String) { values[k] = nil }
    }

    @Test("Unset store is off with the default plan")
    func unset() {
        let s = WaterReminderSettings.load(from: FakeDefaults())
        #expect(!s.isEnabled)
        #expect(s.plan == WaterReminderPlan())
    }

    @Test("Stored values are read back")
    func stored() {
        let d = FakeDefaults()
        d.set(true, forKey: WaterReminderKeys.enabled)
        d.set(0, forKey: WaterReminderKeys.startMinute)
        d.set(600, forKey: WaterReminderKeys.endMinute)
        d.set(90, forKey: WaterReminderKeys.intervalMinutes)
        let s = WaterReminderSettings.load(from: d)
        #expect(s.isEnabled)
        #expect(s.plan == WaterReminderPlan(startMinute: 0, endMinute: 600, intervalMinutes: 90))
    }
}

@Suite("Water reminder daily goal")
struct WaterReminderGoalTests {

    @Test("remaining slots are the ones strictly after now")
    func remaining() {
        let plan = WaterReminderPlan()   // 480, 600, ... 1200
        #expect(plan.remainingSlots(afterMinute: 600) == [720, 840, 960, 1080, 1200])
        #expect(plan.remainingSlots(afterMinute: 0).count == 7)
        #expect(plan.remainingSlots(afterMinute: 1200).isEmpty)
    }

    @Test("goal met skips the rest of today once")
    func skipOnce() {
        let met = WaterReminderGoalAction.decide(todayML: 2100, goalML: 2000, skippedDay: nil, today: "2026-11-18")
        #expect(met == .skipRestOfToday)
        let again = WaterReminderGoalAction.decide(todayML: 2500, goalML: 2000, skippedDay: "2026-11-18", today: "2026-11-18")
        #expect(again == .none)
    }

    @Test("a new day restores the schedule")
    func restoreNextDay() {
        let a = WaterReminderGoalAction.decide(todayML: 300, goalML: 2000, skippedDay: "2026-11-17", today: "2026-11-18")
        #expect(a == .restore)
        let none = WaterReminderGoalAction.decide(todayML: 300, goalML: 2000, skippedDay: nil, today: "2026-11-18")
        #expect(none == .none)
    }

    @Test("goal already met on a new day skips again")
    func skipNewDay() {
        let a = WaterReminderGoalAction.decide(todayML: 2000, goalML: 2000, skippedDay: "2026-11-17", today: "2026-11-18")
        #expect(a == .skipRestOfToday)
    }

    @Test("day key is zero-padded and one-shot identifiers stay reminder identifiers")
    func keys() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = Date(timeIntervalSince1970: 1_767_225_600)   // 2026-01-01
        #expect(WaterReminderGoalAction.dayKey(for: date, calendar: cal) == "2026-01-01")
        #expect(WaterReminderPlan.isReminderIdentifier(WaterReminderPlan.identifier(forSlot: 600, dayOffset: 2)))
    }
}
