//
//  VolumeTrendCardView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI
import Charts

struct VolumeTrendCardView: View {
    let points: [StatsView.VolumePoint]

    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false

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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Training Volume")
                .font(.headline)
            Chart(points) { point in
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Volume", point.volume)
                )
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(axisDateString(date))
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

#Preview {
    VolumeTrendCardView(points: [])
}

