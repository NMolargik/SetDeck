//
//  SetType.swift
//  SetDeckCore
//
//  Created by Nick Molargik on 11/7/25.
//

import Foundation

nonisolated public enum SetType: String, Codable, CaseIterable, Identifiable, Sendable {
    case reps, amap, duration, freeform
    
    public var id: String { rawValue }
}
