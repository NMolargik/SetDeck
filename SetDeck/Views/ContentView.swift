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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(AppStorageKeys.isOnboardingComplete) private var isOnboardingComplete: Bool = false
    
    @Binding var pendingDeepLink: DeepLink?
    
    @State private var viewModel: ContentView.ViewModel = ViewModel()
    @State private var exerciseManager: ExerciseManager?
    @State private var achievementManager: AchievementManager?
    @State private var healthManager: HealthManager = HealthManager()
    @State private var cloudSyncManager = CloudSyncManager()
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
                .environment(healthManager)
                .environment(exerciseManager)
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
                .environment(exerciseManager)
                .environment(cloudSyncManager)
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
                .environment(exerciseManager)
                .environment(healthManager)
                .environment(cloudSyncManager)
                .environment(achievementManager)
            }
        }

        .task {
            // Ensure managers exist in the View
            await MainActor.run {
                if self.exerciseManager == nil {
                    self.exerciseManager = ExerciseManager(context: modelContext)
                }
                if self.achievementManager == nil, let em = self.exerciseManager {
                    self.achievementManager = AchievementManager(exerciseManager: em)
                }
                // Configure cloud sync manager with model context
                self.cloudSyncManager.configure(with: modelContext)
            }
            await viewModel.prepareApp(isOnboardingComplete: isOnboardingComplete)
            
            try? Tips.configure([.displayFrequency(.immediate)])
    
            // Setup Watch connectivity
            setupWatchConnectivity()
        }
        .onAppear {
            viewModel.configure(cloudSyncManager: cloudSyncManager)
        }
    }
    
    private func setupWatchConnectivity() {
        let connectivityManager = PhoneConnectivityManager.shared
        connectivityManager.exerciseManager = exerciseManager
        connectivityManager.activate()
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
    let previewHealthManager = HealthManager()

    return ContentView(pendingDeepLink: .constant(nil))
        .modelContainer(container)
        .environment(previewExerciseManager)
        .environment(previewHealthManager)
}
