//
//  WorkoutCompletionHandler.swift
//  SetDeckFeatureHealth
//
//  Reacts to `HealthManager.lastCompletedWorkout`: presents the shareable summary card and
//  asks for an App Store review at the milestones `ReviewPromptPolicy` allows (first and
//  twentieth completed workout, at most once per version). Applied at the tab shell so it
//  fires no matter which tab the workout was stopped from.
//

#if os(iOS)
import SwiftUI
import StoreKit
import SetDeckCore
import SetDeckServices

public extension View {
    /// Shows a summary sheet (with `ShareLink`) and the review prompt after each completed workout.
    func workoutCompletionHandling() -> some View {
        modifier(WorkoutCompletionHandler())
    }
}

private struct WorkoutCompletionHandler: ViewModifier {
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @Environment(\.requestReview) private var requestReview
    @State private var presentedSummary: WorkoutSummary?

    private let policy = ReviewPromptPolicy()

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: healthManager.lastCompletedWorkout) { _, summary in
                guard let summary else { return }
                presentedSummary = summary
                if policy.recordCompletedWorkout(appVersion: appVersion) {
                    // Let the sheet settle before the system review alert.
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        requestReview()
                    }
                }
            }
            .sheet(item: $presentedSummary) { summary in
                WorkoutCompleteSheet(summary: summary)
                    .presentationDetents([.medium])
                    .colorScheme(.dark)
            }
    }
}

struct WorkoutCompleteSheet: View {
    let summary: WorkoutSummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Nice work!")
                    .font(.title.bold())
                WorkoutSummaryCardView(summary: summary)
                WorkoutSummaryShareLink(summary: summary)
                    .buttonStyle(.borderedProminent)
                    .tint(.greenStart)
                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("Workout Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
#endif
