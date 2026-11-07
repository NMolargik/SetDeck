# Paired-simulator verification, 2026-11-07

Pair: iPhone 18 Pro Max + Apple Watch Series 12 (46mm), iOS/watchOS 27.0.
`simctl privacy grant health` is unsupported here, so both HealthKit sheets were tapped through (iOS Simulator control tool).

01-02 launch · 03 Watch after permissions · 04 phone routine (Sat: Bench Pres, Sq) · 05-06 Watch before/after routine sync
07 standalone workout started (phone terminated) · 08 rest countdown · 09 workout complete
10-12 Live Activity on lock screen (before/after layout fix) · 13 Watch rest

Not verified in simulator: complication / Smart Stack render, queued `transferUserInfo` delivery (never surfaces
in the simulator), wrist-down haptic, Double Tap, Action Button, live Live Activity countdown digits.
