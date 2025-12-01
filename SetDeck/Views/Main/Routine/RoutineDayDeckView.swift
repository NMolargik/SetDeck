//
//  RoutineDayDeckView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/14/25.
//

import SwiftUI
import SwiftData

struct RoutineDayDeckView: View {
    let routine: SetDeckRoutine
    @State private var pageSelection: Int = 0

    private var exercises: [SetDeckExercise] {
        routine.exercises ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                ZStack {
                    if exercises.isEmpty {
                        EmptyDayCardView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        TabView(selection: $pageSelection) {
                            ForEach(Array(exercises.enumerated()), id: \.element.uuid) { (idx, exercise) in
                                ExerciseCardView(index: idx, exercise: exercise)
                                    .frame(width: min(proxy.size.width, max(280, proxy.size.width * 0.92)))
                                    .tag(idx)
                                    .padding(.top)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .onChange(of: exercises.count) { _, newCount in
                            if newCount == 0 {
                                pageSelection = 0
                            } else if pageSelection > newCount - 1 {
                                pageSelection = max(0, newCount - 1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .transition(.move(edge: .leading))

            HStack(spacing: 0) {
                Button(action: {
                    withAnimation(.easeInOut) {
                        if pageSelection != 0 { pageSelection = 0 }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.headline.weight(.semibold))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .tint(.secondary)
                .foregroundStyle(.secondary)
                .opacity(pageSelection > 0 ? 1 : 0.4)
                
                Button(action: {
                    withAnimation(.easeInOut) {
                        if pageSelection > 0 { pageSelection -= 1 }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.semibold))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .tint(.secondary)
                .foregroundStyle(.secondary)
                .opacity(pageSelection > 0 ? 1 : 0.4)
                
                // Progress label after left chevron
                let total = exercises.count
                let current = min(max(pageSelection + 1, 0), max(total, 1))
                if total > 0 {
                    Text("\(current) of \(total)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                }

                Spacer(minLength: 0)

                Button(action: {
                    withAnimation(.easeInOut) {
                        if pageSelection < (exercises.count - 1) { pageSelection += 1 }
                    }
                }) {
                    HStack(spacing: 8) {
                        if pageSelection < (exercises.count - 1) {
                            Text("Next")
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                        }
                        Image(systemName: "chevron.right")
                            .font(.headline.weight(.semibold))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .tint(.secondary)
                .foregroundStyle(.secondary)
                .opacity(pageSelection < (exercises.count - 1) ? 1 : 0.4)
                .disabled(!(pageSelection < (exercises.count - 1)))
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 10)
        }
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([SetDeckRoutine.self, SetDeckExercise.self, SetDeckSet.self, SetDeckSetHistory.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    let exerciseManager = ExerciseManager(context: context)
    
    // Seed one routine per weekday for previewing
    let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    for (_, _) in weekdays.enumerated() {
        let routine = SetDeckRoutine.sample()
        context.insert(routine)
    }
    try? context.save()
    
    return RoutineDayDeckView(routine: SetDeckRoutine.sample())
        .environment(exerciseManager)
        .preferredColorScheme(.dark)
}

