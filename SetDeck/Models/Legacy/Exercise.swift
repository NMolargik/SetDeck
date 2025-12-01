//
//  Exercise.swift
//  SetDeck
//
//  Created by Nick Molargik on 4/17/24.
//

import Foundation
import SwiftData

@Model
class Exercise: Identifiable {
    var id: UUID = UUID()
    var weekday: Int = 0
    var orderIndex: Int = 0
    var name: String = "Unnamed Exercise"
    @Relationship(deleteRule: .cascade)
    var exerciseSets: [ExerciseSet]? = []

    init(id: UUID = UUID(), weekday: Int = 0, orderIndex: Int = 0, name: String = "Unnamed Exercise") {
        self.id = id
        self.weekday = weekday
        self.orderIndex = orderIndex
        self.name = name
    }
}

extension ModelContext {
    func delete(exercise: Exercise) {
        for eset in exercise.exerciseSets ?? [] {
            self.delete(eset)
        }
        self.delete(exercise)
    }
}
