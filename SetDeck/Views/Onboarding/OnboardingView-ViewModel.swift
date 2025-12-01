//
//  OnboardingView-ViewModel.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI

extension OnboardingView {
    @Observable
    class ViewModel {
        var currentPage: OnboardingPage = .health
        var isMovingForward: Bool = true
        
        func criteriaMet(healthManager: HealthManager) -> Bool {
            switch(self.currentPage) {
            case .health:
                return healthManager.isAuthorized
            case .builder:
                return true
            case .complete:
                return true
            }
        }
        
        var forwardTransition: AnyTransition {
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
        
        var backwardTransition: AnyTransition {
            .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                // when going back: outgoing page exits toward trailing
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }
}
