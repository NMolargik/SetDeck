//
//  OnboardingContent.swift
//  OpaliteFeatureOnboarding
//
//  The copy and symbols for each `OnboardingStep`: a hero symbol, a title, a one-line
//  subtitle, and three feature rows. Pure data so it is host-testable and shared by the
//  page views; the profile step carries no feature rows because it is a form.
//

import Foundation
import SwiftUI
import OpaliteCore
import OpaliteDesignSystem

// MARK: - Feature

/// One feature row on an onboarding page.
nonisolated struct OnboardingFeature: Identifiable, Sendable, Equatable {
    let systemImage: String
    let title: String
    let detail: String
    let requiresOnyx: Bool

    var id: String { systemImage + title }

    init(systemImage: String, title: String, detail: String, requiresOnyx: Bool = false) {
        self.systemImage = systemImage
        self.title = title
        self.detail = detail
        self.requiresOnyx = requiresOnyx
    }
}

// MARK: - Page

/// The content of one onboarding page.
nonisolated struct OnboardingPage: Identifiable, Sendable, Equatable {
    let step: OnboardingStep
    let systemImage: String
    let title: String
    let subtitle: String
    let features: [OnboardingFeature]

    var id: OnboardingStep { step }

    /// Whether this page collects input rather than listing features.
    var isForm: Bool { step == .profile }

    /// The page's accent, one of the icon's three colours, so the flow reads as the icon does.
    @MainActor var tint: Color {
        switch step {
        case .welcome, .community: .opalitePurple
        case .portfolio, .profile: .opaliteBlue
        case .canvas: .opaliteTan
        }
    }

    static var all: [OnboardingPage] { OnboardingStep.allCases.map(page(for:)) }

    static func page(for step: OnboardingStep) -> OnboardingPage {
        switch step {
        case .welcome:
            OnboardingPage(
                step: step,
                systemImage: "paintpalette.fill",
                title: String(localized: "Welcome to Opalite"),
                subtitle: String(localized: "Every color you love, captured, organized, and ready to use."),
                features: [
                    OnboardingFeature(
                        systemImage: "eyedropper.halffull",
                        title: String(localized: "Pick colors six ways"),
                        detail: String(localized: "Spectrum, grid, sliders, codes, photos, or a lucky shuffle.")
                    ),
                    OnboardingFeature(
                        systemImage: "eye",
                        title: String(localized: "Check accessibility"),
                        detail: String(localized: "WCAG contrast ratings and color blindness simulation.")
                    ),
                    OnboardingFeature(
                        systemImage: "square.and.arrow.up",
                        title: String(localized: "Export anywhere"),
                        detail: String(localized: "Procreate, Adobe ASE, SwiftUI, CSS, GIMP, and PDF."),
                        requiresOnyx: true
                    ),
                ]
            )
        case .portfolio:
            OnboardingPage(
                step: step,
                systemImage: "swatchpalette.fill",
                title: String(localized: "Build Your Portfolio"),
                subtitle: String(localized: "Group colors into palettes for every brand, project, and mood."),
                features: [
                    OnboardingFeature(
                        systemImage: "rectangle.stack.fill",
                        title: String(localized: "Palettes that grow with you"),
                        detail: String(localized: "Five palettes free, unlimited with Onyx."),
                        requiresOnyx: true
                    ),
                    OnboardingFeature(
                        systemImage: "hand.draw",
                        title: String(localized: "Drag to organize"),
                        detail: String(localized: "Move colors between palettes and reorder with a touch.")
                    ),
                    OnboardingFeature(
                        systemImage: "icloud",
                        title: String(localized: "Private iCloud sync"),
                        detail: String(localized: "Your portfolio follows you to iPhone, iPad, and Mac.")
                    ),
                ]
            )
        case .canvas:
            OnboardingPage(
                step: step,
                systemImage: "pencil.and.outline",
                title: String(localized: "Sketch on the Canvas"),
                subtitle: String(localized: "Try your palette on a drawing surface before it ships."),
                features: [
                    OnboardingFeature(
                        systemImage: "pencil.tip",
                        title: String(localized: "Draw with your colors"),
                        detail: String(localized: "A swatch strip keeps your palette one tap away.")
                    ),
                    OnboardingFeature(
                        systemImage: "square.on.circle",
                        title: String(localized: "Shapes and Apple Pencil"),
                        detail: String(localized: "Place shapes, mockups, and images, then ink over them.")
                    ),
                    OnboardingFeature(
                        systemImage: "doc.on.doc",
                        title: String(localized: "Unlimited canvases"),
                        detail: String(localized: "One canvas free, as many as you like with Onyx."),
                        requiresOnyx: true
                    ),
                ]
            )
        case .community:
            OnboardingPage(
                step: step,
                systemImage: "person.2.fill",
                title: String(localized: "Join the Community"),
                subtitle: String(localized: "Discover colors from other designers and share your own."),
                features: [
                    OnboardingFeature(
                        systemImage: "globe",
                        title: String(localized: "Browse shared work"),
                        detail: String(localized: "Colors and palettes published by people everywhere.")
                    ),
                    OnboardingFeature(
                        systemImage: "arrow.up.circle",
                        title: String(localized: "Publish your creations"),
                        detail: String(localized: "Share a color or a whole palette in a tap.")
                    ),
                    OnboardingFeature(
                        systemImage: "arrow.down.circle",
                        title: String(localized: "Save to your portfolio"),
                        detail: String(localized: "Keep anything you find for your own projects."),
                        requiresOnyx: true
                    ),
                ]
            )
        case .profile:
            OnboardingPage(
                step: step,
                systemImage: "person.crop.circle",
                title: String(localized: "Your Name"),
                subtitle: String(localized: "Choose how you are credited when you publish. You can change it any time in Settings."),
                features: []
            )
        }
    }
}
