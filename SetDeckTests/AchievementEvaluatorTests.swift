//
//  AchievementEvaluatorTests.swift
//  SetDeckTests
//
//  Created by Nick Molargik on 6/14/26.
//

import Foundation
import Testing
@testable import SetDeck

@Suite("AchievementEvaluator Tests")
struct AchievementEvaluatorTests {

    private let calendar = AchievementEvaluator.pinnedCalendar()

    /// Builds `count` consecutive day dates ending today (one per day).
    private func consecutiveDays(_ count: Int) -> [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }

    // MARK: - Volume thresholds

    @Test("Volume achievements unlock at their set-count thresholds",
          arguments: [
            (1, Achievement.firstWorkout),
            (10, Achievement.gettingStarted),
            (100, Achievement.century),
            (500, Achievement.fiveHundredClub),
            (1_000, Achievement.thousandStrong),
            (5_000, Achievement.setMachine)
          ])
    func volumeThresholds(count: Int, achievement: Achievement) {
        let justUnder = WorkoutStats(totalSetsLogged: count - 1)
        let atThreshold = WorkoutStats(totalSetsLogged: count)
        #expect(!AchievementEvaluator.isMet(achievement, stats: justUnder, calendar: calendar))
        #expect(AchievementEvaluator.isMet(achievement, stats: atThreshold, calendar: calendar))
    }

    // MARK: - Strength thresholds

    @Test("Strength achievements unlock at their weight thresholds",
          arguments: [
            (135.0, Achievement.onePlate),
            (225.0, Achievement.twoPlates),
            (315.0, Achievement.threePlates),
            (405.0, Achievement.fourPlates)
          ])
    func strengthThresholds(weight: Double, achievement: Achievement) {
        #expect(!AchievementEvaluator.isMet(achievement, stats: WorkoutStats(maxWeightLogged: weight - 0.1), calendar: calendar))
        #expect(AchievementEvaluator.isMet(achievement, stats: WorkoutStats(maxWeightLogged: weight), calendar: calendar))
    }

    // MARK: - Variety thresholds

    @Test("Variety achievements count unique exercise names")
    func variety() {
        let names = Set((0..<20).map { "Exercise \($0)" })
        let stats = WorkoutStats(uniqueExerciseNames: names)
        #expect(AchievementEvaluator.isMet(.explorer, stats: stats, calendar: calendar))
        #expect(AchievementEvaluator.isMet(.wellRounded, stats: stats, calendar: calendar))
        #expect(AchievementEvaluator.isMet(.renaissanceLifter, stats: stats, calendar: calendar))

        let few = WorkoutStats(uniqueExerciseNames: Set(["A", "B", "C", "D"]))
        #expect(!AchievementEvaluator.isMet(.explorer, stats: few, calendar: calendar))
    }

    // MARK: - Routine coverage

    @Test("Routine achievements count days with exercises")
    func routineCoverage() {
        let fiveDays = WorkoutStats(daysWithExercises: [0, 1, 2, 3, 4])
        #expect(AchievementEvaluator.isMet(.buildingBlocks, stats: fiveDays, calendar: calendar))
        #expect(!AchievementEvaluator.isMet(.fullRoster, stats: fiveDays, calendar: calendar))

        let allDays = WorkoutStats(daysWithExercises: Set(0...6))
        #expect(AchievementEvaluator.isMet(.fullRoster, stats: allDays, calendar: calendar))
    }

    // MARK: - Consecutive-day streaks

    @Test("twoWeekStreak needs 14 consecutive days")
    func twoWeekStreak() {
        #expect(!AchievementEvaluator.isMet(.twoWeekStreak,
                                            stats: WorkoutStats(completionDates: consecutiveDays(13)),
                                            calendar: calendar))
        #expect(AchievementEvaluator.isMet(.twoWeekStreak,
                                           stats: WorkoutStats(completionDates: consecutiveDays(14)),
                                           calendar: calendar))
    }

    @Test("A gap resets the streak")
    func streakGap() {
        let today = calendar.startOfDay(for: Date())
        // 10 consecutive days, then a 2-day gap, then 3 days — longest run is 10.
        var dates = (0..<10).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        dates += (13..<16).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        #expect(AchievementEvaluator.longestConsecutiveDayStreak(dates: dates, calendar: calendar) == 10)
    }

    @Test("Multiple sets on the same day count as one streak day")
    func sameDayDeduplicated() {
        let today = calendar.startOfDay(for: Date())
        let dates = Array(repeating: today, count: 5)
        #expect(AchievementEvaluator.longestConsecutiveDayStreak(dates: dates, calendar: calendar) == 1)
    }

    // MARK: - Week coverage

    @Test("weekWarrior needs 5 distinct weekdays in one week")
    func weekWarrior() {
        // Build dates Sunday...Thursday of the current week.
        let today = calendar.startOfDay(for: Date())
        let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: today).date!
        let fiveWeekdays = (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        #expect(AchievementEvaluator.isMet(.weekWarrior,
                                           stats: WorkoutStats(completionDates: fiveWeekdays),
                                           calendar: calendar))

        let fourWeekdays = Array(fiveWeekdays.prefix(4))
        #expect(!AchievementEvaluator.isMet(.weekWarrior,
                                            stats: WorkoutStats(completionDates: fourWeekdays),
                                            calendar: calendar))
    }

    // MARK: - Empty state

    @Test("No data unlocks nothing")
    func emptyUnlocksNothing() {
        #expect(AchievementEvaluator.unlockedAchievements(from: WorkoutStats(), calendar: calendar).isEmpty)
    }
}
