//
//  UnitSystem.swift
//  SetDeckWidgetExtension
//
//  Created by Nick Molargik on 12/2/25.
//

import Foundation
import AppIntents

enum UnitSystem: String, AppEnum {
    case imperial = "Imperial"
    case metric = "Metric"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Unit System")

    static var typeDescription: String { "Unit system for display" }
    static var defaultValue = Self.imperial  // Fallback if no app setting

    static var caseDisplayRepresentations: [UnitSystem: DisplayRepresentation] = [
        .imperial: "Imperial",
        .metric: "Metric"
    ]

    /// Maps from the app's @AppStorage Bool (true = metric, false = imperial).
    init(fromUseMetric: Bool) {
        self = fromUseMetric ? .metric : .imperial
    }

    /// Human-readable text for this unit system.
    var displayText: String {
        switch self {
        case .imperial: return "Imperial"
        case .metric: return "Metric"
        }
    }
}
