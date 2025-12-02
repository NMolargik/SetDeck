//
//  EnergyProvider.swift
//  SetDeckWidgetExtension
//
//  Created by Nick Molargik on 12/2/25.
//

import Foundation
import WidgetKit

struct EnergyProvider: AppIntentTimelineProvider {
    typealias Entry = EnergyEntry
    
    func placeholder(in context: Context) -> EnergyEntry {
        EnergyEntry(date: Date(), caloriesKCal: 0, unitSystem: .imperial)
    }
    
    func snapshot(for configuration: ConfigureTrackerIntent, in context: Context) async -> EnergyEntry {
        EnergyEntry(date: Date(), caloriesKCal: 0, unitSystem: configuration.unitSystem ?? .imperial)
    }
    
    private func fetchCaloriesForTimeline() async -> Double {
        // If HealthManager has an async refresh method and it's main-actor isolated, do the whole sequence inside MainActor.run
        // using a continuation to bridge async work.
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                let healthManager = HealthManager(forWidget: true)
                // Try to call async refresh if available; if not, just read cached values.
                // We can't reference unknown signatures here, so we safely read the cached value.
                continuation.resume(returning: healthManager.todayCaloriesKCal)
            }
        }
    }
    
    func timeline(for configuration: ConfigureTrackerIntent, in context: Context) async -> Timeline<EnergyEntry> {
        let calories: Double = await fetchCaloriesForTimeline()

        let entry = EnergyEntry(
            date: Date(),
            caloriesKCal: calories,
            unitSystem: configuration.unitSystem ?? .imperial
        )

        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
    }
}

