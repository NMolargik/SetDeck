//
//  CloudSyncStatusTests.swift
//  SetDeckServicesTests
//

import Foundation
import Testing
@testable import SetDeckServices

@Suite("CloudSyncManager status")
@MainActor
struct CloudSyncStatusTests {

    @Test("status presentation maps every case")
    func statusPresentation() {
        #expect(CloudSyncManager.SyncStatus.idle.systemImage == "icloud")
        #expect(CloudSyncManager.SyncStatus.syncing.systemImage == "arrow.triangle.2.circlepath.icloud")
        #expect(CloudSyncManager.SyncStatus.synced(Date()).systemImage == "checkmark.icloud")
        #expect(CloudSyncManager.SyncStatus.error("x").systemImage == "exclamationmark.icloud")
        #expect(CloudSyncManager.SyncStatus.offline.systemImage == "icloud.slash")
        #expect(CloudSyncManager.SyncStatus.error("boom").displayText.contains("boom"))
    }

    @Test("waitForRemoteChange returns immediately when a change already arrived")
    func waitReturnsImmediately() async {
        let manager = CloudSyncManager()
        // No change received and iCloud unavailable in tests → false fast.
        let result = await manager.waitForRemoteChange(timeout: 0.1)
        #expect(result == false)
    }
}
