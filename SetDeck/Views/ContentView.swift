//
//  ContentView.swift
//  Ready Set
//
//  Created by Nick Molargik on 4/10/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(ExerciseManager.self) private var exerciseManager: ExerciseManager
    @AppStorage(AppStorageKeys.hasMigratedFromReadySet) private var hasMigratedFromReadySet: Bool = false
    @AppStorage(AppStorageKeys.isOnboardingComplete) private var isOnboardingComplete: Bool = false

    var resetApplication: () -> Void
    
    @State private var viewModel: ContentView.ViewModel = ViewModel()
    @State private var healthManager: HealthManager = HealthManager()

    var body: some View {
        ZStack {
            switch viewModel.appStage {
            case .start:
                ProgressView()
                    .id("start")
                    .zIndex(0)
                    .task {
                        viewModel.prepareApp(isOnboardingComplete: isOnboardingComplete)
                    }
            case .splash:
                SplashView(
                    moveToMigration: {
                        viewModel.appStage = hasMigratedFromReadySet ? .onboarding : .migration
                    }
                )
                .id("splash")
                .transition(viewModel.leadingTransition)
                .zIndex(1)
            case .migration:
                MigrationView(
                    migrationComplete: {
                        hasMigratedFromReadySet = true
                        withAnimation {
                            viewModel.appStage = .onboarding
                        }
                    }
                )
                .id("migration")
                .environment(exerciseManager)
                .transition(viewModel.leadingTransition)
                .zIndex(1)
            case .onboarding:
                OnboardingView(onFinished: {
                    isOnboardingComplete = true
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.appStage = .main
                    }
                })
                .id("onboarding")
                .transition(viewModel.leadingTransition)
                .zIndex(1)
                .environment(healthManager)
                .environment(exerciseManager)
            case .main:
                MainView(
                    resetApplication: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            resetApplication()
                        }
                    }
                )
                .id("main")
                .transition(viewModel.leadingTransition)
                .environment(exerciseManager)
                .environment(healthManager)
                .zIndex(0)
            }
        }
    }
}

#Preview {
    let container: ModelContainer
    do {
        container = try ModelContainer(for: Exercise.self, SetDeckExercise.self, SetDeckRoutine.self, SetDeckSet.self, SetDeckSetHistory.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    } catch {
        fatalError("Preview ModelContainer setup failed: \(error)")
    }
    let previewExerciseManager = ExerciseManager(context: container.mainContext)
    return ContentView(
        resetApplication: {}
    )
        .modelContainer(container)
        .environment(previewExerciseManager)
}
