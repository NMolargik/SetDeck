//
//  DetailRowView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI

struct DetailRowView<Trailing: View>: View {
    enum Style { case feature, insight }

    let style: Style
    let systemImage: String
    let title: String
    let subtitle: String?
    let tint: Color
    @ViewBuilder let trailing: () -> Trailing

    init(
        style: Style,
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        tint: Color,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.style = style
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.trailing = trailing
    }

    var body: some View {
        switch style {
        case .feature:
            featureBody
        case .insight:
            insightBody
        }
    }
}

private extension DetailRowView {
    var featureBody: some View {
        HStack(spacing: 14) {
            leadingCircle(size: 44, iconSize: 40, font: .title3, backgroundOpacity: 0.18, hierarchical: true)
            Text(title)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.12))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 6, y: 2)
    }
}

private extension DetailRowView {
    var insightBody: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                Image(systemName: systemImage)
                    .symbolVariant(.fill)
                    .foregroundStyle(tint)
            }
            .frame(width: 30, height: 30)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline).bold()
                    .minimumScaleFactor(0.9)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 4) {
                trailing()
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}

private extension DetailRowView {
    @ViewBuilder
    func leadingCircle(size: CGFloat, iconSize: CGFloat, font: Font, backgroundOpacity: Double, hierarchical: Bool) -> some View {
        ZStack {
            Circle()
                .fill(tint.opacity(backgroundOpacity))
                .frame(width: size, height: size)
            Image(systemName: systemImage)
                .frame(width: iconSize, height: iconSize)
                .font(font)
                .foregroundStyle(tint)
                .modifier(SymbolRenderingModifier(hierarchical: hierarchical))
        }
    }
}

private struct SymbolRenderingModifier: ViewModifier {
    let hierarchical: Bool
    func body(content: Content) -> some View {
        if hierarchical {
            content.symbolRenderingMode(.hierarchical)
        } else {
            content
        }
    }
}
