//
//  OnboardingBuilderPage.swift
//  SetDeckFeatureOnboarding
//
//  Created by Nick Molargik on 11/29/25.
//

#if os(iOS)
import SwiftUI
import SwiftData
import SetDeckFeatureShared
import SetDeckFeatureRoutine

struct OnboardingBuilderPage: View {
    @Environment(WorkoutDataModel.self) private var exerciseManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var maxContentWidth: CGFloat? {
        horizontalSizeClass == .regular ? 600 : nil
    }

    var body: some View {
        VStack(spacing: 5) {
            Spacer(minLength: 12)

            VStack(spacing: 8) {
                Text("Build Your Routines")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)
                    .shadow(radius: 5, x: 1, y: -1)

                Text("Add at least one exercise to continue")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            EditRoutineView()
                .padding(.horizontal)
                .frame(maxWidth: maxContentWidth)
                .environment(exerciseManager)

            Spacer(minLength: 12)
        }
    }
}
#endif
