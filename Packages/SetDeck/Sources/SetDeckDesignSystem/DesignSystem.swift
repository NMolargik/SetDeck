//
//  DesignSystem.swift
//  SetDeckDesignSystem
//
//  Created by Nick Molargik on 6/14/26.
//
//  Shared visual language for SetDeck: brand gradients, spacing/radius
//  tokens, the ambient background, and reusable glass control styles.
//  Keeps the deck-of-cards identity consistent across every platform.
//

import SwiftUI

// MARK: - Brand

nonisolated public enum Brand {
    /// Spacing scale (4-pt grid).
    public enum Space {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }

    /// Continuous corner radii.
    public enum Radius {
        public static let chip: CGFloat = 12
        public static let control: CGFloat = 16
        public static let card: CGFloat = 24
        public static let sheet: CGFloat = 28
    }
}

extension ShapeStyle where Self == LinearGradient {
    /// Primary mint→forest brand gradient.
    public static var brandGreen: LinearGradient {
        LinearGradient(colors: [.greenStart, .greenEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    public static var brandBlue: LinearGradient {
        LinearGradient(colors: [.blueStart, .blueEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    public static var brandOrange: LinearGradient {
        LinearGradient(colors: [.orangeStart, .orangeEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    public static var brandPurple: LinearGradient {
        LinearGradient(colors: [.purpleStart, .purpleEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Ambient Background

/// A calm, premium backdrop: near-black base with a soft brand glow at the
/// top that subtly tints the scene. Used behind every main surface so the
/// white cards and glass controls read with depth instead of floating on
/// flat black.
public struct BrandBackground: View {
    public init(tint: Color = .greenStart) { self.tint = tint }
    var tint: Color
    public var body: some View {
        ZStack {
            Color.black
            // Top accent glow
            RadialGradient(
                colors: [tint.opacity(0.22), tint.opacity(0.05), .clear],
                center: .init(x: 0.5, y: -0.05),
                startRadius: 0,
                endRadius: 460
            )
            // Cool counter-tone anchoring the bottom
            RadialGradient(
                colors: [Color.blueEnd.opacity(0.30), .clear],
                center: .init(x: 0.5, y: 1.05),
                startRadius: 0,
                endRadius: 420
            )
            // Gentle darkening vignette to focus the center
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.35)],
                center: .center,
                startRadius: 240,
                endRadius: 620
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glass Capsule Button Style

/// A tactile, Liquid-Glass capsule button (with graceful pre-iOS-26
/// fallback). Used for toolbar actions and floating controls.
public struct GlassCapsuleButtonStyle: ButtonStyle {
    public init(tint: Color = .greenStart, prominent: Bool = false) {
        self.tint = tint
        self.prominent = prominent
    }
    var tint: Color
    var prominent: Bool

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(prominent ? AnyShapeStyle(.white) : AnyShapeStyle(tint))
            .padding(.vertical, 9)
            .padding(.horizontal, 16)
            .background {
                if prominent {
                    Capsule(style: .continuous).fill(LinearGradient(colors: [tint, tint.opacity(0.82)], startPoint: .top, endPoint: .bottom))
                } else {
                    Capsule(style: .continuous).fill(.ultraThinMaterial)
                }
            }
            .overlay(
                Capsule(style: .continuous)
                    .stroke(.white.opacity(prominent ? 0.25 : 0.14), lineWidth: 1)
            )
            .clipShape(Capsule(style: .continuous))
            .shadow(color: (prominent ? tint : .black).opacity(prominent ? 0.35 : 0.2), radius: prominent ? 10 : 6, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}

extension ButtonStyle where Self == GlassCapsuleButtonStyle {
    public static func glassCapsule(tint: Color = .greenStart, prominent: Bool = false) -> GlassCapsuleButtonStyle {
        GlassCapsuleButtonStyle(tint: tint, prominent: prominent)
    }
}
