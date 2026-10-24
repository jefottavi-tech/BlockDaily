"""Draws the Block Daily app icon: the game's blocks plus the Kallistesoft brand marks.

Brand marks, the same on every Kallistesoft game icon: the gold sun (top right), the light-blue
waves (bottom), and K / S in navy on the hero's top-left and bottom-right elements. Only the hero
(here a 3x3 board one block short of full, drawn like paintBlock in lib/ui/palette.dart) and the
background color change between games.

Writes assets/icon/icon.png (iOS, web, legacy Android) and, for the Android adaptive icon,
assets/icon/background.png (background + waves) and assets/icon/foreground.png (hero + sun),
with the design shrunk into the area Android never crops.
Run: python3 tools/make_icon.py  (needs Pillow), then regenerate sizes as in flutter_launcher_icons.yaml.
"""
import math
import os

from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
SS = 4  # supersampling for smooth edges
S = SIZE * SS

# Kallistesoft brand (from kallistesoft.ca/assets/logo.svg).
SUN = (0xF2, 0xB1, 0x34)
WAVE = (0x63, 0xB6, 0xE6)
INK = (0x16, 0x21, 0x3E)  # K and S
FONT = '/System/Library/Fonts/Supplemental/Arial Black.ttf'

# Block Daily.
BACKGROUND = (0x16, 0x21, 0x3E)
EMPTY = (0x1E, 0x29, 0x3B)
YELLOW, PINK, GREEN, PURPLE, BLUE = (0xFF, 0xC9, 0x3C), (0xF4, 0x72, 0xB6), (0x4A, 0xDE, 0x80), (0x7C, 0x4D, 0xFF), (0x4F, 0xC3, 0xF7)
GRID = [
    [YELLOW, YELLOW, None],
    [PINK, GREEN, GREEN],
    [PINK, PURPLE, BLUE],
]

# Android shows only the middle 72/108 of an adaptive icon, sometimes as a circle.
ADAPTIVE_SCALE = 72 / 108


class Canvas:
    """Draws in design units (0..1 of the full icon), optionally shrunk around the center."""

    def __init__(self, img, scale=1.0):
        self.img, self.draw, self.scale = img, ImageDraw.Draw(img), scale

    def p(self, v, axis_center=0.5):
        return (axis_center + (v - axis_center) * self.scale) * S

    def len(self, v):
        return v * self.scale * S


def waves(cv, top):
    # Gentle sine along the top edge, filled down to the bottom of the canvas.
    amp, pts = 0.02, []
    for i in range(0, 201):
        x = i / 200
        pts.append((cv.p(x), cv.p(top + amp * math.sin(x * 2 * math.pi * 2.5))))
    # Stretch the band across the whole canvas even when the design is shrunk.
    pts[0], pts[-1] = (0, pts[0][1]), (S, pts[-1][1])
    cv.draw.polygon(pts + [(S, S), (0, S)], fill=WAVE)


def sun(cv):
    cx, cy, r = cv.p(0.79), cv.p(0.19), cv.len(0.055)
    cv.draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=SUN)


def block(cv, x, y, c, color):
    """Same proportions as paintBlock: 4% inset, 16% corner radius, a light shine band near the top."""
    d = c * 0.04
    cv.draw.rounded_rectangle([x + d, y + d, x + c - d, y + c - d], radius=c * 0.16, fill=color)
    inset = c * 0.14
    top = y + inset * 0.7
    # paintBlock draws white at 28% over the tile; blend it here since ImageDraw doesn't alpha-blend.
    light = tuple(round(v + (255 - v) * 0.28) for v in color)
    cv.draw.rounded_rectangle([x + inset, top, x + c - inset, top + c * 0.22], radius=c * 0.1, fill=light)


def letter(cv, x, y, c, ch):
    font = ImageFont.truetype(FONT, int(c * 0.62))
    b = cv.draw.textbbox((0, 0), ch, font=font)
    # Slightly below center so the shine band stays visible.
    cv.draw.text((x + c / 2 - (b[0] + b[2]) / 2, y + c * 0.56 - (b[1] + b[3]) / 2), ch, font=font, fill=INK)


def hero(cv):
    # Board slightly left and down, leaving the top-right corner to the sun.
    c = cv.len(0.50 / 3)
    left, top = cv.p(0.46) - c * 1.5, cv.p(0.47) - c * 1.5
    for r, row in enumerate(GRID):
        for q, color in enumerate(row):
            x, y = left + q * c, top + r * c
            if color is None:
                d = c * 0.04
                cv.draw.rounded_rectangle([x + d, y + d, x + c - d, y + c - d], radius=c * 0.16, fill=EMPTY)
            else:
                block(cv, x, y, c, color)
    letter(cv, left, top, c, 'K')
    letter(cv, left + 2 * c, top + 2 * c, c, 'S')


def save(img, path, rgb=True):
    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    (img.convert('RGB') if rgb else img).save(path)


def main():
    out = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon')
    os.makedirs(out, exist_ok=True)

    full = Canvas(Image.new('RGBA', (S, S), BACKGROUND + (255,)))
    waves(full, 0.80)
    sun(full)
    hero(full)
    save(full.img, os.path.join(out, 'icon.png'))

    back = Canvas(Image.new('RGBA', (S, S), BACKGROUND + (255,)), ADAPTIVE_SCALE)
    waves(back, 0.80)
    save(back.img, os.path.join(out, 'background.png'))

    front = Canvas(Image.new('RGBA', (S, S), (0, 0, 0, 0)), ADAPTIVE_SCALE)
    sun(front)
    hero(front)
    save(front.img, os.path.join(out, 'foreground.png'), rgb=False)


if __name__ == '__main__':
    main()
