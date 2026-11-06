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

    @Test("prompts once after the first completed workout")
    func firstWorkoutPrompts() {
        let store = FakeKeyValueStore()
        let policy = ReviewPromptPolicy(defaults: store)
        #expect(policy.recordCompletedWorkout(appVersion: "2.5") == true)
        #expect(policy.completedWorkoutCount == 1)
        #expect(policy.lastPromptedVersion == "2.5")
    }

    @Test("does not prompt between milestones")
    func betweenMilestonesSilent() {
        let store = FakeKeyValueStore()
        let policy = ReviewPromptPolicy(defaults: store)
        _ = policy.recordCompletedWorkout(appVersion: "2.5")
        for _ in 2..<20 {
            #expect(policy.recordCompletedWorkout(appVersion: "2.6") == false)
        }
        #expect(policy.completedWorkoutCount == 19)
    }

    @Test("prompts again at the 20th workout on a new version")
    func twentiethWorkoutPromptsOnNewVersion() {
        let store = FakeKeyValueStore()
        let policy = ReviewPromptPolicy(defaults: store)
        _ = policy.recordCompletedWorkout(appVersion: "2.5")
        for _ in 2..<20 { _ = policy.recordCompletedWorkout(appVersion: "2.6") }
        #expect(policy.recordCompletedWorkout(appVersion: "2.6") == true)
        #expect(policy.completedWorkoutCount == 20)
        #expect(policy.lastPromptedVersion == "2.6")
    }

    @Test("never prompts twice on the same version")
    func sameVersionOnlyOnce() {
        let store = FakeKeyValueStore()
        let policy = ReviewPromptPolicy(defaults: store)
        _ = policy.recordCompletedWorkout(appVersion: "2.5")
        for _ in 2..<20 { _ = policy.recordCompletedWorkout(appVersion: "2.5") }
        #expect(policy.recordCompletedWorkout(appVersion: "2.5") == false)
        #expect(policy.completedWorkoutCount == 20)
    }

    @Test("pure rule covers milestones and version gating")
    func pureRule() {
        #expect(ReviewPromptPolicy.shouldPrompt(completedWorkoutCount: 1, lastPromptedVersion: nil, appVersion: "2.5"))
        #expect(ReviewPromptPolicy.shouldPrompt(completedWorkoutCount: 20, lastPromptedVersion: "2.4", appVersion: "2.5"))
        #expect(!ReviewPromptPolicy.shouldPrompt(completedWorkoutCount: 20, lastPromptedVersion: "2.5", appVersion: "2.5"))
        #expect(!ReviewPromptPolicy.shouldPrompt(completedWorkoutCount: 5, lastPromptedVersion: nil, appVersion: "2.5"))
        #expect(!ReviewPromptPolicy.shouldPrompt(completedWorkoutCount: 0, lastPromptedVersion: nil, appVersion: "2.5"))
    }
}
