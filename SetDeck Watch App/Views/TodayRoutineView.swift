//
//  TodayRoutineView.swift
//  SetDeck Watch App
//
//  Created by Nick Molargik on 1/9/26.
//
//  Displays today's workout routine on Apple Watch.
//

import SwiftUI

struct TodayRoutineView: View {
    @Environment(WatchConnectivityManager.self) private var connectivityManager
    @State private var selectedExercise: WatchExercise?

    var body: some View {
        NavigationStack {
            Group {
                if let routine = connectivityManager.todayRoutine {
                    if routine.exercises.isEmpty {
                        emptyRoutineView
                    } else {
                        exerciseList(routine: routine)
                    }
                } else {
                    loadingView
                }
            }
            .navigationTitle(dayTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            connectivityManager.requestTodayRoutine()
        }
    }

    // MARK: - Day Title
    private var dayTitle: String {
        connectivityManager.todayRoutine?.dayName ?? "Today"
    }

    // MARK: - Exercise List
    private func exerciseList(routine: WatchRoutine) -> some View {
        List {
            Section {
                ForEach(routine.exercises) { exercise in
                    NavigationLink(value: exercise) {
                        ExerciseRowView(exercise: exercise)
                    }
                }
            } header: {
                HStack {
                    Text("\(routine.exerciseCount) exercises")
                    Spacer()
                    Text("\(routine.totalSetCount) sets")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .listStyle(.carousel)
        .navigationDestination(for: WatchExercise.self) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }

    // MARK: - Empty State
    private var emptyRoutineView: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("No Exercises")
                    .font(.headline)

                Text("Add exercises from your iPhone to get started")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    WatchHaptics.buttonTapped()
                    connectivityManager.requestTodayRoutine()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
            .padding()
        }
    }

    // MARK: - Loading State
    private var loadingView: some View {
        VStack(spacing: 12) {
            if connectivityManager.isReachable {
                ProgressView()

                Text("Syncing...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "iphone.slash")
                    .font(.title2)
                    .foregroundStyle(.orange)

                Text("iPhone not nearby")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Open SetDeck on your iPhone")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }

            Button {
                connectivityManager.requestTodayRoutine()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.caption2)
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .padding()
    }
}

// MARK: - Exercise Row
struct ExerciseRowView: View {
    let exercise: WatchExercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if exercise.isWarmup {
                        Image(systemName: "flame")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    Text(exercise.name)
                        .font(.headline)
                        .lineLimit(2)
                }

                Text("\(exercise.setCount) sets")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TodayRoutineView()
        .environment(WatchConnectivityManager.shared)
}
