# SetDeck 3.0 App Store screenshots (draft)

Built from the design brief (`BRIEF.md`) the same way as Mygra 3.0's set. Build: local branch `claude/v3-integration` (Debug, `-uiTesting -sdSkipOnboarding`).

- `SetDeck 3.0 Artboards.af`: layered Affinity document. Every artboard has Background (image), Device (framed capture) and Headline (live text, SF Pro Display Heavy; line 1 `#F2F4F3`, line 2 green `#4FC290`, blue `#4E9EEA` or orange `#F2844A`).
- `final/`: flattened PNG exports (no alpha). `iphone-NN`, `ipad-NN` (NN = shot number), `duo-folded-01/02/04/06/08`, `duo-unfolded-01/03/04/07`, `header`, `search`, and `overview-*.png` contact sheets.
- `captures/`: raw simulator captures from build b0a3806 (1206x2622 iPhone 18 Pro, 2064x2752 iPad Pro 13" M5 portrait).
- `backgrounds/`: canvases rendered by `source/bg.swift`. `source/images/`: framed captures (Framous CLI, iPhone18Pro and iPadPro13inM5 silver).
- `source/`: `shots.json`, `affinity/make_jobs.py` (layout), `affinity/build.js` + `create2.js` (Affinity scripts, run with `affinity/run.sh`), `ph.swift`, `montage.swift`.

Rebuild: capture, frame, copy images to `~/Desktop/SetDeck 3.0 Store (Claude)/images/` (Affinity only reads the Desktop), `python3 make_jobs.py jobs.json`, `./run.sh create2.js` once, then `./run.sh build.js jobs.json`.

Health shots: a throwaway helper app (not kept) wrote 7 days of water, dietary and active energy and 5 strength workouts into the iPad simulator Health store, then SetDeck was granted read access. The iPhone Health shot uses the app's own sample chart (access had been declined there). Header and search put the devices at roughly 85% of the canvas height, bleeding off the bottom.
