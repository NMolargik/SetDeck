//
//  OnboardingPageView.swift
//  SetDeckFeatureOnboarding
//
//  The page building blocks: the hero (symbol tile, title, subtitle), the grouped feature
//  list, and a scroll view that centres short content and scrolls only when it must.
//

#if os(iOS)
import SwiftUI
import SetDeckDesignSystem

// MARK: - Hero

struct OnboardingHero: View {
    let content: OnboardingHeroContent
    /// Larger tile for the leading pane of a two-pane layout.
    var isLarge = false
    /// Tile hidden (the builder page needs the height for the editor).
    var showsTile = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounce = false

    @ScaledMetric(relativeTo: .largeTitle) private var tileSide: CGFloat = 88
    @ScaledMetric(relativeTo: .largeTitle) private var largeTileSide: CGFloat = 120

    var body: some View {
        let side = isLarge ? largeTileSide : tileSide
        VStack(spacing: Brand.Space.lg) {
            if showsTile {
                Image(systemName: content.symbol)
                    .font(.system(size: side * 0.48, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(content.tint)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, options: .nonRepeating, value: bounce)
                    .frame(width: side, height: side)
                    .background(
                        RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
                            .fill(content.tint.opacity(0.20))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
                            .strokeBorder(content.tint.opacity(0.35))
                    )
                    .accessibilityHidden(true)
            }

            VStack(spacing: Brand.Space.sm) {
                Text(content.title)
                    .font(.system(isLarge ? .largeTitle : .title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(content.subtitle)
                    .font(isLarge ? .title3 : .body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            guard !reduceMotion else { return }
            bounce.toggle()
        }
    }
}

// MARK: - Feature list

/// A grouped card of rows: a tinted glyph, a title and an optional detail. With
/// `showsChecks` each row ends in a checkmark (the completion page).
struct OnboardingFeatureList: View {
    let features: [OnboardingFeature]
    var showsChecks = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @ScaledMetric(relativeTo: .body) private var glyphBox: CGFloat = 38

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                if index > 0 {
                    Divider().overlay(Color.white.opacity(0.08)).padding(.leading, Brand.Space.lg + glyphBox + Brand.Space.md)
                }
                row(feature)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.85).delay(0.06 * Double(index)), value: appeared)
            }
        }
        .onboardingCard()
        .onAppear { appeared = true }
    }

    private func row(_ feature: OnboardingFeature) -> some View {
        HStack(alignment: .center, spacing: Brand.Space.md) {
            Image(systemName: feature.symbol)
                .font(.body.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(feature.tint)
                .frame(width: glyphBox, height: glyphBox)
                .background(
                    RoundedRectangle(cornerRadius: Brand.Radius.chip, style: .continuous)
                        .fill(feature.tint.opacity(0.20))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.body.weight(.semibold))
                if let detail = feature.detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: Brand.Space.sm)

            if showsChecks {
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.greenStart)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Brand.Space.lg)
        .padding(.vertical, Brand.Space.md)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Centred scroll

/// Centres its content vertically when it fits and scrolls when it does not.
struct OnboardingCenteredScroll<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                content
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
    }
}
#endif
