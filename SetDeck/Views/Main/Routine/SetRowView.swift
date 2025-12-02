//
//  SetRowView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/28/25.
//

import SwiftUI
import SwiftData

struct SetRowView: View {
    @Environment(ExerciseManager.self) private var exerciseManager
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var isEditing: Bool
    @State private var editReps: Int = 0
    @State private var editWeight: Double = 0
    @State private var editRPE: Int = 0
    @State private var editDurationMinutes: Int = 0

    let set: SetDeckSet

    private func lbsToKg(_ lbs: Double) -> Double { lbs * 0.45359237 }
    private func kgToLbs(_ kg: Double) -> Double { kg / 0.45359237 }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                // Type badge
                Text(typeAbbrev)
                    .font(.caption2.bold())
                    .foregroundStyle(.black)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(white: 0.9), in: Capsule())
                    .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                    .frame(width: 55)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(primaryLine)
                        .font(.title3).bold()
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .truncationMode(.tail)

                    if let detail = secondaryLine {
                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(.black)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                Spacer()

                Image(systemName: isEditing ? "chevron.down" : "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.greenStart)
                    .animation(.easeInOut(duration: 0.25), value: isEditing)
            }
            .padding(12)
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
                                    Button("Cancel") { withAnimation { isEditing = false } }
                                        .font(.caption.bold())
                                        .foregroundStyle(.red.gradient)
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 8)
                                    Button {
                                        saveEdits()
                                    } label: {
                                        Text("Save")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 8)
                                            .background(Color.blueStart, in: Capsule())
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: false)
                                    }
                                    .buttonStyle(.plain)
                                }

                                // Vertical editor fields in a horizontal row
                                if horizontalSizeClass == .compact {
                                    VStack(alignment: .leading, spacing: 12) {
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
                                } else {
                                    HStack(alignment: .top, spacing: 12) {
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
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(white: 0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.25), value: isEditing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var typeAbbrev: String {
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
                .foregroundStyle(.black)
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
                .fill(Color.white.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func editorFieldVertical<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .truncationMode(.tail)
            content()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
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
                    .foregroundStyle(.black)
                Text(display)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.black)
                    .frame(minWidth: 44, idealWidth: 64, maxWidth: 80)
                Button(action: { value = max(0, value + step) }) { Image(systemName: "plus.circle.fill") }
                    .font(.title2)
                    .foregroundStyle(.black)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.4))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
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
                    .foregroundStyle(.black)
                Text(display)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.black)
                    .frame(minWidth: 44, idealWidth: 64, maxWidth: 80)
                Button(action: { value = max(0.0, value + step) }) { Image(systemName: "plus.circle.fill") }
                    .font(.title2)
                    .foregroundStyle(.black)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.4))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .sensoryFeedback(
                .selection,
                trigger: Int((value / max(step, 0.0001)).rounded())
            )
        }
    }
}

#Preview {
    struct SetRowPreviewWrapper: View {
        @State private var isEditing: Bool = false

        var body: some View {
            // Provide an ExerciseManager in the environment for preview
            let container: ModelContainer = {
                let schema = Schema([SetDeckRoutine.self, SetDeckExercise.self, SetDeckSet.self, SetDeckSetHistory.self])
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                return try! ModelContainer(for: schema, configurations: [configuration])
            }()
            let context = ModelContext(container)
            let exerciseManager = ExerciseManager(context: context)

            // Create a sample exercise with some sets and pick one
            let exercise = SetDeckExercise.sample(seed: 7, setCount: 3)
            let sets = exerciseManager.sets(for: exercise)
            let set = sets.first ?? (exercise.sets ?? []).first ?? SetDeckSet()

            return SetRowView(isEditing: $isEditing, set: set)
                .environment(exerciseManager)
                .padding()
        }
    }

    return SetRowPreviewWrapper()
}

