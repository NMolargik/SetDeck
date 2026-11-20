# SetDeck icon: "Fan" (chosen 2026-11-19)

Three cards fanned like a hand: green in front with a white dumbbell, blue behind on the right, orange behind on the left. Colours: green #4FC290, blue #4E9EEA, orange #F2844A, dumbbell white. Built to sit with Maestro, Opalite, Mygra, Stork and Waffle (same backgrounds and glass settings as Opalite).

**Shortcut:** `SetDeck Fan.icon` is the finished icon. Open it in Icon Composer, check it, and save it as `AppIcon.icon` (see "Where it goes").

## Files (1024 x 1024 SVG, rotations baked in)

| File | Layer |
|---|---|
| `Dumbbell.svg` | White dumbbell, top |
| `1-Front-Green.svg` | Front card |
| `2-Back-Right-Blue.svg` | Back card, tilted right |
| `3-Back-Left-Orange.svg` | Back card, tilted left |
| `Preview-*.png` | Default, Dark, Tinted and Clear renders |

## Build it in Icon Composer

1. **New document**, keep iOS/iPadOS/macOS on the shared square and turn on watchOS (circle).
2. **Background, Default:** fill Linear Gradient, top #FFFFFF, bottom #E9E8EF.
3. **Background, Dark:** top #34303D, bottom #121015.
4. Add four groups, top to bottom:
   - **Dumbbell** (`Dumbbell.svg`): Shadow Layer Color 40%, Translucency off.
   - **Front** (`1-Front-Green.svg`): Shadow Neutral 30%, Translucency on 45%.
   - **Right** (`2-Back-Right-Blue.svg`): Shadow Neutral 30%, Translucency on 45%.
   - **Left** (`3-Back-Left-Orange.svg`): Shadow Neutral 30%, Translucency on 45%.
5. Leave every layer centred at 100%; the positions are already in the SVGs.
6. Check Default, Dark, Clear and Tinted.

## Where it goes

Save as `AppIcon.icon` over `SetDeck/AppIcon.icon` and `SetDeck Watch App/AppIcon.icon` in the repo (or drop it at the repo root and tell me). After that I update `Icons/AppIcon.png`, the splash and launch mark, the widget icon, the Affinity icon doc, the store art and the website.
