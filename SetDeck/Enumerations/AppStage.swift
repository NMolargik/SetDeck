//
//  AppStage.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/7/25.
//

import Foundation

enum AppStage: String, Identifiable {
    case start
    case splash
    case migration
    case onboarding
    case main
    
    var id: String { self.rawValue }
}
