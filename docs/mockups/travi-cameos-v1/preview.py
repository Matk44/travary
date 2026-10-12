#!/usr/bin/env python3
"""Plays the processed cameo films where the app will: an MP4 to review
before they're exported.

Each peek pops up from behind the countdown postcard (90 points, as
build_cameos.py places the stills), holds, and ducks back down: the same
film played backwards (the app's '-down' films, shots.json 'reversed'). The
lounge loops twice on the app's paper.

Run process.py --set cameos first (keyed/<film>/). Needs numpy, Pillow,
SciPy and ffmpeg:
    /tmp/kf/bin/python docs/mockups/travi-cameos-v1/preview.py
"""
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import build_cameos  # noqa: E402

FPS = 24
HOLD = round(0.5 * FPS)
GAP = round(0.4 * FPS)


def frames(name):
    return [Image.open(p).convert('RGBA') for p in sorted((HERE / 'keyed' / name).glob('*.png'))]


def main():
    shots = json.loads((HERE / 'shots.json').read_text())['shots']
    placed = build_cameos.countdown()
    if placed is None:
        raise SystemExit('Render the countdown first: tool/visual_qa.sh')
    screen, cover, box = placed
    crop = (0, 0, screen.width // 2 * 2, round(screen.height * 0.62) // 2 * 2)
    size = (crop[2], crop[3])
    out = HERE / 'preview.mp4'
    pipe = subprocess.Popen([
        'ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{size[0]}x{size[1]}',
        '-r', str(FPS), '-i', '-', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18',
        '-movflags', '+faststart', str(out)], stdin=subprocess.PIPE)

    def write(image):
        pipe.stdin.write(image.convert('RGB').crop(crop).tobytes())

    empty = screen.crop(crop)
    for name, shot in shots.items():
        film = frames(name)
        if not film:
            print(f'{name}: not processed yet')
            continue
        if shot.get('format') == 'peek':
            up = [build_cameos.peek_on(screen, cover, box, f) for f in film]
            for image in up + [up[-1]] * HOLD + up[::-1] + [screen] * GAP:
                write(image)
        else:
            paper = Image.new('RGB', screen.size, tuple(int(c) for c in build_cameos.PAPER))
            width = round(screen.width * 0.6)
            for f in film * 2:
                image = paper.copy()
                layer = f.resize((width, width), Image.LANCZOS)
                image.paste(layer, ((screen.width - width) // 2, round(size[1] * 0.25)), layer)
                write(image)
            for _ in range(GAP):
                write(empty)
        print(f'{name}: {len(film)} frames')
    pipe.stdin.close()
    pipe.wait()
    print('wrote', out.relative_to(HERE.parent.parent.parent))


if __name__ == '__main__':
    main()
