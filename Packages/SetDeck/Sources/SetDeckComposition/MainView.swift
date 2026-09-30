//
//  MainView.swift
//  SetDeckComposition
//
//  The four-tab shell plus the achievement celebration overlay and the live-workout
//  toolbar chip. Deep links route through the session's `pendingDeepLink`.
//

#if os(iOS)
import SwiftUI
import TipKit
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared
import SetDeckFeatureRoutine
import SetDeckFeatureStats
import SetDeckFeatureHealth
import SetDeckFeatureSettings
import SetDeckServices

struct MainView: View {
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @Environment(AchievementModel.self) private var achievementManager: AchievementModel

    let session: SessionController
    var animateDeckEntrance: Bool = false

    @State private var viewModel = TabModel()
    @State private var workoutNow: Date = Date()
    @State private var workoutToolbarTimer: Timer? = nil

    private let editRoutineTip = EditRoutineTip()

    private var isStrengthWorkoutActive: Bool {
        healthManager.isStrengthTrainingActive
    }

    private var workoutElapsedString: String {
        healthManager.currentWorkoutStartDate?.elapsedString(to: workoutNow) ?? "00:00:00"
    }

    var body: some View {
        ZStack {
            tabView()

            if let celebration = achievementManager.pendingCelebration {
                AchievementCelebrationView(achievement: celebration) {
                    achievementManager.dismissCelebration()
                }
                .zIndex(100)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: achievementManager.pendingCelebration != nil)
        .onAppear {
            workoutToolbarTimer?.invalidate()
            workoutToolbarTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                MainActor.assumeIsolated { workoutNow = Date() }
            }
        }
        .onDisappear {
            workoutToolbarTimer?.invalidate()
            workoutToolbarTimer = nil
        }
    }

    private func handleDeepLink(_ link: DeepLink?) {
        guard let link = link else { return }

        // Reset the deep link after handling
        defer { session.pendingDeepLink = nil }

        switch link {
        case .routine:
            viewModel.appTab = .routine
        case .stats:
            viewModel.appTab = .stats
        case .health:
            viewModel.appTab = .health
        case .settings:
            viewModel.appTab = .settings
        case .editRoutine:
            viewModel.appTab = .routine
            viewModel.showingEditRoutineSheet = true
        }
    }

    // MARK: - Tabs

    @ViewBuilder
    private func tabView() -> some View {
        TabView(selection: $viewModel.appTab) {
            NavigationStack {
                RoutineView(animateEntrance: animateDeckEntrance)
                    .navigationTitle("SetDeck")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                editRoutineTip.invalidate(reason: .actionPerformed)
                                viewModel.showingEditRoutineSheet = true
                            } label: {
                                Text("Edit Routine")
                                    .bold()
                            }
                            .tint(.greenStart)
                            .popoverTip(editRoutineTip, arrowEdge: .bottom)
                        }
                        if isStrengthWorkoutActive {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    withAnimation(.easeInOut) {
                                        viewModel.appTab = .health
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "figure.strengthtraining.traditional")
                                            .font(.body)
                                        Text(workoutElapsedString)
                                            .monospacedDigit()
                                            .bold()
                                    }
                                }
                                .tint(.white)
                                .accessibilityLabel("Strength workout running time")
                                .accessibilityValue(workoutElapsedString)
                            }
                        }
                    }
                    .sheet(isPresented: $viewModel.showingEditRoutineSheet) {
                        NavigationStack {
                            EditRoutineView()
                                .navigationTitle("Edit Routine")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                        .preferredColorScheme(.dark)
                    }
            }
            .tabItem {
                AppTab.routine.icon()
                Text(AppTab.routine.rawValue)
            }
            .tag(AppTab.routine)

            NavigationStack() {
                StatsView()
                    .navigationTitle(AppTab.stats.rawValue)
            }
            .tabItem {
                AppTab.stats.icon()
                Text(AppTab.stats.rawValue)
            }
            .tag(AppTab.stats)

            NavigationStack {
                HealthView()
                    .navigationTitle(AppTab.health.rawValue)
            }
            .tabItem {
                AppTab.health.icon()
                Text(AppTab.health.rawValue)
            }
            .tag(AppTab.health)

            NavigationStack {
                SettingsView()
                .navigationTitle(AppTab.settings.rawValue)
            }
            .tabItem {
                AppTab.settings.icon()
                Text(AppTab.settings.rawValue)
            }
            .tag(AppTab.settings)
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(viewModel.appTab.color())
        .onChange(of: session.pendingDeepLink) { _, newLink in
            handleDeepLink(newLink)
        }
        .onAppear {
            if session.pendingDeepLink != nil {
                handleDeepLink(session.pendingDeepLink)
            }
        }
    }
}

// MARK: - Tab model

@Observable
final class TabModel {
    var appTab: AppTab = .routine
    var showingEditRoutineSheet: Bool = false
}
#endif
