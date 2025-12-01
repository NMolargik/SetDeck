//
//  WorkoutHistorySectionView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI

struct WorkoutHistorySectionView: View {
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup(isExpanded: $isExpanded) {
                let workouts = healthManager.workoutHistory
                VStack(alignment: .leading, spacing: 12) {
                    if !workouts.isEmpty {
                        ForEach(workouts, id: \.id) { workout in
                            WorkoutRowView(
                                title: workout.title,
                                subtitle: workout.subtitle,
                                durationString: workout.durationString,
                                systemImageName: systemIconForWorkout(title: workout.title, subtitle: workout.subtitle)
                            )
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: workout.id)
                        }
                    } else {
                        ContentUnavailableView("No Workouts", systemImage: "figure.run", description: Text("Your Apple Health workouts will appear here when available."))
                    }
                }
                .padding(.top, 8)
            } label: {
                Text("Workout History").font(.title2.bold())
            }
            .foregroundStyle(.greenStart)
        }
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
}
#Preview {
    WorkoutHistorySectionView()
        .padding()
        .environment(HealthManager())
        .preferredColorScheme(.dark)
}

