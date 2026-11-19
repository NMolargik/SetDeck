//
//  ReviewPromptPolicyTests.swift
//  SetDeckCoreTests
//

import Foundation
import Testing
@testable import SetDeckCore

@Suite("ReviewPromptPolicy")
@MainActor
struct ReviewPromptPolicyTests {

    @Test("does not prompt on the first or second workout")
    func earlyWorkoutsSilent() {
        let policy = ReviewPromptPolicy(defaults: FakeKeyValueStore())
        #expect(policy.recordCompletedWorkout(appVersion: "2.5") == false)
        #expect(policy.recordCompletedWorkout(appVersion: "2.5") == false)
        #expect(policy.completedWorkoutCount == 2)
        #expect(policy.lastPromptedVersion == nil)
    }

    @Test("third workout is a review moment, recorded only once marked")
    func thirdWorkoutPrompts() {
        let policy = ReviewPromptPolicy(defaults: FakeKeyValueStore())
        _ = policy.recordCompletedWorkout(appVersion: "2.5")
        _ = policy.recordCompletedWorkout(appVersion: "2.5")
        #expect(policy.recordCompletedWorkout(appVersion: "2.5") == true)
        #expect(policy.lastPromptedVersion == nil, "marked only after the alert is requested")
        policy.markPrompted(appVersion: "2.5")
        #expect(policy.lastPromptedVersion == "2.5")
    }

    @Test("does not prompt between milestones")
    func betweenMilestonesSilent() {
        let policy = ReviewPromptPolicy(defaults: FakeKeyValueStore())
        for _ in 1...3 { _ = policy.recordCompletedWorkout(appVersion: "2.5") }
        policy.markPrompted(appVersion: "2.5")
        for _ in 4..<10 {
            #expect(policy.recordCompletedWorkout(appVersion: "2.6") == false)
        }
        #expect(policy.completedWorkoutCount == 9)
    }

    @Test("prompts again at the 10th workout on a new version")
    func tenthWorkoutPromptsOnNewVersion() {
        let policy = ReviewPromptPolicy(defaults: FakeKeyValueStore())
        for _ in 1...3 { _ = policy.recordCompletedWorkout(appVersion: "2.5") }
        policy.markPrompted(appVersion: "2.5")
        for _ in 4..<10 { _ = policy.recordCompletedWorkout(appVersion: "2.6") }
        #expect(policy.recordCompletedWorkout(appVersion: "2.6") == true)
        #expect(policy.completedWorkoutCount == 10)
    }

    @Test("never prompts twice on the same version")
    func sameVersionOnlyOnce() {
        let policy = ReviewPromptPolicy(defaults: FakeKeyValueStore())
        for _ in 1...3 { _ = policy.recordCompletedWorkout(appVersion: "2.5") }
        policy.markPrompted(appVersion: "2.5")
        for _ in 4..<10 { _ = policy.recordCompletedWorkout(appVersion: "2.5") }
        #expect(policy.recordCompletedWorkout(appVersion: "2.5") == false)
    }

    @Test("pure rule covers milestones and version gating")
    func pureRule() {
        #expect(ReviewPromptPolicy.milestones == [3, 10])
        #expect(ReviewPromptPolicy.shouldPrompt(completedWorkoutCount: 3, lastPromptedVersion: nil, appVersion: "2.5"))
        #expect(ReviewPromptPolicy.shouldPrompt(completedWorkoutCount: 10, lastPromptedVersion: "2.4", appVersion: "2.5"))
        #expect(!ReviewPromptPolicy.shouldPrompt(completedWorkoutCount: 10, lastPromptedVersion: "2.5", appVersion: "2.5"))
        #expect(!ReviewPromptPolicy.shouldPrompt(completedWorkoutCount: 1, lastPromptedVersion: nil, appVersion: "2.5"))
        #expect(!ReviewPromptPolicy.shouldPrompt(completedWorkoutCount: 20, lastPromptedVersion: nil, appVersion: "2.5"))
        #expect(!ReviewPromptPolicy.shouldPrompt(completedWorkoutCount: 0, lastPromptedVersion: nil, appVersion: "2.5"))
    }

    @Test("links point at SetDeck and carry attribution")
    func links() {
        #expect(AppLinks.writeReview.absoluteString == "https://apps.apple.com/app/id6484503374?action=write-review")
        #expect(AppLinks.shareApp.absoluteString == "https://farsidesoftware.com/setdeck?ct=share_app")
        #expect(AppLinks.shareSummary.absoluteString == "https://farsidesoftware.com/setdeck?ct=share_summary")
    }
}
