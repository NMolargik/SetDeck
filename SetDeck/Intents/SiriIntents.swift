//
//  SiriIntents.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/9/26.
//
//  Siri & Shortcuts integration for querying workout information.
//

import AppIntents
import SwiftData
import HealthKit

// MARK: - Shared Container for App Intents

/// Provides access to the SwiftData model container from App Intents
@MainActor
enum IntentModelContainer {
    static let shared: ModelContainer = {
        let cloudKitContainerID = "iCloud.com.molargiksoftware.SetDeck"

        do {
            let config = ModelConfiguration(
                cloudKitDatabase: .private(cloudKitContainerID)
            )

            return try ModelContainer(
                for:
                    SetDeckExercise.self,
                    SetDeckRoutine.self,
                    SetDeckSet.self,
                    SetDeckSetHistory.self,
                configurations: config
            )
        } catch {
            fatalError("[SetDeck Intent] Failed to initialize ModelContainer: \(error)")
        }
    }()
}

// MARK: - Day of Week Enum for Siri

enum WorkoutDay: String, AppEnum {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Day of Week"
    }

    static var caseDisplayRepresentations: [WorkoutDay: DisplayRepresentation] {
        [
            .sunday: "Sunday",
            .monday: "Monday",
            .tuesday: "Tuesday",
            .wednesday: "Wednesday",
            .thursday: "Thursday",
            .friday: "Friday",
            .saturday: "Saturday"
        ]
    }

    var dayIndex: Int {
        switch self {
        case .sunday: return 0
        case .monday: return 1
        case .tuesday: return 2
        case .wednesday: return 3
        case .thursday: return 4
        case .friday: return 5
        case .saturday: return 6
        }
    }

    static func from(dayIndex: Int) -> WorkoutDay {
        switch dayIndex {
        case 0: return .sunday
        case 1: return .monday
        case 2: return .tuesday
        case 3: return .wednesday
        case 4: return .thursday
        case 5: return .friday
        case 6: return .saturday
        default: return .sunday
        }
    }
}

// MARK: - Get Today's Workout Intent

/// "Hey Siri, what's my workout today?"
struct GetTodayWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "What's My Workout Today"
    static let description = IntentDescription("Get your scheduled workout for today")

    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let todayIndex = getTodayDayIndex()
        let dayName = WorkoutDay.from(dayIndex: todayIndex).rawValue

        let exercises = await fetchExercises(forDay: todayIndex)

        if exercises.isEmpty {
            return .result(dialog: "You don't have any exercises scheduled for \(dayName). Open SetDeck to add some exercises to your routine.")
        }

        let exerciseList = exercises.map { $0.name }.joined(separator: ", ")
        let setCount = exercises.reduce(0) { $0 + ($1.sets?.count ?? 0) }

        return .result(dialog: "Your \(dayName) workout has \(exercises.count) exercises with \(setCount) total sets: \(exerciseList)")
    }

    private func getTodayDayIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday - 1 + 7) % 7
    }

    @MainActor
    private func fetchExercises(forDay day: Int) async -> [SetDeckExercise] {
        let context = IntentModelContainer.shared.mainContext

        let predicate = #Predicate<SetDeckExercise> { ex in
            ex.routine?.day == day
        }
        let descriptor = FetchDescriptor<SetDeckExercise>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }
}

// MARK: - Get Workout for Specific Day Intent

/// "Hey Siri, what's my workout on Monday?"
struct GetWorkoutForDayIntent: AppIntent {
    static let title: LocalizedStringResource = "What's My Workout On"
    static let description = IntentDescription("Get your scheduled workout for a specific day")

    static let openAppWhenRun: Bool = false

    @Parameter(title: "Day")
    var day: WorkoutDay

    static var parameterSummary: some ParameterSummary {
        Summary("What's my workout on \(\.$day)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let exercises = await fetchExercises(forDay: day.dayIndex)

        if exercises.isEmpty {
            return .result(dialog: "You don't have any exercises scheduled for \(day.rawValue). Open SetDeck to add some exercises to your routine.")
        }

        let exerciseList = exercises.map { $0.name }.joined(separator: ", ")
        let setCount = exercises.reduce(0) { $0 + ($1.sets?.count ?? 0) }

        return .result(dialog: "Your \(day.rawValue) workout has \(exercises.count) exercises with \(setCount) total sets: \(exerciseList)")
    }

    @MainActor
    private func fetchExercises(forDay day: Int) async -> [SetDeckExercise] {
        let context = IntentModelContainer.shared.mainContext

        let predicate = #Predicate<SetDeckExercise> { ex in
            ex.routine?.day == day
        }
        let descriptor = FetchDescriptor<SetDeckExercise>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }
}

// MARK: - Get Workout Status Intent

/// "Hey Siri, am I working out?"
struct GetWorkoutStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Am I Working Out"
    static let description = IntentDescription("Check if you have an active workout session")

    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthManager()
        await healthManager.requestAuthorization()

        if healthManager.isWorkoutOngoing {
            if let startDate = healthManager.workoutStartDate {
                let duration = Date().timeIntervalSince(startDate)
                let minutes = Int(duration / 60)

                if healthManager.workoutState == .paused {
                    return .result(dialog: "Your workout is paused. You've been at it for \(minutes) minutes so far.")
                } else {
                    return .result(dialog: "Yes, you have a workout in progress. You started \(minutes) minutes ago.")
                }
            } else {
                return .result(dialog: "Yes, you have a workout in progress.")
            }
        } else {
            return .result(dialog: "No, you're not currently working out. Say 'Start my workout' to begin.")
        }
    }
}

// MARK: - Get Exercise Count Intent

/// "Hey Siri, how many exercises do I have today?"
struct GetExerciseCountIntent: AppIntent {
    static let title: LocalizedStringResource = "How Many Exercises Today"
    static let description = IntentDescription("Get the number of exercises in today's workout")

    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let todayIndex = getTodayDayIndex()
        let dayName = WorkoutDay.from(dayIndex: todayIndex).rawValue

        let exercises = await fetchExercises(forDay: todayIndex)

        if exercises.isEmpty {
            return .result(dialog: "You don't have any exercises scheduled for \(dayName).")
        }

        let warmupCount = exercises.filter { $0.isWarmup }.count
        let mainCount = exercises.count - warmupCount
        let setCount = exercises.reduce(0) { $0 + ($1.sets?.count ?? 0) }

        if warmupCount > 0 {
            return .result(dialog: "You have \(exercises.count) exercises today: \(warmupCount) warm-up and \(mainCount) main exercises, with \(setCount) total sets.")
        } else {
            return .result(dialog: "You have \(exercises.count) exercises today with \(setCount) total sets.")
        }
    }

    private func getTodayDayIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday - 1 + 7) % 7
    }

    @MainActor
    private func fetchExercises(forDay day: Int) async -> [SetDeckExercise] {
        let context = IntentModelContainer.shared.mainContext

        let predicate = #Predicate<SetDeckExercise> { ex in
            ex.routine?.day == day
        }
        let descriptor = FetchDescriptor<SetDeckExercise>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }
}

// MARK: - App Shortcuts Provider

struct SetDeckShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetTodayWorkoutIntent(),
            phrases: [
                "What's my workout today in \(.applicationName)",
                "What's my \(.applicationName) workout",
                "Show my workout in \(.applicationName)",
                "What exercises do I have in \(.applicationName)"
            ],
            shortTitle: "Today's Workout",
            systemImageName: "figure.strengthtraining.traditional"
        )

        AppShortcut(
            intent: GetWorkoutForDayIntent(),
            phrases: [
                "What's my workout on \(\.$day) in \(.applicationName)",
                "What's my \(\.$day) workout in \(.applicationName)",
                "Show my \(\.$day) workout in \(.applicationName)"
            ],
            shortTitle: "Workout for Day",
            systemImageName: "calendar"
        )

        AppShortcut(
            intent: GetWorkoutStatusIntent(),
            phrases: [
                "Am I working out in \(.applicationName)",
                "Is my workout active in \(.applicationName)",
                "Check my workout status in \(.applicationName)"
            ],
            shortTitle: "Workout Status",
            systemImageName: "heart.fill"
        )

        AppShortcut(
            intent: StartWorkoutIntent(),
            phrases: [
                "Start my workout in \(.applicationName)",
                "Begin workout in \(.applicationName)",
                "Start \(.applicationName) workout"
            ],
            shortTitle: "Start Workout",
            systemImageName: "play.fill"
        )

        AppShortcut(
            intent: StopWorkoutIntent(),
            phrases: [
                "Stop my workout in \(.applicationName)",
                "End workout in \(.applicationName)",
                "Finish \(.applicationName) workout"
            ],
            shortTitle: "Stop Workout",
            systemImageName: "stop.fill"
        )

        AppShortcut(
            intent: GetExerciseCountIntent(),
            phrases: [
                "How many exercises do I have in \(.applicationName)",
                "How many exercises today in \(.applicationName)",
                "Count my exercises in \(.applicationName)"
            ],
            shortTitle: "Exercise Count",
            systemImageName: "number"
        )
    }
}
