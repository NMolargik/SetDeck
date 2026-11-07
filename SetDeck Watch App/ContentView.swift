//
//  ContentView.swift
//  SetDeck Watch App
//
//  Created by Nick Molargik on 1/9/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Standalone workout: start, log, rest
            ActiveWorkoutView()
                .tag(0)

            // Today's Routine
            TodayRoutineView()
                .tag(1)

            // Workout Control
            WorkoutControlView()
                .tag(2)

            // Rest Timer
            RestTimerView()
                .tag(3)
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    ContentView()
}
