# SetDeck 3.0 App Store screenshots (draft)

Built from the design brief (`BRIEF.md`) the same way as Mygra 3.0's set. Build: local branch `claude/v3-integration` (Debug, `-uiTesting -sdSkipOnboarding`).

- `SetDeck 3.0 Artboards.af`: layered Affinity document. Every artboard has Background (image), Device (framed capture) and Headline (live text, SF Pro Display Heavy; line 1 `#F2F4F3`, line 2 green `#4FC290`, blue `#4E9EEA` or orange `#F2844A`).
- `final/`: flattened PNG exports (no alpha). `iphone-NN`, `ipad-NN` (NN = shot number), `duo-folded-01/02/04/06/08`, `duo-unfolded-01/03/04/07`, `header`, `search`, `watch-01..04` (422x514, Apple Watch Ultra) and `overview-*.png` contact sheets.
- `captures/`: raw simulator captures from build b0a3806 (1206x2622 iPhone 18 Pro, 2064x2752 iPad Pro 13" M5 portrait).
- `backgrounds/`: canvases rendered by `source/bg.swift`. `source/images/`: framed captures (Framous CLI, iPhone18Pro and iPadPro13inM5 silver).
- `source/`: `shots.json`, `affinity/make_jobs.py` (layout), `affinity/build.js` + `create2.js` (Affinity scripts, run with `affinity/run.sh`), `ph.swift`, `montage.swift`.

Rebuild: capture, frame, copy images to `~/Desktop/SetDeck 3.0 Store (Claude)/images/` (Affinity only reads the Desktop), `python3 make_jobs.py jobs.json`, `./run.sh create2.js` once, then `./run.sh build.js jobs.json`.

Health shots: a throwaway helper app (not kept) wrote 7 days of water, dietary and active energy and 5 strength workouts into the iPad simulator Health store, then SetDeck was granted read access. The iPhone Health shot uses the app's own sample chart (access had been declined there). Header and search put the devices at roughly 85% of the canvas height, bleeding off the bottom.

Apple Watch (APP_WATCH_ULTRA, 422x514): raw 422x514 captures (9:41 painted) are kept in `Marketing/SetDeck 3.0/internal (not committed)/watch-raw/` (`watch-01` routine, `-02` sets, `-04` rest timer, `-05` active set). Frame with Framous `appleWatchUltra3 --variant black-black-ocean-band`, trim the top 130 px of the 600x960 frame with `source/watchcrop.swift` (so the strap starts under the headline), copy to `~/Desktop/SetDeck 3.0 Store (Claude)/images/` as `watch-NN-slug.png`, render the canvas with `bg.swift <dir> watch 422 514 0.5 0.7 380` (save as `watch-background.png`), then `python3 make_jobs_watch.py jobs.json` and `./run.sh build.js jobs.json` (artboards `watch 01-04`, row y=11400). Headlines are 38 px: Your workout, on your wrist. / Every set, at a glance. / Log it from the rack. (green) / Rest, then go again. (orange).

New icon (Fan, 2026-11-19): `source/bg.swift` now draws the fan's three card outlines (front card plus two tilted -16/+16 degrees about a pivot below the cards, as in `AppIcon.icon`) at the same ~5% white, low and cropped by the edge. All backgrounds were regenerated (`backgrounds/`, header `bg.swift <dir> header 3840 1646 0.49 0.56 1495`, search `... search 3840 2560 0.49 0.55 2000`, watch `... watch 422 514 0.5 0.7 380`) and every artboard in `SetDeck 3.0 Artboards.af` rebuilt and re-exported. No artboard shows the app icon itself. The layered icon doc and its script are in `../../../Icons/` (`SetDeck App Icon.af`, `SetDeck App Icon (Affinity build script).js`: Background Default/Dark groups, Cards Left/Right/Front, Symbol).
