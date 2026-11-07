//
//  RestTimerView.swift
//  SetDeck Watch App
//
//  Rest timer between sets. Starts automatically when a set is logged; this tab lets you
//  pick the default rest length, start one by hand, extend or skip it. State lives in
//  WatchWorkoutSession so it keeps counting (and taps your wrist) with the screen dimmed.
//

import SwiftUI
import SetDeckCore

struct RestTimerView: View {
    @Environment(WatchWorkoutSession.self) private var session

    let presets: [TimeInterval] = [30, 60, 90, 120, 180]

    var body: some View {
        VStack(spacing: 12) {
            if let rest = session.rest {
                runningTimerView(rest)
            } else {
                durationPickerView
            }
        }
        .padding()
        .navigationTitle("Rest Timer")
    }

    // MARK: - Duration Picker
    private var durationPickerView: some View {
        @Bindable var session = session
        return VStack(spacing: 12) {
            Text("Rest after each set")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { duration in
                        Button {
                            session.restDuration = duration
                            WatchHaptics.selectionChanged()
                        } label: {
                            Text(formatDuration(duration))
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(session.restDuration == duration ? Color.blue : Color.secondary.opacity(0.3))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Digital Crown adjustment
            Text(formatDuration(session.restDuration))
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .focusable()
                .digitalCrownRotation(
                    $session.restDuration,
                    from: 10,
                    through: 300,
                    by: 5,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )

            Button {
                session.startRest(duration: session.restDuration)
                WatchHaptics.buttonTapped()
            } label: {
                Label("Start Now", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
    }

    // MARK: - Running Timer
    private func runningTimerView(_ rest: WatchRestTimer) -> some View {
        VStack(spacing: 12) {
            Text(timerInterval: Date()...rest.endDate, countsDown: true)
                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.orange)
            ProgressView(timerInterval: Date()...rest.endDate, countsDown: true) { EmptyView() } currentValueLabel: { EmptyView() }
                .tint(.orange)
            if let next = session.nextSet {
                Text("Next: \(next.label)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 16) {
                Button { session.skipRest() } label: {
                    Image(systemName: "xmark").frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button { session.extendRest() } label: {
                    Image(systemName: "plus.circle").frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Formatting
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return minutes > 0 ? String(format: "%d:%02d", minutes, seconds) : "\(seconds)s"
    }
}

#Preview {
    RestTimerView().environment(WatchWorkoutSession.shared)
}
