//
//  SettingsView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI
import SwiftData

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ExerciseManager.self) private var exerciseManager: ExerciseManager
    @Environment(AchievementManager.self) private var achievementManager: AchievementManager

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false

    @State private var viewModel = ViewModel()

    var body: some View {
        Form {
            // MARK: - Units & Date Format
            Section {
                Toggle("Display Water in Liters", isOn: $useMetricUnits)
                    .tint(.greenStart)
                    .onChange(of: useMetricUnits) { _, _ in Haptics.lightImpact() }

                Toggle("Use Day–Month–Year Dates", isOn: $useDayMonthYearDates)
                    .tint(.greenStart)
                    .accessibilityHint("Switch between Month–Day–Year and Day–Month–Year formats for dates.")
                    .onChange(of: useDayMonthYearDates) { _, _ in Haptics.lightImpact() }
            }

            // MARK: - App Info
            Section("SetDeck") {
                LabeledContent("Version") {
                    Text(viewModel.appVersion)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Developer") {
                    Link("Nick Molargik", destination: URL(string: "https://www.linkedin.com/in/nicholas-molargik/")!)
                        .foregroundStyle(.blueStart)
                }

                LabeledContent("Publisher") {
                    Link("Molargik Software LLC", destination: URL(string: "https://www.molargiksoftware.com")!)
                        .foregroundStyle(.blueStart)
                }
            }

            // MARK: - Achievements
            Section {
                Button {
                    Haptics.lightImpact()
                    viewModel.showAchievementsSheet = true
                } label: {
                    HStack {
                        Label("View Achievements", systemImage: "trophy.fill")
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(achievementManager.unlockedAchievements.count)/\(Achievement.allCases.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .hoverEffectIfAvailable(.highlight)
            }

            // MARK: - Danger Zone
            Section {
                Button {
                    Haptics.lightImpact()
                    viewModel.showDeleteConfirmation = true
                } label: {
                    Label("Clear Set History", systemImage: "clock.arrow.circlepath")
                        .foregroundStyle(.red)
                }
                .hoverEffectIfAvailable(.highlight)

                Button {
                    Haptics.lightImpact()
                    viewModel.showDeleteRoutinesConfirmation = true
                } label: {
                    Label("Delete All Routines", systemImage: "trash.fill")
                        .foregroundStyle(.red)
                }
                .hoverEffectIfAvailable(.highlight)

                Button {
                    Haptics.lightImpact()
                    viewModel.showResetAchievementsConfirmation = true
                } label: {
                    Label("Reset Achievements", systemImage: "trophy.fill")
                        .foregroundStyle(.red)
                }
                .hoverEffectIfAvailable(.highlight)
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("These actions cannot be undone.")
            }

            #if DEBUG
            // MARK: - Debug
            Section {
                Button {
                    Haptics.lightImpact()
                    viewModel.showGenerateSampleDataConfirmation = true
                } label: {
                    Label("Generate Sample Routines", systemImage: "wand.and.stars")
                        .foregroundStyle(.purple)
                }
                .hoverEffectIfAvailable(.highlight)
            } header: {
                Text("Debug")
            } footer: {
                Text("Creates sample exercises and sets for all 7 days, plus 30 days of workout history.")
            }
            #endif
        }
        .scrollContentBackground(.hidden)
        .background(BrandBackground(tint: .purpleStart))
        .sheet(isPresented: $viewModel.showAchievementsSheet) {
            NavigationStack {
                AchievementsView(
                    unlockedAchievements: achievementManager.unlockedAchievements
                )
            }
        }
        .alert("Clear Set History?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Delete History", role: .destructive) {
                Haptics.lightImpact()
                exerciseManager.clearAllHistory()
                viewModel.showHistoryClearedAlert = true
            }
            Button("Cancel", role: .cancel) {
                Haptics.lightImpact()
            }
        } message: {
            Text("This will permanently delete all of your historical set data. Your Stats tab will likely be pretty empty, but your current routines and exercises will remain untouched.")
        }
        .alert("History Cleared", isPresented: $viewModel.showHistoryClearedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All historical set entries have been removed. Your routines and exercises are unchanged.")
        }
        .alert("Delete All Routines?", isPresented: $viewModel.showDeleteRoutinesConfirmation) {
            Button("Delete Everything", role: .destructive) {
                Haptics.lightImpact()
                exerciseManager.deleteAllRoutines()
                viewModel.showRoutinesDeletedAlert = true
            }
            Button("Cancel", role: .cancel) {
                Haptics.lightImpact()
            }
        } message: {
            Text("This will permanently delete all of your routines, exercises, sets, and history. You will need to rebuild your workout routine from scratch.")
        }
        .alert("Routines Deleted", isPresented: $viewModel.showRoutinesDeletedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All routines, exercises, sets, and history have been deleted.")
        }
        .alert("Reset Achievements?", isPresented: $viewModel.showResetAchievementsConfirmation) {
            Button("Reset", role: .destructive) {
                Haptics.lightImpact()
                achievementManager.resetAllAchievements()
                viewModel.showAchievementsResetAlert = true
            }
            Button("Cancel", role: .cancel) {
                Haptics.lightImpact()
            }
        } message: {
            Text("This will reset all of your achievement progress. You can earn them again by continuing to work out.")
        }
        .alert("Achievements Reset", isPresented: $viewModel.showAchievementsResetAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All achievements have been reset. Keep working out to earn them again!")
        }
        #if DEBUG
        .alert("Generate Sample Data?", isPresented: $viewModel.showGenerateSampleDataConfirmation) {
            Button("Generate", role: .none) {
                Haptics.lightImpact()
                exerciseManager.generateSampleDataForLast30Days()
                viewModel.showSampleDataGeneratedAlert = true
            }
            Button("Cancel", role: .cancel) {
                Haptics.lightImpact()
            }
        } message: {
            Text("This will create sample exercises for all 7 days and generate 30 days of workout history. Existing routines will be preserved.")
        }
        .alert("Sample Data Generated", isPresented: $viewModel.showSampleDataGeneratedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Sample routines and 30 days of history have been created.")
        }
        #endif
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([SetDeckRoutine.self, SetDeckExercise.self, SetDeckSet.self, SetDeckSetHistory.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    let exerciseManager = ExerciseManager(context: context)
    
    // Seed one routine per weekday for previewing
    let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    for (_, _) in weekdays.enumerated() {
        let routine = SetDeckRoutine.sample()
        context.insert(routine)
    }
    try? context.save()
    
    return SettingsView()
        .environment(exerciseManager)
        .environment(AchievementManager(exerciseManager: exerciseManager))
        .preferredColorScheme(.dark)
}
