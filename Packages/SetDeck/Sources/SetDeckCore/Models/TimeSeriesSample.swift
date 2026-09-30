//
//  TimeSeriesSample.swift
//  SetDeckCore
//
//  Created by Nick Molargik on 12/2/25.
//

import Foundation

public struct TimeSeriesSample: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let date: Date
    public let amount: Double

    public init(date: Date, amount: Double) {
        self.date = date
        self.amount = amount
    }
}
