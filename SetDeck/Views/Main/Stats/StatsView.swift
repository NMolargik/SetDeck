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
    @State private var inferredMuscleGroups: [String: [MuscleGroup]] = [:]
    @State private var isLoadingMuscleAnalysis: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if filteredHistory.isEmpty {
                        emptyStateView
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
                            prs: exercisePRs
                        )

                        let selected = selectedExerciseName ?? exerciseNames.first
                        let selectedPoints = selected.flatMap { exercise1RMPoints[$0] } ?? []

                        ExerciseDetailCardView(
                            exerciseNames: exerciseNames,
                            selectedExerciseName: $selectedExerciseName,
                            points: selectedPoints
                        )

                        IntensityDistributionCard(history: filteredHistory)

                        // MARK: - Muscle Analysis Section (iOS 26+ with Foundation Models)
                        if viewModel.isMuscleAnalysisAvailable {
                            if isLoadingMuscleAnalysis {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .controlSize(.regular)
                                    Text("Analyzing muscle groups...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else if !weeklyMuscleVolumes.isEmpty {
                                Text("Muscle Analysis")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .padding(.top, 8)

                                MuscleHeatmapCardView(muscleVolumes: weeklyMuscleVolumes)

                                MuscleDistributionCardView(muscleVolumes: weeklyMuscleVolumes)

                                BalanceAnalysisCardView(muscleVolumes: weeklyMuscleVolumes)
                            }
                        }
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if !allHistory.isEmpty {
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
        }
        .onAppear {
            // History data loaded via allHistory computed property
        }
        .task {
            // Load muscle group inference if available
            if viewModel.isMuscleAnalysisAvailable && inferredMuscleGroups.isEmpty {
                isLoadingMuscleAnalysis = true
                inferredMuscleGroups = await viewModel.inferMuscleGroupsForHistory(allHistory)
                isLoadingMuscleAnalysis = false
            }
        }
        .onChange(of: allHistory.count) {
            // Re-infer when history changes
            if viewModel.isMuscleAnalysisAvailable {
                Task {
                    isLoadingMuscleAnalysis = true
                    inferredMuscleGroups = await viewModel.inferMuscleGroupsForHistory(allHistory)
                    isLoadingMuscleAnalysis = false
                }
            }
        }
        .tint(.purpleStart)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purpleStart, .blueStart],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Your Stats Await")
                    .font(.title2).bold()

                Text("Start logging sets in your routines to unlock powerful insights about your training.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            // Feature Cards
            VStack(spacing: 12) {
                emptyStateFeatureCard(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Volume Tracking",
                    description: "See your total weight lifted over time with beautiful trend charts."
                )

                emptyStateFeatureCard(
                    icon: "trophy.fill",
                    iconColor: .yellow,
                    title: "Personal Records",
                    description: "Track your best lifts and estimated one-rep maxes for each exercise."
                )

                emptyStateFeatureCard(
                    icon: "calendar",
                    iconColor: .green,
                    title: "Workout Streaks",
                    description: "Monitor your consistency with active day counts and best streaks."
                )

                emptyStateFeatureCard(
                    icon: "chart.pie.fill",
                    iconColor: .purple,
                    title: "Intensity Distribution",
                    description: "Understand your training intensity across different RPE levels."
                )
            }

            // Call to Action
            VStack(spacing: 8) {
                Text("Ready to begin?")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Complete a set in your routine and check back here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
        .padding()
    }

    @ViewBuilder
    private func emptyStateFeatureCard(
        icon: String,
        iconColor: Color,
        title: String,
        description: String
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline).bold()
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
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

    var weeklyMuscleVolumes: [MuscleGroup: Double] {
        viewModel.thisWeekMuscleVolumes(allHistory: allHistory, inferredMuscleGroups: inferredMuscleGroups)
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
