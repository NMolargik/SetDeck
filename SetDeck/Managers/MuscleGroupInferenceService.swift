//
//  MuscleGroupInferenceService.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/9/26.
//

import Foundation
import os.log

#if canImport(FoundationModels)
import FoundationModels
#endif

private let logger = Logger(subsystem: "com.molargiksoftware.SetDeck", category: "MuscleGroupInference")

/// Service that uses Apple's Foundation Models framework to infer muscle groups from exercise names.
/// Only available on iOS 26+ devices with on-device model support.
@MainActor
class MuscleGroupInferenceService {
    static let shared = MuscleGroupInferenceService()

    /// Cache of inferred muscle groups to avoid redundant inference
    private var inferenceCache: [String: [MuscleGroup]] = [:]

    /// Check if Foundation Models is available on this device
    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return systemLanguageModelIsAvailable()
        }
        #endif
        return false
    }

    private init() {}

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func systemLanguageModelIsAvailable() -> Bool {
        SystemLanguageModel.default.isAvailable
    }
    #endif

    /// Infer muscle groups for an exercise name using on-device AI
    /// Returns cached result if available, otherwise performs inference
    func inferMuscleGroups(for exerciseName: String) async -> [MuscleGroup] {
        // Check cache first
        let normalizedName = exerciseName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let cached = inferenceCache[normalizedName] {
            return cached
        }

        // Perform inference if available
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            do {
                let result = try await performInference(exerciseName: exerciseName)
                inferenceCache[normalizedName] = result
                logger.info("Inferred muscle groups for '\(exerciseName)': \(result.map { $0.rawValue })")
                return result
            } catch {
                logger.error("Failed to infer muscle groups for '\(exerciseName)': \(error.localizedDescription)")
                return []
            }
        }
        #endif

        return []
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func performInference(exerciseName: String) async throws -> [MuscleGroup] {
        let session = LanguageModelSession()

        let allMuscleGroups = MuscleGroup.allCases
            .filter { $0 != .fullBody && $0 != .cardio }
            .map { $0.rawValue }
            .joined(separator: ", ")

        let prompt = """
        You are a fitness expert. Given an exercise name, identify which muscle groups it primarily targets.

        Available muscle groups: \(allMuscleGroups)

        Exercise: "\(exerciseName)"

        Respond with ONLY a comma-separated list of the 1-3 most relevant muscle groups from the list above. Nothing else.
        Example response: chest, triceps, shoulders
        """

        let response = try await session.respond(to: prompt)
        return parseResponse(response.content)
    }
    #endif

    private func parseResponse(_ response: String) -> [MuscleGroup] {
        let cleaned = response
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let components = cleaned
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var result: [MuscleGroup] = []
        for component in components {
            // Try exact match first
            if let muscle = MuscleGroup(rawValue: component) {
                result.append(muscle)
                continue
            }

            // Try fuzzy matching for common variations
            if let muscle = fuzzyMatch(component) {
                result.append(muscle)
            }
        }

        return Array(Set(result)) // Remove duplicates
    }

    private func fuzzyMatch(_ input: String) -> MuscleGroup? {
        let mappings: [String: MuscleGroup] = [
            "chest": .chest,
            "pecs": .chest,
            "pectorals": .chest,
            "shoulders": .shoulders,
            "delts": .shoulders,
            "deltoids": .shoulders,
            "triceps": .triceps,
            "tris": .triceps,
            "back": .back,
            "upper back": .back,
            "lats": .lats,
            "latissimus": .lats,
            "traps": .traps,
            "trapezius": .traps,
            "biceps": .biceps,
            "bis": .biceps,
            "forearms": .forearms,
            "forearm": .forearms,
            "quads": .quads,
            "quadriceps": .quads,
            "hamstrings": .hamstrings,
            "hams": .hamstrings,
            "glutes": .glutes,
            "gluteus": .glutes,
            "butt": .glutes,
            "calves": .calves,
            "calf": .calves,
            "abs": .abs,
            "abdominals": .abs,
            "core": .abs,
            "obliques": .obliques,
            "lower back": .lowerBack,
            "lowerback": .lowerBack,
            "erectors": .lowerBack,
            "neck": .neck,
            "serratus": .serratus,
            "rotator cuff": .rotatorCuff,
            "rotatorcuff": .rotatorCuff
        ]

        return mappings[input]
    }

    /// Batch infer muscle groups for multiple exercises
    func inferMuscleGroups(for exerciseNames: [String]) async -> [String: [MuscleGroup]] {
        var results: [String: [MuscleGroup]] = [:]

        for name in exerciseNames {
            results[name] = await inferMuscleGroups(for: name)
        }

        return results
    }

    /// Clear the inference cache
    func clearCache() {
        inferenceCache.removeAll()
    }
}
