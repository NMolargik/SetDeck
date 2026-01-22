//
//  OnboardingStep.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import Foundation

enum OnboardingStep: CaseIterable {
    case privacy
    case health
    case builder
    case complete
    
    var title: String {
        switch self {
        case .privacy: return "Your Privacy"
        case .health: return "Health Access"
        case .builder: return "Build Your Deck"
        case .complete: return "You're All Set"
        }
    }
}
