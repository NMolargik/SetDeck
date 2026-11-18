//
//  OnboardingViewModel.swift
//  OpaliteFeatureOnboarding
//
//  The paging state behind `OnboardingView`: the current `OnboardingStep`, the direction
//  of the last move (for slide transitions), the display-name draft from the profile
//  page, and the single-shot finish. Host-testable; the view adds the side effects.
//

import Foundation
import Observation
import OpaliteCore

@Observable
final class OnboardingViewModel {
    /// Which way the last page change went, so the view can slide accordingly.
    enum Direction: Sendable {
        case forward
        case backward
    }

    // MARK: State

    private(set) var step: OnboardingStep
    var direction: Direction = .forward
    private(set) var isFinished = false

    /// The display-name draft edited on the profile page (untrimmed).
    var displayName: String

    /// Called exactly once, with the trimmed display name, when the flow finishes.
    var onFinished: (String) -> Void

    // MARK: Init

    init(step: OnboardingStep = .welcome, displayName: String = "", onFinished: @escaping (String) -> Void = { _ in }) {
        self.step = step
        self.displayName = displayName
        self.onFinished = onFinished
    }

    // MARK: Derived

    var page: OnboardingPage { .page(for: step) }
    var pageNumber: Int { step.rawValue + 1 }
    var pageCount: Int { OnboardingStep.allCases.count }
    var progress: Double { step.progress }
    var canGoBack: Bool { !step.isFirst }
    var isLastStep: Bool { step.isLast }

    /// The primary button's title: "Continue" until the last page, then "Done".
    var continueTitle: String {
        isLastStep ? String(localized: "Done") : String(localized: "Continue")
    }

    /// What VoiceOver announces when the page changes.
    var pageAnnouncement: String {
        String(localized: "Page \(pageNumber) of \(pageCount): \(page.title)")
    }

    /// The display name as it will be saved.
    var trimmedDisplayName: String { Self.trimmed(displayName) }

    // MARK: Navigation

    /// Advances one page; on the last page, finishes.
    func next() {
        guard let next = step.next else {
            finish()
            return
        }
        direction = .forward
        step = next
    }

    /// Goes back one page; a no-op on the first page.
    func previous() {
        guard let previous = step.previous else { return }
        direction = .backward
        step = previous
    }

    /// Skips the rest of the flow. Every page is skippable.
    func skip() {
        finish()
    }

    /// Finishes once; later calls are ignored.
    func finish() {
        guard !isFinished else { return }
        isFinished = true
        onFinished(trimmedDisplayName)
    }

    // MARK: Names

    /// Trims surrounding whitespace and newlines; an all-whitespace name becomes empty.
    nonisolated static func trimmed(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The field's prefill: the stored author name, or empty when it is still the
    /// anonymous default so the placeholder shows instead.
    nonisolated static func initialDisplayName(from authorName: String) -> String {
        let trimmed = trimmed(authorName)
        return trimmed == Authorship.anonymous.displayName ? "" : trimmed
    }
}
