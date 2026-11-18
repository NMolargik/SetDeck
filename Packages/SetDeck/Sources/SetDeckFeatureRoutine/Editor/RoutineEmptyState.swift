//
//  RoutineEmptyState.swift
//  SetDeckFeatureRoutine
//
//  Shown when a day has no exercises: explains how a routine is built and offers
//  one-tap starter exercises (each added with three sets of ten).
//

#if os(iOS)
import SwiftUI
import TipKit
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared

struct RoutineEmptyState: View {
    let day: Int
    let onAddBlank: () -> Void
    let onAddStarter: (String) -> Void

    init(day: Int, onAddBlank: @escaping () -> Void, onAddStarter: @escaping (String) -> Void) {
        self.day = day
        self.onAddBlank = onAddBlank
        self.onAddStarter = onAddStarter
    }

    private let addExerciseTip = AddExerciseTip()
    private let starters = ["Bench Press", "Squat", "Deadlift", "Overhead Press", "Pull-Up", "Barbell Row"]

    var body: some View {
        VStack(spacing: Brand.Space.xl) {
            VStack(spacing: Brand.Space.sm) {
                Image(systemName: "square.stack.3d.up.badge.plus")
                    .font(.system(size: 44))
                    .foregroundStyle(.brandGreen)
                    .accessibilityHidden(true)
                Text("Build \(EditorDay.name(day))'s workout")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                Text("A routine is a list of exercises, and each exercise is a list of sets.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: Brand.Space.md) {
                StepRow(icon: "dumbbell.fill", tint: .blueStart,
                        title: "Add an exercise", detail: "Name it. Muscle groups are filled in for you when possible.")
                StepRow(icon: "repeat", tint: .greenStart,
                        title: "Add sets", detail: "Pick reps, as many as possible, timed or freeform, then set the targets.")
                StepRow(icon: "arrow.up.arrow.down", tint: .purpleStart,
                        title: "Order it", detail: "Use the ••• menu on a card to move or delete it.")
            }

            Button(action: {
                addExerciseTip.invalidate(reason: .actionPerformed)
                onAddBlank()
            }) {
                Label("Add Exercise", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassCapsule(tint: .greenStart, prominent: true))
            .popoverTip(addExerciseTip, arrowEdge: .top)
            .accessibilityHint("Creates a new exercise for this day's routine")

            VStack(spacing: Brand.Space.sm) {
                Text("Or start from a classic")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                FlowLayout(spacing: Brand.Space.sm, lineSpacing: Brand.Space.sm) {
                    ForEach(starters, id: \.self) { name in
                        Button { onAddStarter(name) } label: {
                            Label(name, systemImage: "plus")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.white.opacity(0.1)))
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                        .hoverEffectIfAvailable(.highlight)
                        .accessibilityLabel("Add \(name) with three sets")
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Brand.Space.xl)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        )
    }
}

private struct StepRow: View {
    let icon: String
    let tint: Color
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: Brand.Space.md) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Circle().fill(tint))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
#endif
