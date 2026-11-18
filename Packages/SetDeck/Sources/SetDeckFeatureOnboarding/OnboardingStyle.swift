//
//  OnboardingStyle.swift
//  SetDeckFeatureOnboarding
//
//  The shared look of the introduction: backdrop, primary/secondary buttons, card surface,
//  and the layout metrics that keep content off an iPhone Duo's hinge. The app is always
//  dark, so everything here is drawn for dark.
//

#if os(iOS)
import SwiftUI
import SetDeckDesignSystem

// MARK: - Backdrop

/// Near-black with the brand glow, shared by the splash and the pages so they read as one
/// surface. The glow fades in so the very first frame equals the (flat black) launch screen.
public struct OnboardingBackdrop: View {
    var glow: Color
    var showsGlow: Bool

    public init(glow: Color = .greenStart, showsGlow: Bool = true) {
        self.glow = glow
        self.showsGlow = showsGlow
    }

    public var body: some View {
        ZStack {
            Color.black
            BrandBackground(tint: glow)
                .opacity(showsGlow ? 1 : 0)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

// MARK: - Buttons

/// The filled primary action: brand mint with dark label text (mint is a light colour).
struct OnboardingPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? Color.black.opacity(0.88) : Color.white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Brand.Space.lg)
            .background(
                RoundedRectangle(cornerRadius: Brand.Radius.control, style: .continuous)
                    .fill(isEnabled ? AnyShapeStyle(Color.greenStart) : AnyShapeStyle(Color.white.opacity(0.12)))
            )
            .shadow(color: Color.greenStart.opacity(isEnabled ? 0.28 : 0), radius: 14, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: Brand.Radius.control, style: .continuous))
    }
}

/// A quiet text button for Back / Not now / Open Settings.
struct OnboardingSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.5 : 0.75))
            .padding(.horizontal, Brand.Space.md)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
}

// MARK: - Card surface

extension View {
    /// A grouped card on the dark backdrop.
    func onboardingCard() -> some View {
        background(
            RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10))
        )
        .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
    }
}

// MARK: - Layout metrics

/// How the introduction divides its window. Single column on iPhone and iPad portrait; two
/// panes (hero on the leading side, content and actions on the trailing side) where a vertical
/// hinge divides the window (unfolded iPhone Duo) or an iPad is wide. The pane edges come from
/// the hinge when there is one, so nothing sits in the fold.
struct OnboardingMetrics: Equatable {
    var size: CGSize
    var foldX: CGFloat?
    var isFoldActive: Bool
    var isTwoPane: Bool

    /// Readable width of a single column of content.
    static let columnWidth: CGFloat = 520

    init(_ proxy: GeometryProxy) {
        size = proxy.size
        let fold = proxy.foldCenterXIfAvailable
        foldX = proxy.hasFoldIfAvailable ? fold : nil
        isFoldActive = proxy.isFoldActiveIfAvailable
        let wide = proxy.size.width >= 600
        isTwoPane = wide && (foldX != nil || proxy.size.width > proxy.size.height * 1.15)
    }

    /// Where the two panes meet: the hinge, else the window's middle.
    var splitX: CGFloat { foldX ?? size.width / 2 }
    /// Empty space either side of the split (wider while the hinge is bent).
    var gutter: CGFloat { isFoldActive ? Brand.Space.xxl * 2 : Brand.Space.xxl }
    var leadingWidth: CGFloat { max(0, splitX - gutter / 2) }
    var trailingWidth: CGFloat { max(0, size.width - splitX - gutter / 2) }
}
#endif
