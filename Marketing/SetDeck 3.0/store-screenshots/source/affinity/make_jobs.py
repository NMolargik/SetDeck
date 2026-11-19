#!/usr/bin/env python3
"""make_jobs.py <jobs-out.json>: lays out every SetDeck 3.0 store artboard (headline above, framed device below).
Images live in ~/Desktop/SetDeck 3.0 Store (Claude)/images/ as <class>-<NN>-<slug>.png (Affinity can only read the Desktop)."""
import json, os, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
DESK = os.path.expanduser("~/Desktop/SetDeck 3.0 Store (Claude)")
FONT = "SFProDisplay-Heavy"
WHITE = "#F2F4F3"; ACCENT = {"green": "#4FC290", "blue": "#4E9EEA", "orange": "#F2844A"}
CLASSES = {
    "iphone":    dict(w=1320, h=2868, y=0,     align="left",   dev=("iphone-{n}-{slug}.png", 0.78)),
    "ipad":      dict(w=2064, h=2752, y=3300,  align="centre", dev=("ipad-{n}-{slug}.png", 0.82)),
    "duo-outer": dict(w=1398, h=2034, y=6500,  align="left",   dev=("duo-folded-{n}-{slug}.png", 0.78)),
    "duo-inner": dict(w=2853, h=2007, y=9000,  align="centre", dev=("duo-unfolded-{n}-{slug}.png", None)),
}
def size(path):
    out = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", path], capture_output=True, text=True).stdout
    v = [int(l.split(":")[1]) for l in out.splitlines() if "pixel" in l]
    return v[0], v[1]
def widths(lines):
    out = subprocess.run([os.path.join(HERE, "measure"), FONT, *lines], capture_output=True, text=True, check=True).stdout
    return [float(x) / 100 for x in out.split()]
data = json.load(open(os.path.join(HERE, "shots.json")))
caps, slugs = data["captions"], data["slugs"]
jobs = []
for cls, nums in data["sets"].items():
    C = CLASSES[cls]; W, H = C["w"], C["h"]; portrait = H > W
    widest = max(widths([l for n in nums for l in caps[n][:2]]))
    fs = min(0.84 * W / widest, H * (0.052 if portrait else 0.07)) if portrait else min(0.86 * W / max(widths([caps[n][0] + " " + caps[n][1] for n in nums])), H * 0.07)
    lead = fs * 1.12; top = H * (0.06 if portrait else 0.065); margin = W * 0.075
    for i, n in enumerate(nums):
        pat, frac = C["dev"]; img = pat.format(n=n, slug=slugs[n])
        fw, fh = size(os.path.join(DESK, "images", img)); acc = ACCENT[caps[n][2]]
        if portrait: lines = [[[caps[n][0], WHITE]], [[caps[n][1], acc]]]
        else: lines = [[[caps[n][0] + " ", WHITE], [caps[n][1], acc]]]
        block = fs * 0.75 + lead * (len(lines) - 1)
        dev_top = top + block + H * 0.045
        if cls == 'ipad' and n in ('07', '08'): frac = 1.05  # zoomed device: about 128% of normal, bleeds off the bottom and slightly off the sides
        if portrait:
            dw = W * frac; dh = dw * fh / fw
        else:
            dh = H - dev_top - H * 0.04; dw = dh * fw / fh
        dx = (W - dw) / 2
        name = f"{cls} {i + 1:02d}"
        jobs.append(dict(name=name, out=f"{cls}-{i + 1:02d}-{n}", x=i * (W + 240), y=C["y"], w=W, h=H, bg=f"{cls if cls != 'duo-inner' else 'duo-unfolded'}-background.png",
                         images=[dict(file=img, x=dx, y=dev_top, w=dw, h=dh, name="Device")],
                         lines=lines, font=FONT, fontSize=round(fs, 1), leading=round(lead, 1), top=top, tracking=-0.01, align=C["align"], margin=margin))
# product page header (3840x1646) and search results (3840x2560): devices are the subject, bleeding off the bottom
L1, L2 = "Plan the week. ", "Log every set."
def w100(s): return widths([s])[0]
def asset(name, out, y0, W, H, fs, top, bg, imgs, l1, l2):
    return dict(name=name, out=out, x=0, y=y0, w=W, h=H, bg=bg, images=imgs, lines=[[[l1, WHITE], [l2, ACCENT["green"]]]], font=FONT, fontSize=round(fs, 1), leading=round(fs * 1.12, 1), top=top, tracking=-0.01, align="centre", margin=0)
iphone_h = 2760 / 1350; ipad_h = 3000 / 2300
cx = 1920
ph = 1500; pw = ph / ipad_h  # iPad
ih = 1450; iw = ih / iphone_h
span = pw + iw - 90; left = cx - span / 2
header = asset("header 21x9", "header", 12000, 3840, 1646, 2300 / w100(L1 + L2), 110, "header-background.png", [
    dict(file="ipad-01-routine.png", x=left, y=330, w=pw, h=ph, name="iPad"),
    dict(file="iphone-02-logged.png", x=left + pw - 90, y=380, w=iw, h=ih, name="iPhone")], L1, L2)
M1, M2 = "Your week, ", "one deck at a time."
sw = 1050; sh = sw * iphone_h; off = 1160
search = asset("search 3x2", "search", 14000, 3840, 2560, 2500 / w100(M1 + M2), 130, "search-background.png", [
    dict(file="iphone-01-routine.png", x=cx - off - sw / 2, y=470, w=sw, h=sh, name="iPhone 1"),
    dict(file="iphone-03-edit.png", x=cx + off - sw / 2, y=470, w=sw, h=sh, name="iPhone 3"),
    dict(file="iphone-02-logged.png", x=cx - sw / 2, y=430, w=sw, h=sh, name="iPhone 2")], M1, M2)
jobs += [header, search]
json.dump(jobs, open(sys.argv[1], "w"), indent=1); print(len(jobs), "jobs")
