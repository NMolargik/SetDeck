//
//  EditSetRowView.swift
//  SetDeckFeatureRoutine
//
//  Created by Nick Molargik on 11/29/25.
//
//  One set's inline editor: a numbered, type-coloured card with a type selector and
//  steppers for the targets that type uses. Writes go through `WorkoutDataModel.updateSet`.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared

struct EditSetRowView: View {
    let set: SetDeckSet
    let setCount: Int
    /// 1-based position within the exercise; nil hides the badge.
    var number: Int?
    /// Reorder handlers; nil hides the arrow (first/last row).
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?

    @Environment(WorkoutDataModel.self) private var exerciseManager
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false

    init(set: SetDeckSet, setCount: Int, number: Int? = nil,
         onMoveUp: (() -> Void)? = nil, onMoveDown: (() -> Void)? = nil) {
        self.set = set
        self.setCount = setCount
        self.number = number
        self.onMoveUp = onMoveUp
        self.onMoveDown = onMoveDown
    }

    private func lbsToKg(_ lbs: Double) -> Double { lbs / EditorFormat.poundsPerKilogram }
    private func kgToLbs(_ kg: Double) -> Double { kg * EditorFormat.poundsPerKilogram }

    // MARK: Bindings

    private func commit(_ change: (SetDeckSet) -> Void) {
        exerciseManager.updateSet(set) { change($0) }
    }

    private var repsBinding: Binding<Int> {
        Binding(get: { set.targetReps ?? 10 }, set: { v in commit { $0.targetReps = v } })
    }

    private var weightBinding: Binding<Double> {
        Binding(
            get: {
                let stored = set.weight ?? 0
                return useMetricUnits ? lbsToKg(stored) : stored
            },
            set: { v in
                let lbs = useMetricUnits ? kgToLbs(v) : v
                commit { $0.weight = lbs }
            }
        )
    }

    private var durationMinutesBinding: Binding<Int> {
        Binding(
            get: { Int((set.targetDuration ?? 60) / 60) },
            set: { v in commit { $0.targetDuration = TimeInterval(v * 60) } }
        )
    }

    private var rpeBinding: Binding<Int> {
        Binding(get: { set.rpe ?? 6 }, set: { v in commit { $0.rpe = v } })
    }

    private func select(_ newType: SetType) {
        guard newType != set.setType else { return }
        Haptics.lightImpact()
        commit { set in
            set.setType = newType
            // Clear incompatible fields and set defaults
            switch newType {
            case .duration:
                set.targetReps = nil
                set.setDescription = nil
                if set.targetDuration == nil { set.targetDuration = 60 }
            case .freeform:
                set.targetReps = nil
                set.targetDuration = nil
                if set.rpe == nil { set.rpe = 6 }
            case .reps, .amap:
                set.setDescription = nil
                set.targetDuration = nil
                if set.targetReps == nil { set.targetReps = 10 }
                if set.weight == nil { set.weight = 0 }
            }
        }
    }

    // MARK: Body

    var body: some View {
        let tint = set.setType.editorColor
        VStack(alignment: .leading, spacing: Brand.Space.md) {
            header(tint: tint)
            typePicker
            fields
        }
        .padding(Brand.Space.md)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.control, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.Radius.control, style: .continuous)
                        .strokeBorder(tint.opacity(0.35), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: set.setType)
    }

    private func header(tint: Color) -> some View {
        HStack(spacing: Brand.Space.sm) {
            if let number {
                Text("\(number)")
                    .font(.footnote.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(tint))
                    .accessibilityHidden(true)
            }
            Text(EditorFormat.pillText(for: set, metric: useMetricUnits))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            if let onMoveUp {
                reorderButton("chevron.up", label: "Move set up", action: onMoveUp)
            }
            if let onMoveDown {
                reorderButton("chevron.down", label: "Move set down", action: onMoveDown)
            }
            if setCount > 1 {
                Button {
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            exerciseManager.deleteSet(set)
                        }
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundStyle(.red)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hoverEffectIfAvailable(.highlight)
                .accessibilityLabel("Delete set")
                .accessibilityHint("Removes this set from the exercise")
            }
        }
    }

    private func reorderButton(_ systemName: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.lightImpact()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8), action)
        } label: {
            Image(systemName: systemName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverEffectIfAvailable(.highlight)
        .accessibilityLabel(label)
    }

    private var typePicker: some View {
        ViewThatFits(in: .horizontal) {
            typeChips(showIcon: true, showTitle: true)
            typeChips(showIcon: false, showTitle: true)
            typeChips(showIcon: true, showTitle: false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Set type")
        .accessibilityHint("Choose between reps, as many as possible, timed, or freeform sets")
    }

    private func typeChips(showIcon: Bool, showTitle: Bool) -> some View {
        HStack(spacing: Brand.Space.xs) {
            ForEach(SetType.allCases) { type in
                let selected = type == set.setType
                Button { select(type) } label: {
                    HStack(spacing: 4) {
                        if showIcon {
                            Image(systemName: type.editorIcon)
                                .font(.caption.weight(.bold))
                        }
                        if showTitle {
                            Text(type.editorTitle)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    .foregroundStyle(selected ? Color.white : Color.primary)
                    .background(
                        Capsule().fill(selected ? type.editorColor : Color.white.opacity(0.08))
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(type.editorTitle)
                .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
            }
        }
    }

    @ViewBuilder
    private var fields: some View {
        switch set.setType {
        case .reps, .amap:
            fieldRow {
                StepperField(title: set.setType == .amap ? "Reps Attempted" : "Reps",
                             value: repsBinding, step: 1, display: "\(repsBinding.wrappedValue)",
                             label: "Reps")
                StepperFieldDouble(title: useMetricUnits ? "Weight (kg)" : "Weight (lbs)",
                                   value: weightBinding, step: useMetricUnits ? 2.5 : 5,
                                   display: EditorFormat.weightString(weightBinding.wrappedValue),
                                   label: "Weight", unit: useMetricUnits ? "kilograms" : "pounds")
                rpeField
            }
        case .duration:
            fieldRow {
                StepperField(title: "Duration (min)", value: durationMinutesBinding, step: 1,
                             display: "\(durationMinutesBinding.wrappedValue)", label: "Duration in minutes")
                rpeField
            }
        case .freeform:
            fieldRow { rpeField }
        }
    }

    private var rpeField: some View {
        StepperField(title: "RPE", value: rpeBinding, step: 1, maximum: 10,
                     display: "\(rpeBinding.wrappedValue)", label: "RPE")
    }

    /// Fields sit side by side when they fit, and stack otherwise.
    private func fieldRow<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let built = content()
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Brand.Space.lg) { built }
            VStack(alignment: .leading, spacing: Brand.Space.md) { built }
        }
    }
}

// MARK: - Steppers

private struct StepperField: View {
    let title: LocalizedStringKey
    @Binding var value: Int
    let step: Int
    var maximum: Int = .max
    let display: String
    var label: String = "Value"

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                StepButton(systemName: "minus.circle.fill", label: "Decrease \(label)", hint: "Decreases by \(step)") {
                    let updated = max(0, value - step)
                    if updated != value { value = updated; Haptics.lightImpact() }
                }
                Text(display)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .frame(minWidth: 40)
                    .accessibilityHidden(true)
                StepButton(systemName: "plus.circle.fill", label: "Increase \(label)", hint: "Increases by \(step)") {
                    let updated = min(maximum, value + step)
                    if updated != value { value = updated; Haptics.lightImpact() }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
        .accessibilityValue(display)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(maximum, value + step)
            case .decrement: value = max(0, value - step)
            @unknown default: break
            }
        }
    }
}

private struct StepperFieldDouble: View {
    let title: LocalizedStringKey
    @Binding var value: Double
    let step: Double
    let display: String
    var label: String = "Value"
    var unit: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                StepButton(systemName: "minus.circle.fill", label: "Decrease \(label)",
                           hint: "Decreases by \(EditorFormat.weightString(step)) \(unit)") {
                    let updated = max(0, value - step)
                    if updated != value { value = updated; Haptics.lightImpact() }
                }
                Text(display)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .frame(minWidth: 48)
                    .accessibilityHidden(true)
                StepButton(systemName: "plus.circle.fill", label: "Increase \(label)",
                           hint: "Increases by \(EditorFormat.weightString(step)) \(unit)") {
                    let updated = max(0, value + step)
                    if updated != value { value = updated; Haptics.lightImpact() }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
        .accessibilityValue("\(display) \(unit)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = max(0, value + step)
            case .decrement: value = max(0, value - step)
            @unknown default: break
            }
        }
    }
}

private struct StepButton: View {
    let systemName: String
    let label: String
    let hint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title)
                .foregroundStyle(.primary)
                .frame(minWidth: 36, minHeight: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverEffectIfAvailable(.highlight)
        .accessibilityLabel(label)
        .accessibilityHint(hint)
    }
}
#endif
