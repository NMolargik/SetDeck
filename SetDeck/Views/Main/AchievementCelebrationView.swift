//
//  AchievementCelebrationView.swift
//  SetDeck
//
//  Created by Nick Molargik on 2/16/26.
//

import SwiftUI

// MARK: - Confetti Piece Model

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let shape: ConfettiShape
    let color: Color
    let startX: CGFloat
    let endX: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let rotation: Double
    let duration: Double
    let delay: Double
    let size: CGFloat

    enum ConfettiShape: CaseIterable {
        case circle, rectangle, capsule
    }

    static func random(in size: CGSize) -> ConfettiPiece {
        let colors: [Color] = [.greenStart, .purpleStart, .blueStart, .orangeStart, .yellow, .red]
        let width = max(size.width, 300)
        let startX = CGFloat.random(in: -20...width + 20)
        return ConfettiPiece(
            shape: ConfettiShape.allCases.randomElement()!,
            color: colors.randomElement()!,
            startX: startX,
            endX: startX + CGFloat.random(in: -60...60),
            startY: -20,
            endY: size.height + 40,
            rotation: Double.random(in: 0...720),
            duration: Double.random(in: 2.5...4.0),
            delay: Double.random(in: 0...0.6),
            size: CGFloat.random(in: 6...12)
        )
    }
}

// MARK: - Confetti Piece View

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var animate = false

    var body: some View {
        Group {
            switch piece.shape {
            case .circle:
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
            case .rectangle:
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 0.6)
            case .capsule:
                Capsule()
                    .fill(piece.color)
                    .frame(width: piece.size * 0.5, height: piece.size)
            }
        }
        .rotationEffect(.degrees(animate ? piece.rotation : 0))
        .position(
            x: animate ? piece.endX : piece.startX,
            y: animate ? piece.endY : piece.startY
        )
        .opacity(animate ? 0 : 1)
        .onAppear {
            withAnimation(.easeOut(duration: piece.duration).delay(piece.delay)) {
                animate = true
            }
        }
    }
}

// MARK: - Celebration View

struct AchievementCelebrationView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var showCard = false
    @State private var iconRotation: Double = -90
    @State private var isDismissing = false
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dimmed background
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                // Confetti
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }

                // Card
                if showCard {
                    cardView
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                }
            }
            .onAppear {
                confettiPieces = (0..<80).map { _ in ConfettiPiece.random(in: geo.size) }

                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showCard = true
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    iconRotation = 0
                }

                // Haptics
                Haptics.mediumImpact()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    Haptics.lightImpact()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    Haptics.success()
                }
            }
        }
    }

    private var cardView: some View {
        VStack(spacing: 16) {
            // Category icon
            ZStack {
                Circle()
                    .fill(achievement.category.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: achievement.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(achievement.category.color)
                    .rotationEffect(.degrees(iconRotation))
            }

            Text("ACHIEVEMENT UNLOCKED")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(.secondary)

            Text(achievement.displayName)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)

            Text(achievement.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(achievement.category.color)
                    )
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(achievement.category.color.opacity(0.5), lineWidth: 2)
                )
        )
    }

    private func dismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        withAnimation(.easeOut(duration: 0.25)) {
            showCard = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

#Preview {
    AchievementCelebrationView(achievement: .century) {
        // dismiss
    }
    .preferredColorScheme(.dark)
}
