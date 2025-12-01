//
//  IntensityDistributionCardView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI
import Charts

struct IntensityDistributionCard: View {
    let history: [SetDeckSetHistory]

    struct RPEBucket: Identifiable {
        let rpe: Int
        let count: Int
        var id: Int { rpe }
    }

    var buckets: [RPEBucket] {
        let filtered = history.compactMap { $0.actualRpe }
        let grouped = Dictionary(grouping: filtered, by: { $0 })
        return grouped.keys.sorted().map { key in
            RPEBucket(rpe: key, count: grouped[key]?.count ?? 0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Intensity (RPE)")
                .font(.headline)
            if buckets.isEmpty {
                Text("Log RPE to see intensity trends.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(buckets) { bucket in
                    BarMark(
                        x: .value("RPE", bucket.rpe),
                        y: .value("Sets", bucket.count)
                    )
                }
                .frame(height: 180)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

#Preview("IntensityDistributionCard - Empty") {
    IntensityDistributionCard(history: [])
        .padding()
        .background(Color(.systemBackground))
}
