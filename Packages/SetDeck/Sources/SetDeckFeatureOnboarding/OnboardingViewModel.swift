//
//  OnboardingViewModel.swift
//  SetDeckFeatureOnboarding
//
//  The paging state behind `OnboardingView`: the current step, the direction of the last
//  move (for slide transitions), and the Continue rules (the builder needs one exercise;
//  the health page asks for permission first).
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckFeatureShared
import SetDeckServices

@Observable
final class OnboardingViewModel {
    enum Direction {
        case forward
        case backward
    }

    private(set) var step: OnboardingStep
    var direction: Direction = .forward
    var isRequestingPermission = false

    init(step: OnboardingStep = .privacy) {
        self.step = step
    }

    // MARK: Derived

    var canGoBack: Bool { !step.isFirst && !isRequestingPermission }
    var isLastStep: Bool { step.isLast }

    func canContinue(workoutData: WorkoutDataModel?) -> Bool {
        guard !isRequestingPermission else { return false }
        if step == .builder { return Self.hasAtLeastOneExercise(workoutData) }
        return true
    }

    /// Health was asked for once the user has either granted or declined it.
    static func hasRequestedHealth(_ health: HealthManager) -> Bool {
        health.isAuthorized || health.lastError != nil
    }

    private static func hasAtLeastOneExercise(_ manager: WorkoutDataModel?) -> Bool {
        guard let manager else { return false }
        // Read changeStamp to establish the SwiftUI dependency, so adding an exercise
        // re-evaluates Continue.
        _ = manager.changeStamp
        return (0..<7).contains { !manager.exercises(forDay: $0).isEmpty }
    }

    // MARK: Navigation

    func next() {
        guard let next = step.next else { return }
        direction = .forward
        step = next
    }

    func previous() {
        guard let previous = step.previous else { return }
        direction = .backward
        step = previous
    }

    #if DEBUG
    /// Screenshot affordance: `-duoOnboardingStep 0…3` opens that page.
    func applyDebugStep(from arguments: [String]) {
        guard let i = arguments.firstIndex(of: "-duoOnboardingStep"), i + 1 < arguments.count,
              let n = Int(arguments[i + 1]), let target = OnboardingStep(rawValue: n) else { return }
        step = target
    }
    #endif

    // MARK: Health

    /// Asks for Health access. The page stays put and shows the result; the user then
    /// continues (or opens Settings if it was declined).
    @MainActor
    func requestHealthAccess(_ healthManager: HealthManager) async {
        isRequestingPermission = true
        await healthManager.requestAuthorization()
        isRequestingPermission = false
    }
}
#endif
