//
//  PersonalRecordsTests.swift
//  SetDeckCoreTests
//

import Foundation
import Testing
import SetDeckCore

@Suite("PersonalRecords Tests")
struct PersonalRecordsTests {

    private func entry(_ name: String, type: SetType, reps: Int? = nil, weight: Double? = nil,
                       duration: TimeInterval? = nil, daysAgo: Int = 0) -> SetDeckSetHistory {
        let exercise = SetDeckExercise(name: name)
        let set = SetDeckSet(setType: type)
        set.exercise = exercise
        let e = SetDeckSetHistory(
            completedDate: Date(timeIntervalSinceNow: -Double(daysAgo) * 86_400),
            actualReps: reps, actualWeight: weight, actualDuration: duration)
        e.set = set
        return e
    }

    @Test("Timed sets are ranked by duration, never by weight")
    func timedSetUsesDuration() {
        let history = [
            entry("Plank", type: .duration, weight: 115, duration: 60),
            entry("Plank", type: .duration, weight: 115, duration: 90, daysAgo: 1),
        ]
        let records = PersonalRecords.summaries(from: history)
        #expect(records.count == 1)
        #expect(records[0].isTimed)
        #expect(records[0].bestDuration == 90)
        #expect(records[0].bestWeight == 0)
    }

    @Test("Weighted sets still rank by estimated 1RM and list before timed records")
    func weightedStillRanked() {
        let history = [
            entry("Plank", type: .duration, duration: 120),
            entry("Bench Press", type: .reps, reps: 5, weight: 100),
            entry("Bench Press", type: .reps, reps: 8, weight: 100, daysAgo: 2),
        ]
        let records = PersonalRecords.summaries(from: history)
        #expect(records.map(\.exerciseName) == ["Bench Press", "Plank"])
        #expect(records[0].bestWeight == 100)
        #expect(abs(records[0].best1RM - 100 * (1 + 8.0 / 30.0)) < 0.001)
        #expect(records[1].bestDuration == 120)
    }

    @Test("A duration entry without a set type is still timed")
    func durationWithoutRepsIsTimed() {
        let records = PersonalRecords.summaries(from: [entry("Farmer Carry", type: .reps, weight: 50, duration: 45)])
        #expect(records.first?.bestDuration == 45)
    }
}
