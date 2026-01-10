//
//  AddWaterIntent.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/9/26.
//

import AppIntents
import WidgetKit

/// App Intent to add water intake from widgets and Shortcuts
struct AddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Water"
    static var description = IntentDescription("Log water intake to Apple Health")

    @Parameter(title: "Amount (ml)", default: 250)
    var amountML: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$amountML) ml of water")
    }

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager()
        await healthManager.requestAuthorization()
        await healthManager.addWaterIntakeIfSupported(amountML: Double(amountML), date: Date())

        // Reload widget timelines
        WidgetCenter.shared.reloadTimelines(ofKind: "WaterWidgetOZ")
        WidgetCenter.shared.reloadTimelines(ofKind: "WaterWidgetLiter")

        return .result()
    }
}

/// Quick add 250ml (8oz glass)
struct AddWaterSmallIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Glass of Water"
    static var description = IntentDescription("Log a glass of water (250ml / 8oz)")

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager()
        await healthManager.requestAuthorization()
        await healthManager.addWaterIntakeIfSupported(amountML: 250, date: Date())

        WidgetCenter.shared.reloadTimelines(ofKind: "WaterWidgetOZ")
        WidgetCenter.shared.reloadTimelines(ofKind: "WaterWidgetLiter")

        return .result()
    }
}

/// Quick add 500ml (16oz bottle)
struct AddWaterLargeIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Bottle of Water"
    static var description = IntentDescription("Log a bottle of water (500ml / 16oz)")

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager()
        await healthManager.requestAuthorization()
        await healthManager.addWaterIntakeIfSupported(amountML: 500, date: Date())

        WidgetCenter.shared.reloadTimelines(ofKind: "WaterWidgetOZ")
        WidgetCenter.shared.reloadTimelines(ofKind: "WaterWidgetLiter")

        return .result()
    }
}
