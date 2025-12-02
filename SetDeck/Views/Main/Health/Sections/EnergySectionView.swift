//
//  EnergySectionView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI
import Charts

struct EnergySectionView: View {
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false

    @Binding var newCalorieIntake: Double
    @Binding var isExpanded: Bool
    @Binding var didAddFood: Bool

    private let energyUnitLabel: String = "cal"
    private let energyDisplayMax: Double = 5000
    private let energyStep: Double = 50
    private var energyInputBinding: Binding<Double> { Binding(get: { newCalorieIntake }, set: { newCalorieIntake = $0 }) }
    private func axisDateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = .current
        if useDayMonthYearDates {
            df.dateFormat = "dd/MM" // omit year
        } else {
            df.setLocalizedDateFormatFromTemplate("Md") // locale-aware month/day without year
        }
        return df.string(from: date)
    }

    private struct SeriesItem: Identifiable { let id = UUID(); let date: Date; let amount: Double }

    private func last7Days(_ data: [SeriesItem]) -> [SeriesItem] {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date())) else { return data }
        return data.filter { cal.startOfDay(for: $0.date) >= start }.sorted { $0.date < $1.date }
    }

    private func calorieIntakeSeries() -> [SeriesItem] {
        let samples = healthManager.calorieIntakeSeries
        if !samples.isEmpty { return samples.map { SeriesItem(date: $0.date, amount: $0.amount) } }
        return (0..<14).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let base = 2200.0; let variance = 500.0
            let jitter = Double.random(in: -variance...variance)
            return SeriesItem(date: date, amount: max(0, base + jitter))
        }.sorted { $0.date < $1.date }
    }

    private func calorieBurnSeries() -> [SeriesItem] {
        let samples = healthManager.calorieBurnSeries
        if !samples.isEmpty { return samples.map { SeriesItem(date: $0.date, amount: $0.amount) } }
        return (0..<14).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let base = 2000.0; let variance = 400.0
            let jitter = Double.random(in: -variance...variance)
            return SeriesItem(date: date, amount: max(0, base + jitter))
        }.sorted { $0.date < $1.date }
    }

    private var intakeData: [SeriesItem] { last7Days(calorieIntakeSeries()) }
    private var burnData: [SeriesItem] { last7Days(calorieBurnSeries()) }

    @ChartContentBuilder
    private func intakeLine(_ data: [SeriesItem]) -> some ChartContent {
        ForEach(data) { item in
            LineMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Intake", item.amount)
            )
            .interpolationMethod(.linear)
            .symbol(Circle()).symbolSize(40)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .foregroundStyle(LinearGradient(colors: [.orangeStart, .orangeEnd], startPoint: .leading, endPoint: .trailing))
            .zIndex(1)
            .annotation(position: .top) {
                if Calendar.current.isDateInToday(item.date) {
                    Text("\(Int(item.amount)) \(energyUnitLabel)").font(.caption2).bold()
                }
            }
        }
    }

    @ChartContentBuilder
    private func intakeArea(_ data: [SeriesItem]) -> some ChartContent {
        ForEach(data) { item in
            AreaMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Intake", item.amount)
            )
            .interpolationMethod(.linear)
            .foregroundStyle(LinearGradient(colors: [.orangeStart.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
        }
    }

    @ChartContentBuilder
    private func burnLine(_ data: [SeriesItem]) -> some ChartContent {
        ForEach(data) { item in
            LineMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Burn", item.amount)
            )
            .interpolationMethod(.linear)
            .symbol(.square).symbolSize(40)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .foregroundStyle(LinearGradient(colors: [.red, .orangeStart], startPoint: .leading, endPoint: .trailing))
            .annotation(position: .top) {
                if Calendar.current.isDateInToday(item.date) {
                    Text("\(Int(item.amount)) \(energyUnitLabel)").font(.caption2).bold()
                }
            }
        }
    }

    @ChartContentBuilder
    private func burnArea(_ data: [SeriesItem]) -> some ChartContent {
        ForEach(data) { item in
            AreaMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Burn", item.amount)
            )
            .interpolationMethod(.linear)
            .foregroundStyle(LinearGradient(colors: [.red.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
        }
    }

    private var caloriesConsumedChart: some View {
        let intake = intakeData
        return Chart { intakeArea(intake); intakeLine(intake) }
            .frame(height: 200)
            .chartYAxisLabel(energyUnitLabel, position: .leading)
            .chartXAxisLabel("Date")
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine(); AxisTick(); AxisValueLabel { if let date = value.as(Date.self) { Text(axisDateString(date)) } }
                }
            }
            .chartYAxis { AxisMarks(position: .leading) { _ in AxisGridLine(); AxisTick(); AxisValueLabel() } }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartPlotStyle { $0.background(LinearGradient(colors: [Color.orangeStart.opacity(0.25), Color.orangeEnd.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)) }
    }

    private var caloriesBurnedChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Calories Burned", systemImage: "flame.fill").font(.headline).foregroundStyle(.red)
            let burn = burnData
            Chart { burnLine(burn); burnArea(burn) }
                .frame(height: 200)
                .chartYAxisLabel(energyUnitLabel, position: .leading)
                .chartXAxisLabel("Date")
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine(); AxisTick(); AxisValueLabel { if let date = value.as(Date.self) { Text(axisDateString(date)) } }
                    }
                }
                .chartYAxis { AxisMarks(position: .leading) { _ in AxisGridLine(); AxisTick(); AxisValueLabel() } }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartPlotStyle { $0.background(LinearGradient(colors: [Color.red.opacity(0.25), Color.red.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Calories Consumed", systemImage: "fork.knife").font(.headline).foregroundStyle(.orangeStart)
                        Spacer()
                        Text("\(Int(energyInputBinding.wrappedValue)) \(energyUnitLabel)")
                            .monospacedDigit().foregroundStyle(.orangeStart)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: energyInputBinding.wrappedValue)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Slider(value: energyInputBinding, in: 0...energyDisplayMax, step: energyStep)
                            .tint(.orangeStart)
                            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: energyInputBinding.wrappedValue)
                            .sensoryFeedback(
                                .selection,
                                trigger: Int((energyInputBinding.wrappedValue / energyStep).rounded())
                            )
                        HStack {
                            Stepper("Amount", value: energyInputBinding, in: 0...energyDisplayMax, step: energyStep)
                                .labelsHidden()
                                .foregroundStyle(.orangeStart)
                                .controlSize(.regular)
                                .sensoryFeedback(
                                    .selection,
                                    trigger: Int((energyInputBinding.wrappedValue / energyStep).rounded())
                                )
                            Spacer()
                            Button {
                                Task {
                                    let kcal = energyInputBinding.wrappedValue
                                    await healthManager.addCalorieIntakeIfSupported(amount: kcal, date: Date())
                                    await MainActor.run { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { didAddFood = true; newCalorieIntake = 0 } }
                                    try? await Task.sleep(nanoseconds: 800_000_000)
                                    await MainActor.run { withAnimation(.easeOut(duration: 0.3)) { didAddFood = false } }
                                }
                            } label: {
                                Label("Add Food", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .symbolEffect(.bounce, value: didAddFood)
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                            .tint(.orangeStart)
                            .disabled(energyInputBinding.wrappedValue == 0)
                        }
                    }
                    caloriesConsumedChart
                    caloriesBurnedChart
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8)
                )
                .padding(.top, 8)
            } label: { Text("Energy").font(.title2.bold()) }
            .foregroundStyle(.orangeStart)
        }
    }
}
#Preview {
    EnergySectionPreview()
        .environment(HealthManager())
        .preferredColorScheme(.dark)
}

private struct EnergySectionPreview: View {
    @State private var calorieIntakeKCal: Double = 600
    @State private var expanded: Bool = true
    @State private var didAdd: Bool = false

    var body: some View {
        EnergySectionView(
            newCalorieIntake: $calorieIntakeKCal,
            isExpanded: $expanded,
            didAddFood: $didAdd
        )
        .padding()
    }
}

