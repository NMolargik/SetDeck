//
// ConfigureTrackerIntent.swift
// SetDeckWidgetExtension
//
// Created by Nick Molargik on 12/2/25.
//

import AppIntents
import Foundation

/// The intent that makes your widgets configurable (e.g., units).
struct ConfigureTrackerIntent: WidgetConfigurationIntent {  // Conforms to WidgetConfigurationIntent for clarity
    static var title: LocalizedStringResource = "Configure Tracker"
    static var description = IntentDescription("Choose units for water or energy display.")

    /// The parameter users select when editing the widget.
    @Parameter(title: "Unit System")
    var unitSystem: UnitSystem?

    /// Provide a default value for the parameter when the widget configuration UI opens.
    static func defaultValue(for parameter: inout UnitSystem?) -> Bool {
        let sharedDefaults = UserDefaults(suiteName: "group.nickmolargik.ReadySet")
        let useMetric = sharedDefaults?.bool(forKey: "useMetricUnits") ?? false
        parameter = UnitSystem(fromUseMetric: useMetric)
        return true  // Indicates success
    }

    /// How the parameter is summarized in the configuration UI.
    static var parameterSummary: some ParameterSummary {
        Summary {
            \ConfigureTrackerIntent.$unitSystem
        }
    }

    /// Opens the app when the widget is tapped (optional but recommended).
    static var openAppWhenRun: Bool = true

    /// Required by AppIntent. For configuration intents, just return a successful result.
    func perform() async throws -> some IntentResult {
        .result()
    }
}

