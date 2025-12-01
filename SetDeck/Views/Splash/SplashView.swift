//
//  SplashView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI
import SwiftData

struct SplashView: View {
    var moveToMigration: () -> Void

    @State private var viewModel = SplashView.ViewModel()
    @Environment(\.horizontalSizeClass) private var hSizeClass

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
                Spacer()

                VStack(spacing: 20) {
                    titleSection
                    iconSection
                    
                    Spacer()
                    
                    getStartedButton
                }
                .padding(28)
                .shadow(radius: 30, y: 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, hSizeClass == .regular ? 40 : 80)
            .frame(maxWidth: hSizeClass == .regular ? 520 : .infinity)
        }
        .onAppear {
            viewModel.activateAnimation()
        }
    }

    // MARK: - Subviews

    private var titleSection: some View {
        VStack(spacing: 6) {
            Text("SetDeck")
                .font(.system(size: hSizeClass == .regular ? 90 : 60, weight: .bold))
                .opacity(viewModel.titleVisible ? 1 : 0)
                .scaleEffect(viewModel.titleVisible ? 1 : 0.7)
                .animation(.easeOut(duration: 0.6),
                           value: viewModel.titleVisible)

            Text("Crush your workout routine")
                .font(hSizeClass == .regular ? .title2 : .headline)
                .fontWeight(.semibold)
                .opacity(viewModel.subtitleVisible ? 1 : 0)
                .offset(y: viewModel.subtitleVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.3),
                           value: viewModel.subtitleVisible)
        }
    }

    private var iconSection: some View {
        Image("icon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: hSizeClass == .regular ? 280 : 250)
            .opacity(viewModel.subtitleVisible ? 1 : 0)
            .offset(y: viewModel.subtitleVisible ? (viewModel.float ? -4 : 4) : 30)
            .scaleEffect(viewModel.subtitleVisible ? 1 : 0.9)
            .shadow(radius: 20, y: 10)
            .animation(
                .spring(response: 0.7, dampingFraction: 0.8)
                    .delay(0.45),
                value: viewModel.subtitleVisible
            )
    }

    private var getStartedButton: some View {
        Button {
            Haptics.lightImpact()
            moveToMigration()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right")
                Text("Get Started")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
        }
        .adaptiveGlass(tint: .greenStart)
        .foregroundStyle(.white)
        .frame(maxWidth: 250)
        .opacity(viewModel.buttonVisible ? 1 : 0)
        .scaleEffect(viewModel.buttonVisible ? 1 : 0.96)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.75)
                .delay(0.7),
            value: viewModel.buttonVisible
        )
        .padding(.top, 8)
        .zIndex(1)
    }
}

#Preview {
    SplashView(
        moveToMigration: {},
    )
    .preferredColorScheme(.dark)
}
