//
//  EmptyDayCardView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/19/25.
//

import SwiftUI

struct EmptyDayCardView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 8)
            VStack(spacing: 8) {
                Image(systemName: "square.stack.3d.up.slash")
                    .imageScale(.large)
                    .foregroundStyle(.secondary)
                Text("No routine for today.\nEdit your routines or enjoy your day off!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
        .padding(6)
    }
}

#Preview {
    EmptyDayCardView()
}
