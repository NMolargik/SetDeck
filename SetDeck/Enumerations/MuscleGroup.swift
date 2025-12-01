//
//  MuscleGroup.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/7/25.
//

import Foundation

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, shoulders, triceps
    case back, lats, traps, biceps, forearms
    case quads, hamstrings, glutes, calves
    case abs, obliques, lowerBack
    case neck, serratus, rotatorCuff
    case fullBody, cardio

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lats: return "Lats"
        case .traps: return "Traps"
        case .lowerBack: return "Lower Back"
        case .rotatorCuff: return "Rotator Cuff"
        case .fullBody: return "Full Body"
        default: return rawValue.capitalized
        }
    }
}
