//
//  TimeSeriesSample.swift
//  SetDeck
//
//  Created by Nick Molargik on 12/2/25.
//

import Foundation

struct TimeSeriesSample: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let amount: Double
}
