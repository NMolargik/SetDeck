//
//  DeepLink.swift
//  SetDeckCore
//
//  Created by Nick Molargik on 1/21/26.
//

import Foundation

/// Deep link actions that can be triggered from widgets, App Intents, or
/// external URLs of the form `setdeck://<host>`.
nonisolated public enum DeepLink: String, Equatable, CaseIterable, Sendable {
    case routine
    case stats
    case health
    case settings
    /// Opens the app to the routine tab with the Edit Routine sheet presented.
    case editRoutine

    /// The custom URL scheme handled by the app.
    public static let scheme = "setdeck"

    /// Parses a `setdeck://routine` style URL into a deep link, or returns nil
    /// for unrecognized schemes/hosts. Kept pure so it can be unit-tested.
    public init?(url: URL) {
        guard url.scheme == Self.scheme, let host = url.host() else { return nil }
        guard let link = DeepLink(rawValue: host) else { return nil }
        self = link
    }

    /// The canonical URL that opens this destination.
    public var url: URL {
        URL(string: "\(Self.scheme)://\(rawValue)")!
    }
}
