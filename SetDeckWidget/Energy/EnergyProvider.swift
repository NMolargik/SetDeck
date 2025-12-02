//
// EnergyProvider.swift
// SetDeckWidgetExtension
//
// Created by Nick Molargik on 12/2/25.
//

import Foundation
import WidgetKit

struct EnergyProvider: TimelineProvider {
    typealias Entry = EnergyEntry

    func placeholder(in context: Context) -> EnergyEntry {
        EnergyEntry(date: Date(), caloriesKCal: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (EnergyEntry) -> Void) {
        Task {
            let calories: Double = await fetchCaloriesForTimeline()
            let entry = EnergyEntry(date: Date(), caloriesKCal: calories)
            completion(entry)
        }
    }

    private func fetchCaloriesForTimeline() async -> Double {
        let healthManager = await HealthManager()
        await healthManager.refreshCaloriesToday()
        let calories = await healthManager.todayCaloriesKCal
        // Clamp NaN/invalids to 0 (prevents CoreGraphics errors in view).
        let clampedKCal = calories.isNaN ? 0.0 : max(0.0, calories)
        return clampedKCal
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EnergyEntry>) -> Void) {
        Task {
            let calories: Double = await fetchCaloriesForTimeline()
            let entry = EnergyEntry(date: Date(), caloriesKCal: calories)
            let refreshDate = Date().addingTimeInterval(15 * 60)
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}
