//
//  OnboardingView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(ExerciseManager.self) private var exerciseManager: ExerciseManager
    @Environment(HealthManager.self) private var healthManager: HealthManager
    
    var onFinished: () -> Void = {}

    @State private var viewModel: OnboardingView.ViewModel = OnboardingView.ViewModel()
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.10, blue: 0.22),
                    Color(red: 0.01, green: 0.03, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Group {
                    ZStack {
                        pageView()
                            .id(viewModel.currentPage) // important for transition
                            .transition(viewModel.isMovingForward ? viewModel.forwardTransition : viewModel.backwardTransition)
                    }
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)
                    .padding(.bottom)
                    
                    Spacer()
                    
                    HStack {
                        if viewModel.currentPage != .health && viewModel.currentPage != .complete {
                            Button("Back") {
                                Haptics.lightImpact()
                                viewModel.isMovingForward = false
                                let previous = viewModel.currentPage.previous
                                withAnimation {
                                    viewModel.currentPage = previous
                                }
                            }
                            .frame(width: 80)
                            .foregroundStyle(.white)
                            .bold()
                            .padding()
                            .adaptiveGlass(tint: .red)
                        }
                        
                        Spacer()
                        
                        if viewModel.currentPage != .complete {
                            Button("Next") {
                                Haptics.lightImpact()
                                let allowed = viewModel.criteriaMet(healthManager: healthManager)
                                viewModel.isMovingForward = true
                                let next = viewModel.currentPage.next
                                withAnimation {
                                    viewModel.currentPage = next
                                }
                                if allowed {
                                    Haptics.success()
                                }
                            }
                            .frame(width: 80)
                            .foregroundStyle(.white)
                            .bold()
                            .padding()
                            .adaptiveGlass(tint: viewModel.criteriaMet(healthManager: healthManager) ? .greenStart : .gray)
                            .disabled(!viewModel.criteriaMet(healthManager: healthManager))
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    private func pageView() -> some View {
        switch viewModel.currentPage {
        case .health:
            OnboardingHealthView(viewModel: viewModel)
        case .builder:
            OnboardingBuilderView(viewModel: viewModel, onContinue: {
                viewModel.currentPage = .complete
            })
        case .complete:
            OnboardingCompleteView(viewModel: viewModel, finishOnboarding: {
                Haptics.success()
                onFinished()
            })
        }
    }
}

#Preview {
    let container: ModelContainer

    do {
        container = try ModelContainer(for: Exercise.self, SetDeckExercise.self, SetDeckRoutine.self, SetDeckSet.self, SetDeckSetHistory.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
    } catch {
        fatalError("Preview ModelContainer setup failed: \(error)")
    }
    let previewExerciseManager = ExerciseManager(context: container.mainContext)
    return OnboardingView(
        onFinished: {}
    )
        .environment(previewExerciseManager)
        .environment(HealthManager())
        .preferredColorScheme(.dark)
}
