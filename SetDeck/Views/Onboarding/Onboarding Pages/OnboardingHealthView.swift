//
//  OnboardingHealthView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI

struct OnboardingHealthView: View {
    @Bindable var viewModel: OnboardingView.ViewModel
    @Environment(HealthManager.self) var healthManager: HealthManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var maxContentWidth: CGFloat? {
        horizontalSizeClass == .regular ? 500 : nil
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 12)

            VStack(spacing: 8) {
                Text("Apple Health")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)
                    .shadow(radius: 5, x: 1, y: -1)

                Text("SetDeck connects directly to Apple Health to read and write health data, including water consumption, food consumption, and workout data. All data stays secure on your device or encrypted in iCloud. Please authorize all options!")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .frame(maxWidth: maxContentWidth)
            }

            Image("appleHealth")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .shadow(radius: 8)
                .padding(.vertical, 8)

            Spacer(minLength: 12)

            Button(action: {
                Task { await healthManager.requestAuthorization() }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .imageScale(.large)
                    Text("Continue")
                        .font(.title3).bold()
                }
                .frame(maxWidth: maxContentWidth ?? .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
            }
            .adaptiveGlass(tint: .purpleStart)
            .hoverEffectIfAvailable(.highlight)
            .accessibilityLabel("Continue to Apple Health authorization")
            .accessibilityHint("Opens the Apple Health permission dialog")
            .shadow(radius: 6, y: 3)
            .padding(.horizontal)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    OnboardingHealthView(viewModel: OnboardingView.ViewModel())
        .environment(HealthManager())
}
