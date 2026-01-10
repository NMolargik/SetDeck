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
            lbs.weight(useMetric: useMetricUnits)
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

        // MARK: - Muscle Group Analysis

        /// Check if muscle group inference is available (iOS 26+ with Foundation Models)
        var isMuscleAnalysisAvailable: Bool {
            MuscleGroupInferenceService.shared.isAvailable
        }

        /// Calculate volume per muscle group from history, using AI inference for exercises without muscle groups
        /// Volume = sum of (reps × weight) for each set, distributed across the exercise's muscle groups
        func muscleGroupVolumes(filteredHistory: [SetDeckSetHistory], inferredMuscleGroups: [String: [MuscleGroup]]) -> [MuscleGroup: Double] {
            var volumes: [MuscleGroup: Double] = [:]

            for entry in filteredHistory {
                guard let exercise = entry.set?.exercise else { continue }

                // Use exercise's muscle groups if defined, otherwise use inferred
                var muscleGroups = exercise.muscleGroups
                if muscleGroups.isEmpty, let inferred = inferredMuscleGroups[exercise.name] {
                    muscleGroups = inferred
                }

                // Skip if still no muscle groups
                guard !muscleGroups.isEmpty else { continue }

                let reps = entry.actualReps ?? 0
                let weight = entry.actualWeight ?? 0
                let setVolume = Double(reps) * weight

                // Distribute volume across all muscle groups for this exercise
                let volumePerMuscle = setVolume / Double(muscleGroups.count)

                for muscle in muscleGroups {
                    volumes[muscle, default: 0] += volumePerMuscle
                }
            }

            return volumes
        }

        /// Infer muscle groups for all exercises in history that don't have them set
        func inferMuscleGroupsForHistory(_ history: [SetDeckSetHistory]) async -> [String: [MuscleGroup]] {
            // Get unique exercise names that need inference
            let exerciseNames = Set(
                history.compactMap { entry -> String? in
                    guard let exercise = entry.set?.exercise else { return nil }
                    // Only infer if exercise has no muscle groups set
                    return exercise.muscleGroups.isEmpty ? exercise.name : nil
                }
            )

            guard !exerciseNames.isEmpty else { return [:] }

            return await MuscleGroupInferenceService.shared.inferMuscleGroups(for: Array(exerciseNames))
        }

        /// Get this week's muscle volumes (last 7 days) with inference
        func thisWeekMuscleVolumes(allHistory: [SetDeckSetHistory], inferredMuscleGroups: [String: [MuscleGroup]]) -> [MuscleGroup: Double] {
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let thisWeekHistory = allHistory.filter { $0.completedDate >= weekAgo }
            return muscleGroupVolumes(filteredHistory: thisWeekHistory, inferredMuscleGroups: inferredMuscleGroups)
        }
    }
}
