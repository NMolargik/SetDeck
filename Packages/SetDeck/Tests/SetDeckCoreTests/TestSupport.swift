//
//  TestSupport.swift
//  SetDeckCoreTests
//
//  Created by Nick Molargik on 6/14/26.
//

import Foundation
import SwiftData
import SetDeckCore

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

/// In-memory `KeyValueStoring` for policy/tracker tests.
final class FakeKeyValueStore: KeyValueStoring {
    private(set) var storage: [String: Any] = [:]

    func data(forKey defaultName: String) -> Data? { storage[defaultName] as? Data }
    func string(forKey defaultName: String) -> String? { storage[defaultName] as? String }
    func array(forKey defaultName: String) -> [Any]? { storage[defaultName] as? [Any] }
    func bool(forKey defaultName: String) -> Bool { storage[defaultName] as? Bool ?? false }
    func integer(forKey defaultName: String) -> Int { storage[defaultName] as? Int ?? 0 }
    func set(_ value: Any?, forKey defaultName: String) { storage[defaultName] = value }
    func removeObject(forKey defaultName: String) { storage.removeValue(forKey: defaultName) }
}
