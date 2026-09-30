<img src="Icons/AppIcon-iOS-Default-1024x1024@1x.png" alt="SetDeck" width="128" height="128">

# SetDeck

A modern strength training and fitness tracking app for iOS and Apple Watch.

## Overview

SetDeck helps you plan and track your weightlifting workouts with flexible weekly routines, detailed exercise configuration, and comprehensive set logging. Built with SwiftUI and SwiftData, it features seamless iCloud sync, HealthKit integration, Live Activities, and a full Apple Watch companion app.

## Features

### Workout Management
- Plan weekly routines across 7 days with customizable exercises
- Exercise library with muscle group assignments, equipment, notes, and video references
- Flexible set types: reps, AMAP (As Many As Possible), duration-based, and freeform
- RPE (Rate of Perceived Exertion) ratings for completed sets
- AI-powered automatic muscle group inference for exercises (on-device, iOS 26+)
- Achievements across consistency, volume, routine, variety, and strength — with confetti

### Health Integration
- **HealthKit Sync**: Read and write workout data, hydration, and calories
- **Strength Training Workouts**: Tracked workout sessions with a Live Activity timer
- **Hydration Tracking**: Monitor daily water intake
- **Calorie Tracking**: View consumed and burned calories

### Apple Watch
- Companion app to view daily routine and log sets from your wrist
- Guided rest timer between sets
- Watch face complication for today's workout
- Start and stop workouts directly from Watch

### Widgets & Live Activities
- **Water Widgets**: Daily hydration in liters or ounces
- **Energy Widget**: Calories consumed and burned
- **Live Activity**: Elapsed workout time on the Lock Screen and Dynamic Island, pause-aware
- **Control Center**: Quick workout toggle (iOS 18+)

### Siri & System Integration
- "What's my workout today?", per-day queries, workout status, and exercise counts
- Start/stop workouts hands-free; donations teach Siri your routine
- Exercises are semantically indexed into Spotlight
- `setdeck://` deep links from widgets, shortcuts, and menu commands
- Localized in English, Spanish, French (Canada), and Japanese

## Requirements

- iOS 18.0+ / watchOS 11.0+
- Xcode 27 beta (Swift 6 language mode)
- Apple Developer account (for CloudKit and HealthKit capabilities)

## Setup

1. Clone the repository
2. **Open `SetDeck.xcworkspace`** (not the bare `.xcodeproj`) — it resolves the local Swift package
3. Configure signing with your Apple Developer account
4. Update bundle identifiers and App Group/iCloud container identifiers
5. Build and run

### Required Capabilities

- iCloud (CloudKit with private database)
- HealthKit (with background delivery)
- App Groups (shared with widgets and watch)
- Siri

## Architecture

SetDeck is a **thin app target on top of an SPM umbrella package** (`Packages/SetDeck`) of layered, single-responsibility modules. Dependencies point inward: features depend on the design system and core; data implements core's protocols; core depends on nothing.

```
SetDeck app / widgets / watch (thin shells)
    └── SetDeckComposition       SessionController (composition root) + RootView/MainView
            ├── SetDeckFeature*  Routine · Stats · Health · Settings · Onboarding
            ├── SetDeckFeatureShared  WorkoutDataModel · AchievementModel (environment-injected)
            ├── SetDeckServices  HealthKit + Live Activities · CloudKit sync · WatchConnectivity · on-device ML
            ├── SetDeckData      SwiftData repositories · CloudKit store with graceful fallback
            ├── SetDeckDesignSystem  brand colors/tokens · glass styles · toast stack
            └── SetDeckCore      models · domain logic · protocols · watch wire DTOs (pure)
```

### Key Components

| Component | Responsibility |
|-----------|---------------|
| `SessionController` | Composition root: builds the dependency graph, owns deep-link routing and Spotlight reindexing |
| `WorkoutDataModel` | Shared data surface for feature views — every read/write goes through a use-case, failures surface as toasts |
| `AchievementModel` + `AchievementEvaluator` | Pure achievement logic (pinned calendar) with celebration bookkeeping |
| `RoutineRepository` / `HistoryRepository` | Protocol boundaries over SwiftData, consumed through single-verb use-cases with typed errors |
| `HealthManager` | HealthKit lifecycle, hydration/energy logging, and the strength-training Live Activity |
| `PhoneConnectivityManager` | Watch relay over shared Codable wire DTOs (defined once in Core for both phone and watch) |

### Key Patterns

- **Repositories + use-cases**: views never touch SwiftData; every read/write goes through a single-verb use-case (`LoadExercises`, `LogSet`, …) with typed `throws(PersistenceError)`
- **One multicast change stream**: repositories and CloudKit imports notify a single `AsyncStream`; screens, achievements, and Spotlight all observe it
- **Graceful persistence degradation**: CloudKit → local-only → in-memory, never a launch crash
- **Host-run tests**: the bulk of the suite runs on the Mac in seconds — no simulator

### Data Models

| Model | Description |
|-------|-------------|
| `SetDeckRoutine` | One weekly slot (day 0–6) holding exercises |
| `SetDeckExercise` | Exercise with muscle groups, equipment, order, and sets |
| `SetDeckSet` | Set configuration (type, target reps/weight/duration, RPE) |
| `SetDeckSetHistory` | Audit trail of every completed set |

## Project Structure

```
SetDeck.xcworkspace             # Open this
├── SetDeck/                    # Thin app target: app shell, App Intents, Spotlight, menu commands
├── SetDeckWidget/              # Widget extension: water/energy widgets, control widget, Live Activity
├── SetDeck Watch App/          # Watch companion (WatchConnectivity over Core DTOs)
├── SetDeck Watch Widget/       # Watch complication
├── Packages/SetDeck/           # The real app (SPM umbrella package)
│   ├── Sources/                #   Core · Data · Services · DesignSystem · FeatureShared ·
│   │                           #   FeatureRoutine/Stats/Health/Settings/Onboarding · Composition
│   └── Tests/                  #   Host-run suite (swift test, no simulator)
└── Scripts/                    # Localization pinning tooling
```

## Testing

```sh
cd Packages/SetDeck && swift test
```

Domain (achievements, deep links, models), repositories, the shared feature models (over fake use-cases), and composition policy are all covered on the host. The hosted `SetDeckTests` target covers app-target glue only.

## Privacy

- All workout data stays in your private iCloud container
- Health data is read and written only with your permission, directly via HealthKit
- Muscle-group inference runs entirely on-device
- No analytics or tracking

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Molargik Software LLC
