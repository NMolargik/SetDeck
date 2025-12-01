//
//  SummaryRowView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI

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

#Preview("SummaryRow") {
    SummaryRowView(
        totalVolume: 123_456,
        totalSets: 42,
        activeDays: 18,
        bestStreak: 7
    )
    .padding()
    .background(Color(.systemBackground))
}
