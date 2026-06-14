//
//  AddCaloriesIntent.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/9/26.
//

import AppIntents
import WidgetKit

/// App Intent to add calorie intake from widgets and Shortcuts
struct AddCaloriesIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Calories"
    static let description = IntentDescription("Log calorie intake to Health")

    @Parameter(title: "Amount (kcal)", default: 100)
    var amountKcal: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$amountKcal) calories")
    }

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager()
        await healthManager.requestAuthorization()
        await healthManager.addCalorieIntakeIfSupported(amount: Double(amountKcal), date: Date())

        // Reload widget timeline
        WidgetCenter.shared.reloadTimelines(ofKind: "EnergyWidget")

        return .result()
    }
}

/// Quick add 100 kcal (snack)
struct AddCaloriesSnackIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Snack"
    static let description = IntentDescription("Log a small snack (100 kcal)")

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager()
        await healthManager.requestAuthorization()
        await healthManager.addCalorieIntakeIfSupported(amount: 100, date: Date())

        WidgetCenter.shared.reloadTimelines(ofKind: "EnergyWidget")

        return .result()
    }
}

/// Quick add 300 kcal (small meal)
struct AddCaloriesMealIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Small Meal"
    static let description = IntentDescription("Log a small meal (300 kcal)")

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager()
        await healthManager.requestAuthorization()
        await healthManager.addCalorieIntakeIfSupported(amount: 300, date: Date())

        WidgetCenter.shared.reloadTimelines(ofKind: "EnergyWidget")

        return .result()
    }
}

/// Quick add 500 kcal (regular meal)
struct AddCaloriesLargeMealIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Meal"
    static let description = IntentDescription("Log a meal (500 kcal)")

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager()
        await healthManager.requestAuthorization()
        await healthManager.addCalorieIntakeIfSupported(amount: 500, date: Date())

        WidgetCenter.shared.reloadTimelines(ofKind: "EnergyWidget")

        return .result()
    }
}
