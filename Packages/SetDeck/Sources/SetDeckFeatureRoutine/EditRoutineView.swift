//
//  EditRoutineView.swift
//  SetDeckFeatureRoutine
//
//  Created by Nick Molargik on 11/23/25.
//
//  Routine editor. Compact: one column of rich exercise cards, the selected card expanding
//  into its set editor. Wide (iPad, unfolded iPhone Duo): two panes split at the hinge —
//  exercise list leading, the selected exercise's set editor trailing.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared
import SetDeckServices

public struct EditRoutineView: View {
    @Environment(WorkoutDataModel.self) private var exerciseManager
    /// Optional so the editor still works where no inference service is injected.
    @Environment(MuscleGroupInferenceService.self) private var inference: MuscleGroupInferenceService?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ViewModel()
    @State private var exercisePendingDelete: SetDeckExercise?

    @FocusState private var focusedExerciseID: UUID?
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false

    /// Below this width the editor is a single column.
    private let splitThreshold: CGFloat = 640
    /// Clear space kept on each side of an active hinge.
    private let hingeInset: CGFloat = 20

    public init() {}

    // MARK: Data

    private struct EditorData {
        var routine: SetDeckRoutine?
        var exercises: [SetDeckExercise]
        var sets: [UUID: [SetDeckSet]]
        var summary: RoutineSummary
    }

    private func makeData() -> EditorData {
        // Reading changeStamp makes this re-run whenever data mutates (including CloudKit imports).
        _ = exerciseManager.changeStamp
        let exercises = viewModel.exercises(using: exerciseManager).sorted { $0.orderIndex < $1.orderIndex }
        var sets: [UUID: [SetDeckSet]] = [:]
        for ex in exercises {
            sets[ex.uuid] = exerciseManager.sets(for: ex).sorted { $0.orderIndex < $1.orderIndex }
        }
        return EditorData(
            routine: viewModel.currentRoutine(using: exerciseManager),
            exercises: exercises,
            sets: sets,
            summary: RoutineSummary(exercises: exercises, sets: sets)
        )
    }

    private var isTodaySelected: Bool { viewModel.selectedDay == viewModel.todayIndex }

    // MARK: Body

    public var body: some View {
        GeometryReader { proxy in
            let data = makeData()
            if proxy.size.width >= splitThreshold {
                splitLayout(data: data, probe: LayoutProbe(proxy))
            } else {
                compactLayout(data: data)
            }
        }
        .onAppear {
            viewModel.resetToToday()
            Task { await TipEvents.editRoutineOpened.donate() }
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active { viewModel.resetToToday() }
        }
        .onChange(of: viewModel.selectedDay) { _, _ in
            viewModel.selectedExerciseID = nil
            focusedExerciseID = nil
        }
        .task(id: inferenceKey) { await inferMissingMuscleGroups() }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.selectedDay)
        .confirmationDialog(
            "Delete exercise?",
            isPresented: Binding(get: { exercisePendingDelete != nil }, set: { if !$0 { exercisePendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: exercisePendingDelete
        ) { exercise in
            Button("Delete \(exercise.name)", role: .destructive) {
                focusedExerciseID = nil
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.deleteExercise(exercise, using: exerciseManager)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("This removes the exercise and all of its sets.")
        }
        .navigationTitle("Edit Routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    focusedExerciseID = nil
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .bold()
                .tint(.greenStart)
            }
        }
    }

    // MARK: Compact (single column)

    private func compactLayout(data: EditorData) -> some View {
        ScrollViewReader { scroller in
            ScrollView {
                LazyVStack(spacing: Brand.Space.lg) {
                    overview(data: data)
                    if data.exercises.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(data.exercises.enumerated()), id: \.element.uuid) { index, exercise in
                            VStack(spacing: 0) {
                                card(for: exercise, index: index, data: data)
                                if viewModel.selectedExerciseID == exercise.uuid {
                                    detailEditor(for: exercise, data: data)
                                        .padding(Brand.Space.lg)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .id(exercise.uuid)
                        }
                        addExerciseButton
                    }
                }
                .padding(.horizontal, Brand.Space.lg)
                .padding(.vertical, Brand.Space.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.selectedExerciseID) { _, id in
                guard let id else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    scroller.scrollTo(id, anchor: .top)
                }
            }
        }
    }

    // MARK: Split (two panes)

    private func splitLayout(data: EditorData, probe: LayoutProbe) -> some View {
        let leadingWidth = probe.foldCenterX ?? probe.width * 0.46
        let hinge = probe.isFoldActive ? hingeInset : 0
        let selected = data.exercises.first { $0.uuid == viewModel.selectedExerciseID } ?? data.exercises.first

        return HStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: Brand.Space.lg) {
                    overview(data: data)
                    if data.exercises.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(data.exercises.enumerated()), id: \.element.uuid) { index, exercise in
                            card(for: exercise, index: index, data: data, selected: selected)
                        }
                        addExerciseButton
                    }
                }
                .padding(.leading, Brand.Space.lg)
                .padding(.trailing, Brand.Space.lg + hinge)
                .padding(.vertical, Brand.Space.md)
            }
            .frame(width: leadingWidth)

            ScrollView {
                Group {
                    if let selected {
                        detailEditor(for: selected, data: data)
                            .padding(Brand.Space.lg)
                            .background(detailBackground(for: selected))
                            .id(selected.uuid)
                    } else {
                        detailPlaceholder
                    }
                }
                .padding(.leading, Brand.Space.lg + hinge)
                .padding(.trailing, Brand.Space.lg)
                .padding(.vertical, Brand.Space.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Pieces

    private func overview(data: EditorData) -> some View {
        VStack(spacing: Brand.Space.md) {
            DayPickerView(selectedDay: $viewModel.selectedDay)
            RoutineHeaderView(day: viewModel.selectedDay,
                              isToday: isTodaySelected,
                              summary: data.summary,
                              useMetric: useMetricUnits)
        }
    }

    private func card(for exercise: SetDeckExercise,
                      index: Int,
                      data: EditorData,
                      selected: SetDeckExercise? = nil) -> some View {
        let isSelected = selected.map { $0.uuid == exercise.uuid } ?? (viewModel.selectedExerciseID == exercise.uuid)
        return ExerciseEditorCard(
            exercise: exercise,
            sets: data.sets[exercise.uuid] ?? [],
            index: index,
            total: data.exercises.count,
            isSelected: isSelected,
            useMetric: useMetricUnits,
            onSelect: { toggleSelection(of: exercise, splitMode: selected != nil) },
            onMove: { delta in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.moveExercise(exercise, by: delta, in: data.exercises,
                                           currentRoutine: data.routine, using: exerciseManager)
                }
            },
            onDelete: { exercisePendingDelete = exercise }
        )
    }

    private func toggleSelection(of exercise: SetDeckExercise, splitMode: Bool) {
        focusedExerciseID = nil
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if splitMode {
                viewModel.selectedExerciseID = exercise.uuid
            } else {
                viewModel.selectedExerciseID = viewModel.selectedExerciseID == exercise.uuid ? nil : exercise.uuid
            }
        }
    }

    private func detailEditor(for exercise: SetDeckExercise, data: EditorData) -> some View {
        let sets = data.sets[exercise.uuid] ?? []
        return ExerciseSetEditor(
            exercise: exercise,
            sets: sets,
            canSuggestMuscles: inference?.isAvailable ?? false,
            isSuggestingMuscles: viewModel.suggestingIDs.contains(exercise.uuid),
            showsAddSetTip: exercise.uuid == data.exercises.first?.uuid,
            focus: $focusedExerciseID,
            onSuggestMuscles: { Task { await suggestMuscleGroups(for: exercise) } },
            onAddSet: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.addSet(to: exercise, using: exerciseManager)
                }
            },
            onMoveSet: { from, to in
                viewModel.moveSet(from: from, to: to, in: sets, exercise: exercise, using: exerciseManager)
            }
        )
    }

    private func detailBackground(for exercise: SetDeckExercise) -> some View {
        let tint = exercise.muscleGroups.first?.editorColor ?? .blueStart
        return RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                    .strokeBorder(tint.opacity(0.4), lineWidth: 1)
            )
    }

    private var detailPlaceholder: some View {
        VStack(spacing: Brand.Space.sm) {
            Image(systemName: "hand.tap")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Select an exercise to edit its sets")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Brand.Space.xxl * 2)
    }

    private var emptyState: some View {
        RoutineEmptyState(
            day: viewModel.selectedDay,
            onAddBlank: { addExercise(named: "New Exercise", sets: 0, focusName: true) },
            onAddStarter: { name in addExercise(named: name, sets: 3, focusName: false) }
        )
    }

    private var addExerciseButton: some View {
        Button {
            addExercise(named: "New Exercise", sets: 0, focusName: true)
        } label: {
            Label("Add Exercise", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassCapsule(tint: .greenStart, prominent: true))
        .accessibilityLabel("Add exercise")
        .accessibilityHint("Creates a new exercise for this day's routine")
    }

    // MARK: Actions

    private func addExercise(named name: String, sets: Int, focusName: Bool) {
        var created: SetDeckExercise?
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            created = viewModel.addExercise(named: name, sets: sets, using: exerciseManager)
            viewModel.selectedExerciseID = created?.uuid
        }
        Task { await TipEvents.firstExerciseAdded.donate() }
        guard focusName, let id = created?.uuid else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            focusedExerciseID = id
        }
    }

    // MARK: Muscle-group inference

    /// Changes only when an exercise is added or renamed.
    private var inferenceKey: String {
        viewModel.exercises(using: exerciseManager).map { "\($0.uuid)|\($0.name)" }.joined(separator: ";")
    }

    /// Fills empty muscle groups from the exercise name once the name settles. Each id+name
    /// is attempted once, so clearing the chips by hand sticks.
    private func inferMissingMuscleGroups() async {
        guard let inference, inference.isAvailable else { return }
        try? await Task.sleep(for: .milliseconds(800))
        guard !Task.isCancelled else { return }
        for exercise in viewModel.exercises(using: exerciseManager) where exercise.muscleGroups.isEmpty {
            let name = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let attemptKey = "\(exercise.uuid)|\(name)"
            guard !name.isEmpty, name != "New Exercise", !viewModel.inferenceAttempted.contains(attemptKey) else { continue }
            viewModel.inferenceAttempted.insert(attemptKey)
            let groups = await inference.inferMuscleGroups(for: name)
            guard !Task.isCancelled, !groups.isEmpty, exercise.muscleGroups.isEmpty else { continue }
            exerciseManager.updateExercise(exercise) { $0.muscleGroups = groups }
        }
    }

    private func suggestMuscleGroups(for exercise: SetDeckExercise) async {
        guard let inference else { return }
        viewModel.suggestingIDs.insert(exercise.uuid)
        defer { viewModel.suggestingIDs.remove(exercise.uuid) }
        let groups = await inference.inferMuscleGroups(for: exercise.name)
        guard !groups.isEmpty else { return }
        exerciseManager.updateExercise(exercise) { $0.muscleGroups = groups }
    }
}
#endif
