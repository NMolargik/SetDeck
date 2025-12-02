//
//  ExercisePRCardView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI

struct ExercisePRCardView: View {
    let exerciseNames: [String]
    let prs: [StatsView.PRSummary]

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false

    private func displayWeight(_ lbs: Double) -> String {
        let value = useMetricUnits ? lbs * 0.45359237 : lbs
        return String(Int(value.rounded()))
    }
    private var unitLabel: String { useMetricUnits ? "kg" : "lb" }
    private func formatDate(_ date: Date) -> String {
        if useDayMonthYearDates {
            let df = DateFormatter()
            df.locale = .current
            df.dateFormat = "dd/MM/yyyy"
            return df.string(from: date)
        } else {
            return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Personal Records")
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                if prs.isEmpty {
                    Text("Log some sets to see PRs.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(prs.prefix(3), id: \.exerciseName) { pr in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(pr.exerciseName)
                                    .font(.subheadline)
                                Text("Best: \(displayWeight(pr.bestWeight)) \(unitLabel) • est. 1RM \(displayWeight(pr.best1RM)) \(unitLabel)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(formatDate(pr.bestDate))
                                .font(.caption2)
                                .foregroundStyle(.purpleStart)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

#Preview("ExercisePRCard") {
    let names = ["Bench Press", "Squat", "Deadlift"]
    let prs: [StatsView.PRSummary] = [
        .init(exerciseName: "Bench Press", bestWeight: 225, bestDate: Date().addingTimeInterval(-86400 * 10), best1RM: 250),
        .init(exerciseName: "Squat", bestWeight: 315, bestDate: Date().addingTimeInterval(-86400 * 20), best1RM: 350),
        .init(exerciseName: "Deadlift", bestWeight: 405, bestDate: Date().addingTimeInterval(-86400 * 30), best1RM: 450)
    ]

    return ExercisePRCardView(
        exerciseNames: names,
        prs: prs
    )
    .padding()
    .background(Color(.systemBackground))
}
