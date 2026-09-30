//
//  AppStage.swift
//  SetDeckCore
//
//  Created by Nick Molargik on 11/7/25.
//

import Foundation

nonisolated public enum AppStage: String, Identifiable, Sendable {
    case splash      // Animated branding, "Get Started" button
    case onboarding  // Privacy, Location, Health, Complete
    case main        // Main app experience (iCloud sync runs in the background)

    public var id: String { self.rawValue }
}
