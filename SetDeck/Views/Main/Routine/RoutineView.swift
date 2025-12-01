//
//  RoutineView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI
import SwiftData

struct RoutineView: View {
    @State private var selectedDay: Int = 0 // 0 = Sunday

    @Environment(ExerciseManager.self) private var exerciseManager
    @Environment(\.scenePhase) private var scenePhase

    // Optional convenience if you need the routine for the selected day later
    private var selectedRoutine: SetDeckRoutine {
        exerciseManager.routine(for: selectedDay)
    }

    var body: some View {
        let _ = exerciseManager.changeStamp

        VStack(spacing: 0) {
            DayPickerView(selectedDay: $selectedDay)
            
            RoutineDayDeckView(routine: exerciseManager.routine(for: selectedDay))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedDay)
        }
        .padding(.top, 12)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedDay)
        .onAppear {
            selectedDay = todayIndex
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue == .active {
                selectedDay = todayIndex
            }
        }
    }

    private var todayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday - 1 + 7) % 7 // Convert 1...7 (Sun...Sat) to 0...6
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

    // Seed a few routines for previewing if none exist
    if (try? context.fetch(FetchDescriptor<SetDeckRoutine>()))?.isEmpty ?? true {
        for _ in 0..<7 {
            let routine = SetDeckRoutine.sample()
            context.insert(routine)
        }
        try? context.save()
    }

    return AnyView(
        RoutineView()
            .environment(exerciseManager)
            .preferredColorScheme(.dark)
    )
}
