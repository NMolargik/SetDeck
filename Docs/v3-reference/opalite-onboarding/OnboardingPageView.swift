//
//  OnboardingPageView.swift
//  OpaliteFeatureOnboarding
//
//  The two page bodies: a feature page (hero symbol, title, three feature rows) and the
//  profile form (display name). Both sit at the readable width; a feature page tightens
//  its spacing on short windows and scrolls only when even that cannot fit.
//

#if os(iOS) || os(visionOS)
import SwiftUI
import OpaliteCore
import OpaliteDesignSystem

// MARK: - Feature page

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        // The roomiest layout that fits without clipping, then a tighter one (smaller hero,
        // less air), and only as a last resort the tight layout scrolling under the pinned
        // Continue bar with a soft edge. The closed iPhone Duo (466 × 678) fits the tight one.
        ViewThatFits(in: .vertical) {
            content(compact: false)
            content(compact: true)
            ScrollView {
                content(compact: true)
            }
            .scrollBounceBehavior(.basedOnSize)
            .softScrollEdgesIfAvailable()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func featureRow(_ index: Int, compact: Bool) -> some View {
        if page.features.indices.contains(index) {
            if index > 0 {
                Divider().padding(.leading, Brand.Space.lg)
            }
            OnboardingFeatureRow(feature: page.features[index], tint: page.tint, compact: compact)
        }
    }

    private func content(compact: Bool) -> some View {
        VStack(spacing: compact ? Brand.Space.lg : Brand.Space.xl) {
            OnboardingPageHeader(page: page, compact: compact)

            // Rows are built here, on the main actor, with no `ForEach`: `ViewThatFits` measures
            // its alternatives on SwiftUI's async renderer, and a `ForEach` content closure
            // (main-actor isolated) evaluated there trips libdispatch's queue assertion.
            VStack(spacing: 0) {
                featureRow(0, compact: compact)
                featureRow(1, compact: compact)
                featureRow(2, compact: compact)
                featureRow(3, compact: compact)
            }
            .cardSurface()
        }
        .padding(.horizontal, compact ? Brand.Space.lg : Brand.Space.xl)
        .padding(.vertical, compact ? Brand.Space.sm : Brand.Space.xl)
        .frame(maxWidth: Brand.readableWidth)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Header

/// Hero symbol on a tinted tile (the page's brand colour), then the title and subtitle.
struct OnboardingPageHeader: View {
    let page: OnboardingPage
    /// The tighter hero for short windows (the closed iPhone Duo, iPhone landscape).
    var compact = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounce = false

    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 48
    @ScaledMetric(relativeTo: .largeTitle) private var symbolBox: CGFloat = 96
    @ScaledMetric(relativeTo: .largeTitle) private var compactSymbolSize: CGFloat = 32
    @ScaledMetric(relativeTo: .largeTitle) private var compactSymbolBox: CGFloat = 56

    var body: some View {
        VStack(spacing: compact ? Brand.Space.sm : Brand.Space.lg) {
            Image(systemName: page.systemImage)
                .font(.system(size: compact ? compactSymbolSize : symbolSize, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(page.tint.inkVariant)
                .symbolEffect(.bounce, options: .nonRepeating, value: bounce)
                .frame(width: compact ? compactSymbolBox : symbolBox, height: compact ? compactSymbolBox : symbolBox)
                .background(
                    RoundedRectangle(cornerRadius: (compact ? compactSymbolBox : symbolBox) * 0.26, style: .continuous)
                        .fill(page.tint.opacity(0.28))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: (compact ? compactSymbolBox : symbolBox) * 0.26, style: .continuous)
                        .strokeBorder(.quaternary)
                )
                .accessibilityHidden(true)

            VStack(spacing: compact ? Brand.Space.xs : Brand.Space.sm) {
                Text(page.title)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(page.subtitle)
                    .font(.body)
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

// MARK: - Feature row

/// A `DetailRow`-style line: a tinted glyph, a title with a one-line detail, and the
/// Onyx badge on gated features. One accessibility element.
struct OnboardingFeatureRow: View {
    let feature: OnboardingFeature
    var tint: Color = .opalitePurple
    var compact = false

    @ScaledMetric(relativeTo: .body) private var glyphBox: CGFloat = 36

    var body: some View {
        HStack(alignment: .center, spacing: Brand.Space.md) {
            Image(systemName: feature.systemImage)
                .font(.body.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint.inkVariant)
                .frame(width: glyphBox, height: glyphBox)
                .background(
                    RoundedRectangle(cornerRadius: Brand.Radius.chip, style: .continuous)
                        .fill(tint.opacity(0.28))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.body.weight(.semibold))
                Text(feature.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Brand.Space.sm)

            if feature.requiresOnyx {
                OnyxBadge()
            }
        }
        .padding(.horizontal, Brand.Space.lg)
        .padding(.vertical, compact ? Brand.Space.sm + 2 : Brand.Space.md)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Profile page

/// The one page that collects input: a grouped form with the display-name field.
struct OnboardingProfilePage: View {
    @Bindable var model: OnboardingViewModel
    var onSubmit: () -> Void

    @FocusState private var isNameFocused: Bool

    var body: some View {
        Form {
            Section {
                // Horizontal padding: the row has zero insets, so without it the wrapped
                // subtitle ran into the window's edges on the closed iPhone Duo.
                OnboardingPageHeader(page: model.page)
                    .padding(.top, Brand.Space.lg)
                    .padding(.horizontal, Brand.Space.lg)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            Section {
                TextField("Display Name", text: $model.displayName, prompt: Text("Your name"))
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .onSubmit(onSubmit)
                    .accessibilityIdentifier("displayNameField")
            } header: {
                Text("Display Name")
            } footer: {
                Text("Shown on colors and palettes you publish to the Community. Leave it blank to stay anonymous.")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .dismissingKeyboardOnScroll()
        .frame(maxWidth: Brand.readableWidth)
        .frame(maxWidth: .infinity)
    }
}

private extension View {
    /// Interactive keyboard dismissal where a software keyboard scrolls with content.
    @ContentBuilder
    func dismissingKeyboardOnScroll() -> some View {
        #if os(iOS)
        scrollDismissesKeyboard(.interactively)
        #else
        self
        #endif
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Feature page") {
    OnboardingPageView(page: .page(for: .portfolio))
        .background(groupedBackground)
}

#Preview("Profile page") {
    OnboardingProfilePage(model: OnboardingViewModel(step: .profile, displayName: "Nick"), onSubmit: {})
        .background(groupedBackground)
}
#endif
#endif
