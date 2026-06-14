//
//  ContentView.swift
//  Ready Set
//
//  Created by Nick Molargik on 4/10/24.
//

import SwiftUI
import SwiftData
import TipKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(CloudSyncManager.self) private var cloudSyncManager

    @AppStorage(AppStorageKeys.isOnboardingComplete) private var isOnboardingComplete: Bool = false

    @Binding var pendingDeepLink: DeepLink?

    @State private var viewModel: ContentView.ViewModel = ViewModel()
    @State private var shouldAnimateDeckEntrance: Bool = false

    var body: some View {
        ZStack {
            switch viewModel.appStage {
            case .splash:
                SplashView(
                    onContinue: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.appStage = .onboarding
                        }
                    }
                )
                .id("splash")
                .transition(viewModel.leadingTransition)
                .zIndex(1)

            case .onboarding:
                OnboardingView(onFinished: {
                    isOnboardingComplete = true
                    Task { await TipEvents.onboardingCompleted.donate() }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.appStage = .syncing
                    }
                })
                .id("onboarding")
                .transition(viewModel.leadingTransition)
                .zIndex(1)

            case .syncing:
                SyncingView(
                    onSyncComplete: { foundData in
                        shouldAnimateDeckEntrance = true
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.appStage = .main
                        }
                    }
                )
                .id("syncing")
                .transition(viewModel.leadingTransition)
                .zIndex(1)

            case .main:
                MainView(
                    animateDeckEntrance: shouldAnimateDeckEntrance,
                    pendingDeepLink: $pendingDeepLink
                )
                .id("main")
                .transition(viewModel.leadingTransition)
                .zIndex(0)
            }
        }
        .task {
            await viewModel.prepareApp(isOnboardingComplete: isOnboardingComplete)
        }
        .onAppear {
            viewModel.configure(cloudSyncManager: cloudSyncManager)
        }
    }
}
    
#Preview("ContentView") {
    // Set up an in-memory ModelContainer for preview
    let container: ModelContainer
    do {
        container = try ModelContainer(
            for:
                SetDeckExercise.self,
                SetDeckRoutine.self,
                SetDeckSet.self,
                SetDeckSetHistory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("Preview ModelContainer setup failed: \(error)")
    }

    let previewExerciseManager = ExerciseManager(context: container.mainContext)

    return ContentView(pendingDeepLink: .constant(nil))
        .modelContainer(container)
        .environment(previewExerciseManager)
        .environment(HealthManager())
        .environment(AchievementManager(exerciseManager: previewExerciseManager))
        .environment(CloudSyncManager())
        .environment(PhoneConnectivityManager())
}
