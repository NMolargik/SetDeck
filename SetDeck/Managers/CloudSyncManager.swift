//
//  CloudSyncManager.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/21/26.
//

import Foundation
import SwiftData
import CoreData
import Network

/// Manages and monitors iCloud/CloudKit sync status for SwiftData
@MainActor @Observable
final class CloudSyncManager {

    // MARK: - Sync Status

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced(Date)
        case error(String)
        case offline

        var displayText: String {
            switch self {
            case .idle:
                return "Ready"
            case .syncing:
                return "Syncing..."
            case .synced(let date):
                return "Last synced \(date.formatted(.relative(presentation: .named)))"
            case .error(let message):
                return "Error: \(message)"
            case .offline:
                return "Offline"
            }
        }

        var systemImage: String {
            switch self {
            case .idle:
                return "icloud"
            case .syncing:
                return "arrow.triangle.2.circlepath.icloud"
            case .synced:
                return "checkmark.icloud"
            case .error:
                return "exclamationmark.icloud"
            case .offline:
                return "icloud.slash"
            }
        }

        var color: String {
            switch self {
            case .idle:
                return "secondary"
            case .syncing:
                return "blue"
            case .synced:
                return "green"
            case .error:
                return "red"
            case .offline:
                return "orange"
            }
        }
    }

    // MARK: - Properties

    private(set) var syncStatus: SyncStatus = .idle
    private(set) var isSyncing: Bool = false
    private(set) var lastSyncDate: Date?
    private(set) var hasReceivedRemoteChange: Bool = false

    private var modelContext: ModelContext?
    private var networkMonitor: NWPathMonitor?
    private var isNetworkAvailable: Bool = true
    private var notificationObservers: [Any] = []
    private var remoteChangeContinuations: [CheckedContinuation<Void, Never>] = []

    // MARK: - Initialization

    init() {}

    func configure(with context: ModelContext) {
        self.modelContext = context
        startMonitoring()
    }

    func cleanup() {
        stopMonitoring()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        // Monitor network status
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            let isAvailable = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.handleNetworkChange(isAvailable: isAvailable)
            }
        }
        monitor.start(queue: DispatchQueue(label: "CloudSyncNetworkMonitor"))
        self.networkMonitor = monitor

        // Monitor CloudKit sync events
        let remoteChangeObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                self?.handleRemoteChange()
            }
        }
        notificationObservers.append(remoteChangeObserver)

        // Monitor import/export events from CloudKit
        let importObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSPersistentStoreCoordinatorStoresDidChange"),
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                self?.handleStoreChange()
            }
        }
        notificationObservers.append(importObserver)

        // Set initial status
        updateSyncStatus()
    }

    private func stopMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil

        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers.removeAll()
    }

    // MARK: - Event Handlers

    private func handleNetworkChange(isAvailable: Bool) {
        isNetworkAvailable = isAvailable
        updateSyncStatus()
    }

    private func handleRemoteChange() {
        lastSyncDate = Date()
        hasReceivedRemoteChange = true
        updateSyncStatus()

        // Resume any waiting continuations
        let continuations = remoteChangeContinuations
        remoteChangeContinuations.removeAll()
        for continuation in continuations {
            continuation.resume()
        }
    }

    private func handleStoreChange() {
        lastSyncDate = Date()
        updateSyncStatus()
    }

    private func updateSyncStatus() {
        if !isNetworkAvailable {
            syncStatus = .offline
        } else if isSyncing {
            syncStatus = .syncing
        } else if let lastSync = lastSyncDate {
            syncStatus = .synced(lastSync)
        } else {
            syncStatus = .idle
        }
    }

    // MARK: - Manual Sync

    /// Triggers a manual sync by saving the context and refreshing
    func triggerSync() async {
        guard isNetworkAvailable else {
            syncStatus = .offline
            return
        }

        guard let context = modelContext else {
            syncStatus = .error("Not configured")
            return
        }

        isSyncing = true
        syncStatus = .syncing

        do {
            // Save any pending changes to trigger sync
            if context.hasChanges {
                try context.save()
            }

            // Small delay to allow CloudKit sync to initiate
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Mark sync as complete
            lastSyncDate = Date()
            isSyncing = false
            syncStatus = .synced(lastSyncDate!)

        } catch {
            isSyncing = false
            syncStatus = .error(error.localizedDescription)
        }
    }

    /// Checks if iCloud is available on this device
    var isCloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    // MARK: - Initial Sync Waiting

    /// Waits for a remote change notification or timeout, whichever comes first.
    /// Returns `true` if a remote change was received, `false` if timed out.
    func waitForRemoteChange(timeout: TimeInterval) async -> Bool {
        // If we've already received a remote change, return immediately
        if hasReceivedRemoteChange {
            return true
        }

        // If iCloud isn't available, don't wait
        guard isCloudAvailable && isNetworkAvailable else {
            return false
        }

        // Race between remote change notification and timeout
        return await withTaskGroup(of: Bool.self) { group in
            // Task 1: Wait for remote change notification
            group.addTask { @MainActor in
                await withCheckedContinuation { continuation in
                    self.remoteChangeContinuations.append(continuation)
                }
                return true
            }

            // Task 2: Timeout
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return false
            }

            // Return the first result (either remote change or timeout)
            let result = await group.next() ?? false

            // Cancel remaining tasks
            group.cancelAll()

            // Clean up any pending continuations if we timed out
            if !result {
                await MainActor.run {
                    self.remoteChangeContinuations.removeAll()
                }
            }

            return result
        }
    }

    /// Resets the remote change tracking (useful for testing or re-checking)
    func resetRemoteChangeTracking() {
        hasReceivedRemoteChange = false
    }
}
