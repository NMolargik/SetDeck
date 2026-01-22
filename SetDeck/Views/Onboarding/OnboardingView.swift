//
//  OnboardingView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @Environment(ExerciseManager.self) private var exerciseManager: ExerciseManager

    
    var onFinished: () -> Void = {}
    
    @State private var viewModel = ViewModel()
    
    private var steps: [OnboardingStep] {
        OnboardingStep.allCases
    }
    
    private var currentIndex: Int {
        steps.firstIndex(of: viewModel.currentStep) ?? 0
    }
    
    private var canContinue: Bool {
        // `canContinue` on the view model expects an `ExerciseManager?` and returns a Bool.
        // Pass the manager from the environment if available; otherwise, default to false-safe logic inside the view model.
        return viewModel.canContinue(exerciseManager: exerciseManager)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Page Indicators
            if viewModel.currentStep != .complete {
                HStack(spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        Capsule()
                            .fill(index <= currentIndex ? Color.greenStart : Color.secondary.opacity(0.3))
                            .frame(height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentIndex)
                    }
                }
                .frame(maxWidth: 500)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            
            // Content
            TabView(selection: $viewModel.currentStep) {
                OnboardingPrivacyPage()
                    .tag(OnboardingStep.privacy)
                
                OnboardingHealthPage()
                    .tag(OnboardingStep.health)
                
                OnboardingBuilderPage()
                    .tag(OnboardingStep.builder)
                
                OnboardingCompletePage(onFinish: onFinished)
                    .tag(OnboardingStep.complete)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            
            // Bottom Buttons
            if viewModel.currentStep != .complete {
                VStack(spacing: 12) {
                    // Continue Button
                    Button {
                        Haptics.mediumImpact()
                        Task {
                            await viewModel.handleContinueTapped(
                                healthManager: healthManager
                            )
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isRequestingPermission {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Continue")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canContinue ? Color.blueStart : Color.secondary.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canContinue)
                }
                .frame(maxWidth: 500)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .padding(.top, 12)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .task {
            viewModel.currentStep = .privacy
        }
        .environment(viewModel)
    }
}

