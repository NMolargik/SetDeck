//
//  ExerciseEditorCard.swift
//  SetDeckFeatureRoutine
//
//  A rich, read-at-a-glance exercise card for the routine editor: muscle-group icon and
//  colour, name, set count, warmup badge, and one pill per set showing type and target.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem

struct ExerciseEditorCard: View {
    let exercise: SetDeckExercise
    let sets: [SetDeckSet]
    let index: Int
    let total: Int
    let isSelected: Bool
    var useMetric: Bool = false
    let onSelect: () -> Void
    let onMove: (Int) -> Void
    let onDelete: () -> Void

    private var tint: Color { exercise.presentationTint() }
    private var icon: String { exercise.presentationIcon }

    private var subtitle: String {
        let setText = sets.isEmpty
            ? String(localized: "No sets yet")
            : (sets.count == 1 ? String(localized: "1 set") : String(localized: "\(sets.count) sets"))
        let groups = exercise.presentationGroups
        guard !groups.isEmpty else { return setText }
        let names = groups.prefix(3).map(\.displayName).joined(separator: ", ")
        return "\(setText) · \(names)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Space.md) {
            HStack(alignment: .center, spacing: Brand.Space.md) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: Brand.Radius.chip, style: .continuous)
                            .fill(LinearGradient(colors: [tint, tint.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Brand.Space.sm) {
                        Text(exercise.name.isEmpty ? String(localized: "Untitled Exercise") : exercise.name)
                            .font(.headline)
                            .lineLimit(2)
                            .layoutPriority(1)
                        if exercise.isWarmup {
                            Label(String(localized: "Warm-up"), systemImage: "flame.fill")
                                .labelStyle(.titleAndIcon)
                                .lineLimit(1)
                                .fixedSize()
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .foregroundStyle(Color.orangeStart)
                                .background(Capsule().fill(Color.orangeStart.opacity(0.18)))
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Menu {
                    Button { onMove(-1) } label: { Label("Move Up", systemImage: "arrow.up") }
                        .disabled(index == 0)
                    Button { onMove(1) } label: { Label("Move Down", systemImage: "arrow.down") }
                        .disabled(index >= total - 1)
                    Divider()
                    Button(role: .destructive, action: onDelete) { Label("Delete Exercise", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Options for \(exercise.name)")
            }

            if sets.isEmpty {
                Label("Tap to add sets", systemImage: "plus.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            } else {
                FlowLayout(spacing: Brand.Space.xs + 2, lineSpacing: Brand.Space.xs + 2) {
                    ForEach(Array(sets.enumerated()), id: \.element.uuid) { offset, set in
                        SetPill(set: set, number: offset + 1, useMetric: useMetric)
                    }
                }
            }
        }
        .padding(Brand.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                        .strokeBorder(isSelected ? tint : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isSelected ? tint.opacity(0.35) : .black.opacity(0.2), radius: isSelected ? 14 : 8, x: 0, y: 6)
        )
        .contentShape(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
        .onTapGesture(perform: onSelect)
        .hoverEffectIfAvailable(.highlight)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: Text("Edit sets"), onSelect)
        .accessibilityAction(named: Text("Move up")) { if index > 0 { onMove(-1) } }
        .accessibilityAction(named: Text("Move down")) { if index < total - 1 { onMove(1) } }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
    }
}

/// One set as a capsule: type icon + "10 × 135" / "1 min" / "Freeform", tinted by set type.
struct SetPill: View {
    let set: SetDeckSet
    let number: Int
    var useMetric: Bool = false

    var body: some View {
        let tint = set.setType.editorColor
        HStack(spacing: 5) {
            Image(systemName: set.setType.editorIcon)
                .font(.system(size: 10, weight: .bold))
            Text(EditorFormat.pillText(for: set, metric: useMetric))
                .font(.caption.weight(.semibold).monospacedDigit())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(tint)
        .background(Capsule().fill(tint.opacity(0.16)))
        .overlay(Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 0.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(EditorFormat.spokenText(for: set, number: number, metric: useMetric))
    }
}

/// A muscle group as a coloured capsule.
struct MuscleChip: View {
    let group: MuscleGroup
    var onRemove: (() -> Void)?

    var body: some View {
        let tint = group.editorColor
        HStack(spacing: 5) {
            Image(systemName: group.editorIcon)
                .font(.system(size: 10, weight: .bold))
            Text(group.displayName)
                .font(.caption.weight(.semibold))
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(group.displayName)")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(tint)
        .background(Capsule().fill(tint.opacity(0.16)))
        .overlay(Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 0.5))
    }
}

/// Wraps its children onto new lines, like text.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, usedWidth: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                y += rowHeight + lineSpacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            usedWidth = max(usedWidth, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? usedWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += rowHeight + lineSpacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
#endif
