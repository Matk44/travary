#!/usr/bin/env python3
"""Key the approved Scene Studio plea and export one cropped, quiet idle.

This is video post-production using Travary's existing green-difference key.
The owner's attached artwork remains unmodified in approved-travi.png.
"""
import json
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[2]
SIZE = 480
FPS = 12
BLEND = 3


def key(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    alpha = 1 - np.clip((g - np.maximum(r, b) - 30) / 50, 0, 1)
    rgb = rgb.copy()
    rgb[..., 1] = np.where(alpha < .98, np.minimum(g, np.maximum(r, b)), g)
    return np.dstack([rgb, alpha * 255]).clip(0, 255).astype(np.uint8)


def main():
    raw = subprocess.check_output([
        'ffmpeg', '-v', 'error', '-i', str(ROOT / 'source/plea.mp4'),
        '-vf', f'fps={FPS},scale={SIZE}:{SIZE}:flags=lanczos',
        '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-',
    ])
    rgb = np.frombuffer(raw, np.uint8).reshape(-1, SIZE, SIZE, 3).astype(np.float32)
    approved = np.asarray(Image.open(ROOT / 'generator-frame.png').convert('RGB')
                          .resize((SIZE, SIZE), Image.Resampling.LANCZOS)).astype(np.float32)
    steps = np.abs(np.diff(rgb, axis=0)).mean(axis=(1, 2, 3))
    drift = [float(np.abs(rgb[0] - approved).mean()), float(np.abs(rgb[-1] - approved).mean())]
    for i in range(min(BLEND, len(rgb) // 2)):
        t = i / BLEND
        rgb[i] = approved * (1 - t) + rgb[i] * t
        rgb[-1 - i] = approved * (1 - t) + rgb[-1 - i] * t
    rgba = [key(frame) for frame in rgb]
    still = key(approved)
    occupied = np.any(np.stack([f[..., 3] > 8 for f in [*rgba, still]]), axis=0)
    ys, xs = np.nonzero(occupied)
    box = (max(0, int(xs.min()) - 4), max(0, int(ys.min()) - 4),
           min(SIZE, int(xs.max()) + 5), min(SIZE, int(ys.max()) + 5))
    frames = [Image.fromarray(f).crop(box) for f in rgba]
    pose = Image.fromarray(still).crop(box)
    out = PROJECT / 'assets/travi/cameos'
    pose.save(out / 'stills/profile-plea.webp', quality=88, method=6, exact=True)
    # A two-second quiet hold makes the motion occasional rather than fidgety.
    frames.append(pose)
    duration = [round(1000 / FPS)] * len(rgba) + [2000]
    target = out / 'films/profile-plea.webp'
    frames[0].save(target, save_all=True, append_images=frames[1:],
                   duration=duration, loop=0, quality=80, method=6,
                   minimize_size=True, exact=True)
    report = {
        'source_frames_at_12fps': len(rgba), 'crop': box, 'size': pose.size,
        'source_endpoint_drift_rgb': drift,
        'source_max_frame_change_rgb': float(steps.max()),
        'source_median_frame_change_rgb': float(np.median(steps)),
        'loop_join_rgba_max': int(np.abs(rgba[0].astype(int) - still.astype(int)).max()),
        'seconds': sum(duration) / 1000,
        'animation_bytes': target.stat().st_size,
    }
    (ROOT / 'processing.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
