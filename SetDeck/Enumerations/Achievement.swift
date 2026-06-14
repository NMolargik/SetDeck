//
//  Achievement.swift
//  SetDeck
//
//  Created by Nick Molargik on 2/16/26.
//

import SwiftUI

// MARK: - Achievement Category

nonisolated enum AchievementCategory: String, CaseIterable {
    case consistency
    case volume
    case routine
    case variety
    case strength

    var icon: String {
        switch self {
        case .consistency: return "flame.fill"
        case .volume:      return "number"
        case .routine:     return "calendar"
        case .variety:     return "star.fill"
        case .strength:    return "dumbbell.fill"
        }
    }

    // Reads asset-catalog colors (which inherit the target's main-actor
    // isolation); only ever called from views, so isolate the accessor.
    @MainActor var color: Color {
        switch self {
        case .consistency: return .orangeStart
        case .volume:      return .purpleStart
        case .routine:     return .greenStart
        case .variety:     return .blueStart
        case .strength:    return .red
        }
    }
}

// MARK: - Achievement

nonisolated enum Achievement: String, CaseIterable, Identifiable {
    // Consistency
    case firstWorkout
    case weekWarrior
    case fullWeek
    case twoWeekStreak
    case monthStrong

    // Volume
    case gettingStarted
    case century
    case fiveHundredClub
    case thousandStrong
    case setMachine

    // Routine
    case buildingBlocks
    case fullRoster

    // Variety
    case explorer
    case wellRounded
    case renaissanceLifter

    // Strength
    case onePlate
    case twoPlates
    case threePlates
    case fourPlates

    var id: String { rawValue }

    var category: AchievementCategory {
        switch self {
        case .firstWorkout, .weekWarrior, .fullWeek, .twoWeekStreak, .monthStrong:
            return .consistency
        case .gettingStarted, .century, .fiveHundredClub, .thousandStrong, .setMachine:
            return .volume
        case .buildingBlocks, .fullRoster:
            return .routine
        case .explorer, .wellRounded, .renaissanceLifter:
            return .variety
        case .onePlate, .twoPlates, .threePlates, .fourPlates:
            return .strength
        }
    }

    var displayName: String {
        switch self {
        case .firstWorkout:      return "First Workout"
        case .weekWarrior:       return "Week Warrior"
        case .fullWeek:          return "Full Week"
        case .twoWeekStreak:     return "Two Week Streak"
        case .monthStrong:       return "Month Strong"
        case .gettingStarted:    return "Getting Started"
        case .century:           return "Century"
        case .fiveHundredClub:   return "500 Club"
        case .thousandStrong:    return "Thousand Strong"
        case .setMachine:        return "Set Machine"
        case .buildingBlocks:    return "Building Blocks"
        case .fullRoster:        return "Full Roster"
        case .explorer:          return "Explorer"
        case .wellRounded:       return "Well Rounded"
        case .renaissanceLifter: return "Renaissance Lifter"
        case .onePlate:          return "One Plate"
        case .twoPlates:         return "Two Plates"
        case .threePlates:       return "Three Plates"
        case .fourPlates:        return "Four Plates"
        }
    }

    var description: String {
        switch self {
        case .firstWorkout:      return "Record your first set"
        case .weekWarrior:       return "Work out 5 days in one week"
        case .fullWeek:          return "Work out every day of the week"
        case .twoWeekStreak:     return "14 consecutive days with workouts"
        case .monthStrong:       return "30 consecutive days with workouts"
        case .gettingStarted:    return "Complete 10 total sets"
        case .century:           return "Complete 100 total sets"
        case .fiveHundredClub:   return "Complete 500 total sets"
        case .thousandStrong:    return "Complete 1,000 total sets"
        case .setMachine:        return "Complete 5,000 total sets"
        case .buildingBlocks:    return "Have exercises on 5 different days"
        case .fullRoster:        return "Have exercises on all 7 days"
        case .explorer:          return "Log sets for 5 unique exercises"
        case .wellRounded:       return "Log sets for 10 unique exercises"
        case .renaissanceLifter: return "Log sets for 20 unique exercises"
        case .onePlate:          return "Log a set at 135 lbs"
        case .twoPlates:         return "Log a set at 225 lbs"
        case .threePlates:       return "Log a set at 315 lbs"
        case .fourPlates:        return "Log a set at 405 lbs"
        }
    }

    var icon: String {
        switch self {
        case .firstWorkout:      return "figure.walk"
        case .weekWarrior:       return "flame.fill"
        case .fullWeek:          return "7.square.fill"
        case .twoWeekStreak:     return "bolt.fill"
        case .monthStrong:       return "crown.fill"
        case .gettingStarted:    return "10.square.fill"
        case .century:           return "100.square.fill"
        case .fiveHundredClub:   return "trophy.fill"
        case .thousandStrong:    return "star.circle.fill"
        case .setMachine:        return "gearshape.2.fill"
        case .buildingBlocks:    return "building.2.fill"
        case .fullRoster:        return "checkmark.seal.fill"
        case .explorer:          return "map.fill"
        case .wellRounded:       return "circle.grid.3x3.fill"
        case .renaissanceLifter: return "paintpalette.fill"
        case .onePlate:          return "dumbbell.fill"
        case .twoPlates:         return "scalemass.fill"
        case .threePlates:       return "bolt.shield.fill"
        case .fourPlates:        return "medal.fill"
        }
    }

    var sortOrder: Int {
        switch self {
        case .firstWorkout:      return 0
        case .weekWarrior:       return 1
        case .fullWeek:          return 2
        case .twoWeekStreak:     return 3
        case .monthStrong:       return 4
        case .gettingStarted:    return 10
        case .century:           return 11
        case .fiveHundredClub:   return 12
        case .thousandStrong:    return 13
        case .setMachine:        return 14
        case .buildingBlocks:    return 20
        case .fullRoster:        return 21
        case .explorer:          return 30
        case .wellRounded:       return 31
        case .renaissanceLifter: return 32
        case .onePlate:          return 40
        case .twoPlates:         return 41
        case .threePlates:       return 42
        case .fourPlates:        return 43
        }
    }

    static func achievementsInCategory(_ category: AchievementCategory) -> [Achievement] {
        Achievement.allCases
            .filter { $0.category == category }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
}
