//
//  EditRoutineView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/23/25.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct EditRoutineView: View {
    @Environment(ExerciseManager.self) private var exerciseManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = ViewModel()

    @FocusState private var focusedExerciseID: UUID?
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false

    var body: some View {
        VStack(spacing: 0) {
            DayPickerView(selectedDay: $viewModel.selectedDay)
                .padding(.top, 12)

            let currentRoutine = viewModel.currentRoutine(using: exerciseManager)
            let exercises = viewModel.exercises(using: exerciseManager)
                .sorted { (lhs: SetDeckExercise, rhs: SetDeckExercise) -> Bool in
                    (lhs.orderIndex) < (rhs.orderIndex)
                }
            let _ = exerciseManager.changeStamp

            List {
                if exercises.isEmpty {
                    Section {
                        VStack(spacing: 8) {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    viewModel.addExercise(named: "New Exercise", using: exerciseManager)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Exercise")
                                        .font(.callout.weight(.semibold))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .foregroundStyle(.white)
                                .background(
                                    Capsule()
                                        .fill(Color.blueStart)
                                )
                                .contentShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                } else {
                    ForEach(exercises, id: \.uuid) { exercise in
                        Section(
                            header: exerciseHeader(for: exercise)
                                .listRowInsets(EdgeInsets()),
                            footer: Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    viewModel.addSet(to: exercise, using: exerciseManager)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Set")
                                        .font(.callout.weight(.semibold))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .foregroundStyle(.white)
                                .background(
                                    Capsule()
                                        .fill(Color.blueStart)
                                )
                                .contentShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        ) {
                            let sets = exerciseManager.sets(for: exercise)
                                .sorted { (lhs: SetDeckSet, rhs: SetDeckSet) -> Bool in
                                    (lhs.orderIndex) < (rhs.orderIndex)
                                }
                            ForEach(sets, id: \.uuid) { set in
                                EditSetRowView(set: set, setCount: sets.count)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                            .onDelete { offsets in
                                DispatchQueue.main.async {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        viewModel.deleteSets(at: offsets, from: sets, using: exerciseManager)
                                    }
                                }
                            }
                            .onMove { indices, destination in
                                viewModel.moveSets(from: indices,
                                                   to: destination,
                                                   in: sets,
                                                   exercise: exercise,
                                                   using: exerciseManager)
                            }
                        }
                    }
                    .onDelete { offsets in
                        focusedExerciseID = nil
                        DispatchQueue.main.async {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                viewModel.deleteExercises(at: offsets, from: exercises, using: exerciseManager)
                                // Reindex remaining exercises so new ones appear at the bottom and indices stay contiguous
                                let remaining = viewModel.exercises(using: exerciseManager)
                                    .sorted { (l: SetDeckExercise, r: SetDeckExercise) -> Bool in
                                        (l.orderIndex) < (r.orderIndex)
                                    }
                                for (idx, ex) in remaining.enumerated() {
                                    exerciseManager.updateExercise(ex) { $0.orderIndex = idx }
                                }
                            }
                        }
                    }
                    .onMove { indices, destination in
                        viewModel.moveExercises(from: indices,
                                                to: destination,
                                                in: exercises,
                                                currentRoutine: currentRoutine,
                                                using: exerciseManager)
                        // Persist new order indices after move
                        let reordered = viewModel.exercises(using: exerciseManager)
                            .sorted { (l: SetDeckExercise, r: SetDeckExercise) -> Bool in
                                (l.orderIndex) < (r.orderIndex)
                            }
                        for (idx, ex) in reordered.enumerated() {
                            exerciseManager.updateExercise(ex) { $0.orderIndex = idx }
                        }
                    }

                    if !exercises.isEmpty {
                        Section(footer: Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                viewModel.addExercise(named: "New Exercise", using: exerciseManager)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Exercise")
                                    .font(.callout.weight(.semibold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .foregroundStyle(.white)
                            .background(
                                Capsule()
                                    .fill(Color.blueStart)
                            )
                            .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .listRowInsets(EdgeInsets())) {
                            EmptyView()
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
        }
        .onAppear {
            viewModel.resetToToday()
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue == .active {
                viewModel.resetToToday()
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.selectedDay)
        .navigationTitle("Edit Routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    focusedExerciseID = nil
                    dismiss()
                }
                .bold()
                .tint(.greenStart)
            }
        }
    }

    @ViewBuilder
    private func exerciseHeader(for exercise: SetDeckExercise) -> some View {
        HStack(spacing: 12) {
            TextField("Exercise Name", text: Binding(
                get: { exercise.name },
                set: { newValue in
                    exerciseManager.updateExercise(exercise) { $0.name = newValue }
                }
            ))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .textFieldStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
            .focused($focusedExerciseID, equals: exercise.uuid)

            // When focused, show a checkmark button to clear focus
            if focusedExerciseID == exercise.uuid {
                Button {
                    focusedExerciseID = nil
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.greenStart)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if focusedExerciseID != exercise.uuid {
                HStack(spacing: 8) {
                    Text("Warmup?")
                        .font(.caption)
                        .foregroundStyle(.primary)

                    Toggle("", isOn: Binding(
                        get: { exercise.isWarmup },
                        set: { newValue in
                            exerciseManager.updateExercise(exercise) { $0.isWarmup = newValue }
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .orangeStart))
                }

                Button {
                    if focusedExerciseID == exercise.uuid {
                        focusedExerciseID = nil
                    }
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            exerciseManager.deleteExercise(exercise)
                        }
                    }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.body)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: focusedExerciseID)
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

    return NavigationStack {
        EditRoutineView()
            .environment(exerciseManager)
            .preferredColorScheme(.dark)
            .onAppear {
                // Add one new exercise to the current day's routine when preview appears
                let calendar = Calendar.current
                let todayIndex = (calendar.component(.weekday, from: Date()) - 1 + 7) % 7
                // Check if there is already an exercise with this sentinel name to avoid duplicates per preview run
                let existing = exerciseManager.exercises(forDay: todayIndex).first { $0.name == "Preview Added Exercise" }
                if existing == nil {
                    _ = exerciseManager.addExercise(named: "Preview Added Exercise", toDay: todayIndex)
                }
            }
    }
}

