//
//  ExercisePRCardView.swift
//  SetDeckFeatureStats
//
//  Created by Nick Molargik on 11/29/25.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared

struct ExercisePRCardView: View {
    let exerciseNames: [String]
    let prs: [StatsView.PRSummary]

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false

    private func displayWeight(_ lbs: Double) -> String {
        String(Int(lbs.weight(useMetric: useMetricUnits).rounded()))
    }
    private var unitLabel: String { useMetricUnits ? "kg" : "lb" }
    /// m:ss for holds under an hour, h:mm:ss beyond.
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600, m = (total % 3600) / 60, sec = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
    }
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

    private func accessibilityText(for pr: StatsView.PRSummary) -> LocalizedStringKey {
        if let duration = pr.bestDuration {
            return "\(pr.exerciseName), best time \(formatDuration(duration)), achieved on \(formatDate(pr.bestDate))"
        }
        return "\(pr.exerciseName), best weight \(displayWeight(pr.bestWeight)) \(unitLabel), estimated one rep max \(displayWeight(pr.best1RM)) \(unitLabel), achieved on \(formatDate(pr.bestDate))"
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
                                if let duration = pr.bestDuration {
                                    Text("Best: \(formatDuration(duration))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                Text("Best: \(displayWeight(pr.bestWeight)) \(unitLabel) • est. 1RM \(displayWeight(pr.best1RM)) \(unitLabel)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(formatDate(pr.bestDate))
                                .font(.caption2)
                                .foregroundStyle(.purpleStart)
                        }
                        .padding(.vertical, 2)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(accessibilityText(for: pr))
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Personal Records section, \(prs.count) exercises")
    }
}
#endif
