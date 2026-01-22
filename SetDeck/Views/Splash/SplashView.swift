//
//  SplashView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI

struct SplashView: View {
    var onContinue: () -> Void

    @State private var viewModel = SplashView.ViewModel()
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        VStack {
            Spacer()

            // Title
            Text("SetDeck")
                .font(.system(size: hSizeClass == .regular ? 90 : 60))
                .bold()
                .opacity(viewModel.titleVisible ? 1 : 0)
                .scaleEffect(viewModel.titleVisible ? 1 : 0.7)
                .animation(.easeOut(duration: 0.6), value: viewModel.titleVisible)
                .padding(.bottom, 5)
                .accessibilityAddTraits(.isHeader)

            // Subtitle
            Text("make gains every week")
                .font(hSizeClass == .regular ? .title : .title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .opacity(viewModel.subtitleVisible ? 1 : 0)
                .offset(y: viewModel.subtitleVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.8), value: viewModel.subtitleVisible)

            // App icon
            Image("icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: hSizeClass == .regular ? 200 : 220)
                .opacity(viewModel.subtitleVisible ? 1 : 0)
                .scaleEffect(viewModel.subtitleVisible ? 1 : 0)
                .animation(.bouncy(duration: 0.6).delay(0.8), value: viewModel.subtitleVisible)
                .padding()
                .accessibilityLabel("SetDeck app logo")

            Spacer()

            // Get Started Button
            Button {
                Haptics.lightImpact()
                onContinue()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Get Started")
                        .bold()
                }
                .padding()
                .frame(maxWidth: 250)
                .background(Color.greenStart)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .opacity(viewModel.buttonVisible ? 1 : 0)
            .scaleEffect(viewModel.buttonVisible ? 1 : 0.98)
            .animation(.easeOut(duration: 0.5).delay(1.2), value: viewModel.buttonVisible)
            .accessibilityLabel("Get Started")
            .accessibilityHint("Tap to begin using SetDeck")

            Spacer()
        }
        .onAppear {
            viewModel.activateAnimation()
        }
        .padding(.top, hSizeClass == .regular ? 40 : 80)
        .frame(maxWidth: hSizeClass == .regular ? 520 : .infinity)
        .padding(.horizontal, 24)
    }
}

#Preview {
    SplashView(onContinue: {})
}
