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

    private var volumeCard: some View { SummaryCardView(title: "Volume", value: formattedVolume) }
    private var setsCard: some View { SummaryCardView(title: "Sets", value: "\(totalSets)") }
    private var daysCard: some View { SummaryCardView(title: "Active Days", value: "\(activeDays)") }
    private var streakCard: some View { SummaryCardView(title: "Best Streak", value: "\(bestStreak)d") }

    var body: some View {
        // One row when the four tiles fit at their natural width; otherwise 2 x 2 so a
        // value such as "485.7k" never wraps (the Duo's outer display is narrow).
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                volumeCard
                setsCard
                daysCard
                streakCard
            }
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    volumeCard.frame(maxWidth: .infinity, alignment: .leading)
                    setsCard.frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 12) {
                    daysCard.frame(maxWidth: .infinity, alignment: .leading)
                    streakCard.frame(maxWidth: .infinity, alignment: .leading)
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
