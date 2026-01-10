//
// EnergyWidget.swift
// SetDeckWidgetExtension
//
// Created by Nick Molargik on 12/2/25.
//

import SwiftUI
import WidgetKit

struct EnergyWidget: Widget {
    let kind: String = "EnergyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EnergyProvider()) { entry in
            EnergyWidgetView(entry: entry)
        }
        .configurationDisplayName("Energy Tracker")
        .description("Today's energy consumption.")
        .supportedFamilies([.systemSmall])
    }
}

struct EnergyWidgetView: View {
    var entry: EnergyProvider.Entry

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orangeEnd.gradient)

                Text("Energy Today")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Spacer()
            }

            Spacer()

            Text(formattedAmount)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Spacer()

            HStack {
                Spacer()

                Image("icon")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
            .offset(x: 10, y: 10)
        }
        .containerBackground(
            LinearGradient(colors: [.orangeStart, .orangeEnd], startPoint: .topLeading, endPoint: .bottomTrailing),
            for: .widget
        )
    }

    private var formattedAmount: String {
        let rawKCal = entry.caloriesKCal
        return "\(Int(rawKCal)) cal"
    }
}

#Preview(as: .systemSmall) {
    EnergyWidget()
} timeline: {
    EnergyEntry(date: .now, caloriesKCal: 1200)
}
