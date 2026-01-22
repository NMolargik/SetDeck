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
        
        // MARK: - Dependencies
        var cloudSyncManager: CloudSyncManager?
        
        // MARK: - Configuration
        func configure(cloudSyncManager: CloudSyncManager) {
            self.cloudSyncManager = cloudSyncManager
        }

        // MARK: - Transitions
        var leadingTransition: AnyTransition {
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
        
        func prepareApp(isOnboardingComplete: Bool) async {
            await MainActor.run {
                appStage = isOnboardingComplete ? .syncing : .splash
            }
        }
    }
}
