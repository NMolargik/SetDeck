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
        // MARK: - App State
        var appStage: AppStage = .splash

        // MARK: - Transitions
        var leadingTransition: AnyTransition {
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }

        func advance(to stage: AppStage) {
            withAnimation(.easeInOut(duration: 0.3)) {
                appStage = stage
            }
        }

        /// Returning users go straight to the app; iCloud sync continues in
        /// the background with a toast instead of a blocking screen.
        func prepareApp(isOnboardingComplete: Bool) {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
                appStage = .main
                return
            }
            #endif
            appStage = isOnboardingComplete ? .main : .splash
        }
    }
}
