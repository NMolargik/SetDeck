//
//  SetRowView.swift
//  SetDeckFeatureRoutine
//
//  Created by Nick Molargik on 11/28/25.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared

struct SetRowView: View {
    @Environment(WorkoutDataModel.self) private var exerciseManager
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false

    @Binding var isEditing: Bool
    @State private var editReps: Int = 0
    @State private var editWeight: Double = 0
    @State private var editRPE: Int = 0
    @State private var editDurationMinutes: Int = 0

    // Track original values to detect changes
    @State private var originalReps: Int = 0
    @State private var originalWeight: Double = 0
    @State private var originalRPE: Int = 0
    @State private var originalDurationMinutes: Int = 0

    let set: SetDeckSet
    /// The first set of the exercise not yet logged today: marked "Next".
    var isNext: Bool = false
    /// Logged today.
    var isLogged: Bool = false
    var accent: Color = .greenStart
    /// Minimum height of the collapsed row; the content is centred in it.
    var minRowHeight: CGFloat = 0

    private var hasChanges: Bool {
        editReps != originalReps ||
        editWeight != originalWeight ||
        editRPE != originalRPE ||
        editDurationMinutes != originalDurationMinutes
    }

    private func lbsToKg(_ lbs: Double) -> Double { lbs * 0.45359237 }
    private func kgToLbs(_ kg: Double) -> Double { kg / 0.45359237 }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                // Type badge
                Text(typeAbbreviation)
                    .font(.caption2.bold())
                    .foregroundStyle(Color.greenStart)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .background(Color.greenStart.opacity(0.18), in: Capsule(style: .continuous))
                    .overlay(Capsule(style: .continuous).stroke(Color.greenStart.opacity(0.35), lineWidth: 1))
                    .frame(width: 55)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(primaryLine)
                        .font(.title3).bold()
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .truncationMode(.tail)

                    if let detail = secondaryLine {
                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                Spacer()

                if isNext && !isEditing {
                    Text("Next")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(accent))
                }
                if isLogged && !isEditing {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.greenStart)
                        .accessibilityHidden(true)
                }
                Image(systemName: isEditing ? "chevron.down" : "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isNext ? accent : Color.secondary)
                    .animation(.easeInOut(duration: 0.25), value: isEditing)
            }
            .padding(12)
            .frame(minHeight: isEditing ? 0 : minRowHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isEditing else { return }
                withAnimation { beginEditing() }
            }

            if isEditing {
                Group {
                    VStack(spacing: 0) {
                        Group {
                            VStack(alignment: .leading, spacing: 12) {
                                // Action buttons
                                HStack(spacing: 10) {
                                    Spacer()
                                    Button {
                                        withAnimation { isEditing = false }
                                    } label: {
                                        Text("Cancel")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 8)
                                            .background(Color.red, in: Capsule())
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: false)
                                    }
                                    .buttonStyle(.plain)
                                    .hoverEffectIfAvailable(.highlight)
                                    Button {
                                        saveEdits()
                                    } label: {
                                        Text(hasChanges ? "Save" : "Log")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 8)
                                            .background(hasChanges ? Color.blueStart : Color.greenStart, in: Capsule())
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: false)
                                    }
                                    .buttonStyle(.plain)
                                    .hoverEffectIfAvailable(.highlight)
                                }

                                // Vertical editor fields in a horizontal row
                                // Side by side when the card is wide enough; stacked otherwise. Chosen by
                                // available width (not size class): an iPad portrait card is narrow, and a
                                // forced row overflowed and pushed the card off-screen.
                                ViewThatFits(in: .horizontal) {
                                    HStack(alignment: .top, spacing: 12) { editorFields }
                                    VStack(alignment: .leading, spacing: 12) { editorFields }
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                        .contentTransition(.opacity)
                    }
                }
                .transition(.scale(scale: 0.98, anchor: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.chip, style: .continuous)
                .fill(Color.white.opacity(isNext ? 0.12 : 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.Radius.chip, style: .continuous)
                        .stroke(isNext ? accent.opacity(0.7) : Color.white.opacity(0.10), lineWidth: isNext ? 1.5 : 1)
                )
        )
        .opacity(isLogged && !isEditing ? 0.7 : 1)
        .animation(.easeInOut(duration: 0.25), value: isEditing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    @ViewBuilder
    private var editorFields: some View {
        if set.setType != .duration {
            editorFieldVertical("Reps") {
                StepperControl(value: $editReps, step: 1, display: "\(editReps)")
            }
        }
        editorFieldVertical("Weight (\(useMetricUnits ? "kg" : "lbs"))") {
            StepperControlDouble(
                value: $editWeight,
                step: useMetricUnits ? 2.5 : 5.0,
                display: trimTrailingZeros(editWeight)
            )
        }
        if set.setType == .duration {
            editorFieldVertical("Duration (minutes)") {
                StepperControl(value: $editDurationMinutes, step: 1, display: "\(editDurationMinutes)")
            }
        }
        editorFieldVertical("RPE") {
            StepperControl(value: $editRPE, step: 1, display: "\(editRPE)")
        }
    }

    private var typeAbbreviation: String {
        switch set.setType {
        case .reps: return "REPS"
        case .amap: return "AMAP"
        case .duration: return "TIME"
        case .freeform: return "FREE"
        }
    }

    private var primaryLine: String {
        switch set.setType {
        case .reps, .amap:
            let reps = set.targetReps.map { "\($0)x" } ?? "Reps"
            let weightPart: String = {
                if let w = set.weight {
                    let displayWeight = useMetricUnits ? lbsToKg(w) : w
                    let unit = useMetricUnits ? "kg" : "lbs"
                    return " • \(trimTrailingZeros(displayWeight)) \(unit)"
                }
                return ""
            }()
            return "\(reps)\(weightPart)"
        case .duration:
            let dur = set.targetDuration.map(timeString) ?? "Duration"
            return dur

        case .freeform:
            return "Freeform"
        }
    }

    private var secondaryLine: String? {
        var parts: [String] = []
        if let desc = set.setDescription, !desc.isEmpty {
            parts.append(desc)
        }
        if let rpe = set.rpe, rpe > 0 {
            parts.append("RPE \(rpe)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    private var accessibilitySummary: String {
        var comps: [String] = []
        comps.append(primaryLine)
        if let s = secondaryLine { comps.append(s) }
        if isLogged { comps.append(String(localized: "Logged")) }
        if isNext { comps.append(String(localized: "Next set")) }
        return comps.joined(separator: ", ")
    }

    private func beginEditing() {
        // Seed edit values from the set's targets or existing values
        switch set.setType {
        case .reps, .amap:
            editReps = set.targetReps ?? 0
        case .duration:
            editDurationMinutes = Int((set.targetDuration ?? 0) / 60)
        case .freeform:
            editReps = 0
        }
        let baseWeightLbs = set.weight ?? 0
        editWeight = useMetricUnits ? lbsToKg(baseWeightLbs) : baseWeightLbs
        editRPE = set.rpe ?? 0
        editRPE = max(0, editRPE)

        // Store original values to detect changes
        originalReps = editReps
        originalWeight = editWeight
        originalRPE = editRPE
        originalDurationMinutes = editDurationMinutes

        isEditing = true
    }

    private func saveEdits() {
        // Determine values to save based on set type
        var repsToSave: Int? = nil
        let weightToSave: Double? = useMetricUnits ? kgToLbs(editWeight) : editWeight
        let rpeToSave: Int? = max(0, editRPE)

        switch set.setType {
        case .reps, .amap:
            repsToSave = editReps
        case .duration:
            // Convert minutes to seconds for targetDuration
            let seconds = TimeInterval(editDurationMinutes * 60)
            // Use manager to update duration through reps parameter if your model expects duration elsewhere.
            // Here we directly set on the set before calling manager to persist/history.
            set.targetDuration = seconds
            repsToSave = nil
        case .freeform:
            repsToSave = nil
        }

        exerciseManager.update(set: set, withReps: repsToSave, weight: weightToSave, rpe: rpeToSave)
        withAnimation { isEditing = false }
    }

    private func timeString(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds))
        let minutes = totalSeconds / 60
        return "\(minutes) min"
    }

    private func trimTrailingZeros(_ value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }

    @ViewBuilder
    private func editorField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .truncationMode(.tail)
            Spacer(minLength: 8)
            content()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func editorFieldVertical<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .truncationMode(.tail)
            content()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private struct StepperControl: View {
        @Binding var value: Int
        let step: Int
        let display: String
        var body: some View {
            HStack(spacing: 8) {
                Button(action: { value = max(0, value - step) }) { Image(systemName: "minus.circle.fill") }
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .hoverEffectIfAvailable(.highlight)
                Text(display)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.primary)
                    .frame(minWidth: 44, idealWidth: 64, maxWidth: 80)
                Button(action: { value = max(0, value + step) }) { Image(systemName: "plus.circle.fill") }
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .hoverEffectIfAvailable(.highlight)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .sensoryFeedback(.selection, trigger: value)
        }
    }

    private struct StepperControlDouble: View {
        @Binding var value: Double
        let step: Double
        let display: String
        var body: some View {
            HStack(spacing: 8) {
                Button(action: { value = max(0.0, value - step) }) { Image(systemName: "minus.circle.fill") }
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .hoverEffectIfAvailable(.highlight)
                Text(display)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.primary)
                    .frame(minWidth: 44, idealWidth: 64, maxWidth: 80)
                Button(action: { value = max(0.0, value + step) }) { Image(systemName: "plus.circle.fill") }
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .hoverEffectIfAvailable(.highlight)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .sensoryFeedback(
                .selection,
                trigger: Int((value / max(step, 0.0001)).rounded())
            )
        }
    }
}
#endif
