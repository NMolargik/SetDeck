//
//  ExerciseDetailCardView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI
import Charts

struct ExerciseDetailCardView: View {
    let exerciseName: String
    let points: [StatsView.OneRMPoint]

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false

    private func axisDateString(_ date: Date) -> String {
        if useDayMonthYearDates {
            let df = DateFormatter()
            df.locale = .current
            df.dateFormat = "dd/MM/yyyy"
            return df.string(from: date)
        } else {
            return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(exerciseName) Progress")
                .font(.headline)
            if points.isEmpty {
                Text("No history yet for this exercise.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Est. 1RM", useMetricUnits ? point.value * 0.45359237 : point.value)
                    )
                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Est. 1RM", useMetricUnits ? point.value * 0.45359237 : point.value)
                    )
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(axisDateString(date))
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

#Preview("ExerciseDetailCard") {
    let base = Calendar.current.startOfDay(for: Date())
    let points: [StatsView.OneRMPoint] = [
        .init(date: Calendar.current.date(byAdding: .day, value: -30, to: base)!, value: 225),
        .init(date: Calendar.current.date(byAdding: .day, value: -20, to: base)!, value: 235),
        .init(date: Calendar.current.date(byAdding: .day, value: -10, to: base)!, value: 245),
        .init(date: base, value: 255)
    ]

    return ExerciseDetailCardView(
        exerciseName: "Bench Press",
        points: points
    )
    .padding()
    .background(Color(.systemBackground))
}

