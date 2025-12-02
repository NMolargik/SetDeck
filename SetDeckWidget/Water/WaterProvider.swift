//
//  WaterProvider.swift
//  SetDeckWidgetExtension
//
//  Created by Nick Molargik on 12/2/25.
//

import Foundation
import WidgetKit

struct WaterProvider: AppIntentTimelineProvider {
    typealias Entry = WaterEntry

    func placeholder(in context: Context) -> WaterEntry {
        WaterEntry(date: Date(), waterML: 0, unitSystem: .imperial)
    }

    func snapshot(for configuration: ConfigureTrackerIntent, in context: Context) async -> WaterEntry {
        WaterEntry(date: Date(), waterML: 0, unitSystem: configuration.unitSystem ?? .imperial)
    }

    private func fetchWaterForTimeline() async -> Double {
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                let healthManager = HealthManager(forWidget: true)
                // If an async refresh is needed and main-actor-isolated, it can be awaited here in this block.
                continuation.resume(returning: healthManager.todayWaterML)
            }
        }
    }

    func timeline(for configuration: ConfigureTrackerIntent, in context: Context) async -> Timeline<WaterEntry> {
        let water: Double = await fetchWaterForTimeline()

        let entry = WaterEntry(
            date: Date(),
            waterML: water,
            unitSystem: configuration.unitSystem ?? .imperial
        )

        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
    }
}
