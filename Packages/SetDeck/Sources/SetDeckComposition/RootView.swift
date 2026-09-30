//
//  RootView.swift
//  SetDeckComposition
//
//  The stage machine (splash → onboarding → main), successor to the old ContentView.
//  Injects every shared @Observable model into the environment so feature views read
//  them without knowing the composition root.
//

#if os(iOS)
import SwiftUI
import TipKit
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared
import SetDeckFeatureOnboarding
import SetDeckServices

public struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase

    private let session: SessionController

    @AppStorage(AppStorageKeys.isOnboardingComplete) private var isOnboardingComplete: Bool = false

    @State private var viewModel = StageModel()
    @State private var shouldAnimateDeckEntrance: Bool = false
    @State private var wasReturningUser: Bool = false
    @State private var didShowSyncToast: Bool = false
    @State private var didConfirmSync: Bool = false

    public init(session: SessionController) {
        self.session = session
    }

    public var body: some View {
        stageView
            .colorScheme(.dark)
            .toastContainer()
            .environment(session.workoutData)
            .environment(session.achievements)
            .environment(session.toastManager)
            .environment(session.cloudSyncManager)
            .environment(session.muscleGroupInference)
            .environment(session.healthManager)
    }

    private var stageView: some View {
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
                MainView(session: session, animateDeckEntrance: shouldAnimateDeckEntrance)
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
        // iCloud sync runs in the background. When a remote change lands, the change
        // stream already refreshes the deck; confirm the sync (once) with a toast.
        .onChange(of: session.cloudSyncManager.lastSyncDate) { _, newValue in
            guard newValue != nil, viewModel.appStage == .main else { return }
            if didShowSyncToast, !didConfirmSync {
                didConfirmSync = true
                session.toastManager.showSuccess("Synced with iCloud")
            }
        }
    }

    /// On first entry to the main app for a returning user with iCloud available,
    /// surface a lightweight toast (instead of a blocking screen).
    private func handleMainEntry() {
        guard !didShowSyncToast, wasReturningUser, session.cloudSyncManager.isCloudAvailable else { return }
        didShowSyncToast = true
        session.toastManager.show(message: "Syncing with iCloud…", style: .info, icon: "icloud.fill")
    }
}

// MARK: - Stage model

@Observable
final class StageModel {
    var appStage: AppStage = .splash

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

    /// Returning users go straight to the app; iCloud sync continues in the background
    /// with a toast instead of a blocking screen.
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
#endif
