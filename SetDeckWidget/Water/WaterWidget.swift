//
//  WaterWidget.swift
//  SetDeckWidgetExtension
//
//  Created by Nick Molargik on 12/2/25.
//

import SwiftUI
import WidgetKit
import AppIntents

struct WaterWidget: Widget {
    let kind: String = "WaterWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigureTrackerIntent.self, provider: WaterProvider()) { entry in
            WaterWidgetView(entry: entry)
        }
        .configurationDisplayName("Water Tracker")
        .description("Today's water consumption.")
        .supportedFamilies([.systemSmall])
    }
}

struct WaterWidgetView: View {
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
        let rawML = entry.waterML
        switch entry.unitSystem {
        case .imperial:
            let oz = rawML * 0.033814  // mL to US fl oz
            return "\(Int(oz.rounded())) oz"
        case .metric:
            let liters = rawML / 1000.0
            return "\(liters, default: "%.1f") L"
        }
    }
}

#Preview(as: .systemSmall) {
    WaterWidget()
} timeline: {
    WaterEntry(date: .now, waterML: 1200, unitSystem: .imperial)
}
