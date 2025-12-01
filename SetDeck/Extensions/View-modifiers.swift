//
//  View-modifiers.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
    
    /// Applies a glass effect with the provided tint on iOS 26+,
    /// and falls back to a simple tinted background on earlier iOS versions.
    func adaptiveGlass(tint: Color) -> some View {
        self.modifier(AdaptiveGlassModifier(tint: tint))
    }
}

#if os(iOS)
public extension View {
    @ViewBuilder
    func tabViewBottomAccessoryIfAvailable<Accessory: View>(@ViewBuilder _ accessory: () -> Accessory) -> some View {
        if #available(iOS 26.0, *) {
            // Only use the new API when available at runtime
            self.tabViewBottomAccessory(content: accessory)
        } else {
            // On earlier OS versions, do nothing
            self
        }
    }
}
#else
public extension View {
    @ViewBuilder
    func tabViewBottomAccessoryIfAvailable<Accessory: View>(@ViewBuilder _ accessory: () -> Accessory) -> some View {
        // Non-iOS platforms: no-op to keep API usage consistent
        self
    }
}
#endif

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.35), Color.clear]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .blendMode(.plusLighter)
                    .mask(content)
                    .offset(x: phase * 180)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

 
struct DrawOnOffEffect: ViewModifier {
    let drawOn: Bool
    let drawOff: Bool

    func body(content: Content) -> some View {
        #if compiler(>=6.0)
        content
            .symbolEffect(.pulse, options: .repeating, value: drawOn)
        #else
        content
            .symbolEffect(.pulse, options: .repeating, value: drawOn)
        #endif
    }
}
