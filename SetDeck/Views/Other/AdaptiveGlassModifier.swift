//
//  AdaptiveGlassModifier.swift
//  Stork
//
//  Created by Nick Molargik on 9/23/25.
//

import SwiftUI

struct AdaptiveGlassModifier: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive().tint(tint))
        } else {
            content
                .background(tint)
                .cornerRadius(20)
        }
    }
}
