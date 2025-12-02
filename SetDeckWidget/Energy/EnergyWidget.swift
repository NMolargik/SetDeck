//
//  EnergyWidget.swift
//  SetDeckWidgetExtension
//
//  Created by Nick Molargik on 12/2/25.
//

import WidgetKit
import SwiftUI
import AppIntents

struct EnergyWidget: Widget {
    let kind: String = "EnergyWidget"  // Unique kind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigureTrackerIntent.self, provider: EnergyProvider()) { entry in
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
        switch entry.unitSystem {
        case .imperial:
            return "\(Int(rawKCal)) kcal"
        case .metric:
            let kJ = rawKCal * 4.184  // kcal to kJ
            return "\(Int(kJ.rounded())) kJ"
        }
    }
}

#Preview(as: .systemSmall) {
    EnergyWidget()
} timeline: {
    EnergyEntry(date: .now, caloriesKCal: 1200, unitSystem: .imperial)
}
