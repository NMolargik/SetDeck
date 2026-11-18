//
//  SplashView.swift
//  OpaliteFeatureOnboarding
//
//  The first screen on a fresh install: the app artwork, the name, one line of value,
//  and a single "Get Started" — on the plain grouped background, in the system text
//  colors. On the first appearance the mark's swatches land one on top of the other (tan,
//  lilac, blue), then the title and the button fade up; Reduce Motion shows it at once.
//

#if os(iOS) || os(visionOS)
import SwiftUI
import OpaliteCore
import OpaliteDesignSystem

// MARK: - SplashView

public struct SplashView: View {
    private let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var buttonTop: CGFloat = .greatestFiniteMagnitude
    @State private var textHeight: CGFloat = 0

    /// Per-swatch entrance progress for the mark, back to front.
    @State private var layers: [CGFloat] = SplashView.hasPlayedEntrance ? [1, 1, 1] : [0, 0, 0]
    @State private var showsText = SplashView.hasPlayedEntrance
    @State private var showsButton = SplashView.hasPlayedEntrance

    /// The entrance runs once per launch, not again when the splash is shown again.
    private static var hasPlayedEntrance = false

    @ScaledMetric(relativeTo: .largeTitle) private var artworkSide: CGFloat = 148

    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }

    public var body: some View {
        ZStack {
            groupedBackground.ignoresSafeArea()

            // The mark sits at the exact centre of the full screen, the point the launch
            // storyboard centres its image on, so the launch screen hands off in place. The
            // title block hangs below it; the button is pinned to the bottom.
            GeometryReader { proxy in
                artwork
                    .frame(width: side, height: side)
                    .accessibilityHidden(true)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                let textTop = proxy.size.height / 2 + side / 2 + Brand.Space.xxl
                let textRoom = max(0, buttonTop - (proxy.frame(in: .global).minY + textTop) - Brand.Space.md)

                VStack(spacing: Brand.Space.md) {
                    Text("Opalite")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .accessibilityAddTraits(.isHeader)
                    Text("Capture, organize, and share every color you love.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { textHeight = $0 }
                .padding(.horizontal, Brand.Space.lg)
                .accessibilityElement(children: .combine)
                // Between the centred mark and the button there is only so much room: at very
                // large text sizes the block scales down to fit rather than running into the button.
                .scaleEffect(textHeight > textRoom && textHeight > 0 ? textRoom / textHeight : 1, anchor: .top)
                .opacity(showsText ? 1 : 0)
                .offset(y: showsText ? 0 : 10)
                .frame(maxWidth: Brand.readableWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, textTop)
                .padding(.horizontal, Brand.Space.xl)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                Button {
                    Haptics.mediumImpact()
                    onContinue()
                } label: {
                    HStack(spacing: Brand.Space.sm) {
                        Text("Get Started")
                        Image(systemName: "arrow.right")
                            .accessibilityHidden(true)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .primaryActionButton()
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("continueButton")
                .accessibilityHint("Continues to the introduction")
                .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { buttonTop = $0 }
                .padding(.bottom, Brand.Space.lg)
                .opacity(showsButton ? 1 : 0)
                .offset(y: showsButton ? 0 : 10)
            }
            .padding(.horizontal, Brand.Space.xl)
            .padding(.vertical, Brand.Space.xxl)
            .frame(maxWidth: Brand.readableWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear(perform: runEntrance)
    }

    // MARK: Artwork

    private var side: CGFloat {
        // At accessibility text sizes the mark stops growing so the centred mark leaves room for the text.
        let base = dynamicTypeSize.isAccessibilitySize ? 148 : artworkSide
        return horizontalSizeClass == .regular ? base * 1.2 : base
    }

    /// The app's mark: the icon's three overlapping swatches, drawn in code.
    private var artwork: some View {
        OpaliteMark(layerProgress: layers)
    }

    // MARK: Entrance

    private func runEntrance() {
        guard !Self.hasPlayedEntrance else { return }
        Self.hasPlayedEntrance = true
        guard !reduceMotion else {
            layers = [1, 1, 1]
            showsText = true
            showsButton = true
            return
        }
        // Back to front, 0.18 s apart, each with a small spring settle.
        for index in layers.indices {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.72).delay(0.18 * Double(index))) {
                layers[index] = 1
            }
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.78)) { showsText = true }
        withAnimation(.easeOut(duration: 0.35).delay(0.95)) { showsButton = true }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Splash") {
    SplashView(onContinue: {})
}
#endif
#endif
