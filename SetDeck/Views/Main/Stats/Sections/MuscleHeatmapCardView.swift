//
//  MuscleHeatmapCardView.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/9/26.
//

import SwiftUI

struct MuscleHeatmapCardView: View {
    let muscleVolumes: [MuscleGroup: Double]

    private var maxVolume: Double {
        muscleVolumes.values.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Muscle Heatmap", systemImage: "figure.stand")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("This week's training intensity by muscle group")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                // Front view
                VStack(spacing: 4) {
                    Text("Front")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    BodyFrontView(muscleVolumes: muscleVolumes, maxVolume: maxVolume)
                        .frame(width: 100, height: 200)
                }

                // Back view
                VStack(spacing: 4) {
                    Text("Back")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    BodyBackView(muscleVolumes: muscleVolumes, maxVolume: maxVolume)
                        .frame(width: 100, height: 200)
                }

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    Text("Intensity")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ForEach(legendItems, id: \.label) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
                            Text(item.label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Top trained muscles
                    if !topMuscles.isEmpty {
                        Text("Most Trained")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)

                        ForEach(topMuscles.prefix(3), id: \.0) { muscle, volume in
                            Text(muscle.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    private var legendItems: [(label: String, color: Color)] {
        [
            ("High", .red),
            ("Medium", .orange),
            ("Low", .yellow),
            ("None", Color.gray.opacity(0.3))
        ]
    }

    private var topMuscles: [(MuscleGroup, Double)] {
        muscleVolumes
            .filter { $0.key != .fullBody && $0.key != .cardio }
            .sorted { $0.value > $1.value }
    }
}

// MARK: - Body Front View
struct BodyFrontView: View {
    let muscleVolumes: [MuscleGroup: Double]
    let maxVolume: Double

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // Draw body outline
            drawBodyOutline(context: context, size: size)

            // Draw muscle regions with intensity colors
            // Chest
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.28, y: h * 0.18, width: w * 0.44, height: h * 0.12),
                muscle: .chest,
                cornerRadius: 8
            )

            // Shoulders (front delts)
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.15, y: h * 0.16, width: w * 0.12, height: h * 0.08),
                muscle: .shoulders,
                cornerRadius: 6
            )
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.73, y: h * 0.16, width: w * 0.12, height: h * 0.08),
                muscle: .shoulders,
                cornerRadius: 6
            )

            // Biceps
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.08, y: h * 0.26, width: w * 0.10, height: h * 0.12),
                muscle: .biceps,
                cornerRadius: 5
            )
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.82, y: h * 0.26, width: w * 0.10, height: h * 0.12),
                muscle: .biceps,
                cornerRadius: 5
            )

            // Forearms
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.05, y: h * 0.38, width: w * 0.08, height: h * 0.14),
                muscle: .forearms,
                cornerRadius: 4
            )
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.87, y: h * 0.38, width: w * 0.08, height: h * 0.14),
                muscle: .forearms,
                cornerRadius: 4
            )

            // Abs
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.35, y: h * 0.31, width: w * 0.30, height: h * 0.18),
                muscle: .abs,
                cornerRadius: 6
            )

            // Obliques
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.25, y: h * 0.34, width: w * 0.10, height: h * 0.12),
                muscle: .obliques,
                cornerRadius: 4
            )
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.65, y: h * 0.34, width: w * 0.10, height: h * 0.12),
                muscle: .obliques,
                cornerRadius: 4
            )

            // Quads
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.28, y: h * 0.52, width: w * 0.18, height: h * 0.22),
                muscle: .quads,
                cornerRadius: 8
            )
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.54, y: h * 0.52, width: w * 0.18, height: h * 0.22),
                muscle: .quads,
                cornerRadius: 8
            )

            // Calves (front)
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.30, y: h * 0.78, width: w * 0.14, height: h * 0.14),
                muscle: .calves,
                cornerRadius: 6
            )
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.56, y: h * 0.78, width: w * 0.14, height: h * 0.14),
                muscle: .calves,
                cornerRadius: 6
            )
        }
    }

    private func drawBodyOutline(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height

        var path = Path()

        // Head
        path.addEllipse(in: CGRect(x: w * 0.38, y: h * 0.02, width: w * 0.24, height: h * 0.10))

        // Neck
        path.addRect(CGRect(x: w * 0.43, y: h * 0.11, width: w * 0.14, height: h * 0.04))

        // Torso
        path.addRoundedRect(in: CGRect(x: w * 0.25, y: h * 0.15, width: w * 0.50, height: h * 0.35), cornerSize: CGSize(width: 10, height: 10))

        // Arms
        path.addRoundedRect(in: CGRect(x: w * 0.05, y: h * 0.18, width: w * 0.18, height: h * 0.36), cornerSize: CGSize(width: 8, height: 8))
        path.addRoundedRect(in: CGRect(x: w * 0.77, y: h * 0.18, width: w * 0.18, height: h * 0.36), cornerSize: CGSize(width: 8, height: 8))

        // Legs
        path.addRoundedRect(in: CGRect(x: w * 0.26, y: h * 0.50, width: w * 0.22, height: h * 0.46), cornerSize: CGSize(width: 10, height: 10))
        path.addRoundedRect(in: CGRect(x: w * 0.52, y: h * 0.50, width: w * 0.22, height: h * 0.46), cornerSize: CGSize(width: 10, height: 10))

        context.stroke(path, with: .color(.gray.opacity(0.4)), lineWidth: 1)
    }

    private func drawMuscleRegion(context: GraphicsContext, rect: CGRect, muscle: MuscleGroup, cornerRadius: CGFloat) {
        let intensity = intensityFor(muscle)
        let color = colorFor(intensity: intensity)

        let path = RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
        context.fill(path, with: .color(color))
    }

    private func intensityFor(_ muscle: MuscleGroup) -> Double {
        guard maxVolume > 0 else { return 0 }
        return (muscleVolumes[muscle] ?? 0) / maxVolume
    }

    private func colorFor(intensity: Double) -> Color {
        if intensity < 0.01 { return Color.gray.opacity(0.2) }
        if intensity < 0.33 { return Color.yellow.opacity(0.6) }
        if intensity < 0.66 { return Color.orange.opacity(0.7) }
        return Color.red.opacity(0.8)
    }
}

// MARK: - Body Back View
struct BodyBackView: View {
    let muscleVolumes: [MuscleGroup: Double]
    let maxVolume: Double

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // Draw body outline
            drawBodyOutline(context: context, size: size)

            // Traps
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.32, y: h * 0.12, width: w * 0.36, height: h * 0.08),
                muscle: .traps,
                cornerRadius: 6
            )

            // Back (upper)
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.28, y: h * 0.20, width: w * 0.44, height: h * 0.14),
                muscle: .back,
                cornerRadius: 8
            )

            // Lats
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.24, y: h * 0.28, width: w * 0.14, height: h * 0.14),
                muscle: .lats,
                cornerRadius: 6
            )
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.62, y: h * 0.28, width: w * 0.14, height: h * 0.14),
                muscle: .lats,
                cornerRadius: 6
            )

            // Lower back
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.35, y: h * 0.38, width: w * 0.30, height: h * 0.10),
                muscle: .lowerBack,
                cornerRadius: 6
            )

            // Rear delts
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.15, y: h * 0.16, width: w * 0.12, height: h * 0.08),
                muscle: .shoulders,
                cornerRadius: 6
            )
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.73, y: h * 0.16, width: w * 0.12, height: h * 0.08),
                muscle: .shoulders,
                cornerRadius: 6
            )

            // Triceps
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.08, y: h * 0.26, width: w * 0.10, height: h * 0.12),
                muscle: .triceps,
                cornerRadius: 5
            )
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.82, y: h * 0.26, width: w * 0.10, height: h * 0.12),
                muscle: .triceps,
                cornerRadius: 5
            )

            // Glutes
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.28, y: h * 0.48, width: w * 0.20, height: h * 0.10),
                muscle: .glutes,
                cornerRadius: 8
            )
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.52, y: h * 0.48, width: w * 0.20, height: h * 0.10),
                muscle: .glutes,
                cornerRadius: 8
            )

            // Hamstrings
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.28, y: h * 0.58, width: w * 0.18, height: h * 0.18),
                muscle: .hamstrings,
                cornerRadius: 8
            )
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.54, y: h * 0.58, width: w * 0.18, height: h * 0.18),
                muscle: .hamstrings,
                cornerRadius: 8
            )

            // Calves (back)
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.30, y: h * 0.78, width: w * 0.14, height: h * 0.14),
                muscle: .calves,
                cornerRadius: 6
            )
            drawMuscleRegion(
                context: context,
                rect: CGRect(x: w * 0.56, y: h * 0.78, width: w * 0.14, height: h * 0.14),
                muscle: .calves,
                cornerRadius: 6
            )
        }
    }

    private func drawBodyOutline(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height

        var path = Path()

        // Head
        path.addEllipse(in: CGRect(x: w * 0.38, y: h * 0.02, width: w * 0.24, height: h * 0.10))

        // Neck
        path.addRect(CGRect(x: w * 0.43, y: h * 0.11, width: w * 0.14, height: h * 0.04))

        // Torso
        path.addRoundedRect(in: CGRect(x: w * 0.25, y: h * 0.15, width: w * 0.50, height: h * 0.35), cornerSize: CGSize(width: 10, height: 10))

        // Arms
        path.addRoundedRect(in: CGRect(x: w * 0.05, y: h * 0.18, width: w * 0.18, height: h * 0.36), cornerSize: CGSize(width: 8, height: 8))
        path.addRoundedRect(in: CGRect(x: w * 0.77, y: h * 0.18, width: w * 0.18, height: h * 0.36), cornerSize: CGSize(width: 8, height: 8))

        // Legs
        path.addRoundedRect(in: CGRect(x: w * 0.26, y: h * 0.50, width: w * 0.22, height: h * 0.46), cornerSize: CGSize(width: 10, height: 10))
        path.addRoundedRect(in: CGRect(x: w * 0.52, y: h * 0.50, width: w * 0.22, height: h * 0.46), cornerSize: CGSize(width: 10, height: 10))

        context.stroke(path, with: .color(.gray.opacity(0.4)), lineWidth: 1)
    }

    private func drawMuscleRegion(context: GraphicsContext, rect: CGRect, muscle: MuscleGroup, cornerRadius: CGFloat) {
        let intensity = intensityFor(muscle)
        let color = colorFor(intensity: intensity)

        let path = RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
        context.fill(path, with: .color(color))
    }

    private func intensityFor(_ muscle: MuscleGroup) -> Double {
        guard maxVolume > 0 else { return 0 }
        return (muscleVolumes[muscle] ?? 0) / maxVolume
    }

    private func colorFor(intensity: Double) -> Color {
        if intensity < 0.01 { return Color.gray.opacity(0.2) }
        if intensity < 0.33 { return Color.yellow.opacity(0.6) }
        if intensity < 0.66 { return Color.orange.opacity(0.7) }
        return Color.red.opacity(0.8)
    }
}

#Preview {
    MuscleHeatmapCardView(muscleVolumes: [
        .chest: 5000,
        .shoulders: 3000,
        .triceps: 2500,
        .back: 4500,
        .biceps: 2000,
        .quads: 6000,
        .hamstrings: 3500,
        .glutes: 2000,
        .calves: 1000,
        .abs: 500
    ])
    .padding()
    .preferredColorScheme(.dark)
}
