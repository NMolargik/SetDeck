//
//  RestTimerView.swift
//  SetDeck Watch App
//
//  Created by Nick Molargik on 1/9/26.
//
//  Rest timer between sets with haptic feedback.
//

import SwiftUI

struct RestTimerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDuration: TimeInterval = 60
    @State private var remainingTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var timer: Timer?

    let presets: [TimeInterval] = [30, 60, 90, 120, 180]

    var body: some View {
        VStack(spacing: 12) {
            if isRunning {
                runningTimerView
            } else {
                durationPickerView
            }
        }
        .padding()
        .navigationTitle("Rest Timer")
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Duration Picker
    private var durationPickerView: some View {
        VStack(spacing: 16) {
            Text("Rest Duration")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Preset buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { duration in
                        Button(action: {
                            selectedDuration = duration
                            WatchHaptics.selectionChanged()
                        }) {
                            Text(formatDuration(duration))
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedDuration == duration ? Color.blue : Color.secondary.opacity(0.3))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Digital Crown adjustment
            Text(formatDuration(selectedDuration))
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .focusable()
                .digitalCrownRotation(
                    $selectedDuration,
                    from: 10,
                    through: 300,
                    by: 5,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )

            Button(action: startTimer) {
                Label("Start", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
    }

    // MARK: - Running Timer
    private var runningTimerView: some View {
        VStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                VStack(spacing: 4) {
                    Text(formatDuration(remainingTime))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))

                    Text("remaining")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            HStack(spacing: 16) {
                Button(action: stopTimer) {
                    Image(systemName: "xmark")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button(action: addTime) {
                    Image(systemName: "plus.circle")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Timer State
    private var progress: CGFloat {
        guard selectedDuration > 0 else { return 0 }
        return CGFloat(remainingTime / selectedDuration)
    }

    private var timerColor: Color {
        if remainingTime <= 3 {
            return .red
        } else if remainingTime <= 10 {
            return .orange
        } else {
            return .blue
        }
    }

    // MARK: - Timer Control
    private func startTimer() {
        remainingTime = selectedDuration
        isRunning = true
        WatchHaptics.buttonTapped()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            tick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func addTime() {
        remainingTime += 30
        selectedDuration += 30
        WatchHaptics.selectionChanged()
    }

    private func tick() {
        guard remainingTime > 0 else {
            timerComplete()
            return
        }

        remainingTime -= 1

        // Haptic feedback at key moments
        if remainingTime == 10 {
            WatchHaptics.restTimerWarning()
        } else if remainingTime <= 3 && remainingTime > 0 {
            WatchHaptics.restTimerCountdown()
        }
    }

    private func timerComplete() {
        stopTimer()
        WatchHaptics.restTimerDone()

        // Auto-dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            dismiss()
        }
    }

    // MARK: - Formatting
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}

#Preview {
    RestTimerView()
}
