//
//  MainView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI
import SwiftData
import TipKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(ExerciseManager.self) private var exerciseManager: ExerciseManager
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @Environment(AchievementManager.self) private var achievementManager: AchievementManager

    var animateDeckEntrance: Bool = false

    @Binding var pendingDeepLink: DeepLink?

    @State private var viewModel: ViewModel = ViewModel()
    @State private var showingRoutineEditSheet: Bool = false
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
            Group {
                if isRegularWidth {
                    regularWidthView()
                } else {
                    compactWidthView()
                }
            }

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
    
    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }
    
    // MARK: - iPAD
    @ContentBuilder
    private func regularWidthView() -> some View {
        NavigationSplitView {
            ZStack {
                NavigationStack {
                    VStack(spacing: 0) {
                        RoutineView(animateEntrance: animateDeckEntrance)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .navigationSplitViewColumnWidth(min: 360, ideal: 420, max: 520)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                editRoutineTip.invalidate(reason: .actionPerformed)
                                showingRoutineEditSheet = true
                            } label: {
                                Text("Edit Routine")
                                    .bold()
                            }
                            .tint(.greenStart)
                            .popoverTip(editRoutineTip, arrowEdge: .bottom)
                        }
                    }
                    .sheet(isPresented: $showingRoutineEditSheet) {
                        NavigationStack {
                            EditRoutineView()
                                .navigationTitle("Edit Routine")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                        .preferredColorScheme(.dark)
                    }
                }
            }
        } detail: {
            NavigationStack(path: $viewModel.listPath) {
                ScrollView {
                    StatsView()
                    HealthView()
                }
                .navigationTitle("SetDeck")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if isStrengthWorkoutActive {
                            Button(action: {}) {
                                HStack(spacing: 6) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                    Text(workoutElapsedString)
                                        .monospacedDigit()
                                }
                            }
                            .tint(.greenStart)
                            .accessibilityLabel("Strength workout running time")
                            .accessibilityValue(workoutElapsedString)
                        }
                        Button {
                            viewModel.showingSettingsSheet = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                        .accessibilityLabel("Settings")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingSettingsSheet) {
            NavigationStack {
                SettingsView()
                .interactiveDismissDisabled()
                .presentationDetents([.large])
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            viewModel.showingSettingsSheet = false
                        }
                    }
                }
            }
        }
        .onChange(of: pendingDeepLink) { _, newLink in
            handleDeepLink(newLink)
        }
        .onAppear {
            // Handle any pending deep link on appear
            if pendingDeepLink != nil {
                handleDeepLink(pendingDeepLink)
            }
        }
    }
    
    private func handleDeepLink(_ link: DeepLink?) {
        guard let link = link else { return }

        // Reset the deep link after handling
        defer { pendingDeepLink = nil }

        switch link {
        case .routine:
            viewModel.appTab = .routine
        case .settings:
            viewModel.appTab = .settings
            viewModel.showingSettingsSheet = true
        case .stats:
            viewModel.appTab = .stats
        }
    }
    
    // MARK: - iPHONE
    
    @ContentBuilder
    private func compactWidthView() -> some View {
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
        .tint(viewModel.appTab.color())
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([SetDeckRoutine.self, SetDeckExercise.self, SetDeckSet.self, SetDeckSetHistory.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    
    // Seed routines with content for all days except Saturday (day 6)
    let dayIndices = [0, 1, 2, 3, 4, 5] // 0 = Sunday ... 5 = Friday
    for d in dayIndices {
        let routine = SetDeckRoutine.sample(day: d)
        context.insert(routine)
    }
    try? context.save()
    
    let previewExerciseManager = ExerciseManager(context: context)
    return MainView(pendingDeepLink: .constant(nil))
        .preferredColorScheme(.dark)
        .modelContainer(container)
        .environment(previewExerciseManager)
        .environment(HealthManager())
        .environment(AchievementManager(exerciseManager: previewExerciseManager))
}

