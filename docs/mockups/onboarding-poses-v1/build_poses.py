#!/usr/bin/env python3
"""Builds Travi's onboarding poses for the app (assets/onboarding/poses/).

Every pose is keyed off its green plate and moved onto ONE camera: the
sign-in pose's (green-account-clean-v1.png). Travi's body is found to the
right of his folio, scaled to the same height and set down so his wheels and
right side land exactly where they are in that pose. Poses ChatGPT makes
from that same reference come out nearly identical already; plates from
other frames (the closer "booking saved" shot, the pulled-back desk) are
rescaled. Output: 941 x 1672 WebP with alpha, one per pose.

Run from the project root: python3 docs/mockups/onboarding-poses-v1/build_poses.py
"""
import json
import os
import subprocess
import sys

ROOT = os.getcwd()
PLATES = 'docs/mockups/onboarding-green-plates-v1'
POSES = 'docs/mockups/onboarding-poses-v1'
OUT = 'assets/onboarding/poses'
W, H = 941, 1672

# The reference camera (sign-in pose): Travi's body to the right of x=560.
REF_TOP, REF_BOTTOM, REF_RIGHT = 541, 1176, 912

# name -> (source, rows to keep from the top: drops painted passes)
SOURCES = {
    'account': (f'{PLATES}/green-account-clean-v1.png', None),
    'email': (f'{PLATES}/green-email-clean-v1.png', None),
    'proof': (f'{PLATES}/green-proof-clean-v1.png', None),
    'present': (f'{PLATES}/green-pass-clean-v1.png', 1078),
}
# New poses from docs/onboarding/ART_REQUESTS_POSES_2026-10-09.md win when present.
for name in ['arrived', 'hooray', 'tag', 'folio-open', 'reading', 'linked', 'present', 'sendoff', 'oops']:
    path = f'{POSES}/pose-{name}-v1.png'
    if os.path.exists(path):
        SOURCES[name] = (path, None)


def size(path):
    out = subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'stream=width,height', '-of', 'csv=p=0', path])
    return tuple(map(int, out.decode().split(',')))


def keyed_rgba(path):
    """The plate keyed to RGBA bytes (the green, and its spill, removed)."""
    return subprocess.check_output([
        'ffmpeg', '-v', 'error', '-i', path, '-vf',
        'format=rgb24,chromakey=0x00B140:0.13:0.05,despill=type=green:mix=0.6:expand=0.1,format=rgba',
        '-f', 'rawvideo', '-pix_fmt', 'rgba', '-'])


def travi_box(rgba, w, h, rows):
    """Travi's body: opaque pixels right of 59.5% of the width."""
    x0 = int(w * 0.595)
    top, bottom, right = h, 0, 0
    for y in range(0, rows or h, 2):
        row = y * w * 4
        for x in range(x0, w, 2):
            if rgba[row + x * 4 + 3] > 160:
                top, bottom, right = min(top, y), max(bottom, y), max(right, x)
    return top, bottom, right


def build(name, source, rows):
    w, h = size(source)
    rgba = keyed_rgba(source)
    top, bottom, right = travi_box(rgba, w, h, rows)
    scale = (REF_BOTTOM - REF_TOP) / (bottom - top)
    # Pin the wheels' bottom and Travi's right side to the reference.
    ox = REF_RIGHT - right * scale
    oy = REF_BOTTOM - bottom * scale
    crop = f'crop={w}:{rows}:0:0,' if rows else ''
    sw, sh = round(w * scale), round((rows or h) * scale)
    os.makedirs(OUT, exist_ok=True)
    out = f'{OUT}/{name}.webp'
    subprocess.run([
        'ffmpeg', '-v', 'error', '-y',
        '-f', 'lavfi', '-i', f'color=c=black@0.0:s={W}x{H}:d=1,format=rgba',
        '-i', source,
        '-filter_complex',
        f'[1]format=rgb24,{crop}chromakey=0x00B140:0.13:0.05,despill=type=green:mix=0.6:expand=0.1,'
        f'format=rgba,scale={sw}:{sh}:flags=lanczos[p];[0][p]overlay={ox:.1f}:{oy:.1f}:format=auto,format=rgba',
        '-frames:v', '1', '-c:v', 'libwebp', '-lossless', '0', '-quality', '88', '-compression_level', '6', out,
    ], check=True)
    return {'source': source, 'scale': round(scale, 4), 'offset': [round(ox, 1), round(oy, 1)], 'out': out}


def main():
    log = {name: build(name, src, rows) for name, (src, rows) in SOURCES.items()}
    with open(f'{POSES}/build.json', 'w') as f:
        json.dump(log, f, indent=2)
    for name, entry in log.items():
        print(f"{name:12} x{entry['scale']}  offset {entry['offset']}  -> {entry['out']}")


if __name__ == '__main__':
    sys.exit(main())
