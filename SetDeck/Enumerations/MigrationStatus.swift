//
//  MigrationStatus.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import Foundation

enum MigrationStatus: Equatable {
    case idle
    case preparing(String)
    case running(String, Double) // message, progress 0...1
    case completed
    case failed(String)
}
