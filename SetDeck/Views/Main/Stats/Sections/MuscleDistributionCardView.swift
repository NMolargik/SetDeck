//
//  MuscleDistributionCardView.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/9/26.
//

import SwiftUI
import Charts

struct MuscleDistributionCardView: View {
    let muscleVolumes: [MuscleGroup: Double]

    @State private var selectedSlice: MuscleGroup?

    private var chartData: [MuscleChartData] {
        muscleVolumes
            .filter { $0.value > 0 && $0.key != .fullBody && $0.key != .cardio }
            .map { MuscleChartData(muscle: $0.key, volume: $0.value) }
            .sorted { $0.volume > $1.volume }
    }

    private var totalVolume: Double {
        chartData.reduce(0) { $0 + $1.volume }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Muscle Distribution", systemImage: "chart.pie.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Weekly volume breakdown by muscle group")
                .font(.caption)
                .foregroundStyle(.secondary)

            if chartData.isEmpty {
                Text("No muscle group data available")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                HStack(alignment: .top, spacing: 16) {
                    // Pie Chart
                    Chart(chartData) { data in
                        SectorMark(
                            angle: .value("Volume", data.volume),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(colorFor(data.muscle))
                        .cornerRadius(4)
                        .opacity(selectedSlice == nil || selectedSlice == data.muscle ? 1 : 0.5)
                    }
                    .chartLegend(.hidden)
                    .chartBackground { chartProxy in
                        GeometryReader { geo in
                            if let plotFrame = chartProxy.plotFrame {
                                let frame = geo[plotFrame]
                                VStack(spacing: 2) {
                                    if let selected = selectedSlice {
                                        Text(selected.displayName)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Text(formatVolume(muscleVolumes[selected] ?? 0))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Total")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Text(formatVolume(totalVolume))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .position(x: frame.midX, y: frame.midY)
                            }
                        }
                    }
                    .frame(width: 140, height: 140)

                    // Legend
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(chartData.prefix(8)) { data in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedSlice == data.muscle {
                                        selectedSlice = nil
                                    } else {
                                        selectedSlice = data.muscle
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(colorFor(data.muscle))
                                        .frame(width: 12, height: 12)

                                    Text(data.muscle.displayName)
                                        .font(.caption)
                                        .foregroundStyle(selectedSlice == nil || selectedSlice == data.muscle ? .primary : .secondary)

                                    Spacer()

                                    Text("\(Int(data.percentage(of: totalVolume)))%")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        if chartData.count > 8 {
                            Text("+\(chartData.count - 8) more")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    private func colorFor(_ muscle: MuscleGroup) -> Color {
        switch muscle {
        case .chest: return .red
        case .shoulders: return .orange
        case .triceps: return .yellow
        case .back: return .green
        case .lats: return .mint
        case .traps: return .teal
        case .biceps: return .cyan
        case .forearms: return .blue
        case .quads: return .indigo
        case .hamstrings: return .purple
        case .glutes: return .pink
        case .calves: return .brown
        case .abs: return Color(red: 1, green: 0.5, blue: 0.5)
        case .obliques: return Color(red: 1, green: 0.7, blue: 0.5)
        case .lowerBack: return Color(red: 0.5, green: 0.8, blue: 0.5)
        case .neck: return .gray
        case .serratus: return Color(red: 0.8, green: 0.5, blue: 0.8)
        case .rotatorCuff: return Color(red: 0.5, green: 0.5, blue: 0.8)
        case .fullBody: return .white
        case .cardio: return .red.opacity(0.7)
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk lbs", volume / 1000)
        }
        return "\(Int(volume)) lbs"
    }
}

// MARK: - Chart Data Model
struct MuscleChartData: Identifiable {
    let muscle: MuscleGroup
    let volume: Double

    var id: String { muscle.rawValue }

    func percentage(of total: Double) -> Double {
        guard total > 0 else { return 0 }
        return (volume / total) * 100
    }
}

#Preview {
    MuscleDistributionCardView(muscleVolumes: [
        .chest: 5000,
        .shoulders: 3000,
        .triceps: 2500,
        .back: 4500,
        .biceps: 2000,
        .lats: 1500,
        .quads: 6000,
        .hamstrings: 3500,
        .glutes: 2000,
        .calves: 1000,
        .abs: 800
    ])
    .padding()
    .preferredColorScheme(.dark)
}
