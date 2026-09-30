//
//  AdaptiveGlassModifier.swift
//  SetDeckDesignSystem
//

import SwiftUI

public struct AdaptiveGlassModifier: ViewModifier {
    let tint: Color

    public init(tint: Color) {
        self.tint = tint
    }

    public func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive().tint(tint))
        } else {
            content
                .background(tint)
                .cornerRadius(20)
        }
        #else
        content
            .background(tint)
            .cornerRadius(20)
        #endif
    }
}
