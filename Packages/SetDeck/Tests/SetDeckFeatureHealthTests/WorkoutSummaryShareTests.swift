//
//  WorkoutSummaryShareTests.swift
//  SetDeckFeatureHealthTests
//
//  The summary card renders legibly and the share message carries the tracked app link.
//  The card itself is iOS-only, so these run on an iOS simulator destination.
//

import Foundation
import Testing

#if os(iOS)
import SwiftUI
import HealthKit
import SetDeckServices
@testable import SetDeckFeatureHealth

@Suite("Workout summary sharing")
@MainActor
struct WorkoutSummaryShareTests {
    private func summary(kcal: Double?) -> WorkoutSummary {
        WorkoutSummary(
            id: UUID(),
            startDate: Date(timeIntervalSinceReferenceDate: 800_000_000),
            endDate: Date(timeIntervalSinceReferenceDate: 800_003_000),
            activityType: .traditionalStrengthTraining,
            totalEnergyBurnedKCal: kcal
        )
    }

    @Test func messageEndsWithTheTrackedLink() {
        let withEnergy = WorkoutSummaryShareLink.message(for: summary(kcal: 320))
        let lines = withEnergy.split(separator: "\n").map(String.init)
        #expect(lines.count == 2)
        #expect(lines[0].contains("320 cal"))
        #expect(lines[1] == "https://molargiksoftware.com/go/setdeck?ct=share_summary")
        let without = WorkoutSummaryShareLink.message(for: summary(kcal: nil))
        #expect(without.hasSuffix("?ct=share_summary"))
        #expect(!without.contains("cal\n"))
    }

    @Test func cardRendersAtShareSize() throws {
        let renderer = ImageRenderer(content: WorkoutSummaryCardView(summary: summary(kcal: 320)).colorScheme(.dark))
        renderer.scale = 3
        let image = try #require(renderer.uiImage)
        #expect(image.size.width == 340)
        #expect(image.size.height > 150)
        if let out = ProcessInfo.processInfo.environment["SETDECK_CARD_PNG"], let data = image.pngData() {
            try data.write(to: URL(fileURLWithPath: out))
        }
    }
}
#endif
