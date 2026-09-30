//
//  RoutineView.swift
//  SetDeckFeatureRoutine
//
//  Created by Nick Molargik on 11/13/25.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared

public struct RoutineView: View {
    var animateEntrance: Bool = false

    @State private var selectedDay: Int = 0 // 0 = Sunday
    @State private var hasAnimatedInitialEntrance: Bool = false

    @Environment(WorkoutDataModel.self) private var exerciseManager
    @Environment(\.scenePhase) private var scenePhase

    public init(animateEntrance: Bool = false) {
        self.animateEntrance = animateEntrance
    }

    // Optional convenience if you need the routine for the selected day later
    private var selectedRoutine: SetDeckRoutine? {
        exerciseManager.routine(for: selectedDay)
    }

    public var body: some View {
        let _ = exerciseManager.changeStamp

        ZStack {
            BrandBackground()

            VStack(spacing: 0) {
                DayPickerView(selectedDay: $selectedDay)

                RoutineDayDeckView(
                    routine: exerciseManager.routine(for: selectedDay),
                    animateEntrance: animateEntrance && !hasAnimatedInitialEntrance
                )
            }
            .padding(.top, 12)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedDay)
        .onAppear {
            selectedDay = todayIndex
            // Mark that we've done the initial entrance animation
            if animateEntrance {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    hasAnimatedInitialEntrance = true
                }
            }
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
#endif
