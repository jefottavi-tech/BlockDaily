"""Draws the Block Daily app icon in the game's block style (see paintBlock in lib/ui/palette.dart).

Writes assets/icon/icon.png (full icon, iOS/web/legacy Android) and assets/icon/foreground.png
(adaptive-icon foreground on transparent, kept inside the Android safe zone).
Run: python3 tools/make_icon.py  (needs Pillow), then: dart run flutter_launcher_icons
"""
import os

from PIL import Image, ImageDraw

SIZE = 1024
SS = 4  # supersampling for smooth edges
BACKGROUND = (0x16, 0x21, 0x3E)
EMPTY = (0x1E, 0x29, 0x3B)
YELLOW, PINK, GREEN, PURPLE, BLUE = (0xFF, 0xC9, 0x3C), (0xF4, 0x72, 0xB6), (0x4A, 0xDE, 0x80), (0x7C, 0x4D, 0xFF), (0x4F, 0xC3, 0xF7)

# A 3×3 board one block short of a full row: reads as "fill the gap".
GRID = [
    [YELLOW, YELLOW, None],
    [PINK, GREEN, GREEN],
    [PINK, PURPLE, BLUE],
]


def block(draw, x, y, cell, color):
    """Same proportions as paintBlock: 4% inset, 16% corner radius, a light shine band near the top."""
    d = cell * 0.04
    draw.rounded_rectangle([x + d, y + d, x + cell - d, y + cell - d], radius=cell * 0.16, fill=color + (255,))
    inset = cell * 0.14
    top = y + inset * 0.7
    # paintBlock draws white at 28% over the tile; blend it here since ImageDraw doesn't alpha-blend.
    light = tuple(round(v + (255 - v) * 0.28) for v in color)
    draw.rounded_rectangle([x + inset, top, x + cell - inset, top + cell * 0.22], radius=cell * 0.1, fill=light + (255,))


def render(grid_fraction, with_background):
    s = SIZE * SS
    img = Image.new('RGBA', (s, s), BACKGROUND + (255,) if with_background else (0, 0, 0, 0))
    base = ImageDraw.Draw(img)
    cell = s * grid_fraction / 3
    left = (s - cell * 3) / 2
    for r, row in enumerate(GRID):
        for c, color in enumerate(row):
            x, y = left + c * cell, left + r * cell
            if color is None:
                d = cell * 0.04
                base.rounded_rectangle([x + d, y + d, x + cell - d, y + cell - d], radius=cell * 0.16, fill=EMPTY + (255,))
                continue
            block(base, x, y, cell, color)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    out = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon')
    os.makedirs(out, exist_ok=True)
    render(0.70, True).convert('RGB').save(os.path.join(out, 'icon.png'))
    # Adaptive icons are masked to a circle/squircle of ~61% of the canvas: keep the grid well inside.
    render(0.50, False).save(os.path.join(out, 'foreground.png'))


if __name__ == '__main__':
    main()
