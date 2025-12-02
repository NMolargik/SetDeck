//
// WaterWidgetOZ.swift
// SetDeckWidgetExtension
//
// Created by Nick Molargik on 12/2/25.
//

import SwiftUI
import WidgetKit

struct WaterWidgetOZ: Widget {
    let kind: String = "WaterWidgetOZ"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterProvider()) { entry in
            WaterWidgetViewImperial(entry: entry)
        }
        .configurationDisplayName("Water Tracker (Fluid Oz)")
        .description("Today's water consumption.")
        .supportedFamilies([.systemSmall])
    }
}

struct WaterWidgetViewImperial: View {
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
        let waterOZ = waterML / 29.5735
        return "\(Int(waterOZ.rounded())) fl oz"
    }
}

#Preview(as: .systemSmall) {
    WaterWidgetOZ()
} timeline: {
    WaterEntry(date: .now, waterML: 4000)
}
