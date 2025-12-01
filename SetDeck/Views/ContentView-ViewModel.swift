//
//  ContentView-ViewModel.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/12/25.
//

import SwiftUI

extension ContentView {
    @Observable
    class ViewModel {
        var appStage: AppStage = .start
        var resetApplication: (() -> Void)?
        
        func prepareApp(isOnboardingComplete: Bool) {
            self.appStage = isOnboardingComplete ? .main : .splash
        }
        
        var leadingTransition: AnyTransition {
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }
}
