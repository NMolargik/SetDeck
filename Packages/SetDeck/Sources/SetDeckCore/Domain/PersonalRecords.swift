//
//  PersonalRecords.swift
//  SetDeckCore
//
//  Per-exercise personal records from logged history. Weighted sets are ranked by
//  estimated one-rep max; timed sets (planks, carries, holds) are never ranked by
//  weight: their record is the longest duration.
//

import Foundation

public struct ExercisePersonalRecord: Sendable, Equatable {
    public let exerciseName: String
    /// Heaviest weight at the best estimated 1RM, in pounds. 0 for timed records.
    public let bestWeight: Double
    public let best1RM: Double
    /// Longest hold in seconds. Non-nil only for timed exercises.
    public let bestDuration: TimeInterval?
    public let bestDate: Date

    public var isTimed: Bool { bestDuration != nil }
}

public enum PersonalRecords {
    /// Epley estimate: 1RM = weight * (1 + reps / 30).
    public static func estimated1RM(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        return weight * (1.0 + Double(reps) / 30.0)
    }

    /// A timed entry: logged against a duration set, or carrying a duration but no reps.
    public static func isTimed(_ entry: SetDeckSetHistory) -> Bool {
        if entry.set?.setType == .duration { return true }
        return (entry.actualDuration ?? 0) > 0 && (entry.actualReps ?? 0) == 0
    }

    /// Records per exercise: weighted ones first (by 1RM), then timed ones (by duration).
    public static func summaries(from history: [SetDeckSetHistory]) -> [ExercisePersonalRecord] {
        let grouped = Dictionary(grouping: history) { $0.set?.exercise?.name ?? "Unknown exercise" }

        var weighted: [ExercisePersonalRecord] = []
        var timed: [ExercisePersonalRecord] = []

        for (name, entries) in grouped {
            var bestEntry: SetDeckSetHistory?
            var best1RM = 0.0
            for e in entries where !isTimed(e) {
                let estimate = estimated1RM(weight: e.actualWeight ?? 0, reps: e.actualReps ?? 0)
                if estimate > best1RM { best1RM = estimate; bestEntry = e }
            }
            if let best = bestEntry, let weight = best.actualWeight {
                weighted.append(ExercisePersonalRecord(
                    exerciseName: name, bestWeight: weight, best1RM: best1RM,
                    bestDuration: nil, bestDate: best.completedDate))
                continue
            }
            let longest = entries.filter(isTimed)
                .compactMap { e in e.actualDuration.map { (e, $0) } }
                .filter { $0.1 > 0 }
                .max { $0.1 < $1.1 }
            if let (entry, duration) = longest {
                timed.append(ExercisePersonalRecord(
                    exerciseName: name, bestWeight: 0, best1RM: 0,
                    bestDuration: duration, bestDate: entry.completedDate))
            }
        }
        return weighted.sorted { $0.best1RM > $1.best1RM } + timed.sorted { ($0.bestDuration ?? 0) > ($1.bestDuration ?? 0) }
    }
}
