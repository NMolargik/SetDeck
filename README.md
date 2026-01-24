<p align="center">
  <img src="Icons/AppIcon-iOS-Default-1024x1024@1x.png" alt="SetDeck" width="128" height="128">
</p>

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
- AI-powered automatic muscle group inference for exercises

### Health Integration
- **HealthKit Sync**: Read and write workout data, hydration, and calories
- **Strength Training Workouts**: Create tracked workout sessions
- **Hydration Tracking**: Monitor daily water intake
- **Calorie Tracking**: View consumed and burned calories

### Apple Watch
- Companion app to view daily routine and log sets from your wrist
- Guided rest timer between sets
- Watch face complications for workout info
- Start and stop workouts directly from Watch

### Widgets & Live Activities
- **Water Widget**: Display daily hydration (metric or imperial)
- **Energy Widget**: Show calories burned
- **Live Activity**: Real-time set and rep counters during workouts
- **Control Center**: Quick workout controls (iOS 18+)

### Siri Integration
- Check workout schedules with voice commands
- Control workout sessions hands-free

## Requirements

- iOS 17.0+
- watchOS 10.0+
- Xcode 15.0+
- Apple Developer account (for CloudKit and HealthKit capabilities)

## Setup

1. Clone the repository
2. Open `SetDeck.xcodeproj` in Xcode
3. Configure signing with your Apple Developer account
4. Update bundle identifiers and App Group/iCloud container identifiers
5. Build and run

### Required Capabilities

Enable these in your Xcode project:
- iCloud (CloudKit with private database)
- HealthKit
- App Groups
- Background Modes (workout processing)
- Siri

## Architecture

### App Lifecycle

The app progresses through stages managed by `ContentView`:

```
.start → .splash → .migration → .onboarding → .main
```

### Manager Pattern

Business logic lives in `@Observable` manager classes:

| Manager | Responsibility |
|---------|---------------|
| `ExerciseManager` | CRUD for routines, exercises, sets, and history |
| `HealthManager` | HealthKit integration and workout sessions |
| `MigrationManager` | Legacy "Ready Set" app data import |

### Data Layer

- **SwiftData** with iCloud CloudKit sync
- **App Groups** for widget and watch data sharing
- **AppStorage** for user preferences

### Data Models

| Model | Description |
|-------|-------------|
| `SetDeckRoutine` | Weekly routine container (7 days) |
| `SetDeckExercise` | Exercise with metadata and muscle groups |
| `SetDeckSet` | Set configuration (type, reps, weight, duration) |
| `SetDeckSetHistory` | Completed set records with timestamps |

### Key Patterns

- **Dependency Injection**: Managers injected via SwiftUI `@Environment`
- **MVVM**: Complex views have companion ViewModel extensions
- **Dark Mode**: Always dark mode throughout the app

## Project Structure

```
SetDeck/
├── SetDeckApp.swift            # App entry point
├── ContentView.swift           # App stage state machine
├── Managers/                   # Business logic
├── Models/                     # SwiftData models
├── Views/
│   ├── Main/                   # 4-tab interface
│   │   ├── Routine/            # Weekly routine management
│   │   ├── Stats/              # Workout statistics
│   │   ├── Health/             # HealthKit data display
│   │   └── Settings/           # Preferences
│   ├── Onboarding/             # First-run setup
│   └── Migration/              # Legacy data import
├── Enumerations/               # AppTab, MuscleGroup, SetType
├── Extensions/                 # View modifiers, utilities
├── Intents/                    # Siri Intents
└── TipKit/                     # In-app tips

SetDeck Watch App/              # watchOS companion
SetDeckWidget/                  # Home screen widgets
SetDeck Watch Widget/           # Watch complications
```

## Testing

Tests use the Swift Testing framework (`@Suite`, `@Test`, `#expect()` macros):

```bash
xcodebuild test -scheme SetDeck -destination 'platform=iOS Simulator,name=iPhone 16'
```

Test suites:
- `ExerciseManagerTests` - Exercise and routine operations
- `HealthManagerTests` - HealthKit integration
- `MigrationManagerTests` - Data migration
- `ModelTests` - SwiftData model validation

## Privacy

SetDeck is designed with privacy in mind:
- All data stored in your private iCloud container
- Health data stays on your devices via HealthKit
- No analytics or tracking
- No workout data shared with third parties

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Molargik Software LLC
