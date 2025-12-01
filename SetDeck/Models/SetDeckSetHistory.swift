//
//  SetDeckSetHistory.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/7/25.
//

import Foundation
import SwiftData

@Model
final class SetDeckSetHistory {
    var uuid: UUID = UUID()

    var completedDate: Date = Date()

    var actualReps: Int?
    var actualWeight: Double?
    var actualWeightUnit: String?
    var actualDuration: TimeInterval?
    var actualDescription: String?
    var actualRpe: Int?
    var note: String?

    // INVERSE: points back to SetDeckSet.history
    @Relationship(inverse: \SetDeckSet.history)
    var set: SetDeckSet?

    init(uuid: UUID = UUID(),
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
