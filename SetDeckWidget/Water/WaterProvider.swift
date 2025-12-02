//
// WaterProvider.swift
// SetDeckWidgetExtension
//
// Created by Nick Molargik on 12/2/25.
//

import Foundation
import WidgetKit

struct WaterProvider: TimelineProvider {
    typealias Entry = WaterEntry

    func placeholder(in context: Context) -> WaterEntry {
        WaterEntry(date: Date(), waterML: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (WaterEntry) -> Void) {
        Task {
            let waterML: Double = await fetchWaterForTimeline()
            let entry = WaterEntry(date: Date(), waterML: waterML)
            completion(entry)
        }
    }

    private func fetchWaterForTimeline() async -> Double {
        let healthManager = await HealthManager()
        await healthManager.refreshWaterToday()
        let waterML = await healthManager.todayWaterML
        // Clamp NaN/invalids to 0 (prevents CoreGraphics errors in view).
        let clampedML = waterML.isNaN ? 0.0 : max(0.0, waterML)
        return clampedML
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterEntry>) -> Void) {
        Task {
            let waterML: Double = await fetchWaterForTimeline()
            let entry = WaterEntry(date: Date(), waterML: waterML)
            let refreshDate = Date().addingTimeInterval(15 * 60)
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}
