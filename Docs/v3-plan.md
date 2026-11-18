# SetDeck 3.0 — work plan and shared rules

Base branch `claude/v3` (3.0.0, build 300). Already on it: the earlier Duo pass and rating
polish (`claude/duo-pass`), `SetDeckDesignSystem/FoldAwareness.swift` (ported from Opalite:
`GeometryProxy.hasFoldIfAvailable`, `foldCenterXIfAvailable`, `isFoldActiveIfAvailable`, …),
and `SetDeckCore/Company.swift` (Farside name, site, support, privacy URLs).

`Docs/v3-reference/` holds read-only reference code from the sibling apps that already
shipped this treatment: Opalite's onboarding, splash, launch screen and split Settings,
and Mygra's Duo `MainView`, `SplashView` and `SettingsSplitView`. Match their structure and
feel; do not copy Opalite/Mygra names, colours or content. This folder is deleted at
integration — never import from it or add it to the build.

## Rules for every package

1. Work only on your package's branch (`claude/v3-<package>`), branched from `claude/v3`.
   Commit in small, described commits and push your branch. Never push to `main` or `claude/v3`.
2. There is no Xcode in the cloud. You cannot build the app; write Swift 6 carefully against
   the APIs already used in this codebase (read `CLAUDE.md` first: MainActor default isolation,
   `#MemberImportVisibility`, iOS 18 floor with `#available` guards for newer API, `Log` never
   `print`, typed `throws(PersistenceError)` at the persistence boundary, `WorkoutChangeCenter`
   for change notification). If `swift` is available you may try `swift build` in
   `Packages/SetDeck`, but SwiftUI/SwiftData will not exist on Linux, so a failure there is
   expected. A local agent on a Mac builds and fixes each branch after you finish, so list
   anything you were unsure of in your final report.
3. Stay inside your package's files (listed below). If you must touch a shared file, keep the
   edit minimal and say so in the report.
4. Bundle IDs (`nickmolargik.ReadySet`…), App Group (`group.nickmolargik.ReadySet`), iCloud
   container (`iCloud.com.molargiksoftware.SetDeck`), URL scheme and every other shipping
   identifier stay exactly as they are. Only human-readable text and links change.
5. Leave `*.xcstrings` translations alone except for removing or renaming the company name;
   new strings go in as plain `String(localized:)`/`Text("…")` literals.
6. Never touch the app icon files (`SetDeck/AppIcon.icon`, `Icons/`), Xcode schemes or signing.
7. iPhone Duo (iOS 27.1) is a foldable iPhone: folded it is a normal iPhone; unfolded the window
   is roughly iPad-mini-sized (regular width) with a vertical hinge down the middle. Use the
   FoldAwareness helpers to keep content out of the hinge and to place two panes either side of
   it. Designs must still be correct on a regular iPhone and on iPad.
8. Finish with a report: what changed, files touched, open questions, anything unverified.

## Packages

| Package | Scope | Owns |
|---|---|---|
| `brand-fixes` | Replace every human-readable "Molargik Software"/"Molargik Software LLC" mention and molargiksoftware.com link with Farside via `Company` (Settings links, about/credits, Info.plist usage strings, intents descriptions, README). Fix: routines don't appear as cards until restart (also after sample-data generation). Fix: returning installs (iCloud data already present) get every existing achievement celebrated on first launch — on a fresh install or first launch after restore, silently mark already-earned achievements as seen. | SettingsView link rows only, `AchievementModel`, `AchievementTracker`, `WorkoutDataModel`, `SampleWorkoutData`, `SessionController` (only as needed for the fixes), Info.plist strings, intents, README |
| `onboarding` | Landing page and onboarding rebuilt in Opalite's layout style (see reference); splash in the same family; fix `SetDeck/LaunchScreen.storyboard` so launch → splash is seamless (the app is always dark) (match Opalite's approach). Keep the existing onboarding steps' purpose (health permission, privacy, builder, done). Good on iPhone, unfolded Duo (use the width, e.g. two-column), iPad. | `SetDeckFeatureOnboarding/*`, `SplashView`, `LaunchScreen.storyboard`, `OnboardingStep` |
| `duo-shell` | iPhone Duo across the board: `MainView` and each tab (Routine deck, Stats, Health) use the unfolded width meaningfully — e.g. routine day deck + selected exercise/set detail side by side, Stats as a two-column dashboard, Health with sections paired across the hinge. On the unfolded Duo (and iPad), Settings becomes iPhone-Settings style: a leading list pane with the detail to the right (like Opalite's `SettingsSplitView`), falling back to the current push navigation when compact. | `MainView`, `RootView` (layout only), `RoutineView`, `RoutineDayDeckView`, `DayPickerView`, `ExerciseCardView`, `EmptyDayCardView`, `SetRowView`, `SetDeckFeatureStats/*`, `SetDeckFeatureHealth/*` views, new `SettingsSplitView` + container changes in `SettingsView` (not the link rows), `AchievementsView` layout |
| `routine-editor` | Major overhaul of routine creation and editing: far more visual and descriptive (day/schedule shown at a glance, exercises as rich cards with muscle-group colour and icon from `MuscleGroupInferenceService`, set types and targets readable without opening each row, clear add/reorder/delete affordances, good empty state). Unfolded Duo/iPad: two panes — exercise list on the leading side, the selected exercise's sets editor on the trailing side. Keep using the existing use-cases. | `EditRoutineView`, `EditRoutineView-ViewModel`, `EditSetRowView`, new files under `SetDeckFeatureRoutine/Editor/` |
| `water-reminders` | Optional water-intake reminders: off by default; a Settings section to turn on, choose active hours (e.g. 8:00–20:00) and interval (1h/1.5h/2h/3h), with notification permission requested only when turned on. Schedule local notifications (`UNUserNotificationCenter`), with a notification action "Log a glass" that adds water through the existing water-logging path (see `AddWaterIntent`/Health hydration code). Skip/quiet reminders once the day's water goal is met if feasible. Reschedule on settings change and app launch. | new `SetDeckServices/WaterReminderScheduler.swift`, new `SetDeckFeatureSettings/WaterReminderSettingsView.swift`, one row/section hook in `SettingsView`, minimal wiring in `SessionController`/app delegate for the notification action |
| `store-copy` | New App Store text for 3.0: name (≤30), subtitle (≤30), promotional text (≤170), description (≤4000), keywords (≤100, comma-separated, no spaces, don't repeat name words), and What's New for 3.0. Write in `Docs/store-copy/` as `en-US.md` with character counts. Base it on what the app actually does (read the code). | `Docs/store-copy/*` only |

Integration (done on the Mac afterwards): merge the branches into `claude/v3-integration`,
build all targets, fix, then a visual pass on iPhone, iPhone Duo (folded and unfolded) and iPad.
