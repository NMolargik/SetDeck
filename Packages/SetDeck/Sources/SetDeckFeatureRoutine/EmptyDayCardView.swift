//
//  EmptyDayCardView.swift
//  SetDeckFeatureRoutine
//
//  Created by Nick Molargik on 11/19/25.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared

/// A compact, friendly empty state for a day with no exercises.
struct EmptyDayCardView: View {
    /// Opens the routine editor.
    var onEdit: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Brand.Space.lg) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.greenStart)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Color.greenStart.opacity(0.16)))
                .accessibilityHidden(true)

            Text("No routine for today.\nEdit your routines or enjoy your day off!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let onEdit {
                Button(action: onEdit) {
                    Label("Edit Routine", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassCapsule(tint: .greenStart, prominent: true))
                .accessibilityHint("Opens the routine editor")
            }
        }
        .padding(Brand.Space.xl)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                .fill(LinearGradient(colors: [Color(white: 0.16), Color(white: 0.10)], startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
        )
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}
#endif
