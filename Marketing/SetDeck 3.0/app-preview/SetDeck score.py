#!/usr/bin/env python3
"""SetDeck App Preview score (original, composed for this cut).

Two candidates share one structure, time-locked to the cut (128 BPM, 30.0 s, 64 beats):
  A  "Floor Day"   house / workout electronic: four-on-the-floor, offbeat stabs, gritty saw bass, bright pluck hook
  B  "Heavy Set"   trap-leaning hip-hop: half-time clap, rolling hats, sliding 808, dark bell hook

Beat map (beat = 60/128 s = 0.46875 s):
  b0      hit on the SetDeck mark, riser into the drop
  b8      3.75 s  drop: first scene (log every set)
  b20     9.375 s deck swipe, hook enters
  b52     24.375 s achievement unlock: pre-drop gap, then the big hit
  b59.5   everything stops
  b60     28.125 s end card hit, rings out to 30.0 s

usage: python "SetDeck score.py" A|B   -> writes SetDeck score A floor day.wav / SetDeck score B heavy set.wav
"""
import sys
import numpy as np
from scipy import signal
from scipy.io import wavfile
import pyloudnorm as pyln

SR = 48000
BPM = 128.0
BEAT = 60.0 / BPM
DUR = 30.0
N = int(SR * DUR)
rng = np.random.default_rng(7)
DEBUG = True

# ---------------------------------------------------------------- helpers
def mtof(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)

def tsec(b):
    return b * BEAT

def lp(x, fc, order=2):
    fc = min(fc, SR * 0.45)
    return signal.sosfilt(signal.butter(order, fc, 'low', fs=SR, output='sos'), x)

def hp(x, fc, order=2):
    return signal.sosfilt(signal.butter(order, fc, 'high', fs=SR, output='sos'), x)

def bp(x, lo, hi, order=2):
    return signal.sosfilt(signal.butter(order, [lo, hi], 'band', fs=SR, output='sos'), x)

def add(buf, x, t0, gain=1.0):
    i = int(round(t0 * SR))
    if i >= len(buf) or i + len(x) <= 0:
        return
    a = max(0, -i)
    j = i + a
    k = min(len(x) - a, len(buf) - j)
    buf[j:j + k] += x[a:a + k] * gain

def env(n, attack=0.002, decay=0.2, curve=4.0):
    t = np.arange(n) / SR
    e = np.exp(-t / max(decay, 1e-4) * curve / 4.0 * 4.0 / 4.0)
    a = np.minimum(1.0, t / max(attack, 1e-5))
    return e * a

def saw(f, n, phase=0.0):
    ph = np.mod(phase + np.cumsum(np.full(n, f / SR)), 1.0)
    return 2 * ph - 1

def pulse(f, n, w=0.5):
    ph = np.mod(np.cumsum(np.full(n, f / SR)), 1.0)
    return np.where(ph < w, 1.0, -1.0)

def sine_sweep(f0, f1, n, curve=6.0):
    t = np.arange(n) / SR
    f = f1 + (f0 - f1) * np.exp(-t * curve / (n / SR))
    return np.sin(2 * np.pi * np.cumsum(f) / SR)

def noise(n):
    return rng.standard_normal(n)

def reverb_ir(length=1.4, decay=3.2, seed=3):
    r = np.random.default_rng(seed)
    n = int(SR * length)
    t = np.arange(n) / SR
    ir = r.standard_normal(n) * np.exp(-t * decay)
    ir = lp(ir, 6000)
    ir[:int(0.012 * SR)] *= np.linspace(0, 1, int(0.012 * SR))
    return ir / np.sqrt(np.sum(ir ** 2))

IR = reverb_ir()

def reverb(x, wet=1.0):
    return signal.fftconvolve(x, IR)[:len(x)] * wet

# ---------------------------------------------------------------- drum voices
def kick(vel=1.0, punch=1.0, length=0.38):
    n = int(SR * length)
    body = sine_sweep(170 * punch, 46, n, curve=7) * env(n, 0.001, 0.22) * 1.0
    click = hp(noise(int(SR * 0.012)), 2500) * np.linspace(1, 0, int(SR * 0.012)) * 0.25
    body[:len(click)] += click
    sub = np.sin(2 * np.pi * 48 * np.arange(n) / SR) * env(n, 0.001, 0.3) * 0.5
    return np.tanh((body + sub) * 1.4) * 0.9 * vel

def clap(vel=1.0, tail=0.22):
    n = int(SR * (tail + 0.05))
    out = np.zeros(n)
    for off in (0.0, 0.011, 0.023):
        m = int(SR * 0.03)
        burst = bp(noise(m), 900, 3800) * np.exp(-np.arange(m) / SR / 0.012)
        i = int(off * SR)
        out[i:i + m] += burst
    t = bp(noise(n), 1000, 3600) * np.exp(-np.arange(n) / SR / (tail * 0.4))
    out += t * 0.55
    return out / (np.max(np.abs(out)) + 1e-9) * 0.8 * vel

def snare_rim(vel=1.0):
    n = int(SR * 0.12)
    tone = np.sin(2 * np.pi * 330 * np.arange(n) / SR) * env(n, 0.0005, 0.05)
    nz = hp(noise(n), 1800) * env(n, 0.0005, 0.05)
    return (tone * 0.5 + nz * 0.7) * vel

def hat(vel=1.0, open_=False):
    d = 0.16 if open_ else 0.035
    n = int(SR * (d * 2.2))
    x = hp(noise(n), 7500, 3) * np.exp(-np.arange(n) / SR / d)
    return x * 0.5 * vel

def crash(length=2.4, vel=1.0):
    n = int(SR * length)
    x = hp(noise(n), 4000, 2) * np.exp(-np.arange(n) / SR / 0.9)
    return x * 0.5 * vel

def riser(length, f0=300, f1=9000, vel=1.0):
    n = int(SR * length)
    x = noise(n)
    out = np.zeros(n)
    steps = 40
    for s in range(steps):
        a, b = int(n * s / steps), int(n * (s + 1) / steps)
        fc = f0 * (f1 / f0) ** (s / steps)
        out[a:b] = hp(x[a:b], fc, 2)
    amp = np.linspace(0.05, 1, n) ** 2.2
    return out * amp * 0.5 * vel

def impact(vel=1.0):
    n = int(SR * 1.6)
    x = sine_sweep(120, 36, n, curve=5) * env(n, 0.001, 0.9)
    return np.tanh(x * 1.6) * 0.8 * vel

# ---------------------------------------------------------------- tonal voices
def bass_saw(f, dur, cutoff=900, drive=2.5, vel=1.0):
    n = int(SR * (dur + 0.05))
    x = saw(f, n) * 0.6 + pulse(f * 0.5, n, 0.35) * 0.5 + saw(f * 1.004, n) * 0.4
    e = env(n, 0.003, dur * 0.9)
    x = lp(x, cutoff) * e
    x = np.tanh(x * drive)
    g = np.ones(n)
    r = int(SR * 0.03)
    if n > r:
        g[-r:] = np.linspace(1, 0, r)
    return x * g * 0.55 * vel

def sub808(f, dur, slide_from=None, vel=1.0, dist=2.2):
    n = int(SR * dur)
    t = np.arange(n) / SR
    fr = np.full(n, float(f))
    if slide_from:
        sl = np.exp(-t / 0.07)
        fr = f + (slide_from - f) * sl
    ph = 2 * np.pi * np.cumsum(fr) / SR
    x = np.sin(ph) + 0.25 * np.sin(2 * ph)
    e = np.exp(-t / (dur * 0.65))
    a = np.minimum(1.0, t / 0.004)
    x = np.tanh(x * e * a * dist)
    r = int(SR * 0.04)
    g = np.ones(n)
    g[-r:] = np.linspace(1, 0, r)
    return x * g * 0.7 * vel

def pluck_super(f, dur, vel=1.0, bright=6000):
    n = int(SR * (dur + 0.25))
    x = np.zeros(n)
    for det, g in ((-0.012, 0.6), (0.0, 1.0), (0.012, 0.6), (0.006, 0.5)):
        x += saw(f * (1 + det), n, rng.random()) * g
    e = env(n, 0.002, dur * 0.7 + 0.08)
    x = lp(x, bright) * e
    return x * 0.18 * vel

def stab(midis, dur=0.14, vel=1.0, cutoff=3200):
    n = int(SR * (dur + 0.12))
    x = np.zeros(n)
    for m in midis:
        f = mtof(m)
        for det in (-0.008, 0.008):
            x += saw(f * (1 + det), n, rng.random())
    e = env(n, 0.002, dur)
    return lp(x, cutoff) * e * 0.07 * vel

def pad(midis, dur, vel=1.0, cutoff_from=400, cutoff_to=5000):
    n = int(SR * dur)
    x = np.zeros(n)
    for m in midis:
        f = mtof(m)
        for det in (-0.01, 0.0, 0.01):
            x += saw(f * (1 + det), n, rng.random())
    out = np.zeros(n)
    steps = 24
    for s in range(steps):
        a, b = int(n * s / steps), int(n * (s + 1) / steps)
        fc = cutoff_from * (cutoff_to / cutoff_from) ** (s / steps)
        out[a:b] = lp(x[a:b], fc)
    e = np.minimum(1.0, np.arange(n) / SR / (dur * 0.6)) ** 1.5
    return out * e * 0.04 * vel

def bell(f, dur=1.2, vel=1.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    mod = np.sin(2 * np.pi * f * 3.5 * t) * 2.2 * np.exp(-t / 0.35)
    x = np.sin(2 * np.pi * f * t + mod) + 0.3 * np.sin(2 * np.pi * f * 2 * t)
    return x * np.exp(-t / (dur * 0.35)) * 0.22 * vel

def sparkle(t0, mix, notes, gap=0.07, vel=1.0):
    for i, m in enumerate(notes):
        add(mix, bell(mtof(m), 1.4, vel), t0 + i * gap)

# ---------------------------------------------------------------- song map
PROG = {0: ([48, 52, 55], 36, 60), 1: ([43, 47, 50], 31, 55), 2: ([50, 54, 57], 38, 62), 3: ([52, 55, 59], 40, 64)}
# bar n (from b8) -> chord index: C, G, D, Em repeating, with bar 3 = Em
#   (midi triad for stabs, bass root midi, hook root)
CHORD_ORDER = [0, 1, 2, 3]   # C G D Em

def chord_for_bar(n):
    return CHORD_ORDER[n % 4]

# hook motifs (eighth-note index, midi, length in eighths) per chord
HOOK = {
    3: [(0, 76, 1), (1, 79, 1), (3, 83, 1), (4, 79, 1), (6, 76, 2)],            # Em
    0: [(0, 72, 1), (1, 76, 1), (3, 79, 1), (4, 76, 1), (6, 72, 2)],            # C
    1: [(0, 74, 1), (1, 79, 1), (3, 83, 1), (4, 79, 1), (6, 74, 2)],            # G
    2: [(0, 74, 1), (1, 78, 1), (3, 81, 1), (4, 78, 1), (6, 74, 1), (7, 78, 1)],  # D
}
HOOK_B = {   # sparser, darker bell line for the trap version
    3: [(0, 71, 2), (3, 74, 1), (6, 76, 2)],
    0: [(0, 67, 2), (3, 72, 1), (6, 71, 2)],
    1: [(0, 62, 2), (3, 67, 1), (6, 71, 2)],
    2: [(0, 66, 2), (3, 69, 1), (6, 74, 2)],
}

def build(style):
    drums = np.zeros(N)
    kicks = np.zeros(N)    # kick-only for sidechain
    bass = np.zeros(N)
    music = np.zeros(N)
    lead = np.zeros(N)
    fx = np.zeros(N)

    def K(b, vel=1.0, **kw):
        k = kick(vel, **kw)
        add(drums, k, tsec(b))
        add(kicks, np.abs(k) * 0 + 1.0, tsec(b), 1.0) if False else None
        i = int(tsec(b) * SR)
        ln = int(SR * 0.22)
        kicks[i:i + ln] = np.maximum(kicks[i:i + ln], np.linspace(1, 0, min(ln, len(kicks) - i)) ** 0.8)

    # ------------------------------------------------ intro (b0-b8): the mark builds
    add(fx, impact(1.0), 0.0)
    K(0, 1.1)
    add(fx, riser(tsec(8), 250, 11000, 1.0), 0.0)
    # card thunks / icon plucks locked to the mark animation
    for t0, g in ((0.05, 0.5), (0.28, 0.55), (0.50, 0.6)):
        add(fx, sub808(55, 0.18, vel=0.8) * g, t0)
    for t0, m in ((0.95, 88), (1.12, 91), (1.29, 95)):
        add(fx, bell(mtof(m), 0.9, 1.0), t0)
    add(fx, bell(mtof(64 + 24), 1.6, 0.8), 1.55)
    add(music, pad([40, 47, 52, 55, 59], tsec(8), 1.0, 300, 4500), 0.0)
    for b in np.arange(2, 8, 0.5):
        add(drums, hat(0.25 + 0.04 * b), tsec(b))
    for b in range(4, 8):
        K(b, 0.8)
    if style == 'A':
        # snare roll into the drop: 16ths then 32nds
        for i, b in enumerate(np.arange(6.0, 7.5, 0.25)):
            add(drums, clap(0.25 + 0.05 * i, tail=0.08), tsec(b))
        for i, b in enumerate(np.arange(7.5, 8.0, 0.125)):
            add(drums, clap(0.5 + 0.08 * i, tail=0.06), tsec(b))
    else:
        for i, b in enumerate(np.arange(6.0, 8.0, 0.1667)):   # triplet-ish hat roll
            add(drums, hat(0.3 + 0.045 * i), tsec(b))
        add(drums, clap(0.9), tsec(7.0))

    # ------------------------------------------------ the groove
    END = 59.5
    last_bar = int((60 - 8) / 4)   # bars from b8 to b60
    for n in range(0, last_bar):
        b0 = 8 + 4 * n
        ci = chord_for_bar(n)
        triad, broot, hroot = PROG[ci]
        in_hook = b0 >= 20
        pre_ach = (b0 >= 48 and b0 < 52)
        big = b0 >= 52
        if b0 >= END:
            break
        # ---- drums & bass per style
        if style == 'A':
            for beat in range(4):
                if pre_ach and beat >= 2:
                    continue
                K(b0 + beat, 1.0)
            for beat in (1, 3):
                if pre_ach and beat == 3:
                    continue
                add(drums, clap(0.9), tsec(b0 + beat))
            for e in range(8):
                bb = b0 + e * 0.5
                if bb >= 51.5 and bb < 52:
                    continue
                if e % 2 == 1:
                    add(drums, hat(0.7, open_=True), tsec(bb))
                else:
                    add(drums, hat(0.35), tsec(bb))
            for s in range(16):
                if s % 2 == 1 and s % 4 != 3:
                    add(drums, hat(0.15), tsec(b0 + s * 0.25))
            # gritty saw bass, 8th groove
            for e in (0, 2, 3, 5, 7):
                bb = b0 + e * 0.5
                if bb >= 51.5 and bb < 52:
                    continue
                f = mtof(broot)
                if e in (5,):
                    f *= 2
                add(bass, bass_saw(f, BEAT * 0.46, 700 + 400 * (1 if big else 0), 2.6), tsec(bb))
            # offbeat stabs
            if b0 >= 12 and not pre_ach or big:
                for e in (1, 3, 5, 7):
                    add(music, stab([t + 12 for t in triad], 0.13, 1.0 if in_hook else 0.7), tsec(b0 + e * 0.5))
            # hook
            if in_hook and not pre_ach:
                for (idx, m, ln) in HOOK[ci]:
                    mm = m + (12 if (big and idx in (0, 6)) else 0)
                    add(lead, pluck_super(mtof(mm), ln * BEAT * 0.5 * 0.95, 1.0), tsec(b0 + idx * 0.5))
        else:
            # B: half-time trap. kick 0, 7, 10 (16ths) ; clap on beat 3 ; rolling hats ; sliding 808
            for s in (0, 7, 10):
                if pre_ach and s >= 8:
                    continue
                K(b0 + s * 0.25, 1.0 if s == 0 else 0.8, punch=0.8, length=0.3)
            add(drums, clap(1.0, tail=0.3), tsec(b0 + 2))
            add(drums, snare_rim(0.5), tsec(b0 + 2))
            for s in range(16):
                bb = b0 + s * 0.25
                if bb >= 51.5 and bb < 52:
                    continue
                v = 0.55 if s % 4 == 0 else (0.35 if s % 2 == 0 else 0.22)
                add(drums, hat(v), tsec(bb))
            if n % 2 == 1:   # roll in the last beat every other bar
                for i in range(6):
                    add(drums, hat(0.25 + 0.06 * i), tsec(b0 + 3.0 + i * (1 / 6)))
            add(drums, hat(0.8, open_=True), tsec(b0 + 3.5))
            f = mtof(broot - 12 + 12)
            prev_f = mtof(PROG[chord_for_bar(n - 1)][1]) if n > 0 else None
            add(bass, sub808(f * 0.5 * 2 if False else f, BEAT * 2.9, slide_from=prev_f, vel=1.0), tsec(b0))
            if not pre_ach:
                add(bass, sub808(f, BEAT * 0.9, slide_from=f * 1.5, vel=0.8), tsec(b0 + 2.5))
            # dark bell hook + low pad
            if in_hook and not pre_ach:
                for (idx, m, ln) in HOOK_B[ci]:
                    add(lead, bell(mtof(m + (12 if big else 0)), 1.0, 1.0), tsec(b0 + idx * 0.5))
            if b0 >= 12:
                add(music, pad([t + 12 for t in triad], BEAT * 4, 0.9, 500, 2500), tsec(b0))

    # ------------------------------------------------ crash + impact at the drop and the achievement
    add(fx, crash(2.8, 1.0), tsec(8))
    add(fx, impact(0.7), tsec(8))
    # pre-achievement build: riser b48-b52, snare roll, then the gap
    add(fx, riser(tsec(3.5), 400, 12000, 0.9), tsec(48))
    for i, b in enumerate(np.arange(49.0, 51.5, 0.25)):
        add(drums, clap(0.25 + 0.07 * i, tail=0.07), tsec(b))
    # the hit: b52 (24.375 s)
    add(fx, crash(3.0, 1.2), tsec(52))
    add(fx, impact(1.1), tsec(52))
    add(fx, riser(0.6, 2000, 14000, 0.0), tsec(52))
    sparkle(tsec(52), fx, [88, 91, 95, 100], 0.06, 0.9)

    # tiny UI ticks that follow the recorded taps (log checks, water add)
    for t0 in (5.58, 8.42):
        add(fx, bell(mtof(93), 0.5, 0.6), t0)
    add(fx, bell(mtof(88), 0.5, 0.5), 23.25)
    # whooshes into the scene cuts
    for t0 in (9.38, 12.2, 16.42, 18.82, 21.62):
        add(fx, riser(0.28, 1500, 9000, 0.7), t0 - 0.28)

    # ------------------------------------------------ stop at b59.5, end card at b60
    cut = int(tsec(59.5) * SR)
    for arr in (drums, bass, music, lead):
        fade = int(0.04 * SR)
        arr[cut - fade:cut] *= np.linspace(1, 0, fade)
        arr[cut:] = 0
    # fx tails (crash) stop too
    fx[cut:int(tsec(60) * SR)] *= 0
    # end card hit: tonic chord, sub + bell shimmer, rings to 30.0
    t_end = tsec(60)
    K(60, 1.0)
    add(fx, impact(1.0), t_end)
    add(fx, crash(1.9, 0.8), t_end)
    add(music, pad([40, 47, 52, 55, 59, 64], 1.9, 1.5, 3000, 5000), t_end)
    sparkle(t_end, fx, [76, 83, 88, 91, 95], 0.08, 0.8)
    sparkle(t_end + 0.6, fx, [100, 95, 91], 0.1, 0.5)
    if style == 'A':
        add(bass, bass_saw(mtof(40), 1.9, 600, 1.6), t_end)
    else:
        add(bass, sub808(mtof(40), 1.9, vel=1.0), t_end)

    # ------------------------------------------------ mix
    # sidechain: pump bass, music, lead against the kick
    duck = 1.0 - 0.75 * kicks
    duck_slow = 1.0 - 0.45 * kicks
    G = dict(drums=0.5, bass=0.55, music=2.2, lead=2.2, fx=0.6)
    if DEBUG:
        for nm, a in (('drums', drums), ('bass', bass), ('music', music), ('lead', lead), ('fx', fx)):
            print(nm, 'rms %.3f' % np.sqrt(np.mean((a * G[nm]) ** 2)))
    mix = (drums * G['drums']
           + bass * G['bass'] * duck
           + music * G['music'] * duck
           + lead * G['lead'] * duck_slow
           + fx * G['fx'])
    # a little room on the lead, stabs and clap
    wet = reverb(lead * 0.8 + music * 0.35, 1.0)
    mix += wet * 0.35
    # slight stereo: lead and hats lean opposite
    L = mix.copy()
    R = mix.copy()
    d = int(0.0004 * SR)
    L += np.roll(lead, d) * 0.12
    R += np.roll(lead, -d) * 0.12
    L += np.roll(hp(drums, 6000), d) * 0.2
    R += np.roll(hp(drums, 6000), -d) * 0.2
    stereo = np.stack([L, R], axis=1)
    # master: gentle glue, loudness to -14 LUFS, soft ceiling
    meter = pyln.Meter(SR)
    for _ in range(3):
        loud = meter.integrated_loudness(stereo)
        stereo = stereo * 10 ** ((-14.0 - loud) / 20)
        stereo = np.tanh(stereo * 1.0 / 0.95) * 0.95
    # fade out only the very last 0.35 s
    fo = int(0.35 * SR)
    stereo[-fo:] *= np.linspace(1, 0, fo)[:, None]
    # final trim so true peak sits at -1.0 dBFS or below
    pk = np.max(np.abs(stereo))
    if pk > 0.891:
        stereo *= 0.891 / pk
    loud = meter.integrated_loudness(stereo)
    print(style, 'LUFS %.2f' % loud, 'peak %.3f' % np.max(np.abs(stereo)))
    return stereo

if __name__ == '__main__':
    style = (sys.argv[1] if len(sys.argv) > 1 else 'A').upper()
    out = build(style)
    name = {'A': 'SetDeck score A floor day.wav', 'B': 'SetDeck score B heavy set.wav'}[style]
    path = '/Users/nickmolargik/Movies/Matte/SetDeck/' + name
    wavfile.write(path, SR, (np.clip(out, -1, 1) * 32767).astype(np.int16))
    print(path)
