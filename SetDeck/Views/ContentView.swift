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
    @Environment(ExerciseManager.self) private var exerciseManager
    @Environment(ToastManager.self) private var toastManager

    @AppStorage(AppStorageKeys.isOnboardingComplete) private var isOnboardingComplete: Bool = false

    @Binding var pendingDeepLink: DeepLink?

    @State private var viewModel: ContentView.ViewModel = ViewModel()
    @State private var shouldAnimateDeckEntrance: Bool = false
    @State private var wasReturningUser: Bool = false
    @State private var didShowSyncToast: Bool = false
    @State private var didConfirmSync: Bool = false

    var body: some View {
        ZStack {
            switch viewModel.appStage {
            case .splash:
                SplashView(
                    onContinue: {
                        viewModel.advance(to: .onboarding)
                    }
                )
                .id("splash")
                .transition(viewModel.leadingTransition)
                .zIndex(1)

            case .onboarding:
                OnboardingView(onFinished: {
                    isOnboardingComplete = true
                    Task { await TipEvents.onboardingCompleted.donate() }
                    shouldAnimateDeckEntrance = true
                    viewModel.advance(to: .main)
                })
                .id("onboarding")
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
                .onAppear { handleMainEntry() }
            }
        }
        .task {
            wasReturningUser = isOnboardingComplete
            viewModel.prepareApp(isOnboardingComplete: isOnboardingComplete)
        }
        // iCloud sync runs in the background. When a remote change lands,
        // refresh the deck and (once) confirm the sync with a toast.
        .onChange(of: cloudSyncManager.lastSyncDate) { _, newValue in
            guard newValue != nil, viewModel.appStage == .main else { return }
            Task { await exerciseManager.refresh() }
            if didShowSyncToast, !didConfirmSync {
                didConfirmSync = true
                toastManager.showSuccess("Synced with iCloud")
            }
        }
    }

    /// On first entry to the main app for a returning user with iCloud
    /// available, surface a lightweight toast (instead of a blocking screen)
    /// and nudge the local cache in case data arrived before launch finished.
    private func handleMainEntry() {
        guard !didShowSyncToast, wasReturningUser, cloudSyncManager.isCloudAvailable else { return }
        didShowSyncToast = true
        toastManager.show(message: "Syncing with iCloud…", style: .info, icon: "icloud.fill")
        Task { await exerciseManager.refresh() }
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
        .environment(ToastManager())
}
