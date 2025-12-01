//
//  AppTab.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case routine = "Routine"
    case stats = "Stats"
    case health = "Health"
    case settings = "Settings"
    
    var id: String { self.rawValue }

    func icon() -> Image {
        switch self {
        case .routine:
            return Image(systemName: "figure.strengthtraining.traditional")
        case .stats:
            return Image(systemName: "chart.line.uptrend.xyaxis")
        case .health:
            return Image(systemName: "bolt.heart.fill")
        case .settings:
            return Image(systemName: "gearshape.2")
        }
    }
    
    func color() -> Color {
        switch self {
        case .routine:
            return Color.greenStart
        case .stats:
            return Color.purpleStart
        case .health:
            return Color.blueStart
        case .settings:
            return Color.orangeStart
        }
    }
}
