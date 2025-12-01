//
//  SetType.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/7/25.
//

import Foundation

enum SetType: String, Codable, CaseIterable, Identifiable {
    case reps, amap, duration, freeform
    
    var id: String { rawValue }
}
