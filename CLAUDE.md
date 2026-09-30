# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SetDeck is a fitness-tracking app (weekly routines → exercises → sets, with a completion audit trail) built with SwiftUI + SwiftData and iCloud/CloudKit private-database sync. It ships an iOS app, home-screen widgets (water/energy), a Control Center widget, a strength-training Live Activity, and an Apple Watch companion with its own complication.

The app is a **thin app target on top of an SPM umbrella package** (`Packages/SetDeck`) of layered, single-responsibility modules — the same clean architecture as Stork/Waffle/SCOUT. Dependencies point **inward**: features depend on the design system and core; data implements core's protocols; **core depends on nothing** (Foundation + SwiftData only).

## Build & Run

**Open `SetDeck.xcworkspace`** (not the bare `.xcodeproj`) — it resolves the local package. No external dependencies. If `xcodebuild` complains about CommandLineTools, prefix with `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`.

**Swift 6 language mode**, MainActor default isolation everywhere: app/watch targets set `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; package targets use `swiftSettings: [.defaultIsolation(MainActor.self)]`. `#MemberImportVisibility` is on: every file must import the module defining any member it uses (`import HealthKit` for `HKWorkoutSessionState` cases, `import os` for `Log`). Deployment floors: **iOS 18 / watchOS 11** — package platforms use string initializers (`.iOS("18.0"), .watchOS("11.0"), .macOS("15.0")`; macOS is the host-test floor). iOS-26-only APIs (`glassEffect`, `HKWorkoutSession` on iPhone, FoundationModels) stay behind `#available`/`canImport` guards.

Fast iteration — the package builds and tests on the macOS host, simulator-free:
```
cd Packages/SetDeck && swift build && swift test        # domain/data/models/composition logic
```
Verify iOS UI compiles (feature view files are gated `#if os(iOS)`):
```
xcodebuild build -scheme SetDeckComposition -destination 'generic/platform=iOS Simulator'
```
Build the whole product (app + widget extension + watch app + watch widget):
```
xcodebuild -workspace SetDeck.xcworkspace -scheme SetDeck \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Architecture — `Packages/SetDeck`

```
   ┌────────────── SetDeck (app target — thin) ───────────────┐
   │ SetDeckApp (@main) builds SessionController · Intents ·   │
   │ SpotlightIndexer · SetDeckCommands                        │
   ├────────── SetDeckWidgetExtension ─────────────────────────┤
   │ water/energy widgets · control widget · Live Activity     │
   ├────────── SetDeck Watch App + Watch Widget ───────────────┤
   │ WatchConnectivity UI over the Core wire DTOs              │
   └──────────────────────────┬────────────────────────────────┘
                              │ app hosts RootView, registers session
   ┌──────────────────────────▼────────────────────────────────┐
   │ SetDeckComposition — SessionController (composition root)  │
   │ + RootView (stage machine) + MainView (tabs) + Splash +    │
   │ AchievementCelebrationView                                 │
   └──┬──────────────────────────────────┬─────────────────────┘
 ┌────▼─────────────┐  ┌──────────────┐  ┌▼───────────────────┐
 │ SetDeckFeature*  │  │ SetDeck-     │  │ SetDeckData        │
 │ Routine · Stats ·│  │ Services     │  │ Default*Repository │
 │ Health · Settings│  │ HealthManager│  │ · SetDeckStore     │
 │ · Onboarding     │  │ (HealthKit + │  │ (CloudKit, graceful│
 ├──────────────────┤  │ LiveActivity)│  │ degradation) ·     │
 │ SetDeckFeature-  │  │ CloudSync ·  │  │ SampleWorkoutData  │
 │ Shared           │  │ PhoneConnect-│  │ (DEBUG)            │
 │ WorkoutDataModel │  │ ivity ·      │  └─────────┬──────────┘
 │ AchievementModel │  │ MuscleGroup- │            │ implements
 │ SetDeckTips      │  │ Inference    │            │
 └───┬──────────┬───┘  └──────┬───────┘            │
     │ uses     │ uses        │ implements         │
 ┌───▼──────┐ ┌─▼─────────────▼────────────────────▼───────────┐
 │ SetDeckDS│ │ SetDeckCore (pure domain)                       │
 │ colors · │ │ @Model types · enums · domain (WorkoutStats/    │
 │ Brand    │ │ AchievementEvaluator/AchievementTracker) ·      │
 │ tokens · │ │ DeepLink · watch wire DTOs · repository &       │
 │ toast ·  │ │ use-case PROTOCOLS · WorkoutChangeCenter ·      │
 │ haptics  │ │ seams · Log                                     │
 └──────────┘ └─────────────────────────────────────────────────┘
```

### SetDeckCore (pure — Foundation + SwiftData only, host-tested)
- **Models** (`@Model`): `SetDeckRoutine` → `SetDeckExercise` → `SetDeckSet` → `SetDeckSetHistory` (day 0=Sun…6=Sat; CloudKit-friendly defaults; `.sample` factories are `#if DEBUG`).
- **Enumerations** (`nonisolated`, `Sendable`): `SetType`, `MuscleGroup`, `Achievement`/`AchievementCategory`, `AppStage`, `AppTab`, `OnboardingStep`, `TimeRange`, `DeepLink` (pure `init?(url:)` for `setdeck://routine|stats|health|settings|editRoutine`).
- **Domain**: `WorkoutStats` (pure snapshot), `AchievementEvaluator` (all threshold/streak/week logic on a pinned `en_US_POSIX` Gregorian calendar), `AchievementTracker` (celebration bookkeeping behind `KeyValueStoring`).
- **Watch wire protocol**: `WatchRoutine`/`WatchExercise`/`WatchSet`/`WatchSetType`/`SetCompletionMessage`/`WatchMessageKey` — **one definition linked by both the phone relay and the watch app** (the old code kept two hand-synced copies).
- **Services (protocols only)**: `RoutineRepository`/`HistoryRepository` + single-verb use-cases (`LoadRoutines`, `LoadRoutine`, `LoadExercises`, `AddExercise`, `UpdateExercise`, `ReorderExercises`, `DeleteExercise`, `LoadSets`, `AddSet`, `UpdateSet`, `ReorderSets`, `DeleteSet`, `DeleteAllRoutines`, `LoadHistory`, `RecordSetCompletion`, `FindSet`, `ClearHistory`, `LoadWorkoutStats`, `LogSet` — each a `protocol` + `…UseCase` struct with `callAsFunction`). `LogSet` is the primary user action: update targets + record history in one verb. Nothing outside the composition root touches a repository directly (even App Intents).
- **Typed errors**: the persistence boundary declares `throws(PersistenceError)` (`.fetchFailed`/`.saveFailed`) — new repository/use-case methods must keep the typed signature.
- **Change stream**: `WorkoutChangeCenter` + `ObserveWorkoutChanges` — repositories notify on every successful write and `CloudSyncManager` notifies on CloudKit imports; `WorkoutDataModel`, `AchievementModel`, and Spotlight all observe the one multicast `AsyncStream` (replaces the old `changeStamp`/`onDataMutated` single-subscriber pair). Never add per-screen refresh callbacks.
- **Seams**: `KeyValueStoring` (+`UserDefaults` conformance), `ExerciseIndexing` (Spotlight — impl app-side).
- `Log` — `os.Logger` per category. **Never `print`.**

### SetDeckData (persistence impl, depends on Core)
`DefaultRoutineRepository` (orderIndex assignment/renumbering, `lastUpdated` stamping, duplicate-routine repair after CloudKit merges), `DefaultHistoryRepository` (audit trail + the `WorkoutStats` snapshot), `SetDeckStore.makeContainer(inMemory:)` — **CloudKit → local → in-memory graceful degradation** (container id `iCloud.com.molargiksoftware.SetDeck`; the old app fatal-errored). `SampleWorkoutData` (DEBUG): 7-day program + 30 days of progressive history.

### SetDeckServices (system frameworks, depend on Core)
`HealthManager` (`#if canImport(HealthKit) && !os(macOS)`: authorization, water/calorie logging, series, workout session on iOS 26+, Live Activity lifecycle; also built by the widget via `HealthManager(forWidget: true)`), `CloudSyncManager` (network + remote-change monitoring; notifies the change center on CloudKit imports), `PhoneConnectivityManager` (WatchConnectivity relay over use-cases; delegate callbacks are `nonisolated` and extract Sendable values before hopping), `MuscleGroupInferenceService` (FoundationModels, iOS 26+, `@Observable`, injected — no singleton), `StrengthTrainingActivityAttributes`.

### SetDeckDesignSystem (depends on Core)
Brand colors **in code** on `Color`/`ShapeStyle` (`greenStart`…`orangeEnd` — the app/widget asset catalogs still exist for the widgets' own use), `Brand.Space`/`Brand.Radius` tokens, gradients, `BrandBackground`, `GlassCapsuleButtonStyle`, `Haptics` (no-op off-UIKit), toast stack (`ToastStyle`/`ToastItem`/`ToastManager`/`ToastView`/`.toastContainer()`), `AdaptiveGlassModifier` + shimmer/hover/`if` modifiers, `AchievementCategory.color` and `AppTab.icon()/color()` extensions.

### SetDeckFeatureShared (depends on Core + DesignSystem)
- **`WorkoutDataModel`** — the environment-injected data surface every feature shares (successor to the ExerciseManager environment object): same verbs, but each goes through a use-case, failures surface as error toasts (never `try?`-swallowed), and `changeStamp` bumps via the change stream (including CloudKit imports).
- **`AchievementModel`** — evaluates unlocks from `WorkoutStats`, fires celebrations via `AchievementTracker`, re-checks on every change-stream event.
- **`SetDeckTips`** — shared TipKit events/tips.

### SetDeckFeature* (one per tab, depend on Core + DesignSystem + FeatureShared [+ Services])
`Routine` (day deck, set logging, edit-routine flow), `Stats` (charts, muscle heatmap, achievements card; inference service injected from the environment), `Health` (workout control, hydration/energy logging), `Settings` (units, delete-all, achievements list, DEBUG sample data), `Onboarding` (embeds `EditRoutineView` from the Routine feature). Views are `#if os(iOS)`-gated and read `@Environment(WorkoutDataModel.self)` / `@Environment(HealthManager.self)` etc.; `RootView` injects everything.

### SetDeckComposition (top of graph — the composition root)
`SessionController` (`@MainActor @Observable`) builds the whole graph in `init` (container → change center → repositories → use-cases → shared models → managers), owns `pendingDeepLink` (consumed by `MainView`; set by `onOpenURL`, widgets, menu commands), Spotlight reindexing off the change stream, the DEBUG `-uiTesting` seeding path, and `start()` (connectivity activation + Spotlight seed). `RootView` = stage machine (splash → onboarding → main) + environment injection + `.toastContainer()`; `MainView` = the four-tab shell + celebration overlay + live-workout toolbar chip.

### App target (`SetDeck/`) — thin
`SetDeckApp` (~50 lines): builds `SessionController(indexer: SpotlightIndexer())`, registers it with `AppDependencyManager`, hosts `RootView`, configures TipKit. `SetDeckCommands` (menu bar) drives the same deep-link staging. `Intents/`:
- `ExerciseEntity` + query and the Siri Q&A intents (`GetTodayWorkoutIntent`, …) read via `@Dependency var session` + use-cases — the old duplicate `IntentModelContainer` is gone, and `GetWorkoutStatusIntent` now reads the session's live `HealthManager` (a fresh instance always reported "not working out").
- `StartWorkoutIntent`/`StopWorkoutIntent`/`AddWater…`/`AddCalories…` deliberately create **transient `HealthManager` instances** — they must also run in the widget process where no session exists.
- `SpotlightIndexer: ExerciseIndexing` (app-side seam impl; entity types can't live in the package).

### Widgets & Watch
- `SetDeckWidgetExtension` links `SetDeckCore` + `SetDeckServices` (the old `membershipExceptions` file-sharing is gone). Widget kinds: `WaterWidgetOZ`, `WaterWidgetLiter`, `EnergyWidget`, the Control Center toggle, and the strength-training Live Activity. Widgets keep their own asset-catalog colors.
- `SetDeck Watch App` + watch widget link `SetDeckCore` for the wire DTOs; `WatchConnectivityManager` (watch-side) and views are unchanged otherwise. Phone is the source of truth; the watch is ephemeral + a logging interface.
- If a target needs another package module, add it to that target's `packageProductDependencies` in `project.pbxproj` (deterministic `DEC0DE…` IDs).

## Testing
- Swift Testing (`@Suite`, `@Test`, `#expect`). The real suite is in `Packages/SetDeck/Tests` (`swift test`, host, simulator-free): `SetDeckCoreTests` (evaluator, tracker, deep links, models), `SetDeckDataTests` (repositories over on-disk stores, sample generator), `SetDeckServicesTests` (sync status; the HealthManager spy suite compiles only on device destinations), `SetDeckFeatureSharedTests` (shared models over fake use-cases), `SetDeckCompositionTests` (graph wiring, deep links, celebration flow, Spotlight seam).
- **Suites that create SwiftData containers are `.serialized` with a unique on-disk temp store per test** — parallel in-memory containers share a /dev/null SQLite identity and crash the host.
- `SetDeckTests` (hosted) covers app glue only — **hosted tests must not create SwiftData containers** (the running app already owns a CloudKit-backed container for the same `@Model` classes; a second one in-process crashes SwiftData).
- New logic goes into Core (pure) first with tests, then a repository/use-case in Data, then feature behavior over fakes.

## Localization
- Languages: en (source), es, fr-CA, ja via `SetDeck/Localizable.xcstrings` (+ `InfoPlist.xcstrings`).
- **Policy for package strings:** SwiftUI's key-based initializers resolve in `Bundle.main`, so translations for package-rendered strings live in the **app target's** catalog, pinned `extractionState: "manual"` + `shouldGenerateSymbol: false`. `STRING_CATALOG_GENERATE_SYMBOLS = NO` on every config block.
- **After adding user-facing strings to package code:** add the key + es/fr-CA/ja translations to `SetDeck/Localizable.xcstrings` by hand, then run `python3 Scripts/pin_package_strings.py`. **Don't reword existing keys** — the English literal *is* the key; changing one character orphans three translations.

## Key Patterns & Gotchas
- Always dark mode (`.preferredColorScheme(.dark)` / `.colorScheme(.dark)` at RootView).
- Achievement/streak calendar math uses `AchievementEvaluator.pinnedCalendar()` (en_US_POSIX, Sunday-first) so app/widgets/tests agree regardless of locale.
- `@ContentBuilder` is iOS-27-only; the package targets iOS 18, so package code uses `@ViewBuilder`. `@ToolbarContentBuilder` is a different type.
- Swift 6 concurrency: non-Sendable values crossing isolation (WidgetKit completions, ActivityKit `Activity`) use `UncheckedSendableBox` (Core); system-framework delegate callbacks extract Sendable values before hopping to `@MainActor`.
- App group (legacy literal, shared with widgets/watch): `group.nickmolargik.ReadySet`; bundle id `nickmolargik.ReadySet`. Don't "fix" these — they're shipping identifiers.
- CloudKit model rules: defaults on all attributes, optional relationships, no unique constraints. Duplicate per-day routines from CloudKit merges are folded by the repository on init.
