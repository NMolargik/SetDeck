//
//  AchievementEvaluator.swift
//  SetDeck
//
//  Created by Nick Molargik on 6/14/26.
//

import Foundation

/// Pure achievement-unlock logic. All calendar math is parameterized on a
/// `Calendar` (defaulting to a locale-independent Gregorian calendar) so
/// results are deterministic and independent of device settings.
nonisolated enum AchievementEvaluator {

    /// A fixed calendar for streak/week math, so the app, widgets, and tests
    /// always agree regardless of the user's locale or first-weekday setting.
    static func pinnedCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 1 // Sunday
        return calendar
    }

    /// Returns every achievement currently satisfied by `stats`.
    static func unlockedAchievements(from stats: WorkoutStats,
                                     calendar: Calendar = pinnedCalendar()) -> Set<Achievement> {
        var unlocked = Set<Achievement>()
        for achievement in Achievement.allCases where isMet(achievement, stats: stats, calendar: calendar) {
            unlocked.insert(achievement)
        }
        return unlocked
    }

    /// Whether a single achievement is satisfied by `stats`.
    static func isMet(_ achievement: Achievement,
                      stats: WorkoutStats,
                      calendar: Calendar = pinnedCalendar()) -> Bool {
        switch achievement {
        // Consistency
        case .firstWorkout:   return stats.totalSetsLogged >= 1
        case .weekWarrior:    return hasWeekWithAtLeast(5, dates: stats.completionDates, calendar: calendar)
        case .fullWeek:       return hasWeekWithAtLeast(7, dates: stats.completionDates, calendar: calendar)
        case .twoWeekStreak:  return longestConsecutiveDayStreak(dates: stats.completionDates, calendar: calendar) >= 14
        case .monthStrong:    return longestConsecutiveDayStreak(dates: stats.completionDates, calendar: calendar) >= 30

        // Volume
        case .gettingStarted: return stats.totalSetsLogged >= 10
        case .century:        return stats.totalSetsLogged >= 100
        case .fiveHundredClub: return stats.totalSetsLogged >= 500
        case .thousandStrong: return stats.totalSetsLogged >= 1_000
        case .setMachine:     return stats.totalSetsLogged >= 5_000

        // Routine
        case .buildingBlocks: return stats.daysWithExercises.count >= 5
        case .fullRoster:     return stats.daysWithExercises.count >= 7

        // Variety
        case .explorer:          return stats.uniqueExerciseNames.count >= 5
        case .wellRounded:       return stats.uniqueExerciseNames.count >= 10
        case .renaissanceLifter: return stats.uniqueExerciseNames.count >= 20

        // Strength
        case .onePlate:    return stats.maxWeightLogged >= 135
        case .twoPlates:   return stats.maxWeightLogged >= 225
        case .threePlates: return stats.maxWeightLogged >= 315
        case .fourPlates:  return stats.maxWeightLogged >= 405
        }
    }

    /// Longest run of consecutive calendar days that have at least one entry.
    static func longestConsecutiveDayStreak(dates: [Date], calendar: Calendar) -> Int {
        guard !dates.isEmpty else { return 0 }
        let days = Set(dates.map { calendar.startOfDay(for: $0) }).sorted()
        guard !days.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        for index in 1..<days.count {
            if calendar.dateComponents([.day], from: days[index - 1], to: days[index]).day == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    /// Whether any single week-of-year contains at least `n` distinct weekdays
    /// with entries.
    static func hasWeekWithAtLeast(_ n: Int, dates: [Date], calendar: Calendar) -> Bool {
        guard !dates.isEmpty else { return false }
        var weekdaysByWeek: [String: Set<Int>] = [:]
        for date in dates {
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            let key = "\(components.yearForWeekOfYear ?? 0)-\(components.weekOfYear ?? 0)"
            let weekday = calendar.component(.weekday, from: date)
            weekdaysByWeek[key, default: []].insert(weekday)
        }
        return weekdaysByWeek.values.contains { $0.count >= n }
    }
}
