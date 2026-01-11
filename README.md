# SetDeck

A modern strength training and fitness tracking app for iOS, iPadOS, and Apple Watch built with SwiftUI and SwiftData.

## Features

### Workout Management
- **Weekly Routines** - Plan your workouts across 7 days
- **Exercise Library** - Add exercises with muscle group assignments, equipment, notes, and video references
- **Flexible Set Types** - Support for reps, AMAP (As Many As Possible), duration-based, and freeform sets
- **Set History** - Track completed sets with RPE (Rate of Perceived Exertion) ratings
- **AI Muscle Group Assignment** - Automatic muscle group inference for exercises

### Health Integration
- **HealthKit Sync** - Read and write workout data, hydration, and calories
- **Strength Training Workouts** - Create tracked workout sessions
- **Hydration Tracking** - Monitor daily water intake
- **Calorie Tracking** - View consumed and burned calories

### Apple Watch
- **Companion App** - View daily routine and log sets from your wrist
- **Rest Timer** - Guided rest periods between sets
- **Complications** - Display workout info on watch faces
- **Workout Controls** - Start and stop workouts directly from Watch

### Widgets & Live Activities
- **Water Widget** - Display daily hydration (metric or imperial)
- **Energy Widget** - Show calories burned
- **Live Activity** - Real-time set and rep counters during workouts
- **Control Center** - Quick workout controls (iOS 18+)

### Siri Integration
- Check workout schedules with voice commands
- Control workout sessions hands-free

## Requirements

- iOS 17.0+
- watchOS 10.0+
- Xcode 15.0+

## Building

```bash
# Build for iOS Simulator
xcodebuild -scheme SetDeck -destination 'platform=iOS Simulator,name=iPhone 16'

# Run tests
xcodebuild test -scheme SetDeck -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a specific test
xcodebuild test -scheme SetDeck -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:SetDeckTests/ExerciseManagerTests/testAddExercise
```

## Architecture

### Project Structure

```
SetDeck/
├── SetDeck/                    # Main iOS app
│   ├── Models/                 # SwiftData models
│   ├── Managers/               # Business logic (@Observable)
│   ├── Views/                  # SwiftUI views (MVVM pattern)
│   │   ├── Main/               # Tab views: Routine, Stats, Health, Settings
│   │   ├── Onboarding/         # First-run setup
│   │   └── Migration/          # Legacy data import
│   ├── Enumerations/           # AppTab, MuscleGroup, SetType, etc.
│   ├── Extensions/             # View modifiers, utilities
│   ├── Intents/                # Siri Intents
│   └── TipKit/                 # In-app tips
├── SetDeck Watch App/          # watchOS companion
├── SetDeckWidget/              # Home screen & lock screen widgets
└── SetDeck Watch Widget/       # Watch complications
```

### Data Models

| Model | Description |
|-------|-------------|
| `SetDeckRoutine` | Weekly routine container (7 days) |
| `SetDeckExercise` | Exercise with metadata and muscle groups |
| `SetDeckSet` | Set configuration (type, reps, weight, duration) |
| `SetDeckSetHistory` | Completed set records |

### Key Managers

- **ExerciseManager** - CRUD operations for routines, exercises, sets
- **HealthManager** - HealthKit integration and workout sessions
- **MigrationManager** - Legacy "Ready Set" app data import

### Navigation

The app uses a stage-based lifecycle:
```
start → splash → migration → onboarding → main
```

Main navigation consists of 4 tabs: Routine, Stats, Health, Settings.

## Technologies

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Modern data persistence
- **HealthKit** - Health and fitness data
- **CloudKit** - iCloud sync (`iCloud.com.molargiksoftware.SetDeck`)
- **WatchConnectivity** - iPhone-Watch communication
- **WidgetKit** - Home screen widgets
- **ActivityKit** - Live Activities
- **TipKit** - Contextual tips and guidance

## Testing

Tests use the Swift Testing framework (`@Suite`, `@Test`, `#expect()` macros):

- `ExerciseManagerTests` - Exercise and routine operations
- `HealthManagerTests` - HealthKit integration
- `MigrationManagerTests` - Data migration
- `ModelTests` - SwiftData model validation

## License

Copyright Molargik Software LLC. All rights reserved.
