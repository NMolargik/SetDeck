//
//  MigrationView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import Foundation
import SwiftUI
import SwiftData

struct MigrationView: View {
    @Environment(ExerciseManager.self) private var exerciseManager: ExerciseManager
    
    var migrationComplete: () -> Void = {}

    @State private var migrationManager: MigrationManager? = nil
    @State private var isRunning = false
        
    private var status: MigrationStatus { migrationManager?.status ?? .idle }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.03, green: 0.10, blue: 0.22),
                        Color(red: 0.01, green: 0.03, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Running A Quick Check...")
                            .font(.title3.weight(.semibold))
                        Group {
                            switch status {
                            case .completed:
                                Text("All set! Your workouts have been migrated to SetDeck from Ready, Set!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            case .failed(_):
                                Text("We couldn’t complete the migration. Please retry while connected to the internet.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            default:
                                Text("One sec! We’re moving your Ready, Set workouts to over to SetDeck!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Status / Progress
                    Group {
                        switch status {
                        case .idle:
                            HStack(spacing: 8) {
                                ProgressView().scaleEffect(0.9)
                                Text("Preparing…")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        case .preparing(let msg):
                            HStack(spacing: 8) {
                                ProgressView().scaleEffect(0.9)
                                Text(msg)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        case .running(let msg, let p):
                            VStack(alignment: .leading, spacing: 8) {
                                Text(msg)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                ProgressView(value: p)
                                    .progressViewStyle(.linear)
                                    .tint(.blueStart)
                                    .animation(.default, value: p)
                            }
                        case .completed:
                            Label("Migration complete.", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.greenStart)
                        case .failed(let reason):
                            Label(reason, systemImage: "xmark.octagon.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    Group {
                        switch status {
                        case .running(_, let p):
                            ProgressView(value: p)
                                .progressViewStyle(.linear)
                                .tint(.blueStart)
                                .animation(.default, value: p)
                        case .idle, .preparing:
                            ProgressView()
                        case .completed, .failed:
                            EmptyView()
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding()
                .navigationTitle("Migration")
                .navigationBarTitleDisplayMode(.large)
                .onAppear {
                    if migrationManager == nil {
                        migrationManager = MigrationManager(context: exerciseManager.context)
                    }
                }
                .onChange(of: status) { _, newStatus in
                    switch newStatus {
                    case .completed, .failed(_):
                        migrationComplete()
                    default:
                        break
                    }
                }
            }
            .task {
                await performMigration()
            }
        }
    }
    
    func performMigration() async {
        guard !isRunning else { return }
        if migrationManager == nil {
            migrationManager = MigrationManager(context: exerciseManager.context)
        }
        guard let migrationManager else { return }
        isRunning = true
        defer { isRunning = false }
        do {
            try await migrationManager.performMigration()
            switch status {
            case .completed, .failed(_):
                migrationComplete()
            default:
                break
            }
        } catch {
            migrationManager.status = .failed(error.localizedDescription)
            migrationComplete()
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Exercise.self,
             SetDeckExercise.self,
             SetDeckRoutine.self,
             SetDeckSet.self,
             SetDeckSetHistory.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let previewExerciseManager = ExerciseManager(context: container.mainContext)
    MigrationView()
        .modelContainer(container)
        .environment(previewExerciseManager)
}
