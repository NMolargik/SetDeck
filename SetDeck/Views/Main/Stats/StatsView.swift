//
//  StatsView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(ExerciseManager.self) private var exerciseManager
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false

    @State private var viewModel: ViewModel = ViewModel()
    @State private var range: TimeRange = .last30Days
    @State private var selectedExerciseName: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if filteredHistory.isEmpty {
                        VStack(spacing: 12) {
                            Text("No history yet")
                                .font(.title3).bold()
                            Text("Once you log some sets, you’ll see trends, PRs, and volume charts here.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                                )
                        )
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        SummaryRowView(
                            totalVolume: totalVolume,
                            totalSets: filteredHistory.count,
                            activeDays: activeDayCount,
                            bestStreak: bestStreak
                        )

                        VolumeTrendCardView(points: dailyVolumePoints)

                        ExercisePRCardView(
                            exerciseNames: exerciseNames,
                            selectedExerciseName: $selectedExerciseName,
                            prs: exercisePRs
                        )

                        if let selected = selectedExerciseName,
                           let points = exercise1RMPoints[selected] {
                            ExerciseDetailCardView(
                                exerciseName: selected,
                                points: points
                            )
                        }

                        IntensityDistributionCard(history: filteredHistory)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Range", selection: $range) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280)
                }
            }
        }
        .onAppear {
            let history = allHistory
            print("[StatsView] allHistory count:", history.count)
        }
        .tint(.purpleStart)
    }
    
    var allHistory: [SetDeckSetHistory] {
        // Read changeStamp to trigger view updates when ExerciseManager saves
        let _ = exerciseManager.changeStamp
        return exerciseManager.allHistoryEntries()
    }
    var filteredHistory: [SetDeckSetHistory] {
        viewModel.filteredHistory(allHistory, range: range)
    }

    var totalVolume: Double {
        viewModel.totalVolume(filteredHistory: filteredHistory, useMetricUnits: useMetricUnits)
    }

    var activeDayCount: Int {
        viewModel.activeDayCount(filteredHistory: filteredHistory)
    }

    var bestStreak: Int {
        viewModel.bestStreak(filteredHistory: filteredHistory)
    }

    struct VolumePoint: Identifiable {
        let date: Date
        let volume: Double
        var id: Date { date }
    }

    var dailyVolumePoints: [VolumePoint] {
        viewModel.dailyVolumePoints(filteredHistory: filteredHistory, useMetricUnits: useMetricUnits)
    }

    var exerciseNames: [String] {
        viewModel.exerciseNames(filteredHistory: filteredHistory)
    }

    struct PRSummary {
        let exerciseName: String
        let bestWeight: Double
        let bestDate: Date
        let best1RM: Double
    }

    var exercisePRs: [PRSummary] {
        viewModel.exercisePRs(filteredHistory: filteredHistory)
    }

    struct OneRMPoint: Identifiable {
        let date: Date
        let value: Double
        var id: Date { date }
    }

    var exercise1RMPoints: [String: [OneRMPoint]] {
        viewModel.exercise1RMPoints(filteredHistory: filteredHistory)
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

    // Seed routines and exercises for preview
    if (try? context.fetch(FetchDescriptor<SetDeckRoutine>()))?.isEmpty ?? true {
        for day in 0..<3 {
            let routine = SetDeckRoutine.sample(day: day)
            context.insert(routine)
            for _ in 0..<2 {
                let ex = SetDeckExercise.sample(setCount: 3)
                ex.routine = routine
                context.insert(ex)
                for set in ex.sets ?? [] {
                    context.insert(set)
                }
            }
        }
        try? context.save()
    }

    return StatsView()
        .environment(exerciseManager)
        .modelContainer(container)
}
