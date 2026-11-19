//
//  OnboardingStep.swift
//  SetDeckCore
//
//  The paged introduction after the splash, in order. Pure navigation logic so the
//  onboarding view model is host-testable.
//

import Foundation

nonisolated public enum OnboardingStep: Int, CaseIterable, Sendable, Identifiable {
    case privacy
    case health
    case builder
    case complete

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .privacy: return "Your Privacy"
        case .health: return "Health Access"
        case .builder: return "Build Your Deck"
        case .complete: return "You're All Set"
        }
    }

    // MARK: Navigation

    public var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
    public var previous: OnboardingStep? { OnboardingStep(rawValue: rawValue - 1) }
    public var isFirst: Bool { self == Self.allCases.first }
    public var isLast: Bool { self == Self.allCases.last }

    /// 1-based position, for "Step 2 of 4".
    public var pageNumber: Int { rawValue + 1 }
    public static var pageCount: Int { allCases.count }

    /// Fraction complete including this page (0.25 … 1.0).
    public var progress: Double { Double(pageNumber) / Double(Self.pageCount) }
}
