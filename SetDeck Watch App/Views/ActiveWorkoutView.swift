//
//  ActiveWorkoutView.swift
//  SetDeck Watch App
//
//  The standalone workout screen: start today's routine, see the current set, log it with
//  one tap (or Double Tap / the Action Button), watch the rest countdown, finish.
//

import SwiftUI
import SetDeckCore

struct ActiveWorkoutView: View {
    @Environment(WatchWorkoutSession.self) private var session
    @State private var showingAdjust = false
    @State private var showingFinishConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if session.routine == nil {
                    noRoutineView
                } else if !session.isActive {
                    startView
                } else if let next = session.nextSet {
                    activeView(next)
                } else {
                    completeView
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Workout")
        .confirmationDialog("End Workout?", isPresented: $showingFinishConfirmation, titleVisibility: .visible) {
            Button("End Workout", role: .destructive) { Task { await session.finish() } }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - States
    private var noRoutineView: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Open SetDeck on your iPhone once to load today's routine")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var startView: some View {
        VStack(spacing: 8) {
            if let routine = session.routine {
                Text(routine.dayName).font(.headline)
                Text("\(routine.exerciseCount) exercises, \(routine.totalSetCount) sets")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Button {
                    Task { await session.startRoutine() }
                } label: {
                    Label("Start Workout", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(routine.exercises.isEmpty)
            }
        }
    }

    private func activeView(_ next: WatchNextSet) -> some View {
        VStack(spacing: 8) {
            if let rest = session.rest {
                restBanner(rest)
            }

            Text(next.exercise.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Text("Set \(next.setNumber) of \(next.setsInExercise)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(next.set.displayTarget)
                .font(.title3.bold())
                .foregroundStyle(.green)

            // Double Tap triggers the primary action of the frontmost button.
            Button {
                session.logNextSet()
            } label: {
                Label("Log Set", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .handGestureShortcut(.primaryAction)

            Button {
                showingAdjust = true
            } label: {
                Label("Adjust", systemImage: "slider.horizontal.3")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button("End Workout", role: .destructive) { showingFinishConfirmation = true }
                .font(.caption2)
        }
        .sheet(isPresented: $showingAdjust) {
            LogSetView(set: next.set, exerciseId: next.exercise.id, exerciseName: next.exercise.name)
        }
    }

    private var completeView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("Workout complete")
                .font(.headline)
            Button {
                Task { await session.finish() }
            } label: {
                Label("Finish", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .handGestureShortcut(.primaryAction)
        }
    }

    // MARK: - Rest
    private func restBanner(_ rest: WatchRestTimer) -> some View {
        VStack(spacing: 4) {
            Text("REST")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
            // System-driven countdown: stays accurate with the screen dimmed.
            Text(timerInterval: Date()...rest.endDate, countsDown: true)
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.orange)
            ProgressView(timerInterval: Date()...rest.endDate, countsDown: true) { EmptyView() } currentValueLabel: { EmptyView() }
                .tint(.orange)
            HStack {
                Button { session.extendRest() } label: { Text("+30s") }
                Button { session.skipRest() } label: { Text("Skip") }
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding(8)
        .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
    }
}
