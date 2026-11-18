//
//  AppStorageKeys.swift
//  SetDeckCore
//

import Foundation

nonisolated public enum AppStorageKeys {
    public static let isOnboardingComplete = "isSetDeckOnboardingComplete"
    public static let hasCompletedInitialSync = "hasCompletedInitialSync"
    public static let useMetricUnits = "useMetricUnits"
    public static let useDayMonthYearDates = "useDayMonthYearDates"
    public static let celebratedAchievements = "celebratedAchievements"
    /// Set once already-earned achievements have been silently absorbed on this install.
    public static let achievementsBaselineEstablished = "achievementsBaselineEstablished"
    public static let completedWorkoutCount = "completedWorkoutCount"
    public static let lastReviewPromptVersion = "lastReviewPromptVersion"
}
