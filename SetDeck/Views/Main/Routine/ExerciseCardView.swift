//
//  ExerciseCardView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/14/25.
//

import SwiftUI
import SwiftData

struct ExerciseCardView: View {
    @Environment(ExerciseManager.self) private var exerciseManager: ExerciseManager
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    
    @State private var expandedSetID: UUID? = nil
    @Environment(\.openURL) private var openURLAction
    let index: Int
    let exercise: SetDeckExercise

    private var orderedSets: [SetDeckSet] {
        // Prefer manager fetch for consistent ordering; fallback to relationship if needed
        let fetched = exerciseManager.sets(for: exercise)
        if !fetched.isEmpty { return fetched }
        return (exercise.sets ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Color.white.opacity(0.9), Color.white.opacity(1.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.gray, lineWidth: 7)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8)
            

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header

                    if orderedSets.isEmpty {
                        Text("No sets yet")
                            .font(.subheadline)
                            .foregroundStyle(.black)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(orderedSets, id: \.uuid) { set in
                            let isExpanded = Binding<Bool>(
                                get: { expandedSetID == set.uuid },
                                set: { newValue in
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                        expandedSetID = newValue ? set.uuid : nil
                                    }
                                }
                            )
                            SetRowView(isEditing: isExpanded, set: set)
                        }
                    }
                }
            }
            .padding(16)
            .scrollIndicators(.hidden)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(exercise.name), exercise \(index)")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name.isEmpty ? "Exercise" : exercise.name)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .truncationMode(.tail)

                HStack(spacing: 8) {
                    if let equipment = exercise.equipment, !equipment.isEmpty {
                        Label(equipment, systemImage: "scalemass.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundStyle(.black)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color(white: 0.92))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                    }
                    if exercise.isWarmup {
                        Label("Warmup", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.black)
                            .brightness(-0.1)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color(white: 0.92))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                    }
                    if let urlString = exercise.videoURL, let url = URL(string: urlString.absoluteString), !urlString.absoluteString.isEmpty {
                        Link(destination: url) {
                            Label("Video", systemImage: "play.rectangle.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.red)
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Spacer(minLength: 10)
        }
    }
}

#Preview {
    // Provide an ExerciseManager in the environment for preview
    let container: ModelContainer = {
        let schema = Schema([SetDeckRoutine.self, SetDeckExercise.self, SetDeckSet.self, SetDeckSetHistory.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    let exerciseManager = ExerciseManager(context: context)

    return ExerciseCardView(index: 1, exercise: SetDeckExercise.sample(seed: 42, setCount: 3))
        .environment(exerciseManager)
        .preferredColorScheme(.dark)
}
