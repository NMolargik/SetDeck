//
//  WorkoutComplication.swift
//  SetDeck Watch Widget
//
//  Created by Nick Molargik on 1/10/26.
//
//  Watch face complications showing today's workout info.
//

import WidgetKit
import SwiftUI

// MARK: - Codable Models (must match WatchModels.swift in Watch App)

private struct WatchRoutine: Codable {
    let id: UUID
    let day: Int
    let dayName: String
    let exercises: [WatchExercise]

    var exerciseCount: Int { exercises.count }
    var totalSetCount: Int { exercises.reduce(0) { $0 + $1.sets.count } }
}

private struct WatchExercise: Codable {
    let id: UUID
    let name: String
    let isWarmup: Bool
    let note: String?
    let orderIndex: Int
    let sets: [WatchSet]
}

private struct WatchSet: Codable {
    let id: UUID
    let setType: WatchSetType
    let targetReps: Int?
    let weight: Double?
    let weightUnit: String
    let targetDuration: TimeInterval?
    let rpe: Int?
    let orderIndex: Int
}

private enum WatchSetType: String, Codable {
    case reps, amap, duration, freeform
}

// MARK: - Timeline Entry
struct WorkoutComplicationEntry: TimelineEntry {
    let date: Date
    let dayName: String
    let exerciseCount: Int
    let setCount: Int
    let isWorkoutActive: Bool

    static var placeholder: WorkoutComplicationEntry {
        WorkoutComplicationEntry(
            date: Date(),
            dayName: "Monday",
            exerciseCount: 6,
            setCount: 24,
            isWorkoutActive: false
        )
    }

    static var empty: WorkoutComplicationEntry {
        WorkoutComplicationEntry(
            date: Date(),
            dayName: todayName,
            exerciseCount: 0,
            setCount: 0,
            isWorkoutActive: false
        )
    }

    private static var todayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
}

// MARK: - Timeline Provider
struct WorkoutComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorkoutComplicationEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkoutComplicationEntry) -> Void) {
        let entry = getComplicationEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutComplicationEntry>) -> Void) {
        let entry = getComplicationEntry()

        // Update at midnight for new day, or every hour
        let nextUpdate = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func getComplicationEntry() -> WorkoutComplicationEntry {
        // Get data from WatchConnectivity shared state
        // Since we can't access @Observable from widget, use shared container or UserDefaults
        let routine = loadRoutineFromSharedStorage()

        return WorkoutComplicationEntry(
            date: Date(),
            dayName: routine?.dayName ?? todayName,
            exerciseCount: routine?.exerciseCount ?? 0,
            setCount: routine?.totalSetCount ?? 0,
            isWorkoutActive: false // Would need shared state for this
        )
    }

    private func loadRoutineFromSharedStorage() -> WatchRoutine? {
        // Try to load from App Group shared container
        guard let sharedDefaults = UserDefaults(suiteName: "group.nickmolargik.ReadySet") else {
            return nil
        }

        guard let data = sharedDefaults.data(forKey: "todayRoutine") else {
            return nil
        }

        return try? JSONDecoder().decode(WatchRoutine.self, from: data)
    }

    private var todayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
}

// MARK: - Complication Widget
struct WorkoutComplication: Widget {
    let kind: String = "WorkoutComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutComplicationProvider()) { entry in
            WorkoutComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Workout")
        .description("Shows today's exercise count and workout status.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Complication Views
struct WorkoutComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: WorkoutComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryCorner:
            cornerView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    // MARK: - Circular
    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 0) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 18))

                if entry.exerciseCount > 0 {
                    Text("\(entry.exerciseCount)")
                        .font(.system(size: 14, weight: .semibold))
                } else {
                    Text("--")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Corner
    @ContentBuilder
    private var cornerView: some View {
        let progress = min(Double(entry.exerciseCount) / 10.0, 1.0)
        let labelText = entry.exerciseCount > 0 ? "\(entry.exerciseCount) exercises" : "Rest day"

        Gauge(value: progress) {
            Image(systemName: "figure.strengthtraining.traditional")
        } currentValueLabel: {
            Text("\(entry.exerciseCount)")
                .font(.system(size: 12, weight: .semibold))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetLabel(labelText)
    }

    // MARK: - Rectangular
    private var rectangularView: some View {
        HStack(spacing: 8) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title2)
                .widgetAccentable()

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.dayName)
                    .font(.headline)
                    .lineLimit(1)

                if entry.exerciseCount > 0 {
                    Text("\(entry.exerciseCount) exercises, \(entry.setCount) sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No exercises scheduled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Inline
    private var inlineView: some View {
        if entry.exerciseCount > 0 {
            Label("\(shortDayName) - \(entry.exerciseCount) exercises", systemImage: "figure.strengthtraining.traditional")
        } else {
            Label("\(shortDayName) - Rest", systemImage: "moon.zzz")
        }
    }

    private var shortDayName: String {
        String(entry.dayName.prefix(3))
    }
}

// MARK: - Previews
#Preview("Circular", as: .accessoryCircular) {
    WorkoutComplication()
} timeline: {
    WorkoutComplicationEntry.placeholder
    WorkoutComplicationEntry.empty
}

#Preview("Corner", as: .accessoryCorner) {
    WorkoutComplication()
} timeline: {
    WorkoutComplicationEntry.placeholder
}

#Preview("Rectangular", as: .accessoryRectangular) {
    WorkoutComplication()
} timeline: {
    WorkoutComplicationEntry.placeholder
    WorkoutComplicationEntry.empty
}

#Preview("Inline", as: .accessoryInline) {
    WorkoutComplication()
} timeline: {
    WorkoutComplicationEntry.placeholder
}
