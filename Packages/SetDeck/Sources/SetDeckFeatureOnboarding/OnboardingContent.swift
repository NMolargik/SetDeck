//
//  OnboardingContent.swift
//  SetDeckFeatureOnboarding
//
//  The copy, symbols and tints for each `OnboardingStep`. Plain data, shared by the page
//  views. Strings are `LocalizedStringKey`s so they resolve in the app target's catalog
//  (the English literal is the key, so existing translations keep working).
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem

// MARK: - Feature

/// One row on an onboarding page.
struct OnboardingFeature: Identifiable {
    let symbol: String
    let tint: Color
    let title: LocalizedStringKey
    let detail: LocalizedStringKey?

    var id: String { symbol }
}

// MARK: - Hero

/// The big symbol tile with a title and subtitle at the top of a page.
struct OnboardingHeroContent {
    let symbol: String
    let tint: Color
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
}

// MARK: - Pages

enum OnboardingContent {
    static func tint(for step: OnboardingStep) -> Color {
        switch step {
        case .privacy: .purpleStart
        case .health: .blueStart
        case .builder: .greenStart
        case .complete: .greenStart
        }
    }

    /// The hero for a step. The health page changes with the authorization state.
    static func hero(for step: OnboardingStep, healthAuthorized: Bool = false, healthDenied: Bool = false) -> OnboardingHeroContent {
        switch step {
        case .privacy:
            OnboardingHeroContent(
                symbol: "lock.shield.fill",
                tint: .purpleStart,
                title: "Your Privacy Matters",
                subtitle: "SetDeck is designed to keep your data private and secure."
            )
        case .health:
            if healthAuthorized {
                OnboardingHeroContent(
                    symbol: "checkmark.circle.fill",
                    tint: .greenStart,
                    title: "Health Connected",
                    subtitle: "Your water intake, calorie intake, and workout history are now connected!"
                )
            } else if healthDenied {
                OnboardingHeroContent(
                    symbol: "heart.slash.fill",
                    tint: .orangeStart,
                    title: "Access Denied",
                    subtitle: "Enable Health access in Settings to log water, calories, and workouts."
                )
            } else {
                OnboardingHeroContent(
                    symbol: "heart.fill",
                    tint: .pink,
                    title: "Connect Health",
                    subtitle: "Allow access to log water, calories, and workouts."
                )
            }
        case .builder:
            OnboardingHeroContent(
                symbol: "figure.strengthtraining.traditional",
                tint: .greenStart,
                title: "Build Your Routines",
                subtitle: "Add at least one exercise to continue"
            )
        case .complete:
            OnboardingHeroContent(
                symbol: "checkmark.circle.fill",
                tint: .greenStart,
                title: "You're All Set!",
                subtitle: "Here's what you can do with SetDeck"
            )
        }
    }

    static func features(for step: OnboardingStep) -> [OnboardingFeature] {
        switch step {
        case .privacy:
            [
                OnboardingFeature(symbol: "iphone", tint: .blueStart, title: "On-Device Storage",
                                  detail: "Your routines stay on your device and in your personal iCloud."),
                OnboardingFeature(symbol: "person.fill.questionmark", tint: .orangeStart, title: "Only What You Log",
                                  detail: "SetDeck only tracks the workouts, water, and calories you log."),
                OnboardingFeature(symbol: "checkmark.shield.fill", tint: .greenStart, title: "Your Eyes Only",
                                  detail: "Your health data stays solely in your possession."),
            ]
        case .health:
            [
                OnboardingFeature(symbol: "drop.halffull", tint: .blueStart, title: "Track Water",
                                  detail: "Track your water intake over time."),
                OnboardingFeature(symbol: "flame.fill", tint: .orangeStart, title: "Track Calories",
                                  detail: "Keep track of calories in and out."),
                OnboardingFeature(symbol: "figure.strengthtraining.traditional", tint: .greenStart, title: "Watch Your Workouts",
                                  detail: "See workout history and log strength training sessions."),
            ]
        case .builder:
            []
        case .complete:
            [
                OnboardingFeature(symbol: "figure.strengthtraining.traditional", tint: .greenStart, title: "Crush every set", detail: nil),
                OnboardingFeature(symbol: "icloud.fill", tint: .blueStart, title: "Sync progress across devices", detail: nil),
                OnboardingFeature(symbol: "chart.line.uptrend.xyaxis", tint: .purpleStart, title: "View trends over time", detail: nil),
                OnboardingFeature(symbol: "drop.fill", tint: .blueStart, title: "Closely track water consumption", detail: nil),
                OnboardingFeature(symbol: "flame.fill", tint: .orangeStart, title: "Track calories in and out", detail: nil),
            ]
        }
    }
}
#endif
