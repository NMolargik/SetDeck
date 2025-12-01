//
//  HealthError.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/8/25.
//

import Foundation

enum HealthError: Error, LocalizedError {
    case notAuthorized
    case workoutAlreadyRunning
    case noActiveWorkout
    case workoutNotRunning
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:          return "HealthKit not authorized"
        case .workoutAlreadyRunning:  return "A workout is already in progress"
        case .noActiveWorkout:        return "No workout is currently active"
        case .workoutNotRunning:      return "Workout is not running"
        }
    }
}
