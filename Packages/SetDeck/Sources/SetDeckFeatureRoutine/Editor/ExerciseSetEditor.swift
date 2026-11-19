//
//  ExerciseSetEditor.swift
//  SetDeckFeatureRoutine
//
//  The editor for one exercise: name, warmup, muscle groups and its sets. It is the
//  trailing pane on iPad / unfolded Duo and expands inline under the card on iPhone.
//

#if os(iOS)
import SwiftUI
import TipKit
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared

struct ExerciseSetEditor: View {
    let exercise: SetDeckExercise
    let sets: [SetDeckSet]
    var canSuggestMuscles: Bool = false
    var isSuggestingMuscles: Bool = false
    var showsAddSetTip: Bool = false
    var focus: FocusState<UUID?>.Binding
    let onSuggestMuscles: () -> Void
    let onAddSet: () -> Void
    let onMoveSet: (Int, Int) -> Void

    @Environment(WorkoutDataModel.self) private var exerciseManager

    private let addSetTip = AddSetTip()

    // Explicit: private stored properties would otherwise make the memberwise init private.
    init(exercise: SetDeckExercise,
         sets: [SetDeckSet],
         canSuggestMuscles: Bool = false,
         isSuggestingMuscles: Bool = false,
         showsAddSetTip: Bool = false,
         focus: FocusState<UUID?>.Binding,
         onSuggestMuscles: @escaping () -> Void,
         onAddSet: @escaping () -> Void,
         onMoveSet: @escaping (Int, Int) -> Void) {
        self.exercise = exercise
        self.sets = sets
        self.canSuggestMuscles = canSuggestMuscles
        self.isSuggestingMuscles = isSuggestingMuscles
        self.showsAddSetTip = showsAddSetTip
        self.focus = focus
        self.onSuggestMuscles = onSuggestMuscles
        self.onAddSet = onAddSet
        self.onMoveSet = onMoveSet
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { exercise.name },
            set: { v in exerciseManager.updateExercise(exercise) { $0.name = v } }
        )
    }

    private var warmupBinding: Binding<Bool> {
        Binding(
            get: { exercise.isWarmup },
            set: { v in exerciseManager.updateExercise(exercise) { $0.isWarmup = v } }
        )
    }

    private func binding(for group: MuscleGroup) -> Binding<Bool> {
        Binding(
            get: { exercise.muscleGroups.contains(group) },
            set: { on in
                exerciseManager.updateExercise(exercise) { ex in
                    if on { if !ex.muscleGroups.contains(group) { ex.muscleGroups.append(group) } }
                    else { ex.muscleGroups.removeAll { $0 == group } }
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Space.lg) {
            nameRow
            muscleSection
            setsSection
        }
        .padding(.top, Brand.Space.xs)
    }

    // MARK: Name + warmup

    private var nameRow: some View {
        VStack(alignment: .leading, spacing: Brand.Space.sm) {
            HStack(spacing: Brand.Space.sm) {
                TextField("Exercise Name", text: nameBinding)
                    .font(.body.weight(.semibold))
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .padding(.horizontal, Brand.Space.md)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: Brand.Radius.chip, style: .continuous).fill(.ultraThinMaterial))
                    .overlay(
                        RoundedRectangle(cornerRadius: Brand.Radius.chip, style: .continuous)
                            .strokeBorder(Color.primary.opacity(focus.wrappedValue == exercise.uuid ? 0.5 : 0.2), lineWidth: 1)
                    )
                    .focused(focus, equals: exercise.uuid)
                    .accessibilityLabel("Exercise name")
                    .accessibilityHint("Double tap to edit the exercise name")

                if focus.wrappedValue == exercise.uuid {
                    Button { focus.wrappedValue = nil } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.greenStart)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Done editing")
                    .accessibilityHint("Confirms the exercise name change")
                }
            }

            Toggle(isOn: warmupBinding) {
                Label("Warmup exercise", systemImage: "flame.fill")
                    .font(.subheadline)
            }
            .toggleStyle(SwitchToggleStyle(tint: .orangeStart))
            .accessibilityHint("Mark this exercise as a warmup")
        }
    }

    // MARK: Muscles

    private var muscleSection: some View {
        VStack(alignment: .leading, spacing: Brand.Space.sm) {
            Text("Muscles")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            FlowLayout(spacing: Brand.Space.xs + 2, lineSpacing: Brand.Space.xs + 2) {
                ForEach(exercise.muscleGroups) { group in
                    MuscleChip(group: group) { binding(for: group).wrappedValue = false }
                }
                Menu {
                    ForEach(MuscleGroup.allCases) { group in
                        Toggle(isOn: binding(for: group)) {
                            Label(group.displayName, systemImage: group.editorIcon)
                        }
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(Capsule().strokeBorder(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Add muscle group")

                if canSuggestMuscles && exercise.muscleGroups.isEmpty {
                    Button(action: onSuggestMuscles) {
                        HStack(spacing: 4) {
                            if isSuggestingMuscles { ProgressView().controlSize(.mini) }
                            else { Image(systemName: "sparkles") }
                            Text("Suggest")
                        }
                        .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.glassCapsule(tint: .purpleStart))
                    .disabled(isSuggestingMuscles)
                    .accessibilityHint("Guesses the muscle groups from the exercise name")
                }
            }
        }
    }

    // MARK: Sets

    private var setsSection: some View {
        VStack(alignment: .leading, spacing: Brand.Space.sm) {
            HStack {
                Text("Sets")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(sets.count)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if sets.isEmpty {
                VStack(spacing: Brand.Space.xs) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No sets yet. Add a set to choose reps, weight, or a timer.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Brand.Space.lg)
                .background(
                    RoundedRectangle(cornerRadius: Brand.Radius.control, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                )
            }

            ForEach(Array(sets.enumerated()), id: \.element.uuid) { offset, set in
                EditSetRowView(
                    set: set,
                    setCount: sets.count,
                    number: offset + 1,
                    onMoveUp: offset > 0 ? { onMoveSet(offset, offset - 1) } : nil,
                    onMoveDown: offset < sets.count - 1 ? { onMoveSet(offset, offset + 1) } : nil
                )
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }

            let addButton = Button {
                addSetTip.invalidate(reason: .actionPerformed)
                onAddSet()
            } label: {
                Label("Add Set", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassCapsule(tint: .blueStart, prominent: true))
            .accessibilityLabel("Add set to \(exercise.name)")
            .accessibilityHint("Creates a new set for this exercise")

            if showsAddSetTip {
                addButton.popoverTip(addSetTip, arrowEdge: .bottom)
            } else {
                addButton
            }
        }
    }
}
#endif
