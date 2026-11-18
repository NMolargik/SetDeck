//
//  SplashView.swift
//  MygraComposition
//
//  The first screen on a fresh install: the Mygra mark, the name, one line of value, and a
//  single "Get Started", on the plain grouped background. The mark sits where the launch
//  storyboard centres it, so the launch screen hands off in place; then the title and the
//  button fade up. Reduce Motion shows everything at once. On an iPhone Duo with a hinge
//  (unfolded) the mark takes the leading half and the text and button the trailing half, so
//  nothing sits in the fold.
//

#if os(iOS)
import SwiftUI
import MygraDesignSystem

struct SplashView: View {
    let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var probe = LayoutProbe()
    @State private var trailingInset: CGFloat = 0
    @State private var buttonTop: CGFloat = .greatestFiniteMagnitude
    @State private var textHeight: CGFloat = 0

    @State private var showsMark = SplashView.hasPlayedEntrance
    @State private var showsText = SplashView.hasPlayedEntrance
    @State private var showsButton = SplashView.hasPlayedEntrance

    /// The entrance runs once per launch, not again when the splash is shown again.
    private static var hasPlayedEntrance = false

    @ScaledMetric(relativeTo: .largeTitle) private var artworkSide: CGFloat = 180

    var body: some View {
        ZStack {
            groupedBackground.ignoresSafeArea()

            GeometryReader { proxy in
                if let foldX = probe.foldCenterX, probe.hasFold {
                    foldedLayout(size: proxy.size, foldX: foldX)
                } else {
                    flatLayout(size: proxy.size)
                }
            }
            .ignoresSafeArea()
        }
        .containerLayoutProbe { probe = $0 }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.trailing } action: { trailingInset = $0 }
        .onAppear(perform: runEntrance)
    }

    // MARK: Flat layout (iPhone, iPad, folded Duo)

    private func flatLayout(size: CGSize) -> some View {
        // The Duo's vertical bar takes the trailing edge: centre in what is left of it.
        let usable = size.width - (probe.hasVerticalBar ? trailingInset : 0)
        let side = markSide(height: size.height)
        let textTop = size.height / 2 + side / 2 + Brand.Space.xxl
        let textRoom = max(0, buttonTop - textTop - Brand.Space.md)

        return ZStack {
            // The mark sits at the exact centre of the full screen, the point the launch
            // storyboard centres its image on.
            mark
                .frame(width: side, height: side)
                .position(x: usable / 2, y: size.height / 2)

            titleBlock
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { textHeight = $0 }
                // Between the centred mark and the button there is only so much room: at very
                // large text sizes the block scales down to fit rather than running into the button.
                .scaleEffect(textHeight > textRoom && textHeight > 0 ? textRoom / textHeight : 1, anchor: .top)
                .opacity(showsText ? 1 : 0)
                .offset(y: showsText ? 0 : 10)
                .frame(maxWidth: Brand.readableWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, textTop)
                .padding(.horizontal, Brand.Space.xl)
                .frame(width: usable)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                startButton
                    .padding(.bottom, Brand.Space.lg)
            }
            .padding(.horizontal, Brand.Space.xl)
            .padding(.vertical, Brand.Space.xxl)
            .frame(maxWidth: Brand.readableWidth)
            .frame(width: usable)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    // MARK: Folded layout (unfolded Duo)

    private func foldedLayout(size: CGSize, foldX: CGFloat) -> some View {
        let gap = Brand.Space.xxl
        let leadingWidth = max(0, foldX - gap)
        let trailingWidth = max(0, size.width - foldX - gap)
        let side = min(artworkSide, leadingWidth * 0.7)

        return HStack(spacing: 0) {
            mark
                .frame(width: side, height: side)
                .frame(width: leadingWidth, height: size.height)

            Spacer(minLength: 0)

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
        MygraMark(isRevealed: showsMark)
            .accessibilityLabel("Mygra")
            .accessibilityHidden(true)
    }

    private var titleBlock: some View {
        VStack(spacing: Brand.Space.md) {
            Text("Mygra")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text("A calm journal for your migraines.")
                .font(.title3)
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
            .frame(maxWidth: .infinity)
        }
        .primaryActionButton()
        .keyboardShortcut(.defaultAction)
        .accessibilityIdentifier("continueButton")
        .accessibilityHint("Begins the introduction")
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { buttonTop = $0 }
        .opacity(showsButton ? 1 : 0)
        .offset(y: showsButton ? 0 : 10)
    }

    private func markSide(height: CGFloat) -> CGFloat {
        // At accessibility text sizes the mark stops growing; on a short window (the folded
        // Duo) it leaves room for the text under it.
        let base = dynamicTypeSize.isAccessibilitySize ? 180 : artworkSide
        let scaled = horizontalSizeClass == .regular ? base * 1.2 : base
        return min(scaled, height * 0.27)
    }

    // MARK: Entrance

    private func runEntrance() {
        #if DEBUG
        // Simulator verification: `-MygraOnboardingStep N` skips straight to that page.
        if UserDefaults.standard.object(forKey: "MygraOnboardingStep") != nil {
            onContinue()
            return
        }
        #endif
        guard !Self.hasPlayedEntrance else { return }
        Self.hasPlayedEntrance = true
        guard !reduceMotion else {
            showsMark = true
            showsText = true
            showsButton = true
            return
        }
        // The mark animates itself (halo segments, then head, then shoulders, about a second).
        showsMark = true
        withAnimation(.easeOut(duration: 0.4).delay(0.9)) { showsText = true }
        withAnimation(.easeOut(duration: 0.35).delay(1.1)) { showsButton = true }
    }
}

#if DEBUG
#Preview {
    SplashView(onContinue: {})
}
#endif
#endif
