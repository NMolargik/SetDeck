//
//  BalanceAnalysisCardView.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/9/26.
//

import SwiftUI

struct BalanceAnalysisCardView: View {
    let muscleVolumes: [MuscleGroup: Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Balance Analysis", systemImage: "scale.3d")
                .font(.headline)
                .foregroundStyle(.primary)

            // Push vs Pull
            BalanceBarView(
                title: "Push vs Pull",
                leftLabel: "Push",
                rightLabel: "Pull",
                leftValue: pushVolume,
                rightValue: pullVolume,
                leftColor: .blue,
                rightColor: .green
            )

            // Upper vs Lower
            BalanceBarView(
                title: "Upper vs Lower",
                leftLabel: "Upper",
                rightLabel: "Lower",
                leftValue: upperVolume,
                rightValue: lowerVolume,
                leftColor: .purple,
                rightColor: .orange
            )

            // Anterior vs Posterior
            BalanceBarView(
                title: "Front vs Back",
                leftLabel: "Anterior",
                rightLabel: "Posterior",
                leftValue: anteriorVolume,
                rightValue: posteriorVolume,
                leftColor: .pink,
                rightColor: .cyan
            )

            // Suggestions
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    ForEach(suggestions, id: \.self) { suggestion in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text(suggestion)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Volume Calculations

    private var pushVolume: Double {
        [.chest, .shoulders, .triceps].reduce(0) { $0 + (muscleVolumes[$1] ?? 0) }
    }

    private var pullVolume: Double {
        [.back, .lats, .biceps, .forearms, .traps].reduce(0) { $0 + (muscleVolumes[$1] ?? 0) }
    }

    private var upperVolume: Double {
        [.chest, .shoulders, .triceps, .back, .lats, .biceps, .forearms, .traps].reduce(0) { $0 + (muscleVolumes[$1] ?? 0) }
    }

    private var lowerVolume: Double {
        [.quads, .hamstrings, .glutes, .calves].reduce(0) { $0 + (muscleVolumes[$1] ?? 0) }
    }

    private var anteriorVolume: Double {
        [.chest, .abs, .quads, .biceps, .shoulders].reduce(0) { $0 + (muscleVolumes[$1] ?? 0) }
    }

    private var posteriorVolume: Double {
        [.back, .lats, .hamstrings, .glutes, .calves, .traps, .lowerBack].reduce(0) { $0 + (muscleVolumes[$1] ?? 0) }
    }

    // MARK: - Suggestions

    private var suggestions: [String] {
        var result: [String] = []

        // Push/Pull imbalance
        let pushPullRatio = pushVolume > 0 && pullVolume > 0 ? pushVolume / pullVolume : 1
        if pushPullRatio > 1.5 {
            result.append("Your pushing volume is \(String(format: "%.1fx", pushPullRatio)) your pulling. Add more rows and pull-ups to balance.")
        } else if pushPullRatio < 0.67 {
            let inversePullPushRatio = pullVolume / pushVolume
            result.append("Your pulling volume is \(String(format: "%.1fx", inversePullPushRatio)) your pushing. Add more pressing movements.")
        }

        // Upper/Lower imbalance
        let upperLowerRatio = upperVolume > 0 && lowerVolume > 0 ? upperVolume / lowerVolume : 1
        if upperLowerRatio > 2.0 {
            result.append("Upper body focus detected (\(String(format: "%.1fx", upperLowerRatio)) ratio). Consider adding squats, lunges, or deadlifts.")
        } else if upperLowerRatio < 0.5 {
            let inverseLowerUpperRatio = lowerVolume / upperVolume
            result.append("Lower body focus detected (\(String(format: "%.1fx", inverseLowerUpperRatio)) ratio). Add some upper body work for balance.")
        }

        // Anterior/Posterior imbalance
        let anteriorPosteriorRatio = anteriorVolume > 0 && posteriorVolume > 0 ? anteriorVolume / posteriorVolume : 1
        if anteriorPosteriorRatio > 1.8 {
            result.append("Front-dominant training. Add posterior chain work like deadlifts, rows, and hip hinges.")
        } else if anteriorPosteriorRatio < 0.55 {
            result.append("Back-dominant training. Add more chest, quad, and ab work for balance.")
        }

        // Neglected muscle groups
        let neglectedMuscles = findNeglectedMuscles()
        if !neglectedMuscles.isEmpty {
            let muscleNames = neglectedMuscles.prefix(3).map { $0.displayName }.joined(separator: ", ")
            result.append("Potentially undertrained: \(muscleNames). Consider adding exercises targeting these areas.")
        }

        if result.isEmpty {
            result.append("Great balance! Your training is well-distributed across muscle groups.")
        }

        return result
    }

    private func findNeglectedMuscles() -> [MuscleGroup] {
        let importantMuscles: [MuscleGroup] = [.chest, .back, .shoulders, .quads, .hamstrings, .glutes]
        let totalVolume = muscleVolumes.values.reduce(0, +)
        guard totalVolume > 0 else { return [] }

        return importantMuscles.filter { muscle in
            let volume = muscleVolumes[muscle] ?? 0
            let percentage = volume / totalVolume
            return percentage < 0.05 // Less than 5% of total volume
        }
    }
}

// MARK: - Balance Bar View
struct BalanceBarView: View {
    let title: String
    let leftLabel: String
    let rightLabel: String
    let leftValue: Double
    let rightValue: Double
    let leftColor: Color
    let rightColor: Color

    private var total: Double {
        leftValue + rightValue
    }

    private var leftPercentage: Double {
        guard total > 0 else { return 0.5 }
        return leftValue / total
    }

    private var rightPercentage: Double {
        guard total > 0 else { return 0.5 }
        return rightValue / total
    }

    private var isBalanced: Bool {
        leftPercentage >= 0.4 && leftPercentage <= 0.6
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if total > 0 {
                    Text(isBalanced ? "Balanced" : "Imbalanced")
                        .font(.caption2)
                        .foregroundStyle(isBalanced ? .green : .orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill((isBalanced ? Color.green : Color.orange).opacity(0.2))
                        )
                }
            }

            if total > 0 {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(leftColor.gradient)
                            .frame(width: max(geo.size.width * leftPercentage - 1, 0))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(rightColor.gradient)
                            .frame(width: max(geo.size.width * rightPercentage - 1, 0))
                    }
                }
                .frame(height: 12)

                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(leftColor)
                            .frame(width: 8, height: 8)
                        Text("\(leftLabel) \(Int(leftPercentage * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("\(rightLabel) \(Int(rightPercentage * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Circle()
                            .fill(rightColor)
                            .frame(width: 8, height: 8)
                    }
                }
            } else {
                Text("No data yet")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    BalanceAnalysisCardView(muscleVolumes: [
        .chest: 5000,
        .shoulders: 3000,
        .triceps: 2500,
        .back: 2000,
        .biceps: 1500,
        .quads: 6000,
        .hamstrings: 2000,
        .glutes: 1500,
        .calves: 500
    ])
    .padding()
    .preferredColorScheme(.dark)
}
