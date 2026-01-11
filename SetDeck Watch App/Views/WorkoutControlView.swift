//
//  WorkoutControlView.swift
//  SetDeck Watch App
//
//  Created by Nick Molargik on 1/9/26.
//
//  Start, pause, resume, and stop workout sessions.
//

import SwiftUI
import HealthKit

struct WorkoutControlView: View {
    @Environment(WatchHealthManager.self) private var healthManager
    @Environment(WatchConnectivityManager.self) private var connectivityManager

    @State private var showingEndConfirmation = false

    var body: some View {
        VStack(spacing: 16) {
            if healthManager.isWorkoutActive {
                activeWorkoutView
            } else {
                inactiveWorkoutView
            }
        }
        .padding()
        .navigationTitle("Workout")
        .confirmationDialog(
            "End Workout?",
            isPresented: $showingEndConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Workout", role: .destructive) {
                endWorkout()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Inactive State
    private var inactiveWorkoutView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 50))
                .foregroundStyle(.green.gradient)

            Text("Ready to Train?")
                .font(.headline)

            Button(action: startWorkout) {
                Label("Start", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }

    // MARK: - Active State
    private var activeWorkoutView: some View {
        VStack(spacing: 12) {
            // Elapsed time
            Text(healthManager.formattedElapsedTime)
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundStyle(.green)

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(healthManager.isPaused ? .orange : .green)
                    .frame(width: 8, height: 8)

                Text(healthManager.isPaused ? "Paused" : "Active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Control buttons
            HStack(spacing: 16) {
                // Pause/Resume
                Button(action: togglePause) {
                    Image(systemName: healthManager.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.bordered)
                .tint(healthManager.isPaused ? .green : .orange)

                // End
                Button(action: { showingEndConfirmation = true }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }

    // MARK: - Actions
    private func startWorkout() {
        Task {
            do {
                try await healthManager.startWorkout()
                connectivityManager.notifyWorkoutStarted()
                WatchHaptics.workoutStarted()
            } catch {
                WatchHaptics.error()
            }
        }
    }

    private func togglePause() {
        if healthManager.isPaused {
            healthManager.resumeWorkout()
            WatchHaptics.workoutResumed()
        } else {
            healthManager.pauseWorkout()
            WatchHaptics.workoutPaused()
        }
    }

    private func endWorkout() {
        Task {
            await healthManager.endWorkout()
            connectivityManager.notifyWorkoutEnded()
            WatchHaptics.workoutEnded()
        }
    }
}

#Preview {
    WorkoutControlView()
        .environment(WatchHealthManager())
        .environment(WatchConnectivityManager.shared)
}
