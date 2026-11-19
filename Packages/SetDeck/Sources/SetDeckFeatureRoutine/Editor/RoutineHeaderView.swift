//
//  RoutineHeaderView.swift
//  SetDeckFeatureRoutine
//
//  The routine at a glance: day, focus, exercise/set/time/volume stats and the muscle
//  groups the day covers.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem

struct RoutineHeaderView: View {
    let day: Int
    let isToday: Bool
    let summary: RoutineSummary
    var useMetric: Bool = false

    private var title: String {
        String(localized: "\(EditorDay.name(day)) Routine")
    }

    private var subtitle: String {
        if summary.exerciseCount == 0 { return String(localized: "Rest day — add exercises to build a workout") }
        if let focus = summary.focus { return String(localized: "\(focus.title) focus") }
        return String(localized: "Ready to train")
    }

    private var accent: Color { summary.focus?.color ?? .greenStart }

    private var volumeText: String? {
        guard summary.volumeLbs > 0 else { return nil }
        let v = EditorFormat.displayWeight(summary.volumeLbs, metric: useMetric)
        let formatted = v >= 10_000 ? String(format: "%.1fk", v / 1000) : String(format: "%.0f", v)
        return "\(formatted) \(EditorFormat.unit(metric: useMetric))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Space.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title2.weight(.bold))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: Brand.Space.sm)
                if isToday {
                    Text("Today")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(.white)
                        .background(Capsule().fill(.brandGreen))
                }
            }

            HStack(spacing: Brand.Space.sm) {
                StatTile(value: "\(summary.exerciseCount)", label: "Exercises", icon: "dumbbell.fill", tint: accent)
                StatTile(value: "\(summary.setCount)", label: "Sets", icon: "square.stack.3d.up.fill", tint: accent)
                if summary.estimatedMinutes > 0 {
                    StatTile(value: "≈\(summary.estimatedMinutes)", label: "Minutes", icon: "clock.fill", tint: accent)
                }
                if let volumeText {
                    StatTile(value: volumeText, label: "Volume", icon: "scalemass.fill", tint: accent)
                }
            }
            .accessibilityElement(children: .combine)

            if !summary.muscleGroups.isEmpty {
                FlowLayout(spacing: Brand.Space.xs + 2, lineSpacing: Brand.Space.xs + 2) {
                    ForEach(summary.muscleGroups) { MuscleChip(group: $0) }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Muscles covered")
                .accessibilityValue(summary.muscleGroups.map(\.displayName).joined(separator: ", "))
            }
        }
        .padding(Brand.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                .fill(
                    LinearGradient(colors: [accent.opacity(0.28), accent.opacity(0.06)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .background(
                    RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous).fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                        .strokeBorder(accent.opacity(0.4), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: summary)
    }
}

private struct StatTile: View {
    let value: String
    let label: LocalizedStringKey
    let icon: String
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(tint)
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Brand.Space.sm)
        .background(RoundedRectangle(cornerRadius: Brand.Radius.chip, style: .continuous).fill(Color.white.opacity(0.07)))
    }
}
#endif
