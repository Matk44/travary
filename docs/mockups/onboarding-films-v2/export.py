#!/usr/bin/env python3
"""Exports the keyed films and key frames for the app.

- assets/onboarding/travi/films/<film>.webp: animated WebP with alpha, cropped
  to where Travi moves (transitions at 24 fps, idle loops at 12 fps).
- assets/onboarding/travi/stills/<pose>.webp: each key frame, keyed, cropped.
- lib/logic/onboarding_film_assets.dart: what exists and where each sits on
  the 540 x 960 canvas (the key frames' camera), generated.

Only films that passed review are exported (EXPORT below); a pose or move
without a film gets the app's dissolve until one exists. 'folio-out',
'envelope-back' and 'oops-back' are films played backwards (REVERSED).

    /tmp/kf/bin/python docs/mockups/onboarding-films-v2/export.py
"""
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parent.parent.parent
FRAMES = ROOT.parent / 'onboarding-keyframes-v1' / 'registered'
OUT = PROJECT / 'assets' / 'onboarding' / 'travi'
DART = PROJECT / 'lib' / 'logic' / 'onboarding_film_assets.dart'
CW, CH = 540, 960  # the key frames' 941 x 1672 camera, scaled
QUALITY = 50

POSES = {
    '01-empty': 'empty', '02-hello': 'hello', '03-wow': 'wow', '04-tag': 'tag', '05-toss': 'toss',
    '06-folio-open': 'folioOpen', '07-folio-full': 'folioFull', '08-reading': 'reading', '09-card': 'card',
    '10-proud': 'proud', 'id-tag': 'idTag', '11-envelope': 'envelope', '12-linked': 'linked',
    '13-present': 'present', '14-cheer': 'cheer', '15-wave': 'wave', '16-oops': 'oops',
}
# Reviewed films: exported name -> keyed source. Missing ones dissolve.
EXPORT = {
    'roll-in': 'roll-in', 'world': 'world', 'tag-out': 'tag-out', 'tag-toss': 'tag-toss',
    'folio-up': 'folio-up-b', 'reading': 'reading', 'got-it': 'got-it', 'folio-in': 'folio-in',
    'card-out': 'card-out', 'card-toss': 'card-toss', 'proud': 'proud', 'later': 'later',
    'id-tag': 'id-tag', 'envelope': 'envelope', 'guest': 'guest', 'finale': 'finale',
    'linked': 'linked', 'envelope-linked': 'envelope-linked',
    'to-desk': 'to-desk', 'cheer': 'cheer', 'wave-paid': 'wave-paid', 'wave-free': 'wave-free',
    'oops': 'oops',
    'hello-idle': 'hello-idle', 'tag-idle': 'tag-idle', 'folio-full-idle': 'folio-full-idle',
    'reading-idle': 'reading-idle', 'proud-idle': 'proud-idle',
    'id-tag-idle': 'id-tag-idle', 'present-idle': 'present-idle',
    # The first take closed the folio mid-loop.
    'folio-open-idle': 'folio-open-idle-b',
    # Not made (10 Oct 2026, to save generations): the card, envelope and
    # oops idles; he holds the key frame there.
}
# Played backwards: exported name -> the film it reverses.
REVERSED = {'folio-out': 'folio-in', 'envelope-back': 'envelope', 'oops-back': 'oops'}


def scaled(image):
    return image.resize((CW, CH), Image.LANCZOS)


def box_of(images):
    alpha = np.zeros((CH, CW), bool)
    for im in images:
        alpha |= np.asarray(im)[..., 3] > 8
    ys, xs = np.nonzero(alpha)
    left, top = max(0, xs.min() - 4) // 2 * 2, max(0, ys.min() - 4) // 2 * 2
    right, bottom = min(CW, (xs.max() + 6) // 2 * 2), min(CH, (ys.max() + 6) // 2 * 2)
    return left, top, right - left, bottom - top


def keyed_still(name):
    rgb = np.asarray(Image.open(FRAMES / f'{name}.png').convert('RGB')).astype(np.float32)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    alpha = 1 - np.clip((g - np.maximum(r, b) - 30) / 50, 0, 1)
    rgb[..., 1] = np.where(alpha < 0.98, np.minimum(g, np.maximum(r, b)), g)
    return Image.fromarray(np.dstack([rgb, alpha * 255]).astype(np.uint8), 'RGBA')


def encode(images, out, frame_ms):
    """Animated WebP: each frame lossy with lossy alpha (cwebp), then muxed."""
    with tempfile.TemporaryDirectory() as tmp:
        args = []
        for i, im in enumerate(images):
            png, webp = Path(tmp) / f'{i:04d}.png', Path(tmp) / f'{i:04d}.webp'
            im.save(png)
            subprocess.run(['cwebp', '-quiet', '-q', str(QUALITY), '-alpha_q', '50', '-alpha_filter', 'best',
                            '-m', '4', str(png), '-o', str(webp)], check=True)
            args += ['-frame', str(webp), f'+{frame_ms}+0+0+0-b']
        subprocess.run(['webpmux', *args, '-loop', '0', '-o', str(out)], check=True, capture_output=True)


def lead_in(images):
    """Frames at the start that don't move yet (all but two are dropped)."""
    first = np.asarray(images[0]).astype(np.int16)
    for i, im in enumerate(images[1:], 1):
        if np.abs(np.asarray(im).astype(np.int16) - first).mean() > 1.2:
            return max(0, i - 2)
    return 0


def main():
    shots = json.loads((ROOT / 'shots.json').read_text())['shots']
    films_dir, stills_dir = OUT / 'films', OUT / 'stills'
    for d in (films_dir, stills_dir):
        shutil.rmtree(d, ignore_errors=True)
        d.mkdir(parents=True)
    stills = {}
    for frame, pose in POSES.items():
        im = scaled(keyed_still(frame))
        box = box_of([im])
        l, t, w, h = box
        im.crop((l, t, l + w, t + h)).save(stills_dir / f'{pose}.webp', quality=80, method=6)
        stills[pose] = box
    films, idles, total = [], {}, 0
    items = [(name, source, False) for name, source in EXPORT.items()]
    items += [(name, EXPORT[of], True) for name, of in REVERSED.items()]
    for name, source, reverse in items:
        shot = shots[source]
        frames_dir = ROOT / 'keyed' / source
        if not frames_dir.exists() or not any(frames_dir.glob('*.png')):
            continue
        idle = shot.get('loop', False)
        paths = sorted(frames_dir.glob('*.png'))
        if reverse:
            paths = paths[::-1]
        if idle:
            paths = paths[::2]
        images = [scaled(Image.open(p).convert('RGBA')) for p in paths]
        lead = 0 if idle or reverse else lead_in(images)
        images = images[lead:]
        l, t, w, h = box_of(images)
        images = [im.crop((l, t, l + w, t + h)) for im in images]
        out = films_dir / f'{name}.webp'
        encode(images, out, 83 if idle else 42)
        total += out.stat().st_size
        seconds = round(len(images) * (83 if idle else 42) / 1000, 2)
        a, b = POSES[shot['to' if reverse else 'from']], POSES[shot['from' if reverse else 'to']]
        entry = {'id': name, 'from': a, 'to': b, 'box': (l, t, w, h), 'seconds': seconds,
                 'handoff': None if reverse or not shot.get('handoff') else round(shot['handoff'] - lead / 24, 2)}
        if idle:
            idles[a] = entry
        else:
            films.append(entry)
        print(f'{name:16} {len(images):3} frames {out.stat().st_size / 1e6:.2f} MB')
    print(f'films: {total / 1e6:.1f} MB')
    write_dart(stills, films, idles)


def clip(box):
    l, t, w, h = box
    return f'(left: {l}, top: {t}, width: {w}, height: {h})'


def write_dart(stills, films, idles):
    lines = [
        '// GENERATED by docs/mockups/onboarding-films-v2/export.py from the',
        '// reviewed films and key frames. Do not edit by hand.',
        "part of 'onboarding_films.dart';",
        '',
        '/// The key frames\' camera, in pixels: every clip sits on it at its [TraviBox].',
        f'const traviCanvas = (width: {CW}, height: {CH});',
        '',
        '/// Each pose as a still (reduced motion, and while a film loads).',
        'const traviStills = <TraviPose, TraviBox>{',
        *[f'  TraviPose.{pose}: {clip(box)},' for pose, box in stills.items()],
        '};',
        '',
        '/// The moves between poses.',
        'const traviFilms = <TraviFilm>[',
    ]
    for f in films:
        handoff = f", handoff: {f['handoff']}" if f['handoff'] else ''
        lines.append(f"  TraviFilm('{f['id']}', TraviPose.{f['from']}, TraviPose.{f['to']}, {clip(f['box'])}, "
                     f"seconds: {f['seconds']}{handoff}),")
    lines += ['];', '', '/// Idle loops, played while Travi waits on a pose.', 'const traviIdles = <TraviPose, TraviFilm>{']
    for pose, f in idles.items():
        lines.append(f"  TraviPose.{pose}: TraviFilm('{f['id']}', TraviPose.{pose}, TraviPose.{pose}, {clip(f['box'])}, "
                     f"seconds: {f['seconds']}),")
    lines += ['};', '']
    DART.write_text('\n'.join(lines))
    subprocess.run(['dart', 'format', str(DART)], check=True, capture_output=True, cwd=PROJECT)


if __name__ == '__main__':
    main()
