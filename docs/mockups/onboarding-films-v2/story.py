#!/usr/bin/env python3
"""A review cut of the onboarding: keyed films chained over the workshop and
then a destination, at phone size, as the app will layer them.

Each step is a film (keyed/<name>/), a still hold on a key frame
('hold:<frame>:<seconds>') or a loop played once. The destination rises
behind Travi during 'world', like the app's pop-up page. Review only: the
app does this live, with its words and controls on top.

    python story.py tokyo assets/onboarding/stages/city_jp_tokyo.webp
"""
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parent.parent.parent
FRAMES = ROOT.parent / 'onboarding-keyframes-v1' / 'registered'
WORKSHOP = ROOT.parent / 'onboarding-keyframes-v1' / 'frame-17-workshop.png'
W = 941
PHONE_W, PHONE_H = 720, 1566
FPS = 24
FLOOR = 1142 / W  # the camera's floor, in frame widths
FLOOR_COLOR = (251, 232, 211)
SKY = (1, 77, 110)

STORY = [
    'roll-in', 'hello-idle', 'world', 'tag-out', 'tag-idle', 'tag-toss', 'folio-up-b',
    'hold:06-folio-open:1.0', 'reading', 'reading-idle', 'got-it', 'card-out',
    'hold:09-card:1.2', 'card-toss', 'proud', 'proud-idle', 'id-tag', 'hold:id-tag:1.2',
    'guest', 'hold:13-present:2.0',
]


def plate(path, floor_widths):
    """A stage across the phone, its floor on the camera's floor."""
    canvas = Image.new('RGB', (PHONE_W, PHONE_H), FLOOR_COLOR)
    art = Image.open(path).convert('RGB')
    art = art.resize((PHONE_W, round(art.height * PHONE_W / art.width)), Image.LANCZOS)
    top = round(FLOOR * PHONE_W - floor_widths * PHONE_W)
    canvas.paste(art, (0, top))
    if top > 0:
        canvas.paste(Image.new('RGB', (PHONE_W, top), SKY), (0, 0))
    return canvas


def with_shadow(base):
    k = PHONE_W / W
    mask = Image.new('L', base.size, 0)
    ImageDraw.Draw(mask).ellipse([(352 * k, 1160 * k), (752 * k, 1192 * k)], fill=110)
    mask = mask.filter(ImageFilter.GaussianBlur(9 * k))
    return Image.composite(Image.new('RGB', base.size, (68, 42, 20)), base, mask)


def ease_out_back(t):
    c1, c3 = 1.70158, 2.70158
    return 1 + c3 * (t - 1) ** 3 + c1 * (t - 1) ** 2


def pop_up(old, new, t):
    """`new` stands up from the floor line over `old` (the app's pop-up page)."""
    floor = round(FLOOR * PHONE_W)
    frame = old.copy()
    # The new floor fades in.
    below = Image.blend(old.crop((0, floor, PHONE_W, PHONE_H)), new.crop((0, floor, PHONE_W, PHONE_H)), min(1, t * 1.5))
    frame.paste(below, (0, floor))
    lift = max(0.0, ease_out_back(min(1, t)))
    h = round(floor * lift)
    if h > 1:
        page = new.crop((0, 0, PHONE_W, floor)).resize((PHONE_W, h), Image.LANCZOS)
        frame.paste(page, (0, floor - h))
    return frame


def frames_of(step):
    if step.startswith('hold:'):
        _, name, seconds = step.split(':')
        im = Image.open(FRAMES / f'{name}.png').convert('RGB')
        rgb = np.asarray(im).astype(np.float32)
        r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
        alpha = 1 - np.clip((g - np.maximum(r, b) - 30) / 50, 0, 1)
        layer = Image.fromarray(np.dstack([rgb, alpha * 255]).astype(np.uint8), 'RGBA')
        return [layer] * round(float(seconds) * FPS)
    return [Image.open(p) for p in sorted((ROOT / 'keyed' / step).glob('*.png'))]


def render(name, stage):
    workshop = with_shadow(plate(WORKSHOP, 1215 / 787))
    destination = with_shadow(plate(PROJECT / stage, 1.41))
    out = ROOT / f'story-{name}.mp4'
    pipe = subprocess.Popen([
        'ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{PHONE_W}x{PHONE_H}',
        '-r', str(FPS), '-i', '-', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18',
        '-movflags', '+faststart', str(out)], stdin=subprocess.PIPE)
    base = workshop
    for step in STORY:
        layers = frames_of(step)
        for i, layer in enumerate(layers):
            if step == 'world':
                # The place rises over the first 60% of his reaction.
                bg = pop_up(workshop, destination, i / (len(layers) * 0.6))
            else:
                bg = base
            frame = bg.copy()
            layer = layer.resize((PHONE_W, round(layer.height * PHONE_W / layer.width)), Image.LANCZOS)
            frame.paste(layer, (0, 0), layer)
            pipe.stdin.write(frame.tobytes())
        if step == 'world':
            base = destination
    pipe.stdin.close()
    pipe.wait()
    print('wrote', out.relative_to(PROJECT))


if __name__ == '__main__':
    render(sys.argv[1], sys.argv[2])
