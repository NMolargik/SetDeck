# SetDeck 3.0 icon: components for Icon Composer

Concept B ("Flat"), grey cards (#EBEBEB), chosen 2026-11-19.

Shortcut: `../icon-concepts/B-flat.icon` is this exact icon already assembled. You can open it in Icon Composer, check it, and use it as is. The steps below rebuild it from the loose layers.

## Files

All layers are 1024 x 1024 with every transform baked in. Use the SVGs; the PNGs are previews.

| File | What it is |
|---|---|
| `Symbols.svg` | Dumbbell, drop and flame together, the top layer |
| `Dumbbell.svg`, `Drop.svg`, `Flame.svg` | The same symbols split apart, only if you want separate glass layers |
| `Card-1.svg` | Top card (front) |
| `Card-2.svg` | Middle card |
| `Card-3.svg` | Bottom card (back) |
| `Background-Default.svg`, `Background-Dark.svg` | References for the two background gradients (set them as fills, not layers) |
| `Composite-Default.png`, `Composite-Dark.png` | Flat preview of the finished icon, without glass effects |

Colours: dumbbell #4FC290, drop #4E9EEA, flame #F2844A, cards #EBEBEB.

## Build it in Icon Composer

1. **New document.** File > New. Under Platforms, keep iOS/iPadOS/macOS on the shared square, and turn on watchOS (circle) if you want one file for both apps.
2. **Background (Default appearance).** Select the icon (top of the sidebar), set Fill to Linear Gradient, vertical:
   - Top stop #FFFFFF at 0%
   - Bottom stop #E9E8EF at 70%
3. **Background (Dark appearance).** Switch the appearance control to Dark and set the fill to:
   - Top stop #34303D at 0%
   - Bottom stop #121015 at 70%
4. **Cards group.** Drag in `Card-3.svg`, `Card-2.svg`, `Card-1.svg` as one group named Cards, with Card-1 on top. On each card layer set Opacity 95%. On the group:
   - Shadow: Neutral, 100%
   - Translucency: on, 50%
   - Specular: on
5. **Symbols group.** Drag `Symbols.svg` in as a second group above Cards, named Symbols. On the group:
   - Shadow: Layer Color, 70%
   - Translucency: on, 5%
   - Specular: on
   - Lighting: Individual
   - Turn Glass on for the Symbols layer.
6. **Position.** Leave both groups centred. Symbols.svg already includes its 11 pt shift to the right; do not move it again.
7. **Check** the Default, Dark, Clear and Tinted previews. In Tinted the symbols should stay readable over the cards.

## Where it goes

- iPhone/iPad app: save as `AppIcon.icon` and replace `SetDeck/AppIcon.icon` in the project. Build the app from the `claude/v3-integration` branch (worktree `Apps/SetDeck/.claude/worktrees/v3-integration`) or tell me where you saved it and I'll put it in.
- Watch app: `SetDeck Watch App/AppIcon.icon` is a separate file. Either save a copy there (with watchOS turned on in step 1), or tell me and I'll copy it in.

After the icon is in, I'll replace the remaining old icon art (splash, launch screen, onboarding, website, press kit, store art) with this one.

## Sources

Layered Affinity source: `Icons/SetDeck App Icon.af` on `claude/v3` (built 2026-11-18). Concepts and renders: `../icon-concepts/`.

## Softer shadows (variant D, chosen 2026-11-19)

Nick chose variant D (`shadow-variants/D-neutral25-clear.icon`) to bring the icon in line with Opalite, Maestro and Mygra. Changes from the shipped `AppIcon.icon`:

| Group | Setting | Was | Now |
|---|---|---|---|
| Cards | Shadow | Neutral 100% | Neutral 25% |
| Cards | Translucency | 50% | 30% |
| Symbols | Shadow | Layer Color 70% | Layer Color 40% |

Everything else (fills, card opacity 95%, specular, lighting) stays the same. Apply to both `SetDeck/AppIcon.icon` and `SetDeck Watch App/AppIcon.icon`.

Applied 2026-11-19 (SetDeck `claude/v3-integration` 674a721). Glass renders of the shipped icon for marketing use: `AppIcon-final-Default.png`, `-Dark`, `-TintedDark`, `-ClearLight` (1024 px, from ictool).
