//
//  DayPickerView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/14/25.
//

import SwiftUI
import SwiftData

struct DayPickerView: View {
    @Binding var selectedDay: Int
    @Namespace private var selectionNamespace

    @Environment(ExerciseManager.self) private var exerciseManager

    private let dayShortNames: [String] = ["S", "M", "T", "W", "T", "F", "S"]
    private let dayLongNames: [String] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private var todayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday - 1 + 7) % 7 // Convert 1...7 (Sun...Sat) to 0...6
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<dayShortNames.count, id: \.self) { index in
                let isSelected = selectedDay == index
                let title = isSelected ? dayLongNames[index] : dayShortNames[index]
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedDay = index
                    }
                } label: {
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 5)
                        .frame(minWidth: isSelected ? 50 : 30)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .background(background(for: index))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(isSelected ? 0.2 : 0), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(isSelected ? 0.35 : 0.0), radius: isSelected ? 10 : 0, x: 0, y: 6)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .contentShape(Capsule())
                        .accessibilityLabel(Text("\(title) routine"))
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            // Skip data work in previews to avoid crashes
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                DispatchQueue.main.async {
                    for i in 0..<7 {
                        _ = exerciseManager.routine(for: i)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func background(for index: Int) -> some View {
        if selectedDay == index {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.greenEnd.opacity(0.8), Color.greenStart],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.greenStart, lineWidth: index == todayIndex ? 2 : 0)
                )
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.red.opacity(0.8), lineWidth: index == todayIndex ? 2 : 0)
                )
        }
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([SetDeckRoutine.self, SetDeckExercise.self, SetDeckSet.self, SetDeckSetHistory.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    let exerciseManager = ExerciseManager(context: context)

    struct PreviewWrapper: View {
        @State var selectedDay: Int = 2
        let exerciseManager: ExerciseManager
        var body: some View {
            DayPickerView(selectedDay: $selectedDay)
                .environment(exerciseManager)
        }
    }

    return PreviewWrapper(exerciseManager: exerciseManager)
        .preferredColorScheme(.dark)
}

