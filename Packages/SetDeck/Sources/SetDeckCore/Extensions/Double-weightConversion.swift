//
//  Double-weightConversion.swift
//  SetDeckCore
//

import Foundation

extension Double {
    private static let lbsToKgFactor: Double = 0.45359237

    /// Converts pounds to kilograms
    public var poundsToKilograms: Double {
        self * Self.lbsToKgFactor
    }

    /// Returns weight in the specified unit system
    public func weight(useMetric: Bool) -> Double {
        useMetric ? poundsToKilograms : self
    }
}
