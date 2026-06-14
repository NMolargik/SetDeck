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
    /// The deck's "suit" accent, supplied by the day. Defaults to brand green.
    var accent: Color = .greenStart

    private var orderedSets: [SetDeckSet] {
        // Prefer manager fetch for consistent ordering; fallback to relationship if needed
        let fetched = exerciseManager.sets(for: exercise)
        if !fetched.isEmpty { return fetched }
        return (exercise.sets ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            cardBase

            // Large faint rank watermark — fills the face and reinforces the
            // deck-of-cards identity.
            Text("\(index + 1)")
                .font(.system(size: 220, weight: .bold, design: .rounded))
                .foregroundStyle(accent.opacity(0.06))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, -8)
                .padding(.bottom, -24)
                .clipped()
                .accessibilityHidden(true)

            ScrollView {
                VStack(alignment: .leading, spacing: Brand.Space.lg) {
                    header

                    if orderedSets.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: Brand.Space.sm) {
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
                .padding(Brand.Space.xl)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(exercise.name), exercise \(index + 1)")
    }

    // MARK: - Card surface

    private var cardBase: some View {
        RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
            .fill(LinearGradient(colors: [Color(white: 0.99), Color(white: 0.95)], startPoint: .top, endPoint: .bottom))
            .overlay( // crisp inner card-stock highlight
                RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                    .stroke(.white, lineWidth: 3)
            )
            .overlay( // subtle accent-tinted edge
                RoundedRectangle(cornerRadius: Brand.Radius.card - 2, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [accent.opacity(0.45), accent.opacity(0.12)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1.5
                    )
                    .padding(3)
            )
            .shadow(color: .black.opacity(0.28), radius: 20, x: 0, y: 14)
            .shadow(color: accent.opacity(0.18), radius: 30, x: 0, y: 0)
    }

    private var emptyState: some View {
        VStack(spacing: Brand.Space.sm) {
            Image(systemName: "plus.rectangle.on.rectangle")
                .font(.title2)
                .foregroundStyle(accent)
                .symbolEffect(.pulse)
            Text("No sets yet")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Brand.Space.xl)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Brand.Space.md) {
            // Suit-style accent pip
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [accent, accent.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: exercise.isWarmup ? "flame.fill" : "figure.strengthtraining.traditional")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)
            .shadow(color: accent.opacity(0.4), radius: 8, y: 3)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Brand.Space.sm) {
                Text(exercise.name.isEmpty ? "Exercise" : exercise.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: Brand.Space.sm) {
                    if exercise.isWarmup {
                        cardPill("Warm-up", systemImage: "flame.fill", tint: .orangeStart)
                    }
                    if let equipment = exercise.equipment, !equipment.isEmpty {
                        cardPill(equipment, systemImage: "scalemass.fill", tint: .secondary)
                    }
                    if let urlString = exercise.videoURL, let url = URL(string: urlString.absoluteString), !urlString.absoluteString.isEmpty {
                        Link(destination: url) {
                            cardPill("Video", systemImage: "play.fill", tint: .red, filled: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ContentBuilder
    private func cardPill(_ title: String, systemImage: String, tint: Color, filled: Bool = false) -> some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(filled ? .white : tint)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(filled ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.14)))
            )
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
