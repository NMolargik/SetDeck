//
//  MainView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.scenePhase) private var scenePhase
    
    @Environment(ExerciseManager.self) private var exerciseManager: ExerciseManager
    @Environment(HealthManager.self) private var healthManager: HealthManager

    var resetApplication: () -> Void
    
    @State private var viewModel: ViewModel = ViewModel()
    @State private var showingEditRoutineSheet: Bool = false
    
    // Workout timer state for toolbar
    @State private var workoutNow: Date = Date()
    @State private var workoutToolbarTimer: Timer? = nil

    private var isStrengthWorkoutActive: Bool {
        healthManager.isStrengthTrainingActive
    }

    private var workoutElapsedString: String {
        guard let start = healthManager.currentWorkoutStartDate else { return "00:00:00" }
        let interval = Int(workoutNow.timeIntervalSince(start))
        let h = interval / 3600
        let m = (interval % 3600) / 60
        let s = interval % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    var body: some View {
        Group {
            if isRegularWidth {
                regularWidthView()
            } else {
                compactWidthView()
            }
        }
        .onAppear {
            workoutToolbarTimer?.invalidate()
            workoutToolbarTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                workoutNow = Date()
            }
        }
        .onDisappear {
            workoutToolbarTimer?.invalidate()
            workoutToolbarTimer = nil
        }
    }
    
    private var isRegularWidth: Bool {
        hSizeClass == .regular
    }
    
    // MARK: - iPAD
    @ViewBuilder
    private func regularWidthView() -> some View {
        NavigationSplitView {
            ZStack {
                NavigationStack {
                    VStack(spacing: 0) {
                        RoutineView()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .navigationSplitViewColumnWidth(min: 360, ideal: 420, max: 520)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showingEditRoutineSheet = true
                            } label: {
                                Text("Edit Routine")
                                    .bold()
                            }
                            .tint(.greenStart)
                        }
                    }
                    .sheet(isPresented: $showingEditRoutineSheet) {
                        NavigationStack {
                            EditRoutineView()
                                .navigationTitle("Edit Routine")
                                .navigationBarTitleDisplayMode(.inline)
                        }
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
                        .tint(.orangeStart)
                    }
                }
                .navigationDestination(for: Exercise.self) { deliveryId in
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
    }
    
    // MARK: - iPHONE
    
    @ViewBuilder
    private func compactWidthView() -> some View {
        TabView(selection: $viewModel.appTab) {
            NavigationStack {
                RoutineView()
                    .navigationTitle("SetDeck")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            NavigationLink {
                                EditRoutineView()
                                    .navigationTitle("Edit Routine")
                                    .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                Text("Edit Routine")
                                    .bold()
                                    .tint(.greenStart)
                            }
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
    
    return MainView(resetApplication: {})
        .preferredColorScheme(.dark)
        .environment(ExerciseManager(context: context))
        .environment(HealthManager())

}

