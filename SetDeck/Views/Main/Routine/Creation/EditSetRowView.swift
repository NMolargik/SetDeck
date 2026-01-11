//
//  EditSetRowView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI

struct EditSetRowView: View {
    let set: SetDeckSet
    let setCount: Int

    @Environment(ExerciseManager.self) private var exerciseManager
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false

    private func lbsToKg(_ lbs: Double) -> Double { lbs * 0.45359237 }
    private func kgToLbs(_ kg: Double) -> Double { kg / 0.45359237 }
    private func trimTrailingZeros(_ value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }

    private var repsBinding: Binding<Int?> {
        Binding(
            get: { set.targetReps },
            set: { newValue in
                set.targetReps = newValue
                exerciseManager.updateSet(set) { _ in }
            }
        )
    }

    private var weightBinding: Binding<Double?> {
        Binding(
            get: { set.weight },
            set: { newValue in
                set.weight = newValue
                exerciseManager.updateSet(set) { _ in }
            }
        )
    }

    private var durationBinding: Binding<TimeInterval?> {
        Binding(
            get: { set.targetDuration },
            set: { newValue in
                set.targetDuration = newValue
                exerciseManager.updateSet(set) { _ in }
            }
        )
    }

    private var rpeBinding: Binding<Int?> {
        Binding(
            get: { set.rpe },
            set: { newValue in
                set.rpe = newValue
                exerciseManager.updateSet(set) { _ in }
            }
        )
    }
   
    private var rpeNonOptionalBinding: Binding<Int> {
        Binding(
            get: { rpeBinding.wrappedValue ?? 6 },
            set: { newValue in rpeBinding.wrappedValue = newValue }
        )
    }

    private var repsNonOptionalBinding: Binding<Int> {
        Binding(
            get: { set.targetReps ?? 10 },
            set: { newValue in
                set.targetReps = newValue
                exerciseManager.updateSet(set) { _ in }
            }
        )
    }

    private var weightNonOptionalBinding: Binding<Double> {
        Binding(
            get: {
                let storedLbs = set.weight ?? 0
                return useMetricUnits ? lbsToKg(storedLbs) : storedLbs
            },
            set: { newValue in
                let valueToStoreLbs = useMetricUnits ? kgToLbs(newValue) : newValue
                set.weight = valueToStoreLbs
                exerciseManager.updateSet(set) { _ in }
            }
        )
    }

    private var durationMinutesBinding: Binding<Int> {
        Binding(
            get: { Int((set.targetDuration ?? 60) / 60) },
            set: { newValue in
                set.targetDuration = TimeInterval(newValue * 60)
                exerciseManager.updateSet(set) { _ in }
            }
        )
    }

    private var typeBinding: Binding<SetType> {
        Binding(
            get: { set.setType },
            set: { newType in
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
                exerciseManager.updateSet(set) { _ in }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Picker("Type", selection: typeBinding) {
                    ForEach(SetType.allCases) { type in
                        Text(type == .amap ? "AMAP" : type.rawValue.capitalized)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityLabel("Set type")
                .accessibilityHint("Choose between reps, as many as possible, timed, or freeform sets")

                Spacer()

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
                    }
                    .buttonStyle(.plain)
                    .hoverEffectIfAvailable(.highlight)
                    .accessibilityLabel("Delete set")
                    .accessibilityHint("Removes this set from the exercise")
                }
            }
            .padding(.vertical, 8)

            switch set.setType {
            case .reps, .amap:
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        HStack {
                            Spacer()
                            Text(set.setType == .amap ? "Reps Attempted" : "Reps")
                                .font(.body)
                                .foregroundStyle(.primary)
                            StepperControl(value: repsNonOptionalBinding, step: 1, display: "\(repsNonOptionalBinding.wrappedValue)", label: "Reps")
                        }
                        HStack {
                            Spacer()
                            Text("Weight (\(useMetricUnits ? "kg" : "lbs"))")
                                .font(.body)
                                .foregroundStyle(.primary)
                            StepperControlDouble(
                                value: weightNonOptionalBinding,
                                step: useMetricUnits ? 2.5 : 5.0,
                                display: trimTrailingZeros(weightNonOptionalBinding.wrappedValue),
                                label: "Weight",
                                unit: useMetricUnits ? "kilograms" : "pounds"
                            )
                        }
                        HStack {
                            Spacer()
                            Text("RPE")
                                .font(.body)
                                .foregroundStyle(.primary)
                            HStack(spacing: 6) {
                                Button(action: { rpeNonOptionalBinding.wrappedValue = max(0, rpeNonOptionalBinding.wrappedValue - 1) }) {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .font(.title)
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                                .hoverEffectIfAvailable(.highlight)
                                .accessibilityLabel("Decrease RPE")

                                Text("\(rpeNonOptionalBinding.wrappedValue)")
                                    .font(.title3.monospacedDigit())
                                    .foregroundStyle(.primary)
                                    .frame(minWidth: 36)
                                    .accessibilityHidden(true)

                                Button(action: { rpeNonOptionalBinding.wrappedValue = min(10, rpeNonOptionalBinding.wrappedValue + 1) }) {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .font(.title)
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                                .hoverEffectIfAvailable(.highlight)
                                .accessibilityLabel("Increase RPE")
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("RPE, \(rpeNonOptionalBinding.wrappedValue)")
                            .accessibilityValue("\(rpeNonOptionalBinding.wrappedValue)")
                            .accessibilityHint("Rate of perceived exertion, 0 to 10")
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Spacer()
                            Text(set.setType == .amap ? "Reps Attempted" : "Reps")
                                .font(.body)
                                .foregroundStyle(.primary)
                            StepperControl(value: repsNonOptionalBinding, step: 1, display: "\(repsNonOptionalBinding.wrappedValue)", label: "Reps")
                        }
                        HStack {
                            Spacer()
                            Text("Weight (\(useMetricUnits ? "kg" : "lbs"))")
                                .font(.body)
                                .foregroundStyle(.primary)
                            StepperControlDouble(
                                value: weightNonOptionalBinding,
                                step: useMetricUnits ? 2.5 : 5.0,
                                display: trimTrailingZeros(weightNonOptionalBinding.wrappedValue),
                                label: "Weight",
                                unit: useMetricUnits ? "kilograms" : "pounds"
                            )
                        }
                        HStack {
                            Spacer()
                            Text("RPE")
                                .font(.body)
                                .foregroundStyle(.primary)
                            HStack(spacing: 6) {
                                Button(action: { rpeNonOptionalBinding.wrappedValue = max(0, rpeNonOptionalBinding.wrappedValue - 1) }) {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .font(.title)
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                                .hoverEffectIfAvailable(.highlight)
                                .accessibilityLabel("Decrease RPE")

                                Text("\(rpeNonOptionalBinding.wrappedValue)")
                                    .font(.title3.monospacedDigit())
                                    .foregroundStyle(.primary)
                                    .frame(minWidth: 36)
                                    .accessibilityHidden(true)

                                Button(action: { rpeNonOptionalBinding.wrappedValue = min(10, rpeNonOptionalBinding.wrappedValue + 1) }) {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .font(.title)
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                                .hoverEffectIfAvailable(.highlight)
                                .accessibilityLabel("Increase RPE")
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("RPE, \(rpeNonOptionalBinding.wrappedValue)")
                            .accessibilityValue("\(rpeNonOptionalBinding.wrappedValue)")
                            .accessibilityHint("Rate of perceived exertion, 0 to 10")
                        }
                    }
                }
            case .duration:
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        HStack {
                            Spacer()
                            Text("Duration (min)")
                                .font(.body)
                                .foregroundStyle(.primary)
                            StepperControl(value: durationMinutesBinding, step: 1, display: "\(durationMinutesBinding.wrappedValue)", label: "Duration in minutes")
                        }
                        HStack {
                            Spacer()
                            Text("RPE")
                                .font(.body)
                                .foregroundStyle(.primary)
                            HStack(spacing: 6) {
                                Button(action: { rpeNonOptionalBinding.wrappedValue = max(0, rpeNonOptionalBinding.wrappedValue - 1) }) {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .font(.title)
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                                .hoverEffectIfAvailable(.highlight)
                                .accessibilityLabel("Decrease RPE")

                                Text("\(rpeNonOptionalBinding.wrappedValue)")
                                    .font(.title3.monospacedDigit())
                                    .foregroundStyle(.primary)
                                    .frame(minWidth: 36)
                                    .accessibilityHidden(true)

                                Button(action: { rpeNonOptionalBinding.wrappedValue = min(10, rpeNonOptionalBinding.wrappedValue + 1) }) {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .font(.title)
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                                .hoverEffectIfAvailable(.highlight)
                                .accessibilityLabel("Increase RPE")
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("RPE, \(rpeNonOptionalBinding.wrappedValue)")
                            .accessibilityValue("\(rpeNonOptionalBinding.wrappedValue)")
                            .accessibilityHint("Rate of perceived exertion, 0 to 10")
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Spacer()
                            Text("Duration (min)")
                                .font(.body)
                                .foregroundStyle(.primary)
                            StepperControl(value: durationMinutesBinding, step: 1, display: "\(durationMinutesBinding.wrappedValue)", label: "Duration in minutes")
                        }
                        HStack {
                            Spacer()
                            Text("RPE")
                                .font(.body)
                                .foregroundStyle(.primary)
                            HStack(spacing: 6) {
                                Button(action: { rpeNonOptionalBinding.wrappedValue = max(0, rpeNonOptionalBinding.wrappedValue - 1) }) {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .font(.title)
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                                .hoverEffectIfAvailable(.highlight)
                                .accessibilityLabel("Decrease RPE")

                                Text("\(rpeNonOptionalBinding.wrappedValue)")
                                    .font(.title3.monospacedDigit())
                                    .foregroundStyle(.primary)
                                    .frame(minWidth: 36)
                                    .accessibilityHidden(true)

                                Button(action: { rpeNonOptionalBinding.wrappedValue = min(10, rpeNonOptionalBinding.wrappedValue + 1) }) {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .font(.title)
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                                .hoverEffectIfAvailable(.highlight)
                                .accessibilityLabel("Increase RPE")
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("RPE, \(rpeNonOptionalBinding.wrappedValue)")
                            .accessibilityValue("\(rpeNonOptionalBinding.wrappedValue)")
                            .accessibilityHint("Rate of perceived exertion, 0 to 10")
                        }
                    }
                }
            case .freeform:
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        HStack {
                            Spacer()
                            Text("RPE")
                                .font(.body)
                                .foregroundStyle(.primary)
                            HStack(spacing: 6) {
                                Button(action: { rpeNonOptionalBinding.wrappedValue = max(0, rpeNonOptionalBinding.wrappedValue - 1) }) {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .font(.title)
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                                .hoverEffectIfAvailable(.highlight)
                                .accessibilityLabel("Decrease RPE")

                                Text("\(rpeNonOptionalBinding.wrappedValue)")
                                    .font(.title3.monospacedDigit())
                                    .foregroundStyle(.primary)
                                    .frame(minWidth: 36)
                                    .accessibilityHidden(true)

                                Button(action: { rpeNonOptionalBinding.wrappedValue = min(10, rpeNonOptionalBinding.wrappedValue + 1) }) {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .font(.title)
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                                .hoverEffectIfAvailable(.highlight)
                                .accessibilityLabel("Increase RPE")
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("RPE, \(rpeNonOptionalBinding.wrappedValue)")
                            .accessibilityValue("\(rpeNonOptionalBinding.wrappedValue)")
                            .accessibilityHint("Rate of perceived exertion, 0 to 10")
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Spacer()
                            Text("RPE")
                                .font(.body)
                                .foregroundStyle(.primary)
                            HStack(spacing: 6) {
                                Button(action: { rpeNonOptionalBinding.wrappedValue = max(0, rpeNonOptionalBinding.wrappedValue - 1) }) {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .font(.title)
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                                .hoverEffectIfAvailable(.highlight)
                                .accessibilityLabel("Decrease RPE")

                                Text("\(rpeNonOptionalBinding.wrappedValue)")
                                    .font(.title3.monospacedDigit())
                                    .foregroundStyle(.primary)
                                    .frame(minWidth: 36)
                                    .accessibilityHidden(true)

                                Button(action: { rpeNonOptionalBinding.wrappedValue = min(10, rpeNonOptionalBinding.wrappedValue + 1) }) {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .font(.title)
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                                .hoverEffectIfAvailable(.highlight)
                                .accessibilityLabel("Increase RPE")
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("RPE, \(rpeNonOptionalBinding.wrappedValue)")
                            .accessibilityValue("\(rpeNonOptionalBinding.wrappedValue)")
                            .accessibilityHint("Rate of perceived exertion, 0 to 10")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    private struct StepperControl: View {
        @Binding var value: Int
        let step: Int
        let display: String
        var label: String = "Value"

        var body: some View {
            HStack(spacing: 6) {
                Button(action: {
                    let updated = max(0, value - step)
                    if updated != value {
                        value = updated
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        #endif
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                }
                .font(.title)
                .foregroundStyle(.primary)
                .buttonStyle(.plain)
                .hoverEffectIfAvailable(.highlight)
                .accessibilityLabel("Decrease \(label)")
                .accessibilityHint("Decreases by \(step)")

                Text(display)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.primary)
                    .frame(minWidth: 36)
                    .accessibilityHidden(true)

                Button(action: {
                    let updated = max(0, value + step)
                    if updated != value {
                        value = updated
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        #endif
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                }
                .font(.title)
                .foregroundStyle(.primary)
                .buttonStyle(.plain)
                .hoverEffectIfAvailable(.highlight)
                .accessibilityLabel("Increase \(label)")
                .accessibilityHint("Increases by \(step)")
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(label), \(display)")
            .accessibilityValue(display)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    value = max(0, value + step)
                case .decrement:
                    value = max(0, value - step)
                @unknown default:
                    break
                }
            }
        }
    }

    private struct StepperControlDouble: View {
        @Binding var value: Double
        let step: Double
        let display: String
        var label: String = "Value"
        var unit: String = ""

        var body: some View {
            HStack(spacing: 6) {
                Button(action: {
                    let updated = max(0.0, value - step)
                    if updated != value {
                        value = updated
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        #endif
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                }
                .font(.title)
                .foregroundStyle(.primary)
                .buttonStyle(.plain)
                .hoverEffectIfAvailable(.highlight)
                .accessibilityLabel("Decrease \(label)")
                .accessibilityHint("Decreases by \(String(format: "%.1f", step))\(unit.isEmpty ? "" : " \(unit)")")

                Text(display)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.primary)
                    .frame(minWidth: 36)
                    .accessibilityHidden(true)

                Button(action: {
                    let updated = max(0.0, value + step)
                    if updated != value {
                        value = updated
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        #endif
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                }
                .font(.title)
                .foregroundStyle(.primary)
                .buttonStyle(.plain)
                .hoverEffectIfAvailable(.highlight)
                .accessibilityLabel("Increase \(label)")
                .accessibilityHint("Increases by \(String(format: "%.1f", step))\(unit.isEmpty ? "" : " \(unit)")")
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(label), \(display)\(unit.isEmpty ? "" : " \(unit)")")
            .accessibilityValue("\(display)\(unit.isEmpty ? "" : " \(unit)")")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    value = max(0.0, value + step)
                case .decrement:
                    value = max(0.0, value - step)
                @unknown default:
                    break
                }
            }
        }
    }
}

