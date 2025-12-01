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
    var goalType: GoalType = GoalType.weight
    var repetitionsToDo: Int = 5
    var durationToDo: Int = 10
    var weightToLift: Int = 100
    var timestamp: Date = Date.now

    // Inverse relationship back to Exercise; optional per CloudKit requirement
    @Relationship(inverse: \Exercise.exerciseSets)
    var exercise: Exercise?

    init(goalType: GoalType = .weight, repetitionsToDo: Int = 5, durationToDo: Int = 10, weightToLift: Int = 100, timestamp: Date = .now) {
        self.id = UUID()
        self.goalType = goalType
        self.repetitionsToDo = repetitionsToDo
        self.durationToDo = durationToDo
        self.weightToLift = weightToLift
        self.timestamp = timestamp
    }
}
