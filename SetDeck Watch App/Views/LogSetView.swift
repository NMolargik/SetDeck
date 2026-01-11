//
//  LogSetView.swift
//  SetDeck Watch App
//
//  Created by Nick Molargik on 1/9/26.
//
//  Digital Crown input for logging a completed set.
//

import SwiftUI

struct LogSetView: View {
    let set: WatchSet
    let exerciseId: UUID
    let exerciseName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(WatchConnectivityManager.self) private var connectivityManager

    @State private var reps: Int
    @State private var weight: Double
    @State private var rpe: Int

    @State private var editingField: EditingField = .reps
    @FocusState private var isDigitalCrownFocused: Bool

    enum EditingField {
        case reps, weight, rpe
    }

    init(set: WatchSet, exerciseId: UUID, exerciseName: String) {
        self.set = set
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self._reps = State(initialValue: set.targetReps ?? 10)
        self._weight = State(initialValue: set.weight ?? 0)
        self._rpe = State(initialValue: set.rpe ?? 7)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Exercise name
                Text(exerciseName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Reps field
                fieldButton(
                    label: "Reps",
                    value: "\(reps)",
                    isSelected: editingField == .reps
                ) {
                    editingField = .reps
                    WatchHaptics.selectionChanged()
                }

                // Weight field
                fieldButton(
                    label: "Weight",
                    value: "\(Int(weight)) \(set.weightUnit)",
                    isSelected: editingField == .weight
                ) {
                    editingField = .weight
                    WatchHaptics.selectionChanged()
                }

                // RPE field
                fieldButton(
                    label: "RPE",
                    value: "\(rpe)",
                    isSelected: editingField == .rpe
                ) {
                    editingField = .rpe
                    WatchHaptics.selectionChanged()
                }

                // Save button
                Button(action: saveSet) {
                    Label("Save", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
        }
        .focusable()
        .focused($isDigitalCrownFocused)
        .digitalCrownRotation(
            detent: crownBinding,
            from: crownRange.lowerBound,
            through: crownRange.upperBound,
            by: crownStride,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onAppear {
            isDigitalCrownFocused = true
        }
        .navigationTitle("Log Set")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Field Button
    private func fieldButton(label: String, value: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(isSelected ? .blue : .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Digital Crown Binding
    private var crownBinding: Binding<Double> {
        switch editingField {
        case .reps:
            return Binding(
                get: { Double(reps) },
                set: { reps = max(1, Int($0)) }
            )
        case .weight:
            return $weight
        case .rpe:
            return Binding(
                get: { Double(rpe) },
                set: { rpe = max(1, min(10, Int($0))) }
            )
        }
    }

    private var crownRange: ClosedRange<Double> {
        switch editingField {
        case .reps: return 1...100
        case .weight: return 0...1000
        case .rpe: return 1...10
        }
    }

    private var crownStride: Double {
        switch editingField {
        case .reps: return 1
        case .weight: return 2.5
        case .rpe: return 1
        }
    }

    // MARK: - Save
    private func saveSet() {
        let completion = SetCompletionMessage(
            setId: set.id,
            exerciseId: exerciseId,
            completedDate: Date(),
            actualReps: reps,
            actualWeight: weight,
            actualRpe: rpe
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
