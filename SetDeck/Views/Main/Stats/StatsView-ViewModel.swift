//
//  StatsView-ViewModel.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI

extension StatsView {
    @Observable
    class ViewModel {
        // MARK: - Date helpers
        func startOfDay(_ date: Date) -> Date {
            Calendar.current.startOfDay(for: date)
        }

        // MARK: - Filtering
        func filteredHistory(_ allHistory: [SetDeckSetHistory], range: TimeRange) -> [SetDeckSetHistory] {
            guard let start = range.lowerBound() else { return allHistory }
            return allHistory.filter { $0.completedDate >= start }
        }

        // MARK: - Units
        func displayWeight(_ lbs: Double, useMetricUnits: Bool) -> Double {
            useMetricUnits ? lbs * 0.45359237 : lbs
        }

        // MARK: - Aggregates
        func totalVolume(filteredHistory: [SetDeckSetHistory], useMetricUnits: Bool) -> Double {
            filteredHistory.reduce(0) { partial, entry in
                let reps = entry.actualReps ?? 0
                let weightLbs = entry.actualWeight ?? 0
                let weight = displayWeight(weightLbs, useMetricUnits: useMetricUnits)
                return partial + Double(reps) * weight
            }
        }

        func activeDayCount(filteredHistory: [SetDeckSetHistory]) -> Int {
            Set(filteredHistory.map { startOfDay($0.completedDate) }).count
        }

        func bestStreak(filteredHistory: [SetDeckSetHistory]) -> Int {
            let days = Array(Set(filteredHistory.map { startOfDay($0.completedDate) })).sorted()
            guard !days.isEmpty else { return 0 }

            var best = 1
            var current = 1
            let cal = Calendar.current

            for idx in 1..<days.count {
                if let prev = cal.date(byAdding: .day, value: -1, to: days[idx]),
                   prev == days[idx - 1] {
                    current += 1
                    best = max(best, current)
                } else {
                    current = 1
                }
            }
            return best
        }

        // MARK: - Daily volume points
        func dailyVolumePoints(filteredHistory: [SetDeckSetHistory], useMetricUnits: Bool) -> [StatsView.VolumePoint] {
            let grouped = Dictionary(grouping: filteredHistory, by: { startOfDay($0.completedDate) })
            return grouped.keys.sorted().map { day in
                let volume = grouped[day]!.reduce(0) { partial, entry in
                    let reps = entry.actualReps ?? 0
                    let weightLbs = entry.actualWeight ?? 0
                    let weight = displayWeight(weightLbs, useMetricUnits: useMetricUnits)
                    return partial + Double(reps) * weight
                }
                return StatsView.VolumePoint(date: day, volume: volume)
            }
        }

        // MARK: - Exercise names (handle deleted exercises)
        func exerciseNames(filteredHistory: [SetDeckSetHistory]) -> [String] {
            let names = filteredHistory.compactMap { entry -> String? in
                entry.set?.exercise?.name ?? "Unknown exercise"
            }
            return Array(Set(names)).sorted()
        }

        // MARK: - PRs & 1RM trends
        // Very simple Epley estimate: 1RM = w * (1 + reps/30)
        func estimated1RM(weight: Double, reps: Int) -> Double {
            guard weight > 0, reps > 0 else { return 0 }
            return weight * (1.0 + Double(reps) / 30.0)
        }

        func exercisePRs(filteredHistory: [SetDeckSetHistory]) -> [StatsView.PRSummary] {
            let grouped = Dictionary(grouping: filteredHistory) { entry in
                entry.set?.exercise?.name ?? "Unknown exercise"
            }

            return grouped.compactMap { (name, entries) in
                var bestEntry: SetDeckSetHistory?
                var best1RM: Double = 0

                for e in entries {
                    let weight = e.actualWeight ?? 0
                    let reps = e.actualReps ?? 0
                    let estimate = estimated1RM(weight: weight, reps: reps)
                    if estimate > best1RM {
                        best1RM = estimate
                        bestEntry = e
                    }
                }

                guard let best = bestEntry,
                      let bestWeight = best.actualWeight else { return nil }

                return StatsView.PRSummary(
                    exerciseName: name,
                    bestWeight: bestWeight,
                    bestDate: best.completedDate,
                    best1RM: best1RM
                )
            }.sorted { $0.best1RM > $1.best1RM }
        }

        func exercise1RMPoints(filteredHistory: [SetDeckSetHistory]) -> [String: [StatsView.OneRMPoint]] {
            var result: [String: [StatsView.OneRMPoint]] = [:]
            let grouped = Dictionary(grouping: filteredHistory) { entry in
                entry.set?.exercise?.name ?? "Unknown exercise"
            }

            for (name, entries) in grouped {
                let byDay = Dictionary(grouping: entries) { startOfDay($0.completedDate) }
                let points: [StatsView.OneRMPoint] = byDay.keys.sorted().map { day in
                    let best = byDay[day]!.reduce(0) { partial, entry in
                        let w = entry.actualWeight ?? 0
                        let r = entry.actualReps ?? 0
                        return max(partial, estimated1RM(weight: w, reps: r))
                    }
                    return StatsView.OneRMPoint(date: day, value: best)
                }

                result[name] = points
            }

            return result
        }
    }
}
