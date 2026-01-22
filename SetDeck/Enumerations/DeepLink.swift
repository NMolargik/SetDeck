//
//  DeepLink.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/21/26.
//

import Foundation

/// Deep link actions that can be triggered from widgets or external URLs
enum DeepLink: Equatable {
    case routine
    case stats
    case settings
}
