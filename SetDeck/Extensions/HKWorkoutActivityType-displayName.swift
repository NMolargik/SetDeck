//
//  HKWorkoutActivityType-displayName.swift
//  SetDeck
//
//  Created by Nick Molargik on 12/2/25.
//

import Foundation
import HealthKit

extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .traditionalStrengthTraining: return "Strength Training"
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .yoga: return "Yoga"
        case .highIntensityIntervalTraining: return "HIIT"
        default: return String(describing: self)
        }
    }
}
