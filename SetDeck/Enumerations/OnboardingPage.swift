//
//  OnboardingPage.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import Foundation

enum OnboardingPage {
    case health
    case builder
    case complete
    
    var next: OnboardingPage {
        switch self {
        case .health: return .builder
        case .builder: return .complete
        case .complete: return .complete
        }
    }
    var previous: OnboardingPage {
        switch self {
        case .health: return .health
        case .builder: return .health
        case .complete: return .builder
        }
    }
}
