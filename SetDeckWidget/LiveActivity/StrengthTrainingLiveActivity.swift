//
//  StrengthTrainingLiveActivity.swift
//  SetDeckWidget
//
//  Created by Nick Molargik on 1/9/26.
//

import ActivityKit
import SwiftUI
import WidgetKit
import SetDeckServices

struct StrengthTrainingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StrengthTrainingActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundStyle(.purpleStart)
                        Text("Workout")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    WorkoutTimerText(state: context.state)
                        .font(.title2.monospacedDigit())
                        .fontWeight(.semibold)
                        .foregroundStyle(.blueStart)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 20) {
                        if let rest = context.state.restEndDate, rest > Date() {
                            RestCountdownRow(endDate: rest, nextSetLabel: context.state.nextSetLabel)
                        } else if context.state.isPaused {
                            Label("Paused", systemImage: "pause.fill")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        } else {
                            Label("Active", systemImage: "bolt.fill")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.purpleStart)
            } compactTrailing: {
                if let rest = context.state.restEndDate, rest > Date() {
                    Text(timerInterval: Date()...rest, countsDown: true)
                        .font(.caption.monospacedDigit())
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: 44)
                } else {
                WorkoutTimerText(state: context.state)
                    .font(.caption.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundStyle(context.state.isPaused ? .orange : .blueStart)
                }
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.purpleStart)
            }
        }
    }
}

// MARK: - Lock Screen View
struct LockScreenView: View {
    let context: ActivityViewContext<StrengthTrainingActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purpleStart, .blueStart],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Strength Training")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 8) {
                    if let rest = context.state.restEndDate, rest > Date() {
                        RestCountdownRow(endDate: rest, nextSetLabel: context.state.nextSetLabel)
                    } else if context.state.isPaused {
                        Image(systemName: "pause.fill")
                            .foregroundStyle(.orange)
                        Text("Paused")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    } else {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.green)
                        Text("In Progress")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Timer
            WorkoutTimerText(state: context.state)
                .font(.title.monospacedDigit())
                .fontWeight(.bold)
                .foregroundStyle(context.state.isPaused ? .orange : .blueStart)
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.8))
    }
}

// MARK: - Rest countdown (mirrors the Apple Watch rest timer)
struct RestCountdownRow: View {
    let endDate: Date
    let nextSetLabel: String?

    var body: some View {
        // Text(timerInterval:) greedily takes all available width, so in the old single HStack it
        // was squeezed by the "Next:" label ("1:––" / "Next: B…"). Give it a fixed-width slot on
        // its own line, with the label underneath.
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
                Text(timerInterval: Date()...endDate, countsDown: true)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 64, alignment: .leading)
            }
            if let nextSetLabel {
                Text("Next: \(nextSetLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

// MARK: - Timer Text
struct WorkoutTimerText: View {
    let state: StrengthTrainingActivityAttributes.ContentState

    var body: some View {
        if state.isPaused {
            // Show static elapsed time when paused
            Text(formatElapsed(elapsedTime))
        } else {
            // Use Text timer for live updates when active
            Text(timerInterval: state.startDate.addingTimeInterval(state.accumulatedPause)...Date.distantFuture, countsDown: false)
        }
    }

    private var elapsedTime: TimeInterval {
        let now = Date()
        var elapsed = now.timeIntervalSince(state.startDate)
        elapsed -= state.accumulatedPause
        if let pauseDate = state.lastPauseDate {
            // Currently paused, don't count time since pause started
            elapsed -= now.timeIntervalSince(pauseDate)
        }
        return max(0, elapsed)
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Previews
#Preview("Lock Screen", as: .content, using: StrengthTrainingActivityAttributes()) {
    StrengthTrainingLiveActivity()
} contentStates: {
    StrengthTrainingActivityAttributes.ContentState(
        startDate: Date().addingTimeInterval(-300),
        accumulatedPause: 0,
        lastPauseDate: nil,
        isPaused: false
    )
    StrengthTrainingActivityAttributes.ContentState(
        startDate: Date().addingTimeInterval(-600),
        accumulatedPause: 60,
        lastPauseDate: Date(),
        isPaused: true
    )
    StrengthTrainingActivityAttributes.ContentState(
        startDate: Date().addingTimeInterval(-900),
        accumulatedPause: 0,
        lastPauseDate: nil,
        isPaused: false,
        restEndDate: Date().addingTimeInterval(75),
        nextSetLabel: "Bench Press · 3/4"
    )
}
