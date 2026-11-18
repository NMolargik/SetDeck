//
//  OnboardingView.swift
//  SetDeckFeatureOnboarding
//
//  The paged introduction after the splash (privacy → Health → routine builder → done),
//  in the same structure as the splash: a hero (tinted symbol tile, title, one line), the
//  page's content, and a primary action pinned at the bottom with a quiet secondary row.
//  Single column on iPhone and iPad portrait. Where a vertical hinge divides the window
//  (unfolded iPhone Duo) or an iPad is wide, the hero takes the leading pane and the
//  content and actions the trailing pane, so nothing sits in the fold.
//

#if os(iOS)
import SwiftUI
import UIKit
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared
import SetDeckServices

public struct OnboardingView: View {
    @Environment(HealthManager.self) private var healthManager
    @Environment(WorkoutDataModel.self) private var workoutData
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let onFinished: () -> Void

    @State private var model = OnboardingViewModel()
    @State private var didConfigure = false

    public init(onFinished: @escaping () -> Void = {}) {
        self.onFinished = onFinished
    }

    public var body: some View {
        ZStack {
            OnboardingBackdrop(glow: OnboardingContent.tint(for: model.step))
                .animation(.easeInOut(duration: 0.4), value: model.step)

            GeometryReader { proxy in
                let metrics = OnboardingMetrics(proxy)
                layout(metrics)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .id(model.step)
                    .transition(pageTransition)
            }
        }
        .onAppear(perform: configure)
        .onChange(of: model.step) { _, step in
            Haptics.selection()
            AccessibilityNotification.Announcement("Step \(step.pageNumber) of \(OnboardingStep.pageCount): \(step.title)").post()
        }
    }

    // MARK: Layout

    @ViewBuilder
    private func layout(_ metrics: OnboardingMetrics) -> some View {
        let step = model.step
        VStack(spacing: 0) {
            column(metrics) { progressBar.padding(.horizontal, Brand.Space.xl).padding(.top, Brand.Space.sm) }

            if step == .builder {
                OnboardingBuilderPage()
            } else {
                column(metrics) {
                    OnboardingCenteredScroll {
                        VStack(spacing: Brand.Space.xl) {
                            if !metrics.isTwoPane {
                                hero(compact: metrics.size.height < 700)
                            }
                            details
                        }
                        .padding(.horizontal, Brand.Space.xl)
                        .padding(.vertical, Brand.Space.lg)
                    }
                }
            }

            column(metrics) {
                actionBar
                    .padding(.horizontal, Brand.Space.xl)
                    .padding(.bottom, Brand.Space.sm)
            }
        }
        .overlay(alignment: .leading) {
            if metrics.isTwoPane && step != .builder {
                hero(compact: false, isLarge: true)
                    .padding(.horizontal, Brand.Space.xl)
                    .frame(width: metrics.leadingWidth, height: metrics.size.height)
            }
        }
    }

    /// Single column: centred at a readable width. Two panes: the trailing pane only.
    private func column<V: View>(_ metrics: OnboardingMetrics, @ViewBuilder _ content: () -> V) -> some View {
        let built = content()
        return Group {
            if metrics.isTwoPane {
                HStack(spacing: 0) {
                    Color.clear.frame(width: metrics.leadingWidth + metrics.gutter)
                    built.frame(width: metrics.trailingWidth)
                }
            } else {
                built
                    .frame(maxWidth: OnboardingMetrics.columnWidth)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Pieces

    private func hero(compact: Bool, isLarge: Bool = false) -> some View {
        let content = OnboardingContent.hero(
            for: model.step,
            healthAuthorized: healthManager.isAuthorized,
            healthDenied: !healthManager.isAuthorized && healthManager.lastError != nil
        )
        return OnboardingHero(content: content, isLarge: isLarge, showsTile: !compact)
    }

    @ViewBuilder
    private var details: some View {
        let features = OnboardingContent.features(for: model.step)
        if !features.isEmpty {
            OnboardingFeatureList(features: features, showsChecks: model.step == .complete)
        }
    }

    private var progressBar: some View {
        HStack(spacing: Brand.Space.sm) {
            ForEach(OnboardingStep.allCases) { step in
                Capsule(style: .continuous)
                    .fill(step.rawValue <= model.step.rawValue ? AnyShapeStyle(Color.greenStart) : AnyShapeStyle(Color.white.opacity(0.18)))
                    .frame(height: 4)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: model.step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(model.step.pageNumber) of \(OnboardingStep.pageCount)")
        .accessibilityValue(model.step.title)
    }

    // MARK: Actions

    private var healthRequested: Bool { OnboardingViewModel.hasRequestedHealth(healthManager) }
    private var healthDenied: Bool { !healthManager.isAuthorized && healthManager.lastError != nil }

    private var primaryTitle: LocalizedStringKey {
        switch model.step {
        case .health where !healthRequested: "Connect Health"
        case .complete: "Enter SetDeck"
        default: "Continue"
        }
    }

    private var actionBar: some View {
        VStack(spacing: Brand.Space.xs) {
            Button(action: primaryTapped) {
                HStack(spacing: Brand.Space.sm) {
                    if model.isRequestingPermission {
                        ProgressView().tint(.black)
                    } else {
                        Text(primaryTitle)
                        if !model.isLastStep {
                            Image(systemName: "arrow.right").accessibilityHidden(true)
                        }
                    }
                }
            }
            .buttonStyle(OnboardingPrimaryButtonStyle())
            .disabled(!model.canContinue(workoutData: workoutData))
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("continueButton")

            // A fixed-height row so the primary button never jumps between pages.
            HStack {
                if model.canGoBack {
                    Button("Back", action: goBack)
                        .buttonStyle(OnboardingSecondaryButtonStyle())
                        .accessibilityIdentifier("backButton")
                }
                Spacer(minLength: 0)
                contextualAction
            }
            .frame(minHeight: 44)
        }
    }

    @ViewBuilder
    private var contextualAction: some View {
        if model.step == .health {
            if healthDenied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(OnboardingSecondaryButtonStyle())
            } else if !healthRequested && !model.isRequestingPermission {
                Button("Not now") { slide(.forward) { model.next() } }
                    .buttonStyle(OnboardingSecondaryButtonStyle())
                    .accessibilityHint("Continues without connecting Health")
            }
        }
    }

    private func primaryTapped() {
        Haptics.mediumImpact()
        switch model.step {
        case .health where !healthRequested:
            Task { await model.requestHealthAccess(healthManager) }
        case .complete:
            onFinished()
        default:
            slide(.forward) { model.next() }
        }
    }

    private func goBack() {
        slide(.backward) { model.previous() }
    }

    // MARK: Transitions

    private var pageTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        let forward = model.direction == .forward
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private var pageAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.86)
    }

    /// Commits the direction first so the outgoing page slides the right way, then animates.
    private func slide(_ direction: OnboardingViewModel.Direction, _ change: @escaping () -> Void) {
        model.direction = direction
        Task { @MainActor in
            withAnimation(pageAnimation) { change() }
        }
    }

    private func configure() {
        guard !didConfigure else { return }
        didConfigure = true
        #if DEBUG
        model.applyDebugStep(from: ProcessInfo.processInfo.arguments)
        #endif
    }
}
#endif
