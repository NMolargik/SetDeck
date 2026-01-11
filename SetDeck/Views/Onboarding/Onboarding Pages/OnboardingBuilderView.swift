//
//  OnboardingBuilderView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI
import SwiftData

struct OnboardingBuilderView: View {
    @Bindable var viewModel: OnboardingView.ViewModel
    @Environment(ExerciseManager.self) var exerciseManager: ExerciseManager
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

    return OnboardingBuilderView(
        viewModel: OnboardingView.ViewModel()
    )
    .environment(exerciseManager)
    .preferredColorScheme(.dark)
}
