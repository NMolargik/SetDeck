//
// WaterWidgetLiter.swift
// SetDeckWidgetExtension
//
// Created by Nick Molargik on 12/2/25.
//

import SwiftUI
import WidgetKit

struct WaterWidgetLiter: Widget {
    let kind: String = "WaterWidgetLiter"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterProvider()) { entry in
            WaterWidgetViewMetric(entry: entry)
        }
        .configurationDisplayName("Water Tracker (Liters)")
        .description("Today's water consumption.")
        .supportedFamilies([.systemSmall])
    }
}

struct WaterWidgetViewMetric: View {
    var entry: WaterProvider.Entry

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blueEnd.gradient)
                
                Text("Water Today")
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
        .containerBackground(LinearGradient(colors: [.blueStart, .blueEnd], startPoint: .topLeading, endPoint: .bottomTrailing), for: .widget)
    }
    
    private var formattedAmount: String {
        let waterML = entry.waterML
        let liters = waterML / 1000.0
        return "\(String(format: "%.1f", liters)) L"
    }
}

#Preview(as: .systemSmall) {
    WaterWidgetLiter()
} timeline: {
    WaterEntry(date: .now, waterML: 4000)
}
