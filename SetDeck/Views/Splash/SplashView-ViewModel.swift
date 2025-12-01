//
//  SplashView-ViewModel.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI

extension SplashView {
    @Observable
    class ViewModel {
        var titleVisible = false
        var subtitleVisible = false
        var buttonVisible = false
        var float = false

        func activateAnimation() {
            withAnimation {
                self.titleVisible = true
            }

            withAnimation(.easeOut.delay(0.18)) {
                self.subtitleVisible = true
            }

            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.7)
                    .delay(0.5)
            ) {
                self.buttonVisible = true
            }

            // Start a gentle idle float for the icon
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(
                    .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true)
                ) {
                    self.float.toggle()
                }
            }
        }
    }
}
