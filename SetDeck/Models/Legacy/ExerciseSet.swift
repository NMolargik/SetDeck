//
//  ExerciseSet.swift
//  ReadySet
//
//  Created by Nicholas Molargik on 4/10/24.
//

import Foundation
import SwiftData

@Model
class ExerciseSet: Identifiable {
    var id: UUID = UUID()
    var repetitionsToDo: Int = 5
    var durationToDo: Int = 10
    var weightToLift: Int = 100
    var timestamp: Date = Date.now

    // Inverse relationship back to Exercise; optional per CloudKit requirement
    @Relationship(inverse: \Exercise.exerciseSets)
    var exercise: Exercise?

    // goalType removed - was causing deserialization crashes with legacy data
    // Migration now infers type from other properties

    init(repetitionsToDo: Int = 5, durationToDo: Int = 10, weightToLift: Int = 100, timestamp: Date = .now) {
        self.id = UUID()
        self.repetitionsToDo = repetitionsToDo
        self.durationToDo = durationToDo
        self.weightToLift = weightToLift
        self.timestamp = timestamp
    }
}
