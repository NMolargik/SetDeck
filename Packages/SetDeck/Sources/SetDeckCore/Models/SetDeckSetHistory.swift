//
//  SetDeckSetHistory.swift
//  SetDeckCore
//
//  Created by Nick Molargik on 11/7/25.
//

import Foundation
import SwiftData

@Model
public final class SetDeckSetHistory {
    public var uuid: UUID = UUID()

    public var completedDate: Date = Date()

    public var actualReps: Int?
    public var actualWeight: Double?
    public var actualWeightUnit: String?
    public var actualDuration: TimeInterval?
    public var actualDescription: String?
    public var actualRpe: Int?
    public var note: String?

    // INVERSE: points back to SetDeckSet.history
    @Relationship(inverse: \SetDeckSet.history)
    public var set: SetDeckSet?

    public init(uuid: UUID = UUID(),
         completedDate: Date = Date(),
         actualReps: Int? = nil,
         actualWeight: Double? = nil,
         actualWeightUnit: String? = nil,
         actualDuration: TimeInterval? = nil,
         actualDescription: String? = nil,
         actualRpe: Int? = nil,
         note: String? = nil) {
        self.uuid = uuid
        self.completedDate = completedDate
        self.actualReps = actualReps
        self.actualWeight = actualWeight
        self.actualWeightUnit = actualWeightUnit
        self.actualDuration = actualDuration
        self.actualDescription = actualDescription
        self.actualRpe = actualRpe
        self.note = note
    }
}
