//
//  SplashView.swift
//  SetDeckComposition
//
//  The landing page on a fresh install: the app mark, the name, one line of value and a
//  single "Get Started", on the same dark backdrop as the introduction that follows. The
//  mark is the launch storyboard's image at the same size and the exact centre of the
//  screen, so launch → splash hands off in place; then the brand glow, the title and the
//  button fade up (Reduce Motion shows everything at once). Where a vertical hinge divides
//  the window (unfolded iPhone Duo) the mark takes the leading pane and the text and button
//  the trailing pane, so nothing sits in the fold.
//

#if os(iOS)
import SwiftUI
import SetDeckDesignSystem
import SetDeckFeatureOnboarding

struct SplashView: View {
    let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var buttonTop: CGFloat = .greatestFiniteMagnitude
    @State private var textHeight: CGFloat = 0

    @State private var showsGlow = SplashView.hasPlayedEntrance
    @State private var showsText = SplashView.hasPlayedEntrance
    @State private var showsButton = SplashView.hasPlayedEntrance

    /// The entrance runs once per launch, not again when the splash is shown again.
    private static var hasPlayedEntrance = false

    /// The launch storyboard's image sizes (compact / regular width). Keep in sync with
    /// `SetDeck/LaunchScreen.storyboard`.
    private static let compactMarkSide: CGFloat = 196
    private static let regularMarkSide: CGFloat = 235

    var body: some View {
        ZStack {
            OnboardingBackdrop(glow: .greenStart, showsGlow: showsGlow)

            GeometryReader { proxy in
                let foldX = proxy.hasFoldIfAvailable ? proxy.foldCenterXIfAvailable : nil
                if let foldX, proxy.size.width >= 600 {
                    foldedLayout(size: proxy.size, foldX: foldX, isFoldActive: proxy.isFoldActiveIfAvailable)
                } else {
                    flatLayout(size: proxy.size, trailingInset: LayoutProbe.isVerticalBar(proxy.safeAreaInsets) ? proxy.safeAreaInsets.trailing : 0)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear(perform: runEntrance)
    }

    // MARK: Flat layout (iPhone, iPad, folded Duo)

    private func flatLayout(size: CGSize, trailingInset: CGFloat) -> some View {
        // The Duo's vertical bar takes the trailing edge: centre in what is left of it.
        let usable = size.width - trailingInset
        let side = markSide
        let textTop = size.height / 2 + side / 2 + Brand.Space.xxl
        let textRoom = max(0, buttonTop - textTop - Brand.Space.md)

        return ZStack {
            // The exact centre of the full screen: where the launch storyboard centres its image.
            mark
                .frame(width: side, height: side)
                .position(x: usable / 2, y: size.height / 2)

            titleBlock
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { textHeight = $0 }
                // Between the centred mark and the button there is only so much room: at very
                // large text sizes the block scales down rather than running into the button.
                .scaleEffect(textHeight > textRoom && textHeight > 0 ? textRoom / textHeight : 1, anchor: .top)
                .opacity(showsText ? 1 : 0)
                .offset(y: showsText ? 0 : 10)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, textTop)
                .padding(.horizontal, Brand.Space.xl)
                .frame(width: usable)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                startButton
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { buttonTop = $0 }
                    .padding(.bottom, Brand.Space.lg)
            }
            .padding(.horizontal, Brand.Space.xl)
            .padding(.vertical, Brand.Space.xxl)
            .frame(maxWidth: 520)
            .frame(width: usable)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    // MARK: Folded layout (unfolded Duo)

    private func foldedLayout(size: CGSize, foldX: CGFloat, isFoldActive: Bool) -> some View {
        let gap = isFoldActive ? Brand.Space.xxl * 2 : Brand.Space.xxl
        let leadingWidth = max(0, foldX - gap / 2)
        let trailingWidth = max(0, size.width - foldX - gap / 2)
        let side = min(markSide, leadingWidth * 0.8)

        return HStack(spacing: 0) {
            mark
                .frame(width: side, height: side)
                .frame(width: leadingWidth, height: size.height)

            Color.clear.frame(width: gap)

            VStack(spacing: Brand.Space.xl) {
                titleBlock
                    .opacity(showsText ? 1 : 0)
                    .offset(y: showsText ? 0 : 10)
                startButton
            }
            .padding(.horizontal, Brand.Space.lg)
            .frame(width: trailingWidth, height: size.height)
        }
    }

    // MARK: Pieces

    private var mark: some View {
        Image("icon")
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }

    private var titleBlock: some View {
        VStack(spacing: Brand.Space.md) {
            Text("SetDeck")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text("make gains every week")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Brand.Space.lg)
        .accessibilityElement(children: .combine)
    }

    private var startButton: some View {
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
            .foregroundStyle(Color.black.opacity(0.88))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Brand.Space.lg)
            .background(
                RoundedRectangle(cornerRadius: Brand.Radius.control, style: .continuous)
                    .fill(Color.greenStart)
            )
            .shadow(color: Color.greenStart.opacity(0.28), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.defaultAction)
        .accessibilityIdentifier("continueButton")
        .accessibilityHint("Begins the introduction")
        .opacity(showsButton ? 1 : 0)
        .offset(y: showsButton ? 0 : 10)
    }

    /// The launch image's size, so the hand-off doesn't jump. At accessibility text sizes the
    /// mark stops growing; it never exceeds what the storyboard draws.
    private var markSide: CGFloat {
        let regular = horizontalSizeClass == .regular
        let base = regular ? Self.regularMarkSide : Self.compactMarkSide
        return dynamicTypeSize.isAccessibilitySize ? min(base, Self.compactMarkSide) : base
    }

    // MARK: Entrance

    private func runEntrance() {
        guard !Self.hasPlayedEntrance else { return }
        Self.hasPlayedEntrance = true
        guard !reduceMotion else {
            showsGlow = true
            showsText = true
            showsButton = true
            return
        }
        withAnimation(.easeOut(duration: 0.8)) { showsGlow = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) { showsText = true }
        withAnimation(.easeOut(duration: 0.35).delay(0.5)) { showsButton = true }
    }
}

#if DEBUG
#Preview("Splash") {
    SplashView(onContinue: {})
        .colorScheme(.dark)
}
#endif
#endif
