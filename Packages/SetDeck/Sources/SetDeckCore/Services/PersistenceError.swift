//
//  PersistenceError.swift
//  SetDeckCore
//
//  The typed failure for the whole persistence boundary. Repositories and use-cases
//  declare `throws(PersistenceError)` so view models catch a concrete, Equatable error.
//

import Foundation

nonisolated public enum PersistenceError: Error, Equatable, LocalizedError {
    case fetchFailed(String)
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let detail): String(localized: "Couldn't load your workout data. (\(detail))")
        case .saveFailed(let detail): String(localized: "Couldn't save your changes. (\(detail))")
        }
    }
}
