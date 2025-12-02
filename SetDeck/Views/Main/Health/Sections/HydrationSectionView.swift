//
//  HydrationSectionView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI
import Charts

struct HydrationSectionView: View {
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false

    @Binding var newWaterIntakeOZ: Double
    @Binding var isExpanded: Bool
    @Binding var didAddWater: Bool

    private var waterUnitLabel: String { useMetricUnits ? "L" : "fl oz" }
    private var waterDisplayMax: Double { useMetricUnits ? 4.0 : 200 }
    private var waterStep: Double { useMetricUnits ? 0.1 : 4 }
    private var waterInputBinding: Binding<Double> {
        Binding(
            get: {
                useMetricUnits ? (newWaterIntakeOZ * 29.5735) / 1000.0 : newWaterIntakeOZ
            },
            set: { newValue in
                if useMetricUnits {
                    newWaterIntakeOZ = (newValue * 1000.0) / 29.5735
                } else {
                    newWaterIntakeOZ = newValue
                }
            }
        )
    }
    private func axisDateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = .current
        // Always omit the year for compact axis labels
        if useDayMonthYearDates {
            df.dateFormat = "dd/MM" // previously dd/MM/yyyy
        } else {
            df.setLocalizedDateFormatFromTemplate("Md") // e.g., 11/29 or 29/11 depending on locale
        }
        return df.string(from: date)
    }

    private struct SeriesItem: Identifiable { let id = UUID(); let date: Date; let amount: Double }

    private func last7Days(_ data: [SeriesItem]) -> [SeriesItem] {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date())) else { return data }
        return data.filter { cal.startOfDay(for: $0.date) >= start }.sorted { $0.date < $1.date }
    }

    private func waterSeries() -> [SeriesItem] {
        let samples = healthManager.waterIntakeSeries
        if !samples.isEmpty { return samples.map { SeriesItem(date: $0.date, amount: $0.amount) } }
        // Demo fallback
        return (0..<14).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let base = 1800.0; let variance = 400.0
            let jitter = Double.random(in: -variance...variance)
            return SeriesItem(date: date, amount: max(0, base + jitter))
        }.sorted { $0.date < $1.date }
    }

    private var waterData: [SeriesItem] { last7Days(waterSeries()) }

    private var waterChart: some View {
        Chart(waterData) { item in
            BarMark(
                x: .value("Date", item.date, unit: .day),
                y: .value(waterUnitLabel, useMetricUnits ? item.amount / 1000.0 : item.amount / 29.5735)
            )
            .foregroundStyle(Gradient(colors: [.blueStart.opacity(0.7), .cyan]))
            .annotation(position: .top) {
                if Calendar.current.isDateInToday(item.date) {
                    Text("\(useMetricUnits ? String(format: "%.1f", item.amount / 1000.0) : String(Int(item.amount / 29.5735))) \(waterUnitLabel)")
                        .font(.caption2).bold()
                }
            }
        }
        .frame(height: 160)
        .chartYAxisLabel(waterUnitLabel, position: .leading)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine(); AxisTick(); AxisValueLabel {
                    if let date = value.as(Date.self) { Text(axisDateString(date)) }
                }
            }
        }
        .chartYAxis { AxisMarks(position: .leading) { _ in AxisGridLine(); AxisTick(); AxisValueLabel() } }
        .chartPlotStyle { $0.background(LinearGradient(colors: [Color.blueEnd.opacity(0.25), Color.cyan.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)) }
        .chartForegroundStyleScale([waterUnitLabel: .blueStart])
        .chartLegend(.hidden)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Water Intake", systemImage: "drop.fill").font(.headline).foregroundStyle(.blueStart)
                        Spacer()
                        Text("\(Int(waterInputBinding.wrappedValue)) \(waterUnitLabel)")
                            .monospacedDigit().foregroundStyle(.blueStart)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: waterInputBinding.wrappedValue)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Slider(value: waterInputBinding, in: 0...waterDisplayMax, step: waterStep)
                            .tint(.blueStart)
                            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: waterInputBinding.wrappedValue)
                            .sensoryFeedback(
                                .selection,
                                trigger: Int((waterInputBinding.wrappedValue / waterStep).rounded())
                            )
                        HStack {
                            Stepper("Amount", value: waterInputBinding, in: 0...waterDisplayMax, step: waterStep)
                                .labelsHidden()
                                .foregroundStyle(.blueStart)
                                .controlSize(.regular)
                                .sensoryFeedback(
                                    .selection,
                                    trigger: Int((waterInputBinding.wrappedValue / waterStep).rounded())
                                )
                            Spacer()
                            Button {
                                let ml = useMetricUnits ? (waterInputBinding.wrappedValue * 1000.0) : waterInputBinding.wrappedValue * 29.5735
                                Task {
                                    await healthManager.addWaterIntakeIfSupported(amountML: ml, date: Date())
                                    await MainActor.run {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { newWaterIntakeOZ = 0; didAddWater = true }
                                    }
                                    try? await Task.sleep(nanoseconds: 800_000_000)
                                    await MainActor.run { withAnimation(.easeOut(duration: 0.3)) { didAddWater = false } }
                                }
                            } label: {
                                Label("Add Water", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .symbolEffect(.bounce, value: didAddWater)
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                            .tint(.blueStart)
                            .disabled(waterInputBinding.wrappedValue == 0)
                        }
                    }
                    waterChart
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8)
                )
                .padding(.top, 8)
            } label: { Text("Hydration").font(.title2.bold()) }
            .foregroundStyle(.blueStart)
        }
    }
}

#Preview {
    HydrationSectionPreview()
        .environment(HealthManager())
        .preferredColorScheme(.dark)
}

private struct HydrationSectionPreview: View {
    @State private var waterOZ: Double = 16
    @State private var expanded: Bool = true
    @State private var didAdd: Bool = false

    var body: some View {
        HydrationSectionView(
            newWaterIntakeOZ: $waterOZ,
            isExpanded: $expanded,
            didAddWater: $didAdd
        )
        .padding()
    }
}
