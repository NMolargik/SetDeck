# SetDeck 3.0 App Store screenshots: design brief

Built the same way as Mygra 3.0's set (read `/Users/nickmolargik/Developer/Farside Software/Apps/Mygra/Marketing/Mygra 3.0/store-screenshots/README.md` and its `source/` scripts, and reuse them).

## Look

- **Canvas**: dark, matching the app. Near-black `#07090A` to `#0B110E` vertical gradient, a soft green glow behind the device (`#4FC290`, roughly 20% at its centre, fading out), and, very faint (about 5% white), the icon's three stacked card outlines large in the lower background, cropped by the edge. Nothing busy: the device is the subject.
- **Headline**: two lines above the device, SF Pro Display Heavy (`SFProDisplay-Heavy`), live text in Affinity. Line 1 white `#F2F4F3`; line 2 in the caption's accent colour (below). Left-aligned on iPhone and Duo folded, centred on iPad and Duo unfolded, generous top margin, max two lines each.
- **Accent colours** (from the icon): green `#4FC290` (training), blue `#4E9EEA` (water), orange `#F2844A` (energy and achievements).
- **Device**: Framous frames, silver/star-white: `iPhone18Pro` for iPhone captures, `iPadPro13inM5` for iPad, `iPhoneDuoOuterClosed` and `iPhoneDuoInnerOpen` for the Duo. Device fills about 78% of the artboard width (iPhone), slightly bleeding off the bottom edge is fine.
- **Status bar**: `xcrun simctl status_bar <udid> override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3`.

## Captions and screens (order matters: the first three show in search)

| # | Line 1 | Line 2 (accent) | Screen | Launch flags |
|---|---|---|---|---|
| 1 | Your week, | one deck at a time. (green) | Routine tab, today's deck card filling the screen, Next set visible (iPad: deck beside This Week) | `-uiTesting -sdSkipOnboarding` |
| 2 | Log every set | in one tap. (green) | Routine tab with a set expanded or just logged (check mark visible, Next moved on) | `-uiTesting -sdSkipOnboarding -sdSelectExercise` or tap |
| 3 | Build routines | you can see. (green) | Edit Routine with exercise cards (iPad: two-pane with the set editor) | open editor |
| 4 | Watch your numbers | climb. (green) | Stats: training volume chart and summary tiles, 90D | Stats tab |
| 5 | See every muscle | you trained. (green) | Stats scrolled to the Muscle Heatmap and Distribution | Stats tab, scroll |
| 6 | Hit your water goal, | every day. (blue) | Health tab: Hydration card with a filled day, Add Water | Health tab (grant Health permission first) |
| 7 | Reminders that | know when to stop. (blue) | Settings > Preferences with Water Reminders on, Daily Goal shown | `-sdSettingsPage preferences`, turn reminders on |
| 8 | Earn every | achievement. (orange) | Achievements sheet with several earned | `-sdShowAchievementsSheet` |

## Sets and sizes

| Set | Artboard | Shots |
|---|---|---|
| iPhone (`APP_IPHONE_67`) | 1320x2868 | 8 |
| iPad (`APP_IPAD_PRO_3GEN_129`) | 2064x2752 | 8 |
| iPhone Duo folded (`APP_IPHONE_DUO`) | 1398x2034 | 5 (#1, 2, 4, 6, 8) |
| iPhone Duo unfolded | 2853x2007 | 4 (#1, 3, 4, 7): captured later by the lead session with Nick unfolding the simulator; leave these artboards with a placeholder device |
| Product page header | 3840x1646 | 1: iPad shot 1 and iPhone shot 2 side by side, headline "Plan the week. Log every set." |
| Search results | 3840x2560 | 1: iPhone shots 1, 2, 3 in a row |

## Files

- Working copy for Affinity (it can only read the Desktop): `~/Desktop/SetDeck 3.0 Store (Claude)/` with `images/` (framed captures and backgrounds) and the build scripts.
- Durable copy: this folder, `Marketing/SetDeck 3.0/store-screenshots/`: `SetDeck 3.0 Artboards.af`, `final/` (flattened PNG exports, no alpha, named `iphone-01.png` …), `backgrounds/`, `captures/` (raw), `source/` (shot lists and scripts), `README.md` describing how to rebuild, like Mygra's.
- Leave every other Affinity document that is open alone (Opalite, Maestro, Mygra, the SetDeck icon doc).
