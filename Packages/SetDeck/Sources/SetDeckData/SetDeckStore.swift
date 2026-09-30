//
//  SetDeckStore.swift
//  SetDeckData
//
//  Builds the SwiftData container, degrading gracefully when CloudKit is unavailable:
//  CloudKit-synced → local-only → in-memory (the old app assumed iCloud and had no
//  fallback). No fatalError short of a machine that can't allocate memory.
//

import Foundation
import SwiftData
import SetDeckCore
import os

public enum SetDeckStore {

    public static let cloudKitContainerID = "iCloud.com.molargiksoftware.SetDeck"

    public static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            SetDeckRoutine.self,
            SetDeckExercise.self,
            SetDeckSet.self,
            SetDeckSetHistory.self,
        ])

        if inMemory {
            do {
                let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: memory)
            } catch {
                fatalError("Failed to create an in-memory ModelContainer: \(error)")
            }
        }

        do {
            let cloud = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private(cloudKitContainerID)
            )
            return try ModelContainer(for: schema, configurations: cloud)
        } catch {
            Log.app.error("CloudKit container unavailable, falling back to local store: \(error.localizedDescription)")
        }

        do {
            let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, configurations: local)
        } catch {
            Log.app.fault("Local store unavailable, falling back to in-memory: \(error.localizedDescription)")
        }

        do {
            let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: memory)
        } catch {
            fatalError("Failed to create even an in-memory ModelContainer: \(error)")
        }
    }
}
