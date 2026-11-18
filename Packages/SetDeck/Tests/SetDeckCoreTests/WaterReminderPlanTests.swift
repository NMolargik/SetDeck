//
//  WaterReminderPlanTests.swift
//  SetDeckCoreTests
//

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
