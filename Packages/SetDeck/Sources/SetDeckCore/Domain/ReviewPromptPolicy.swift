//
//  ReviewPromptPolicy.swift
//  SetDeckCore
//
//  Decides when to ask for an App Store review. SetDeck asks at two value moments —
//  right after the first completed workout session and again after the twentieth — and
//  never more than once per app version. Counters live behind `KeyValueStoring` so the
//  policy is host-testable with a fake store.
//

import Foundation

@MainActor
public struct ReviewPromptPolicy {

    /// Completed-workout counts at which a prompt is eligible.
    public static let milestones: Set<Int> = [1, 20]

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

    /// Records a completed workout session. Returns `true` when the caller should request
    /// a review now; the version is marked as prompted so it never fires twice per version.
    @discardableResult
    public func recordCompletedWorkout(appVersion: String) -> Bool {
        let count = completedWorkoutCount + 1
        defaults.set(count, forKey: AppStorageKeys.completedWorkoutCount)
        guard Self.shouldPrompt(completedWorkoutCount: count, lastPromptedVersion: lastPromptedVersion, appVersion: appVersion) else {
            return false
        }
        defaults.set(appVersion, forKey: AppStorageKeys.lastReviewPromptVersion)
        return true
    }
}
