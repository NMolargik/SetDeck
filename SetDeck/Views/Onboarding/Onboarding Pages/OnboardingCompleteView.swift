//
//  OnboardingCompleteView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI

struct OnboardingCompleteView: View {
    @Bindable var viewModel: OnboardingView.ViewModel
    var finishOnboarding: () -> Void
    
    @State private var shownRows: [Bool] = [false, false, false, false]
    @State private var showButton: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)

            VStack(spacing: 8) {
                Text("All Done!")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)
                    .shadow(radius: 5, x: 1, y: -1)
                
                Text("Here's what you've got to look forward to.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Feature cards
            VStack(spacing: 14) {
                DetailRowView(
                    style: .feature,
                    systemImage: "figure.strengthtraining.traditional",
                    title: "Track your workouts, down to the set!",
                    tint: .greenStart
                )
                .opacity(shownRows[0] ? 1 : 0)
                .offset(x: shownRows[0] ? 0 : -32)
                .animation(.spring(response: 1.2, dampingFraction: 0.85), value: shownRows[0])
                .symbolEffect(.bounce, value: shownRows[0])

                DetailRowView(
                    style: .feature,
                    systemImage: "chart.xyaxis.line",
                    title: "Check lifting stats over time.",
                    tint: .purpleStart
                )
                .opacity(shownRows[1] ? 1 : 0)
                .offset(x: shownRows[1] ? 0 : 32)
                .animation(.spring(response: 1.2, dampingFraction: 0.85), value: shownRows[1])
                .symbolEffect(.bounce, value: shownRows[1])

                DetailRowView(
                    style: .feature,
                    systemImage: "drop",
                    title: "Keep track of water and energy consumption.",
                    tint: .blueStart
                )
                .opacity(shownRows[2] ? 1 : 0)
                .offset(x: shownRows[2] ? 0 : -32)
                .animation(.spring(response: 1.2, dampingFraction: 0.85), value: shownRows[2])
                .symbolEffect(.bounce, value: shownRows[2])

                DetailRowView(
                    style: .feature,
                    systemImage: "icloud.fill",
                    title: "All of your data syncs to iPhones and iPads signed into iCloud!",
                    tint: .secondary
                )
                .opacity(shownRows[3] ? 1 : 0)
                .offset(x: shownRows[3] ? 0 : 32)
                .animation(.spring(response: 1.2, dampingFraction: 0.85), value: shownRows[3])
                .symbolEffect(.bounce, value: shownRows[3])
            }
            .padding(.horizontal)

            Spacer(minLength: 12)
            
            Button(action: finishOnboarding) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .symbolEffect(.bounce, value: showButton)
                    Text("Enter SetDeck")
                        .font(.title3).bold()
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .adaptiveGlass(tint: .purpleStart)
            .shadow(radius: 6, y: 3)
            .padding(.horizontal)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 12)
            .animation(.spring(response: 1.2, dampingFraction: 0.85), value: showButton)
        }
        .task {
            for i in 0..<shownRows.count {
                try? await Task.sleep(nanoseconds: 600_000_000)
                withAnimation(.spring(response: 1.2, dampingFraction: 0.85)) {
                    shownRows[i] = true
                }
            }
            try? await Task.sleep(nanoseconds: 800_000_000)
            withAnimation(.spring(response: 1.2, dampingFraction: 0.85)) {
                showButton = true
            }
        }
    }
}

#Preview {
    OnboardingCompleteView(
        viewModel: OnboardingView.ViewModel(),
        finishOnboarding: {}
    )
}
