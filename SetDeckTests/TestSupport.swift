//
//  TestSupport.swift
//  SetDeckTests
//
//  Created by Nick Molargik on 6/14/26.
//

import Foundation
import SwiftData
@testable import SetDeck

enum TestSupport {
    /// Creates a fresh SwiftData container backed by a unique on-disk store in
    /// the temporary directory.
    ///
    /// `isStoredInMemoryOnly` containers all share the same `/dev/null` SQLite
    /// identity. When Swift Testing runs suites in parallel, CoreData's
    /// connection manager throws an Objective-C exception (`SIGABRT` inside
    /// `-[NSSQLDefaultConnectionManager handleStoreRequest:]`) that takes down
    /// the whole test host — making every test "fail" in 0.000s. A unique
    /// on-disk store per container avoids the collision.
    static func makeContainer() throws -> ModelContainer {
        let storeURL = URL.temporaryDirectory.appending(path: "setdeck-test-\(UUID().uuidString).store")
        let configuration = ModelConfiguration(url: storeURL)
        return try ModelContainer(
            for: SetDeckRoutine.self,
            SetDeckExercise.self,
            SetDeckSet.self,
            SetDeckSetHistory.self,
            configurations: configuration
        )
    }
}
