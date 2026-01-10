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
    static var title: LocalizedStringResource = "Add Calories"
    static var description = IntentDescription("Log calorie intake to Apple Health")

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
    static var title: LocalizedStringResource = "Add Snack"
    static var description = IntentDescription("Log a small snack (100 kcal)")

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
    static var title: LocalizedStringResource = "Add Small Meal"
    static var description = IntentDescription("Log a small meal (300 kcal)")

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
    static var title: LocalizedStringResource = "Add Meal"
    static var description = IntentDescription("Log a meal (500 kcal)")

    func perform() async throws -> some IntentResult {
        let healthManager = await HealthManager()
        await healthManager.requestAuthorization()
        await healthManager.addCalorieIntakeIfSupported(amount: 500, date: Date())

        WidgetCenter.shared.reloadTimelines(ofKind: "EnergyWidget")

        return .result()
    }
}
