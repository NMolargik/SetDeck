//
//  SummaryRowView.swift
//  SetDeckFeatureStats
//
//  Created by Nick Molargik on 11/29/25.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared

struct SummaryRowView: View {
    let totalVolume: Double
    let totalSets: Int
    let activeDays: Int
    let bestStreak: Int

    var body: some View {
        HStack(spacing: 12) {
            SummaryCardView(title: "Volume", value: formattedVolume)
            SummaryCardView(title: "Sets", value: "\(totalSets)")
            SummaryCardView(title: "Active Days", value: "\(activeDays)")
            SummaryCardView(title: "Best Streak", value: "\(bestStreak)d")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Workout summary: Volume \(formattedVolume), \(totalSets) sets, \(activeDays) active days, best streak \(bestStreak) days")
    }

    private var formattedVolume: String {
        if totalVolume >= 1_000_000 {
            return String(format: "%.1fM", totalVolume / 1_000_000)
        } else if totalVolume >= 1_000 {
            return String(format: "%.1fk", totalVolume / 1_000)
        } else {
            return String(format: "%.0f", totalVolume)
        }
    }
}
#endif
