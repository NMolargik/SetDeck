//
//  WorkoutCompletionHandler.swift
//  SetDeckFeatureHealth
//
//  Reacts to `HealthManager.lastCompletedWorkout`: presents the shareable summary card and
//  asks for an App Store review at the milestones `ReviewPromptPolicy` allows (third and
//  tenth completed workout, at most once per version) after the summary sheet is dismissed. Applied at the tab shell so it
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
    /// A review moment is waiting for the summary sheet to be dismissed.
    @State private var isReviewPending = false
    /// Height of the window the sheet appears in; short windows get a full-height sheet.
    @State private var hostHeight: CGFloat = 1000

    private let policy = ReviewPromptPolicy()

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { hostHeight = $0 }
            .onChange(of: healthManager.lastCompletedWorkout) { _, summary in
                guard let summary else { return }
                presentedSummary = summary
                if policy.recordCompletedWorkout(appVersion: appVersion) { isReviewPending = true }
            }
            .sheet(item: $presentedSummary, onDismiss: askForReviewIfPending) { summary in
                WorkoutCompleteSheet(summary: summary)
                    .presentationDetents(hostHeight < 700 ? [.large] : [.medium, .large])
                    .colorScheme(.dark)
            }
    }
}

extension WorkoutCompletionHandler {
    /// The sheet is the sharing moment, so the system alert waits until it has gone.
    private func askForReviewIfPending() {
        guard isReviewPending else { return }
        isReviewPending = false
        let version = appVersion
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            policy.markPrompted(appVersion: version)
            requestReview()
        }
    }
}

struct WorkoutCompleteSheet: View {
    let summary: WorkoutSummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Nice work!")
                        .font(.title.bold())
                        .accessibilityAddTraits(.isHeader)
                    WorkoutSummaryCardView(summary: summary)
                    WorkoutSummaryShareLink(summary: summary)
                        .buttonStyle(.borderedProminent)
                        .tint(.greenStart)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Label("Done", systemImage: "checkmark") }
                }
            }
        }
    }
}
#endif
