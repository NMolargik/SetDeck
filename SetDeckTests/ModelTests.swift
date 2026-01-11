//
//  ModelTests.swift
//  SetDeckTests
//
//  Created by Nick Molargik on 1/11/26.
//

import Foundation
import Testing
import SwiftData
@testable import SetDeck

// MARK: - SetDeckRoutine Tests

@Suite("SetDeckRoutine Tests")
struct SetDeckRoutineTests {

    @Test("init creates routine with correct properties")
    func init_CreatesRoutineWithCorrectProperties() {
        let uuid = UUID()
        let routine = SetDeckRoutine(uuid: uuid, day: 3, lastUpdated: nil)

        #expect(routine.uuid == uuid)
        #expect(routine.day == 3)
        #expect(routine.lastUpdated == nil)
        #expect(routine.exercises == nil)
    }

    @Test("init with defaults generates UUID and date")
    func init_WithDefaultsGeneratesUUIDAndDate() {
        let routine = SetDeckRoutine(day: 5, lastUpdated: Date())

        #expect(routine.day == 5)
        #expect(routine.lastUpdated != nil)
    }

    @Test("sample generates routine with specified parameters")
    func sample_GeneratesRoutineWithSpecifiedParameters() {
        let routine = SetDeckRoutine.sample(seed: 42, day: 2, exerciseCount: 3, setsPerExercise: 2)

        #expect(routine.day == 2)
        #expect(routine.exercises?.count == 3)

        // Each exercise should have 2 sets
        for exercise in routine.exercises ?? [] {
            #expect(exercise.sets?.count == 2)
        }
    }

    @Test("sample with seed produces deterministic results")
    func sample_WithSeedProducesDeterministicResults() {
        let routine1 = SetDeckRoutine.sample(seed: 123, day: 0, exerciseCount: 2, setsPerExercise: 1)
        let routine2 = SetDeckRoutine.sample(seed: 123, day: 0, exerciseCount: 2, setsPerExercise: 1)

        #expect(routine1.exercises?.count == routine2.exercises?.count)

        // Exercise names should match with same seed
        let names1 = routine1.exercises?.map { $0.name } ?? []
        let names2 = routine2.exercises?.map { $0.name } ?? []
        #expect(names1 == names2)
    }

    @Test("samples generates multiple routines")
    func samples_GeneratesMultipleRoutines() {
        let routines = SetDeckRoutine.samples(5, seed: 42, startDay: 0)

        #expect(routines.count == 5)

        // Days should increment from startDay
        for (index, routine) in routines.enumerated() {
            #expect(routine.day == index)
        }
    }
}

// MARK: - SetDeckExercise Tests

@Suite("SetDeckExercise Tests")
struct SetDeckExerciseTests {

    @Test("init creates exercise with correct properties")
    func init_CreatesExerciseWithCorrectProperties() {
        let uuid = UUID()
        let exercise = SetDeckExercise(
            uuid: uuid,
            name: "Squat",
            note: "Focus on depth",
            isWarmup: true,
            equipment: "Barbell",
            orderIndex: 2
        )

        #expect(exercise.uuid == uuid)
        #expect(exercise.name == "Squat")
        #expect(exercise.note == "Focus on depth")
        #expect(exercise.isWarmup == true)
        #expect(exercise.equipment == "Barbell")
        #expect(exercise.orderIndex == 2)
    }

    @Test("sample generates exercise with sets")
    func sample_GeneratesExerciseWithSets() {
        let exercise = SetDeckExercise.sample(seed: 42, setCount: 4)

        #expect(!exercise.name.isEmpty)
        #expect(exercise.sets?.count == 4)
    }

    @Test("samples generates multiple exercises")
    func samples_GeneratesMultipleExercises() {
        let exercises = SetDeckExercise.samples(3, seed: 42, setCount: 2)

        #expect(exercises.count == 3)
        for exercise in exercises {
            #expect(exercise.sets?.count == 2)
        }
    }
}

// MARK: - SetDeckSet Tests

@Suite("SetDeckSet Tests")
struct SetDeckSetTests {

    @Test("init creates set with correct properties")
    func init_CreatesSetWithCorrectProperties() {
        let uuid = UUID()
        let set = SetDeckSet(
            uuid: uuid,
            setType: .reps,
            targetReps: 10,
            weight: 135.0,
            rpe: 7,
            orderIndex: 1
        )

        #expect(set.uuid == uuid)
        #expect(set.setType == .reps)
        #expect(set.targetReps == 10)
        #expect(set.weight == 135.0)
        #expect(set.rpe == 7)
        #expect(set.orderIndex == 1)
    }

    @Test("init with duration type")
    func init_WithDurationType() {
        let set = SetDeckSet(
            setType: .duration,
            targetDuration: 60.0,
            orderIndex: 0
        )

        #expect(set.setType == .duration)
        #expect(set.targetDuration == 60.0)
    }

    @Test("sample generates valid set")
    func sample_GeneratesValidSet() {
        let set = SetDeckSet.sample(seed: 42)

        #expect(set.orderIndex >= 0)
    }

    @Test("samples generates multiple sets")
    func samples_GeneratesMultipleSets() {
        let sets = SetDeckSet.samples(5, seed: 42)

        #expect(sets.count == 5)
    }
}

// MARK: - SetType Tests

@Suite("SetType Tests")
struct SetTypeTests {

    @Test("all set types have string representation")
    func allSetTypesHaveStringRepresentation() {
        #expect(SetType.reps.rawValue == "reps")
        #expect(SetType.amap.rawValue == "amap")
        #expect(SetType.duration.rawValue == "duration")
        #expect(SetType.freeform.rawValue == "freeform")
    }

    @Test("set types are codable")
    func setTypesAreCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for type in [SetType.reps, .amap, .duration, .freeform] {
            let data = try encoder.encode(type)
            let decoded = try decoder.decode(SetType.self, from: data)
            #expect(decoded == type)
        }
    }
}

// MARK: - SetDeckSetHistory Tests

@Suite("SetDeckSetHistory Tests")
struct SetDeckSetHistoryTests {

    @Test("init creates history with correct properties")
    func init_CreatesHistoryWithCorrectProperties() {
        let uuid = UUID()
        let date = Date()
        let history = SetDeckSetHistory(
            uuid: uuid,
            completedDate: date,
            actualReps: 12,
            actualWeight: 150.0,
            actualRpe: 8
        )

        #expect(history.uuid == uuid)
        #expect(history.completedDate == date)
        #expect(history.actualReps == 12)
        #expect(history.actualWeight == 150.0)
        #expect(history.actualRpe == 8)
        #expect(history.actualDuration == nil)
    }

    @Test("init with duration")
    func init_WithDuration() {
        let history = SetDeckSetHistory(
            completedDate: Date(),
            actualDuration: 120.0
        )

        #expect(history.actualDuration == 120.0)
        #expect(history.actualReps == nil)
    }
}
