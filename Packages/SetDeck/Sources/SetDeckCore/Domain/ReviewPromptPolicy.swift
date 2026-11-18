//
//  ReviewPromptPolicy.swift
//  SetDeckCore
//
//  Decides when to ask for an App Store review. SetDeck asks at two value moments —
//  after the third completed workout session and again after the tenth, once the workout
//  summary sheet has been dismissed — and never more than once per app version. Counters live behind `KeyValueStoring` so the
//  policy is host-testable with a fake store.
//

import Foundation

@MainActor
public struct ReviewPromptPolicy {

    /// Completed-workout counts at which a prompt is eligible.
    public static let milestones: Set<Int> = [3, 10]

    private let defaults: any KeyValueStoring

    public init(defaults: any KeyValueStoring = UserDefaults.standard) {
        self.defaults = defaults
    }

    /// Number of workout sessions the user has completed in SetDeck.
    public var completedWorkoutCount: Int {
        defaults.integer(forKey: AppStorageKeys.completedWorkoutCount)
    }

    /// Marketing version of the app the last time a prompt was shown (nil when never shown).
    public var lastPromptedVersion: String? {
        defaults.string(forKey: AppStorageKeys.lastReviewPromptVersion)
    }

    /// Pure rule: prompt when `count` hits a milestone and this `appVersion` hasn't prompted yet.
    public static func shouldPrompt(completedWorkoutCount count: Int, lastPromptedVersion: String?, appVersion: String) -> Bool {
        milestones.contains(count) && lastPromptedVersion != appVersion
    }

    /// Records a completed workout session. Returns `true` when this workout is a review
    /// moment for `appVersion`; the caller asks once the summary sheet is gone and then
    /// calls `markPrompted(appVersion:)`.
    @discardableResult
    public func recordCompletedWorkout(appVersion: String) -> Bool {
        let count = completedWorkoutCount + 1
        defaults.set(count, forKey: AppStorageKeys.completedWorkoutCount)
        return Self.shouldPrompt(completedWorkoutCount: count, lastPromptedVersion: lastPromptedVersion, appVersion: appVersion)
    }

    /// Marks `appVersion` as prompted so it never fires twice per version.
    public func markPrompted(appVersion: String) {
        defaults.set(appVersion, forKey: AppStorageKeys.lastReviewPromptVersion)
    }
}
