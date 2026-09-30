//
//  CoreStyling.swift
//  SetDeckDesignSystem
//
//  SwiftUI-facing styling for Core enums (Core stays SwiftUI-free).
//

import SwiftUI
import SetDeckCore

extension AchievementCategory {
    public var color: Color {
        switch self {
        case .consistency: return .orangeStart
        case .volume:      return .purpleStart
        case .routine:     return .greenStart
        case .variety:     return .blueStart
        case .strength:    return .red
        }
    }
}

extension AppTab {
    public func icon() -> Image {
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

    public func color() -> Color {
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
