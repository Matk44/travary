#!/usr/bin/env python3
"""Readies Travi's cameo stills for the films (Scene Studio, first + last frame).

The six peeks came back from imagegen on one mark already (made from one base
image): the handle's grip and the top of his body sit on the same pixels in
all six, and his body runs into the bottom edge, which is the edge he hides
behind in the app. This checks that (it stops if a new still drifts), then:

- makes the green perfectly flat #00B140 (keyed and laid back on green), so
  Seedance keeps a still background and the films key cleanly;
- scales the 1254 px originals to 1024 x 1024 (the films are 1:1);
- adds peek-empty: plain green, for "pop up" and "duck";
- writes contact.png (every frame keyed onto the app's paper) and, when
  `tool/visual_qa.sh` has rendered the countdown, in-place.png (peeks over
  the countdown postcard at their likely size).

Output: registered/. Needs numpy, Pillow and SciPy:
    python3 -m venv /tmp/kf && /tmp/kf/bin/pip install numpy pillow scipy
    /tmp/kf/bin/python docs/mockups/travi-cameos-v1/build_cameos.py
"""
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'registered')
ROOT = os.path.abspath(os.path.join(HERE, '../../..'))
COUNTDOWN = os.path.join(ROOT, 'build/visual_qa/countdown_844_actual.png')
SIZE = 1024
GREEN = np.array([0, 177, 64], np.float32)  # #00B140
PAPER = np.array([239, 231, 218], np.float32)

PEEKS = ['peek-hello', 'peek-wave', 'peek-cheer', 'peek-packing', 'peek-ready', 'peek-today']
LOUNGE = 'lounge'
# The peeks' grip may differ by this much (original px) before they need
# lining up by hand.
TOLERANCE = 4


def load(name):
    return np.asarray(Image.open(os.path.join(HERE, f'{name}.png')).convert('RGB')).astype(np.float32)


def keyed(im):
    """RGBA float: green-difference key, spill pulled from soft edges."""
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    alpha = 1 - np.clip((g - np.maximum(r, b) - 30) / 50, 0, 1)
    out = im.copy()
    edge = alpha < 0.98
    out[..., 1] = np.where(edge, np.minimum(g, np.maximum(r, b)), g)
    return np.dstack([out, alpha])


def grip(rgba):
    """The navy grip and carry handle at the top: (left, top, right)."""
    rgb, a = rgba[..., :3], rgba[..., 3] > 0.5
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    navy = (b > r + 15) & (b > g) & (r < 90) & (g < 90) & a
    navy[int(navy.shape[0] * 0.3):] = False
    ys, xs = np.nonzero(navy)
    return int(xs.min()), int(ys.min()), int(xs.max())


def resized(rgba, size):
    """Premultiplied resize (no green fringes)."""
    pre = rgba.copy()
    pre[..., :3] *= pre[..., 3:4]
    chans = [np.asarray(Image.fromarray(pre[..., c]).resize((size, size), Image.LANCZOS)) for c in range(4)]
    out = np.dstack(chans)
    a = np.clip(out[..., 3:4], 0, 1)
    out[..., :3] = np.where(a > 1e-4, out[..., :3] / np.maximum(a, 1e-4), 0)
    out[..., 3:4] = a
    return out


def over(background, layer):
    a = layer[..., 3:4]
    return background * (1 - a) + np.clip(layer[..., :3], 0, 255) * a


def save(rgb, name):
    Image.fromarray(np.clip(rgb, 0, 255).round().astype(np.uint8)).save(os.path.join(OUT, f'{name}.png'))


def rgba_image(rgba):
    return Image.fromarray(np.dstack([np.clip(rgba[..., :3], 0, 255), rgba[..., 3:4] * 255]).round().astype(np.uint8), 'RGBA')


def main():
    os.makedirs(OUT, exist_ok=True)
    frames = {name: keyed(load(name)) for name in PEEKS + [LOUNGE]}

    marks = {name: grip(frames[name]) for name in PEEKS}
    reference = marks['peek-hello']
    for name, mark in marks.items():
        drift = max(abs(m - r) for m, r in zip(mark, reference))
        print(f'{name}: grip {mark}, {drift} px from peek-hello')
        if drift > TOLERANCE:
            raise SystemExit(f'{name} is off the mark by {drift} px: line it up before making films')
        h = frames[name].shape[0]
        body = frames[name][h - 1, 300:950, 3]
        if (body < 0.5).any():
            raise SystemExit(f'{name}: his body stops short of the bottom edge')

    small = {name: resized(rgba, SIZE) for name, rgba in frames.items()}
    green = np.broadcast_to(GREEN, (SIZE, SIZE, 3)).copy()
    save(green, 'peek-empty')
    for name, rgba in small.items():
        save(over(green, rgba), name)

    contact(small)
    in_place(small)


def contact(small):
    names = ['peek-empty'] + PEEKS + [LOUNGE]
    cell, pad, label = 300, 16, 28
    sheet = Image.new('RGB', (4 * (cell + pad) + pad, 2 * (cell + label + pad) + pad), (52, 52, 52))
    draw = ImageDraw.Draw(sheet)
    paper = np.broadcast_to(PAPER, (SIZE, SIZE, 3))
    for i, name in enumerate(names):
        x = pad + (i % 4) * (cell + pad)
        y = pad + (i // 4) * (cell + label + pad)
        rgb = paper if name == 'peek-empty' else over(paper, small[name])
        tile = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8)).resize((cell, cell), Image.LANCZOS)
        sheet.paste(tile, (x, y))
        if name != LOUNGE:
            # The edge he hides behind.
            draw.line([(x, y + cell - 1), (x + cell, y + cell - 1)], fill=(16, 43, 70), width=3)
        draw.text((x, y + cell + 6), name, fill=(240, 240, 240))
    sheet.save(os.path.join(OUT, 'contact.png'))


def countdown(points=90):
    """The countdown screen and where a peek goes on it: from behind the
    postcard's top right corner, `points` wide on a 390-point phone (the
    render is 813 px wide; 120 points runs into the date pill). He sits
    behind the card: it covers him below its own deckled edge, and he's sunk
    a little so his cut never shows. Returns the screen, the card's cover
    (255 where he shows) and his box (left, top, width), or None without the
    render."""
    if not os.path.exists(COUNTDOWN):
        print('No countdown render (run tool/visual_qa.sh)')
        return None
    screen = Image.open(COUNTDOWN).convert('RGB')
    scale = screen.width / 390
    pixels = np.asarray(screen).astype(np.float32)
    # The postcard's top edge: down the right-hand side to the top of its
    # picture (the first dark row under the header), then up through its
    # warm cream border (linen is greyer and textured).
    column = pixels[:, round(screen.width * 0.82)]
    picture = next(y for y in range(round(160 * scale), screen.height) if column[y].mean() < 180)
    edge = picture - 2  # past the picture's thin highlight
    while column[edge - 1][0] >= 246 and column[edge - 1][0] - column[edge - 1][2] >= 25:
        edge -= 1
    # Column by column, where the deckled border starts.
    r, b = pixels[..., 0], pixels[..., 2]
    border = (r >= 249) & (r - b >= 33)
    border = border & np.roll(border, -1, axis=0)
    near = range(edge - round(6 * scale), picture)
    card = np.array([next((y for y in near if border[y, x]), edge) for x in range(screen.width)])
    # The finder is noisy on linen; the deckle is gentle.
    card = ndimage.median_filter(ndimage.minimum_filter1d(card, 9), 9)
    cover = (np.arange(screen.height)[:, None] < card[None, :]).astype(np.uint8) * 255
    width = round(points * scale)
    left = round(screen.width * 0.86) - width
    top = edge + round(6 * scale) - width
    return screen, cover, (left, top, width)


def peek_on(screen, cover, box, travi):
    """`travi` (RGBA image) peeking from behind the card."""
    left, top, width = box
    shot = screen.copy()
    layer = Image.new('RGBA', shot.size)
    layer.paste(travi.resize((width, width), Image.LANCZOS), (left, top))
    layer.putalpha(Image.fromarray(np.minimum(np.asarray(layer.getchannel('A')), cover)))
    shot.paste(layer, (0, 0), layer)
    return shot


def in_place(small):
    """The peeks on the countdown, and a close up where he meets the card."""
    placed = countdown()
    if placed is None:
        return
    screen, cover, box = placed
    shots = [peek_on(screen, cover, box, rgba_image(small[name])) for name in
             ['peek-hello', 'peek-wave', 'peek-cheer', 'peek-today']]
    shots = [shot.crop((0, 0, shot.width, round(shot.height * 0.62))) for shot in shots]
    w, h = shots[0].size
    k = 0.5
    board = Image.new('RGB', (round(len(shots) * (w * k + 16)) + 16, round(h * k) + 32), (52, 52, 52))
    for i, shot in enumerate(shots):
        board.paste(shot.resize((round(w * k), round(h * k)), Image.LANCZOS), (16 + round(i * (w * k + 16)), 16))
    board.save(os.path.join(OUT, 'in-place.png'))
    left, top, width = box
    pad = round(width / 9)
    detail = shots[0].crop((left - pad, top - pad, left + width + pad, top + width + pad))
    detail.resize((detail.width * 3, detail.height * 3), Image.LANCZOS).save(os.path.join(OUT, 'in-place-detail.png'))


if __name__ == '__main__':
    main()
