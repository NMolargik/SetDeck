//
//  OnboardingStep.swift
//  SetDeckCore
//
//  Created by Nick Molargik on 11/29/25.
//

import Foundation

nonisolated public enum OnboardingStep: CaseIterable, Sendable {
    case privacy
    case health
    case builder
    case complete
    
    public var title: String {
        switch self {
        case .privacy: return "Your Privacy"
        case .health: return "Health Access"
        case .builder: return "Build Your Deck"
        case .complete: return "You're All Set"
        }
    }
}
