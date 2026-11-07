//
//  WatchStandaloneTests.swift
//  SetDeckCoreTests
//
//  Standalone-watch pure logic: the log, rest timer, and the phone merge rule.
//

import Foundation
import Testing
import SetDeckCore

@Suite("Watch standalone logic")
struct WatchStandaloneTests {

    private func routine() -> WatchRoutine {
        func set(_ i: Int) -> WatchSet {
            WatchSet(id: UUID(), setType: .reps, targetReps: 10, weight: 100, weightUnit: "lb",
                     targetDuration: nil, rpe: nil, orderIndex: i)
        }
        let a = WatchExercise(id: UUID(), name: "Bench", isWarmup: false, note: nil, orderIndex: 0, sets: [set(0), set(1)])
        let b = WatchExercise(id: UUID(), name: "Row", isWarmup: false, note: nil, orderIndex: 1, sets: [set(0)])
        return WatchRoutine(day: 1, exercises: [b, a])  // deliberately unsorted
    }

    @Test("nextSet walks exercise then set order and finishes")
    func nextSetOrder() {
        let r = routine()
        var log = WatchWorkoutLog(routineId: r.id, startedAt: Date())
        var seen: [String] = []
        while let next = log.nextSet(in: r) {
            seen.append(next.label)
            log.record(setId: next.set.id, exerciseId: next.exercise.id, reps: 10, weight: 100, rpe: nil)
        }
        #expect(seen == ["Bench · 1/2", "Bench · 2/2", "Row · 1/1"])
        #expect(log.completedCount(in: r) == 3)
    }

    @Test("re-logging a set keeps the completion id and moves the timestamp forward")
    func relogKeepsIdentity() {
        var log = WatchWorkoutLog(routineId: UUID(), startedAt: Date())
        let setId = UUID(), exId = UUID()
        let t = Date()
        let first = log.record(setId: setId, exerciseId: exId, reps: 8, weight: 100, rpe: nil, at: t)
        let edit = log.record(setId: setId, exerciseId: exId, reps: 9, weight: 105, rpe: nil, at: t.addingTimeInterval(-5))
        #expect(edit.completionId == first.completionId)
        #expect(edit.completedDate > first.completedDate)
        #expect(log.loggedSetCount == 1)
    }

    @Test("pending shrinks on delivery and regrows on edit")
    func pendingTracking() {
        var log = WatchWorkoutLog(routineId: UUID(), startedAt: Date())
        let setId = UUID(), exId = UUID()
        let first = log.record(setId: setId, exerciseId: exId, reps: 8, weight: 100, rpe: nil)
        #expect(log.pending.count == 1)
        log.markDelivered(first)
        #expect(log.pending.isEmpty)
        log.record(setId: setId, exerciseId: exId, reps: 9, weight: 100, rpe: nil)
        #expect(log.pending.count == 1)
    }

    @Test("log survives a JSON round-trip")
    func logCodable() throws {
        var log = WatchWorkoutLog(routineId: UUID(), startedAt: Date(timeIntervalSince1970: 1000))
        log.record(setId: UUID(), exerciseId: UUID(), reps: 5, weight: 50, rpe: 8, at: Date(timeIntervalSince1970: 2000))
        let data = try JSONEncoder().encode(log)
        #expect(try JSONDecoder().decode(WatchWorkoutLog.self, from: data) == log)
    }

    @Test("rest timer is deadline-based")
    func restTimerDeadline() {
        let t0 = Date(timeIntervalSince1970: 0)
        var timer = WatchRestTimer(duration: 60, now: t0)
        #expect(timer.remaining(at: t0.addingTimeInterval(45)) == 15)
        #expect(!timer.isFinished(at: t0.addingTimeInterval(59.9)))
        #expect(timer.isFinished(at: t0.addingTimeInterval(60)))
        // Long suspension: remaining is still exact, never negative.
        #expect(timer.remaining(at: t0.addingTimeInterval(600)) == 0)
        timer.extend()
        #expect(timer.totalDuration == 90)
        #expect(timer.progress(at: t0.addingTimeInterval(45)) == 0.5)
    }

    @Test("merge rule: insert, update newer, ignore same or older")
    func mergeRule() {
        let t = Date(timeIntervalSince1970: 100)
        #expect(WatchCompletionMerge.decide(existingDate: nil, incomingDate: t) == .insert)
        #expect(WatchCompletionMerge.decide(existingDate: t, incomingDate: t.addingTimeInterval(1)) == .update)
        #expect(WatchCompletionMerge.decide(existingDate: t, incomingDate: t) == .ignore)
        #expect(WatchCompletionMerge.decide(existingDate: t, incomingDate: t.addingTimeInterval(-1)) == .ignore)
    }

    @Test("completion decodes without completionId (older payloads)")
    func legacyDecode() throws {
        let json = """
        {"setId":"\(UUID())","exerciseId":"\(UUID())","completedDate":0,"actualReps":5}
        """
        let m = try JSONDecoder().decode(SetCompletionMessage.self, from: Data(json.utf8))
        #expect(m.actualReps == 5)
    }

    @Test("rest snapshot reports resting only before its end date")
    func snapshot() {
        let now = Date()
        #expect(WatchRestSnapshot(endDate: now.addingTimeInterval(5), nextSetLabel: nil).isResting(at: now))
        #expect(!WatchRestSnapshot(endDate: now.addingTimeInterval(-5), nextSetLabel: nil).isResting(at: now))
        #expect(!WatchRestSnapshot.cleared.isResting(at: now))
    }
}
