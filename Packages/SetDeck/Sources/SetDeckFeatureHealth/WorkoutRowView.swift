//
//  WorkoutRowView.swift
//  SetDeckFeatureHealth
//
//  Created by Nick Molargik on 11/20/25.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckServices
import SetDeckFeatureShared

struct WorkoutRowView: View {
    let title: String
    let subtitle: String
    let durationString: String
    let systemImageName: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Leading icon (fallback to a generic figure if unknown)
            Image(systemName: systemImageName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(.greenEnd.gradient)
                )
                .overlay(
                    Circle().stroke(.separator, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 6) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer(minLength: 8)

            // Duration pill
            Text(durationString)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .frame(width: 60)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(.separator, lineWidth: 1)
                )
                .foregroundStyle(.white)
        }
        .padding(12)
        .background(
            // Subtle progress/accent bar on the leading edge
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.separator, lineWidth: 1)
            }
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .hoverEffectIfAvailable(.highlight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle), duration \(durationString)")
    }
}
#endif
