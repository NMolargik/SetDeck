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

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false

    @State private var viewModel = ViewModel()

    var body: some View {
        Form {
            // MARK: - Units & Date Format
            Toggle("Use Metric Units", isOn: $useMetricUnits)
                .tint(.greenStart)
                .onChange(of: useMetricUnits) { _, _ in Haptics.lightImpact() }

            Toggle("Use Day–Month–Year Dates", isOn: $useDayMonthYearDates)
                .tint(.greenStart)
                .accessibilityHint("Switch between Month–Day–Year and Day–Month–Year formats for dates.")
                .onChange(of: useDayMonthYearDates) { _, _ in Haptics.lightImpact() }

            Button {
                Haptics.lightImpact()
                DispatchQueue.main.async {
                    viewModel.showDeleteConfirmation = true
                }
            } label: {
                Text("Clear Set History")
                    .bold()
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)

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
        .preferredColorScheme(.dark)
}
