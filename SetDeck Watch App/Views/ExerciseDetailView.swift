//
//  ExerciseDetailView.swift
//  SetDeck Watch App
//
//  Created by Nick Molargik on 1/9/26.
//
//  Shows sets for a single exercise with logging capability.
//

import SwiftUI

struct ExerciseDetailView: View {
    let exercise: WatchExercise

    @Environment(WatchConnectivityManager.self) private var connectivityManager
    @State private var selectedSet: WatchSet?

    var body: some View {
        List {
            // Exercise info section
            if exercise.isWarmup || exercise.note != nil {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        if exercise.isWarmup {
                            Label("Warm-up", systemImage: "flame")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }

                        if let note = exercise.note {
                            Text(note)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Sets section
            Section("Sets") {
                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                    Button {
                        selectedSet = set
                        WatchHaptics.buttonTapped()
                    } label: {
                        SetRowView(set: set, setNumber: index + 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.carousel)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSet) { set in
            LogSetView(
                set: set,
                exerciseId: exercise.id,
                exerciseName: exercise.name
            )
            .environment(connectivityManager)
        }
    }
}

// MARK: - Set Row
struct SetRowView: View {
    let set: WatchSet
    let setNumber: Int

    var body: some View {
        HStack {
            // Set number badge
            Text("\(setNumber)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(set.isCompleted ? Color.green : Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(set.displayTarget)
                    .font(.headline)

                if let rpe = set.rpe {
                    Text("RPE \(rpe)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if set.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: WatchRoutine.sample.exercises[0])
    }
}
