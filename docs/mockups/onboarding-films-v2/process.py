#!/usr/bin/env python3
"""Turns Seedance sources into seamless, keyed onboarding films.

For each film in shots.json:
1. Decode the source, scaled onto the key frames' camera (941 wide), and
   line it up with them: Seedance frames every shot about 2% tighter, which
   eased into the key frames zoomed each film in and out (a pulse at every
   join and every turn of a loop). Its first and last frames, matched to the
   key frames it starts and ends on, measure the difference.
2. Keep its action (`keep`, seconds) and drop the long hold at the end.
3. Ease the first and last frames into the EXACT key frames, so every join
   between films (and every loop) is pixel-identical.
4. Key out the green: `keyed/<film>/NNNN.png` (RGBA), what the app layers
   over any destination.
5. Report cuts (a frame that jumps) and how far the ends drifted.

`preview` lays a chain of films over destination stages as an MP4, at phone
size: python process.py preview tag-idle tag-toss folio-up

`--set cameos` processes Travi's cameos (docs/mockups/travi-cameos-v1/) on
their square frames, at the films' 480 px.

Needs numpy, Pillow (see build_keyframes.py) and ffmpeg.
"""
import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parent.parent.parent
# Each set: its folder (shots.json, source/, keyed/), its key frames, and the
# size films are processed at.
SETS = {
    'onboarding': (HERE, HERE.parent / 'onboarding-keyframes-v1' / 'registered', (941, 1672)),
    'cameos': (HERE.parent / 'travi-cameos-v1', HERE.parent / 'travi-cameos-v1' / 'registered', (480, 480)),
}
ROOT, FRAMES, (W, H) = SETS['onboarding']
FPS = 24
BLEND = 5  # frames eased into the exact key frame at each end
GREEN = np.array([0, 177, 64], np.float32)


def decode(path):
    out = subprocess.check_output([
        'ffmpeg', '-v', 'error', '-i', str(path),
        '-vf', f'fps={FPS},scale={W}:{H}:flags=lanczos', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'])
    return np.frombuffer(out, np.uint8).reshape(-1, H, W, 3).astype(np.float32).copy()


def still(name):
    im = Image.open(FRAMES / f'{name}.png').convert('RGB')
    if im.size != (W, H):
        im = im.resize((W, H), Image.LANCZOS)
    return np.asarray(im).astype(np.float32)


def key(rgb):
    """Green-difference key (as build_keyframes.py), spill pulled from edges."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    alpha = 1 - np.clip((g - np.maximum(r, b) - 30) / 50, 0, 1)
    out = rgb.copy()
    out[..., 1] = np.where(alpha < 0.98, np.minimum(g, np.maximum(r, b)), g)
    return np.dstack([out, alpha])


def settles(frames, last):
    """Seconds until the film comes to rest on its last key frame."""
    away = np.array([np.abs(f - last).mean() for f in frames])
    rest = away.min() + 1.5
    moving = np.nonzero(away > rest)[0]
    return (moving.max() + 1 if len(moving) else 0) / FPS


def _warp(image, s, dx, dy, size):
    """[image] scaled by [s] and moved by ([dx], [dy]) (in [size]'s pixels)."""
    fill = tuple(int(c) for c in GREEN)
    return image.transform(size, Image.AFFINE, (1 / s, 0, -dx / s, 0, 1 / s, -dy / s), Image.BILINEAR,
                           fillcolor=fill)


def register(frame, key):
    """The scale and move that lay a film [frame] on its [key] frame: Seedance
    starts on the first key frame and ends on the last, a little tighter.
    Searched coarse to fine, on the whole picture."""
    def at(k):
        size = (W // k, H // k)
        return Image.fromarray(frame.astype(np.uint8)).resize(size, Image.BILINEAR), \
            np.asarray(Image.fromarray(key.astype(np.uint8)).resize(size, Image.BILINEAR), np.float32), size

    def search(k, scales, moves, around):
        src, want, size = at(k)
        best = None
        for sc in scales:
            for mx in moves:
                for my in moves:
                    dx, dy = around[1] + mx, around[2] + my
                    got = np.asarray(_warp(src, sc, dx / k, dy / k, size), np.float32)
                    err = float(np.abs(got - want).mean())
                    if best is None or err < best[0]:
                        best = (err, sc, dx, dy)
        return best

    _, s0, dx0, dy0 = search(4, np.arange(0.95, 1.0101, 0.004), range(-28, 29, 4), (0, 0, 0))
    err, s1, dx1, dy1 = search(2, np.arange(s0 - 0.004, s0 + 0.0041, 0.001), range(-4, 5), (0, dx0, dy0))
    return s1, dx1, dy1, err


def align(frames, first, last):
    """[frames] scaled and moved onto the key frames' camera, and how: one
    correction for the whole film (the mean of where it starts and ends), so
    nothing jitters. Seedance frames every shot about 2% tighter; eased into
    the exact key frames, unaligned films zoomed at every join and loop."""
    if (W, H) != (941, 1672):
        return frames, None
    a = register(frames[0], first)
    b = register(frames[-1], last)
    s, dx, dy = ((a[i] + b[i]) / 2 for i in range(3))
    out = np.empty_like(frames)
    for i, frame in enumerate(frames):
        out[i] = np.asarray(_warp(Image.fromarray(frame.astype(np.uint8)), s, dx, dy, (W, H)), np.float32)
    return out, {'scale': round(float(s), 4), 'dx': round(float(dx), 1), 'dy': round(float(dy), 1),
                 'ends': [[round(float(v), 4) for v in a[:3]], [round(float(v), 4) for v in b[:3]]]}


def film(name, shot):
    frames = decode(ROOT / 'source' / f'{name}.mp4')
    first, last = still(shot['from']), still(shot['to'])
    frames, aligned = align(frames, first, last)
    # Keep the action and a breath after it ('keep' overrides).
    if shot.get('loop'):
        start, end = 0, len(frames)
    elif 'keep' in shot and shot.get('keep_fixed'):
        start, end = (round(t * FPS) for t in shot['keep'])
    else:
        start, end = 0, round((settles(frames, last) + 0.25) * FPS)
    frames = frames[start:min(end, len(frames))]
    # Fixes instead of re-rolls (seconds, after trimming), cross-faded once
    # keyed so a blend never mixes green into him:
    # 'cut': a detour Seedance added, dropped; the join fades over a few frames.
    # 'smooth': a snap it left in the action, faded across the window.
    fades = []
    # 'palindrome' (seconds): plays to that calm moment and back, so a loop
    # that ended in a snap returns to its first frame by retracing itself.
    if 'palindrome' in shot:
        k = round(shot['palindrome'] * FPS)
        frames = np.concatenate([frames[:k + 1], frames[k - 1:0:-1]])
    for a, b in sorted(shot.get('cut', []), reverse=True):
        ia, ib = round(a * FPS), round(b * FPS)
        frames = np.concatenate([frames[:ia], frames[ib:]])
        fades = [(lo - (ib - ia) if lo >= ia else lo, hi - (ib - ia) if hi >= ia else hi) for lo, hi in fades]
        fades.append((max(0, ia - 2), min(len(frames) - 1, ia + 2)))
    for a, b in shot.get('smooth', []):
        fades.append((round(a * FPS), round(b * FPS)))
    n = len(frames)
    report = {
        'aligned': aligned,
        'frames': n,
        'seconds': round(n / FPS, 2),
        'drift_first': round(float(np.abs(frames[0] - first).mean()), 1),
        'drift_last': round(float(np.abs(frames[-1] - last).mean()), 1),
    }
    steps = np.array([np.abs(frames[i + 1] - frames[i]).mean() for i in range(n - 1)])
    # Cuts: a frame-to-frame change far above the film's usual motion.
    report['jumps'] = [round((i + 1) / FPS, 2) for i in np.nonzero(steps > max(12, 5 * np.median(steps)))[0]]
    # Held frames in the middle of a move read as stutter.
    held = [i for i in range(1, n - 2) if steps[i] < 0.5 and steps[i - 1] > 3 and steps[i + 1] > 3]
    report['held_frames'] = len(held)
    out = ROOT / 'keyed' / name
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob('*.png'):
        old.unlink()
    def keyed_at(i):
        frame = frames[i]
        # Ease into the exact key frames at both ends.
        if i < BLEND:
            t = i / BLEND
            frame = first * (1 - t) + frame * t
        if i >= n - BLEND:
            t = (n - 1 - i) / BLEND
            frame = last * (1 - t) + frame * t
        return key(frame)

    for i in range(n):
        rgba = keyed_at(i)
        for lo, hi in fades:
            if lo < i < hi:
                t = (i - lo) / (hi - lo)
                a, b = keyed_at(lo), keyed_at(hi)
                alpha = a[..., 3:] * (1 - t) + b[..., 3:] * t
                colour = a[..., :3] * a[..., 3:] * (1 - t) + b[..., :3] * b[..., 3:] * t
                rgba = np.dstack([colour / np.maximum(alpha, 1e-4), alpha])
        Image.fromarray(np.dstack([np.clip(rgba[..., :3], 0, 255), rgba[..., 3:] * 255]).astype(np.uint8),
                        'RGBA').save(out / f'{i:04d}.png')
    return report


PHONE_W, PHONE_H = 720, 1566  # 402 x 874 points
FLOOR = 1142 / W  # the camera's floor, in frame widths
FLOOR_COLOR = (251, 232, 211)
SKY = (1, 77, 110)


def backdrop(stage):
    """A destination stage across the phone, its floor on the camera's."""
    canvas = Image.new('RGB', (PHONE_W, PHONE_H), FLOOR_COLOR)
    plate = Image.open(PROJECT / stage).convert('RGB')
    plate = plate.resize((PHONE_W, round(plate.height * PHONE_W / plate.width)), Image.LANCZOS)
    top = round(FLOOR * PHONE_W - 1.41 * PHONE_W)
    canvas.paste(plate, (0, top))
    if top > 0:
        canvas.paste(Image.new('RGB', (PHONE_W, top), SKY), (0, 0))
    return canvas


def shadow():
    """The soft oval the app draws under his wheels."""
    k = PHONE_W / W
    layer = Image.new('L', (PHONE_W, PHONE_H), 0)
    from PIL import ImageDraw, ImageFilter
    ImageDraw.Draw(layer).ellipse([(352 * k, 1160 * k), (752 * k, 1192 * k)], fill=110)
    return layer.filter(ImageFilter.GaussianBlur(9 * k))


def preview(names, stages, out):
    pipe = None
    shade = shadow()
    for stage in stages:
        base = backdrop(stage)
        base = Image.composite(Image.new('RGB', base.size, (68, 42, 20)), base, shade)
        for name in names:
            for png in sorted((ROOT / 'keyed' / name).glob('*.png')):
                layer = Image.open(png).resize((PHONE_W, round(H * PHONE_W / W)), Image.LANCZOS)
                frame = base.copy()
                frame.paste(layer, (0, 0), layer)
                if pipe is None:
                    pipe = subprocess.Popen([
                        'ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24',
                        '-s', f'{PHONE_W}x{PHONE_H}', '-r', str(FPS), '-i', '-',
                        '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-movflags', '+faststart', str(out)],
                        stdin=subprocess.PIPE)
                pipe.stdin.write(frame.tobytes())
    pipe.stdin.close()
    pipe.wait()


def main():
    global ROOT, FRAMES, W, H
    if '--set' in sys.argv:
        i = sys.argv.index('--set')
        ROOT, FRAMES, (W, H) = SETS[sys.argv[i + 1]]
        del sys.argv[i:i + 2]
    shots = json.loads((ROOT / 'shots.json').read_text())['shots']
    if sys.argv[1:2] == ['preview']:
        names = sys.argv[2:]
        stages = ['assets/onboarding/stages/city_jp_tokyo.webp', 'assets/onboarding/stages/country_ch.webp']
        out = ROOT / ('preview-' + '-'.join(names) + '.mp4')
        preview(names, stages, out)
        print('wrote', out.relative_to(PROJECT))
        return
    names = sys.argv[1:] or [n for n in shots if (ROOT / 'source' / f'{n}.mp4').exists()]
    reports = json.loads((ROOT / 'processing.json').read_text()) if (ROOT / 'processing.json').exists() else {}
    for name in names:
        reports[name] = film(name, shots[name])
        print(name, json.dumps(reports[name]))
    (ROOT / 'processing.json').write_text(json.dumps(reports, indent=2) + '\n')


if __name__ == '__main__':
    main()
