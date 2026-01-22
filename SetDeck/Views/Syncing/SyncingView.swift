//
//  SyncingView.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/21/26.
//

import SwiftUI
import SwiftData

struct SyncingView: View {
    @Environment(ExerciseManager.self) private var exerciseManager
    @Environment(CloudSyncManager.self) private var cloudSyncManager

    @AppStorage(AppStorageKeys.hasCompletedInitialSync) private var hasCompletedInitialSync: Bool = false

    var onSyncComplete: (Bool) -> Void

    @State private var statusMessage: String = "Checking for your data..."
    @State private var hasTimedOut: Bool = false
    @State private var dotCount: Int = 0
    @State private var syncTask: Task<Void, Never>?

    /// Maximum time to wait for sync on fresh install (in seconds)
    private let freshInstallTimeout: TimeInterval = 20

    /// Maximum time to wait for sync on returning user (in seconds)
    private let returningUserTimeout: TimeInterval = 8

    /// How often to poll for data (in seconds)
    private let pollInterval: TimeInterval = 1.5

    /// Animated dots for the loading indicator
    private var animatedDots: String {
        String(repeating: ".", count: dotCount)
    }

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            // Animated edge gradients
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                EdgeGradientsView(time: time)
            }

            // Main content
            VStack(spacing: 24) {
                Spacer()
                
                // iCloud icon with animation
                Image(systemName: "icloud.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, options: .repeating)
                    .accessibilityHidden(true)
                
                VStack(spacing: 12) {
                    Text("SetDeck is Syncing with iCloud")
                        .font(.title2)
                        .bold()
                    
                    Text(statusMessage + animatedDots)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                        .frame(width: 300)
                        .frame(height: 20)
                }
                
                Spacer()
                
                // Progress indicator
                ProgressView()
                    .controlSize(.large)
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            startDotAnimation()
        }
        .onDisappear {
            syncTask?.cancel()
        }
        .task {
            await performSyncWithPolling()
        }
    }
    
    /// Animates the loading dots
    private func startDotAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if hasTimedOut {
                timer.invalidate()
                return
            }
            withAnimation {
                dotCount = (dotCount + 1) % 4
            }
        }
    }

    /// Main sync method that polls for data with appropriate timeout
    private func performSyncWithPolling() async {
        // Use longer timeout for fresh installs where iCloud data may take time to arrive
        let timeout = hasCompletedInitialSync ? returningUserTimeout : freshInstallTimeout

        let deadline = Date().addingTimeInterval(timeout)

        // Initial status
        await MainActor.run {
            statusMessage = hasCompletedInitialSync
                ? "Looking for deliveries"
                : "Syncing with iCloud"
        }

        // Initial refresh
        await exerciseManager.refresh()

        // Check if we already have data
        if checkForData() {
            await completeSync(foundData: true)
            return
        }

        // Wait for remote change notification first (more reliable than just polling)
        // Give iCloud a chance to notify us of incoming data
        let receivedRemoteChange = await cloudSyncManager.waitForRemoteChange(timeout: min(5, timeout / 2))

        if receivedRemoteChange {
            // Remote change received - refresh and check
            await exerciseManager.refresh()

            if checkForData() {
                await completeSync(foundData: true)
                return
            }
        }

        // Poll until deadline or data found
        while Date() < deadline {
            if Task.isCancelled { return }

            // Wait for poll interval
            try? await Task.sleep(for: .seconds(pollInterval))

            // Refresh managers
            await exerciseManager.refresh()

            // Check for data
            if checkForData() {
                await completeSync(foundData: true)
                return
            }

            // Update status message periodically to show progress
            await MainActor.run {
                let remainingSeconds = Int(deadline.timeIntervalSinceNow)
                if remainingSeconds > 5 {
                    statusMessage = "Looking for existing data"
                } else if remainingSeconds > 0 {
                    statusMessage = "Making sure"
                }
            }
        }

        // Timeout reached - complete with whatever we have
        await completeSync(foundData: checkForData())
    }

    /// Checks if we have any delivery data
    private func checkForData() -> Bool {
        return !exerciseManager.allRoutines().isEmpty
    }

    /// Completes the sync process
    private func completeSync(foundData: Bool) async {
        let deliveryCount = exerciseManager.allRoutines().count

        // Mark that we've completed initial sync (for future app launches)
        if foundData && !hasCompletedInitialSync {
            hasCompletedInitialSync = true
        }

        // Print to console for debugging
        print("Sync complete - Found \(deliveryCount) deliveries")

        await MainActor.run {
            hasTimedOut = true
            if deliveryCount > 0 {
                statusMessage = "Found \(deliveryCount) \(deliveryCount == 1 ? "delivery" : "deliveries")!"
            } else {
                statusMessage = "Ready to go!"
            }
        }

        // Brief delay to show success message
        try? await Task.sleep(for: .seconds(0.5))

        await MainActor.run {
            onSyncComplete(foundData)
        }
    }
}

/// Animated gradient overlay for the syncing view edges
private struct EdgeGradientsView: View {
    let time: TimeInterval

    /// Speed multiplier for the pulsing animation (lower = slower)
    private let speed: Double = 2.0

    /// Compute a pulsing opacity value
    private func pulse(_ offset: Double, baseOpacity: Double = 0.35) -> Double {
        let wave = sin(time * speed + offset)
        // Map sin (-1 to 1) to opacity range (0.15 to baseOpacity)
        return baseOpacity * 0.4 + baseOpacity * 0.6 * (wave * 0.5 + 0.5)
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            // Top edge gradient
            EllipticalGradient(
                colors: [
                    Color.greenStart.opacity(pulse(0, baseOpacity: 0.5)),
                    Color.greenEnd.opacity(pulse(1, baseOpacity: 0.4)),
                    Color.clear
                ],
                center: .top,
                startRadiusFraction: 0,
                endRadiusFraction: 0.6
            )
            .frame(height: size.height * 0.5)
            .position(x: size.width / 2, y: 0)
            .blur(radius: 40)

            // Bottom edge gradient
            EllipticalGradient(
                colors: [
                    Color.blueStart.opacity(pulse(2, baseOpacity: 0.45)),
                    Color.blueEnd.opacity(pulse(3, baseOpacity: 0.35)),
                    Color.clear
                ],
                center: .bottom,
                startRadiusFraction: 0,
                endRadiusFraction: 0.6
            )
            .frame(height: size.height * 0.5)
            .position(x: size.width / 2, y: size.height)
            .blur(radius: 40)

            // Left edge gradient
            EllipticalGradient(
                colors: [
                    Color.orangeStart.opacity(pulse(4, baseOpacity: 0.4)),
                    Color.orangeEnd.opacity(pulse(5, baseOpacity: 0.3)),
                    Color.clear
                ],
                center: .leading,
                startRadiusFraction: 0,
                endRadiusFraction: 0.5
            )
            .frame(width: size.width * 0.5)
            .position(x: 0, y: size.height / 2)
            .blur(radius: 30)

            // Right edge gradient
            EllipticalGradient(
                colors: [
                    Color.purpleStart.opacity(pulse(6, baseOpacity: 0.45)),
                    Color.purpleEnd.opacity(pulse(7, baseOpacity: 0.35)),
                    Color.clear
                ],
                center: .trailing,
                startRadiusFraction: 0,
                endRadiusFraction: 0.5
            )
            .frame(width: size.width * 0.5)
            .position(x: size.width, y: size.height / 2)
            .blur(radius: 30)

            // Corner accents - top left
            RadialGradient(
                colors: [
                    Color.greenStart.opacity(pulse(0.5, baseOpacity: 0.35)),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: size.width * 0.4
            )
            .blur(radius: 20)

            // Corner accents - top right
            RadialGradient(
                colors: [
                    Color.blueStart.opacity(pulse(1.5, baseOpacity: 0.3)),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: size.width * 0.35
            )
            .blur(radius: 20)

            // Corner accents - bottom left
            RadialGradient(
                colors: [
                    Color.orangeStart.opacity(pulse(2.5, baseOpacity: 0.3)),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: size.width * 0.35
            )
            .blur(radius: 20)

            // Corner accents - bottom right
            RadialGradient(
                colors: [
                    Color.purpleStart.opacity(pulse(3.5, baseOpacity: 0.35)),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: size.width * 0.4
            )
            .blur(radius: 20)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview("SyncingView") {
    // Build a configured environment for preview without returning Void statements
    let view: some View = {
        // Seed AppStorage for preview scenario
        UserDefaults.standard.set(false, forKey: AppStorageKeys.hasCompletedInitialSync)

        // Create an in-memory SwiftData stack for previews
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: SetDeckRoutine.self,
                 SetDeckExercise.self,
                 SetDeckSet.self,
                 SetDeckSetHistory.self,
            configurations: config
        )
        let context = ModelContext(container)

        // Managers
        let exerciseManager = ExerciseManager(context: context)
        let cloudSyncManager = CloudSyncManager()
        cloudSyncManager.configure(with: context)

        // Seed minimal data so the preview completes quickly
        _ = exerciseManager.routine(for: 1)

        return SyncingView(onSyncComplete: { _ in })
            .environment(exerciseManager)
            .environment(cloudSyncManager)
    }()
    return AnyView(view)
}

