"""Synthesizes the game's sound effects into assets/sfx (no third-party audio, no licensing).

Run: python3 tools/make_sfx.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "sfx"


def note(freq, dur, vol=0.5, attack=0.004, decay=8.0, harmonics=((1, 1.0), (2, 0.3), (3, 0.12))):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / attack) * math.exp(-decay * t)
        s = sum(a * math.sin(2 * math.pi * freq * h * t) for h, a in harmonics)
        out.append(vol * env * s / sum(a for _, a in harmonics))
    return out


def mix(*tracks):
    """tracks: (start_seconds, samples)"""
    length = max(int(start * RATE) + len(s) for start, s in tracks)
    buf = [0.0] * length
    for start, s in tracks:
        o = int(start * RATE)
        for i, v in enumerate(s):
            buf[o + i] += v
    return buf


def noise(dur, vol=0.3, decay=30.0, seed=1):
    rng = random.Random(seed)
    return [vol * rng.uniform(-1, 1) * math.exp(-decay * i / RATE) for i in range(int(RATE * dur))]


def save(name, samples):
    peak = max(1e-9, max(abs(v) for v in samples))
    scale = min(1.0, 0.9 / peak)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(v * scale * 32767)) for v in samples))


OUT.mkdir(parents=True, exist_ok=True)

# Picking a piece up: short soft blip.
save("pick", note(660, 0.06, vol=0.25, decay=40))
# Placing: wooden "tock".
save("place", mix((0, note(180, 0.09, vol=0.6, decay=45, harmonics=((1, 1), (2.7, 0.4)))), (0, noise(0.03, vol=0.25, decay=120))))
# Line clear: rising arpeggio, higher with each combo level (1..5).
base = [523.25, 587.33, 659.25, 783.99, 880.0]  # C D E G A
for level in range(1, 6):
    shift = 2 ** ((level - 1) * 2 / 12)  # +2 semitones per combo level
    tones = [(i * 0.055, note(f * shift, 0.35, vol=0.35, decay=7)) for i, f in enumerate(base[:4])]
    save(f"clear{level}", mix(*tones, (0, noise(0.12, vol=0.08, decay=25, seed=level))))
# Perfect clear: bright major chord + sparkle.
chord = [523.25, 659.25, 783.99, 1046.5]
save("perfect", mix(*[(i * 0.03, note(f, 0.9, vol=0.3, decay=3.5)) for i, f in enumerate(chord)],
                    *[(0.25 + i * 0.06, note(2093 * (1 + i * 0.12), 0.15, vol=0.12, decay=20)) for i in range(5)]))
# Game over: descending minor.
save("gameover", mix(*[(i * 0.16, note(f, 0.5, vol=0.35, decay=5)) for i, f in enumerate([392.0, 311.13, 261.63])]))
print("written:", sorted(p.name for p in OUT.glob("*.wav")))
