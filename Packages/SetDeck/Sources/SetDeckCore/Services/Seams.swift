//
//  Seams.swift
//  SetDeckCore
//
//  Protocol seams over system frameworks so everything above them is testable.
//

import Foundation

// MARK: - Key-value storage

/// The slice of `UserDefaults` the app uses, as a seam so persistence-adjacent logic
/// (achievement celebrations, unit preferences) is testable with an in-memory fake.
nonisolated public protocol KeyValueStoring: AnyObject {
    func data(forKey defaultName: String) -> Data?
    func string(forKey defaultName: String) -> String?
    func array(forKey defaultName: String) -> [Any]?
    func bool(forKey defaultName: String) -> Bool
    func integer(forKey defaultName: String) -> Int
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
}

extension UserDefaults: KeyValueStoring {}

// MARK: - Spotlight indexing

/// Abstraction over Spotlight's semantic index. The concrete indexer lives in the app
/// target (it maps models to `AppEntity` types, which can't live in the package).
@MainActor
public protocol ExerciseIndexing {
    /// Replaces the index contents with entries for the given exercises.
    func reindex(exercises: [SetDeckExercise])
}

