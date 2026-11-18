//
//  WeekOverviewView.swift
//  SetDeckFeatureRoutine
//
//  The unfolded Duo / iPad companion to today's deck: the whole week at a glance, one row
//  per day with its exercises. Tapping a day selects it on the deck beside it.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared

struct WeekOverviewView: View {
    @Binding var selectedDay: Int
    let todayIndex: Int

    @Environment(WorkoutDataModel.self) private var exerciseManager

    private let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var body: some View {
        let _ = exerciseManager.changeStamp

        ScrollView {
            VStack(alignment: .leading, spacing: Brand.Space.md) {
                Text("This Week")
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, Brand.Space.xs)

                ForEach(0..<7, id: \.self) { day in
                    dayRow(day)
                }
            }
            .padding(Brand.Space.lg)
        }
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func dayRow(_ day: Int) -> some View {
        let exercises = exerciseManager.exercises(forDay: day)
        let isSelected = selectedDay == day

        Button {
            Haptics.lightImpact()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedDay = day
            }
        } label: {
            VStack(alignment: .leading, spacing: Brand.Space.sm) {
                HStack {
                    Text(dayNames[day])
                        .font(.headline)
                    if day == todayIndex {
                        Text("Today")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.greenStart.opacity(0.25), in: Capsule())
                    }
                    Spacer()
                    Text(exercises.isEmpty ? "Rest" : "\(exercises.count) exercises")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !exercises.isEmpty {
                    Text(exercises.prefix(4).map(\.name).joined(separator: " · ") + (exercises.count > 4 ? " …" : ""))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(Brand.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Brand.Radius.control, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Color.greenStart.opacity(0.18)) : AnyShapeStyle(.ultraThinMaterial))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Brand.Radius.control, style: .continuous)
                    .strokeBorder(isSelected ? Color.greenStart : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Brand.Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .hoverEffectIfAvailable(.highlight)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(Text("\(dayNames[day]), \(exercises.isEmpty ? "rest day" : "\(exercises.count) exercises")"))
    }
}
#endif
