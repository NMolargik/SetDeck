//
//  LogSetView.swift
//  SetDeck Watch App
//
//  Created by Nick Molargik on 1/9/26.
//
//  Simple view for logging a completed set.
//

import SwiftUI

struct LogSetView: View {
    let set: WatchSet
    let exerciseId: UUID
    let exerciseName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(WatchConnectivityManager.self) private var connectivityManager

    @State private var reps: Int
    @State private var weight: Int

    init(set: WatchSet, exerciseId: UUID, exerciseName: String) {
        self.set = set
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self._reps = State(initialValue: set.targetReps ?? 10)
        self._weight = State(initialValue: Int(set.weight ?? 0))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Title
                Text("Log Set")
                    .font(.headline)
                    .foregroundStyle(.white)

                // Reps control
                VStack(spacing: 4) {
                    Text("REPS")
                        .font(.caption2)
                        .foregroundStyle(.gray)

                    HStack {
                        Button {
                            if reps > 1 { reps -= 1 }
                            WatchHaptics.selectionChanged()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)

                        Text("\(reps)")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .frame(minWidth: 50)

                        Button {
                            if reps < 99 { reps += 1 }
                            WatchHaptics.selectionChanged()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)

                // Weight control
                VStack(spacing: 4) {
                    Text("WEIGHT (\(set.weightUnit.uppercased()))")
                        .font(.caption2)
                        .foregroundStyle(.gray)

                    HStack {
                        Button {
                            if weight >= 5 { weight -= 5 }
                            WatchHaptics.selectionChanged()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)

                        Text("\(weight)")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .frame(minWidth: 50)

                        Button {
                            if weight < 995 { weight += 5 }
                            WatchHaptics.selectionChanged()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)

                // Log button
                Button(action: saveSet) {
                    Text("Log")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)

                // Cancel button
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }

    private func saveSet() {
        let completion = SetCompletionMessage(
            setId: set.id,
            exerciseId: exerciseId,
            completedDate: Date(),
            actualReps: reps,
            actualWeight: Double(weight),
            actualRpe: set.rpe
        )

        connectivityManager.sendSetCompletion(completion)
        WatchHaptics.setCompleted()
        dismiss()
    }
}

#Preview {
    LogSetView(
        set: WatchRoutine.sample.exercises[0].sets[0],
        exerciseId: UUID(),
        exerciseName: "Bench Press"
    )
    .environment(WatchConnectivityManager.shared)
}
