//
//  ContentView.swift
//  SetDeck Watch App
//
//  Created by Nick Molargik on 1/9/26.
//

import SwiftUI

struct ContentView: View {
    #if DEBUG
    @State private var tab: Int = {
        switch WatchDemo.screen {
        case "workout", "restbanner": return 0
        case "rest": return 3
        case .some: return 1
        case .none: return 0
        }
    }()
    #else
    @State private var tab = 0
    #endif

    var body: some View {
        TabView(selection: $tab) {
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
