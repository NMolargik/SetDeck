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
            // Today's Routine
            TodayRoutineView()
                .tag(0)

            // Workout Control
            WorkoutControlView()
                .tag(1)

            // Rest Timer
            RestTimerView()
                .tag(2)
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    ContentView()
}
