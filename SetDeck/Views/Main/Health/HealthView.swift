//
//  HealthView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI
import Charts

struct HealthView: View {
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
    
    @AppStorage(AppStorageKeys.useMetricUnits, store: UserDefaults(suiteName: "group.nickmolargik.ReadySet")) private var useMetricUnits: Bool = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false
    
    // MARK: - Local input state
    @State private var newWaterIntakeOZ: Double = 8 // fluid ounces
    @State private var newCalorieIntake: Double = 300 // kcal (Calories)
    @State private var newCalorieBurn: Double = 200 // kcal

    @State private var isWaterExpanded: Bool = true
    @State private var isCaloriesExpanded: Bool = true

    @State private var didAddWater: Bool = false
    @State private var didAddFood: Bool = false

    // MARK: - Workout state
    @State private var workoutTimer: Timer? = nil
    @State private var now: Date = Date()
    @State private var isPulsing: Bool = false

    private var isStrengthWorkoutActive: Bool {
        healthManager.isStrengthTrainingActive
    }

    private var workoutStartDate: Date? {
        healthManager.currentWorkoutStartDate
    }

    private var workoutElapsedString: String {
        guard let start = workoutStartDate else { return "00:00:00" }
        let interval = Int(now.timeIntervalSince(start))
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Unit & Date helpers
    private var waterUnitLabel: String { useMetricUnits ? "mL" : "fl oz" }
    private var waterDisplayMax: Double { useMetricUnits ? 4000 : 200 }
    private var waterStep: Double { useMetricUnits ? 100 : 4 }
    private var waterInputBinding: Binding<Double> {
        Binding(
            get: { useMetricUnits ? newWaterIntakeOZ * 29.5735 : newWaterIntakeOZ },
            set: { newValue in
                if useMetricUnits {
                    newWaterIntakeOZ = newValue / 29.5735
                } else {
                    newWaterIntakeOZ = newValue
                }
            }
        )
    }
    private func axisDateString(_ date: Date) -> String {
        if useDayMonthYearDates {
            let df = DateFormatter()
            df.locale = .current
            df.dateFormat = "dd/MM/yyyy"
            return df.string(from: date)
        } else {
            return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
        }
    }

    private var energyUnitLabel: String { useMetricUnits ? "kJ" : "kcal" }
    private var energyDisplayMax: Double { useMetricUnits ? 20000 : 5000 }
    private var energyStep: Double { useMetricUnits ? 100 : 50 }
    private var energyInputBinding: Binding<Double> {
        Binding(
            get: { useMetricUnits ? newCalorieIntake * 4.184 : newCalorieIntake },
            set: { newValue in
                if useMetricUnits {
                    newCalorieIntake = newValue / 4.184
                } else {
                    newCalorieIntake = newValue
                }
            }
        )
    }
    
    private var isRegularWidth: Bool {
        hSizeClass == .regular
    }

    // MARK: - Body
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Active Workout Section
                if (!isRegularWidth) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .foregroundStyle(.primary)
                                .scaleEffect(isStrengthWorkoutActive && isPulsing ? 1.15 : 1.0)
                                .animation(
                                    isStrengthWorkoutActive && isPulsing
                                    ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                                    : .easeOut(duration: 0.2),
                                    value: isPulsing
                                )
                                .onChange(of: isStrengthWorkoutActive) { _, active in
                                    if active {
                                        // Kick off pulsing when workout becomes active
                                        isPulsing = true
                                    } else {
                                        // Immediately stop pulsing when workout ends/pauses
                                        isPulsing = false
                                    }
                                }
                            if (isStrengthWorkoutActive) {
                                Text(workoutElapsedString)
                                    .monospacedDigit()
                                    .font(.subheadline).bold()
                                    .foregroundStyle(.greenEnd)
                            } else {
                                Text("Record Workout")
                                    .font(.headline)
                            }
                            Spacer()
                            if isStrengthWorkoutActive {
                                Button(role: .destructive) {
                                    Task { await healthManager.stopStrengthTrainingWorkoutIfSupported() }
                                } label: {
                                    Label("Stop", systemImage: "stop.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            } else {
                                if isStrengthWorkoutActive {
                                    
                                } else {
                                    Button {
                                        Task { await healthManager.startStrengthTrainingWorkoutIfSupported() }
                                    } label: {
                                        Label("Start", systemImage: "play.fill")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.greenEnd)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }

                HydrationSectionView(newWaterIntakeOZ: $newWaterIntakeOZ, isExpanded: $isWaterExpanded, didAddWater: $didAddWater)
                EnergySectionView(newCalorieIntake: $newCalorieIntake, isExpanded: $isCaloriesExpanded, didAddFood: $didAddFood)
                WorkoutHistorySectionView()
            }
            .padding()
        }
        .task {
            await refreshHealthData()
        }
        .onAppear {
            // Start a periodic timer to update elapsed display
            workoutTimer?.invalidate()
            workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                now = Date()
            }
            isPulsing = isStrengthWorkoutActive
        }
        .onDisappear {
            workoutTimer?.invalidate()
            workoutTimer = nil
            isPulsing = false
        }
    }
    
    private var waterData: [SeriesItem] { last7Days(waterSeries()) }
    private var intakeData: [SeriesItem] { last7Days(calorieIntakeSeries()) }
    private var burnData: [SeriesItem] { last7Days(calorieBurnSeries()) }
    
    private func last7Days(_ data: [SeriesItem]) -> [SeriesItem] {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date())) else { return data }
        return data.filter { item in
            let day = cal.startOfDay(for: item.date)
            return day >= start
        }
        .sorted { $0.date < $1.date }
    }

    private var waterChart: some View {
        Chart(waterData) { item in
            BarMark(
                x: .value("Date", item.date, unit: .day),
                y: .value(waterUnitLabel, useMetricUnits ? item.amount : item.amount / 29.5735)
            )
            .foregroundStyle(Gradient(colors: [.blueStart.opacity(0.7), .cyan]))
            .annotation(position: .top) {
                if Calendar.current.isDateInToday(item.date) {
                    Text("\(Int(useMetricUnits ? item.amount : item.amount / 29.5735)) \(waterUnitLabel)")
                        .font(.caption2).bold()
                }
            }
        }
        .frame(height: 160)
        .chartYAxisLabel(waterUnitLabel, position: .leading)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(axisDateString(date))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    LinearGradient(
                        colors: [Color.blueStart.opacity(0.25), Color.cyan.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .chartForegroundStyleScale([waterUnitLabel: .blueStart])
        .chartLegend(.hidden)
    }

    private var caloriesConsumedChart: some View {
        let intake: [SeriesItem] = self.intakeData

        return Chart {
            intakeArea(intake)
            intakeLine(intake)
        }
        .frame(height: 200)
        .chartYAxisLabel(energyUnitLabel, position: .leading)
        .chartXAxisLabel("Date")
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(axisDateString(date))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    LinearGradient(
                        colors: [Color.orangeStart.opacity(0.25), Color.orangeEnd.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var caloriesBurnedChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(useMetricUnits ? "Energy Burned" : "Calories Burned", systemImage: "flame.fill")
                .font(.headline)
                .foregroundStyle(.red)

            let burn: [SeriesItem] = self.burnData

            Chart {
                burnLine(burn)
                burnArea(burn)
            }
            .frame(height: 200)
            .chartYAxisLabel(energyUnitLabel, position: .leading)
            .chartXAxisLabel("Date")
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(axisDateString(date))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartPlotStyle { plotArea in
                plotArea
                    .background(
                        LinearGradient(
                            colors: [Color.red.opacity(0.25), Color.red.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
    
    @ChartContentBuilder
    private func intakeLine(_ data: [SeriesItem]) -> some ChartContent {
        ForEach(data) { item in
            LineMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Intake", useMetricUnits ? item.amount * 4.184 : item.amount)
            )
            .interpolationMethod(.linear)
            .symbol(Circle())
            .symbolSize(40)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .foregroundStyle(LinearGradient(colors: [.orangeStart, .orangeEnd], startPoint: .leading, endPoint: .trailing))
            .zIndex(1)
            .annotation(position: .top) {
                if Calendar.current.isDateInToday(item.date) {
                    Text("\(Int(useMetricUnits ? item.amount * 4.184 : item.amount)) \(energyUnitLabel)")
                        .font(.caption2).bold()
                }
            }
        }
    }

    @ChartContentBuilder
    private func intakeArea(_ data: [SeriesItem]) -> some ChartContent {
        ForEach(data) { item in
            AreaMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Intake", useMetricUnits ? item.amount * 4.184 : item.amount)
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
                y: .value("Burn", useMetricUnits ? item.amount * 4.184 : item.amount)
            )
            .interpolationMethod(.linear)
            .symbol(.square)
            .symbolSize(40)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .foregroundStyle(LinearGradient(colors: [.red, .orangeStart], startPoint: .leading, endPoint: .trailing))
            .annotation(position: .top) {
                if Calendar.current.isDateInToday(item.date) {
                    Text("\(Int(useMetricUnits ? item.amount * 4.184 : item.amount)) \(energyUnitLabel)")
                        .font(.caption2).bold()
                }
            }
        }
    }

    @ChartContentBuilder
    private func burnArea(_ data: [SeriesItem]) -> some ChartContent {
        ForEach(data) { item in
            AreaMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Burn", useMetricUnits ? item.amount * 4.184 : item.amount)
            )
            .interpolationMethod(.linear)
            .foregroundStyle(LinearGradient(colors: [.red.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
        }
    }

    // MARK: - Data helpers & placeholders

    private struct SeriesItem: Identifiable {
        let id = UUID()
        let date: Date
        let amount: Double
    }

    private func waterSeries() -> [SeriesItem] {
        let samples = healthManager.waterIntakeSeries
        if !samples.isEmpty { return samples.map { SeriesItem(date: $0.date, amount: $0.amount) } }
        // Fallback demo data
        return demoSeries(days: 14, base: 1800, variance: 400)
    }

    private func calorieIntakeSeries() -> [SeriesItem] {
        let samples = healthManager.calorieIntakeSeries
        if !samples.isEmpty { return samples.map { SeriesItem(date: $0.date, amount: $0.amount) } }
        return demoSeries(days: 14, base: 2200, variance: 500)
    }

    private func calorieBurnSeries() -> [SeriesItem] {
        let samples = healthManager.calorieBurnSeries
        if !samples.isEmpty { return samples.map { SeriesItem(date: $0.date, amount: $0.amount) } }
        return demoSeries(days: 14, base: 2000, variance: 400)
    }

    private func demoSeries(days: Int, base: Double, variance: Double) -> [SeriesItem] {
        (0..<days).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let jitter = Double.random(in: -variance...variance)
            return SeriesItem(date: date, amount: max(0, base + jitter))
        }.sorted { $0.date < $1.date }
    }
    
    private func systemIconForWorkout(title: String, subtitle: String) -> String {
        let t = (title + " " + subtitle).lowercased()
        if t.contains("run") || t.contains("jog") { return "figure.run" }
        if t.contains("walk") || t.contains("hike") { return "figure.walk" }
        if t.contains("cycle") || t.contains("bike") { return "bicycle" }
        if t.contains("swim") { return "figure.pool.swim" }
        if t.contains("row") { return "figure.rower" }
        if t.contains("yoga") || t.contains("stretch") { return "figure.yoga" }
        if t.contains("strength") || t.contains("weights") || t.contains("lift") { return "figure.strengthtraining.traditional" }
        if t.contains("hiit") || t.contains("interval") { return "flame.fill" }
        if t.contains("pilates") { return "figure.mind.and.body" }
        if t.contains("stair") { return "figure.stairs" }
        if t.contains("ski") { return "figure.skiing.downhill" }
        if t.contains("elliptical") { return "figure.elliptical" }
        if t.contains("dance") { return "figure.dance" }
        return "figure.run"
    }

    private func addWaterIntake(amountML: Double, date: Date) async {
        await healthManager.addWaterIntakeIfSupported(amountML: amountML, date: date)
    }

    private func refreshHealthData() async {
        await healthManager.refreshIfSupported()
    }

    private func addCalorieIntake(amount: Double, date: Date) async {
        await healthManager.addCalorieIntakeIfSupported(amount: amount, date: date)
    }

    private func addCalorieBurn(amount: Double, date: Date) async {
        await healthManager.addCalorieBurnIfSupported(amount: amount, date: date)
    }
}

#Preview {
    HealthView()
        .environment(HealthManager())
        .preferredColorScheme(.dark)
}

