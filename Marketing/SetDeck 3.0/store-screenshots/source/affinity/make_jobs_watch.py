#!/usr/bin/env python3
"""make_jobs_watch.py <jobs-out.json>: the four 422x514 Apple Watch Ultra artboards (headline above, Framous appleWatchUltra3 frame below).
Frames live in ~/Desktop/SetDeck 3.0 Store (Claude)/images/watch-NN-slug.png, already cropped to 600x830 (top band trimmed so the strap starts under the headline)."""
import json, os, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
FONT = "SFProDisplay-Heavy"; WHITE = "#F2F4F3"; GREEN = "#4FC290"; ORANGE = "#F2844A"
W, H = 422, 514
SHOTS = [("01", "watch-01-routine.png", "Your workout,", "on your wrist.", GREEN),
         ("02", "watch-02-sets.png", "Every set,", "at a glance.", GREEN),
         ("03", "watch-03-log.png", "Log it", "from the rack.", GREEN),
         ("04", "watch-04-rest.png", "Rest, then", "go again.", ORANGE)]
lines = [l for s in SHOTS for l in s[2:4]]
out = subprocess.run([os.path.join(HERE, "measure"), FONT, *lines], capture_output=True, text=True, check=True).stdout
widest = max(float(x) / 100 for x in out.split())
fs = min(0.86 * W / widest, 38); lead = fs * 1.12; top = 26
dw = 336; dh = dw * 830 / 600; dev_top = top + fs * 0.75 + lead + 24
jobs = [dict(name=f"watch {i + 1:02d}", out=f"watch-{i + 1:02d}-{n}", x=i * (W + 120), y=11400, w=W, h=H, bg="watch-background.png",
             images=[dict(file=f, x=(W - dw) / 2, y=dev_top, w=dw, h=dh, name="Device")],
             lines=[[[a, WHITE]], [[b, c]]], font=FONT, fontSize=round(fs, 1), leading=round(lead, 1), top=top, tracking=-0.01, align="centre", margin=0)
        for i, (n, f, a, b, c) in enumerate(SHOTS)]
json.dump(jobs, open(sys.argv[1], "w"), indent=1); print(len(jobs), "jobs, font", round(fs, 1))
