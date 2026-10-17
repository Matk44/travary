"""Puts a real simulator capture into a frame's green screen.

ChatGPT draws each App Store frame with the phone's screen as flat chroma
green (#00B140). This keys the green out and puts the simulator capture
underneath, so Travi or anything else drawn over the screen stays on top, then
writes the frame at both App Store sizes (1320 x 2868 and 1206 x 2622).

    python3 -I compose.py FRAME.png CAPTURE.png OUT.png
    python3 -I compose.py --all

--all pairs chatgpt/NN-*.png with captures/NN-*.png (same NN) and writes
final/NN-<slug>.png plus final/NN-<slug>_1206x2622.png.

Needs Pillow and numpy.
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image

W, H = 1320, 2868
MEDIUM = (1206, 2622)
HERE = Path(__file__).resolve().parent


def load_frame(path):
    im = Image.open(path).convert("RGB")
    ratio, want = im.width / im.height, W / H
    if abs(ratio - want) / want > 0.02:
        sys.exit(
            f"{path}: {im.width} x {im.height} isn't the App Store shape (9:19.5). "
            "Ask ChatGPT for 1320 x 2868, or extend the canvas, then run this again."
        )
    return im.resize((W, H), Image.LANCZOS) if im.size != (W, H) else im


def green_alpha(rgb):
    """How much each pixel is screen green: 1 inside, 0 outside, soft at edges."""
    r, g, b = (rgb[..., i].astype(np.float32) for i in range(3))
    lead = g - np.maximum(r, b)
    a = np.clip((lead - 35.0) / 70.0, 0.0, 1.0)
    a[g < 80] = 0.0
    return a


def screen_box(alpha):
    """The screen's bounding box: rows and columns that are mostly green."""
    solid = alpha > 0.9
    cols = solid.sum(axis=0)
    rows = solid.sum(axis=1)
    xs = np.nonzero(cols > cols.max() * 0.25)[0]
    ys = np.nonzero(rows > rows.max() * 0.25)[0]
    if len(xs) == 0 or len(ys) == 0:
        sys.exit("No green screen found: the phone's screen must be flat #00B140.")
    return xs[0], ys[0], xs[-1] + 1, ys[-1] + 1


def compose(frame_path, capture_path, out_path):
    frame = load_frame(frame_path)
    rgb = np.asarray(frame).astype(np.float32)
    alpha = green_alpha(rgb)
    x0, y0, x1, y1 = screen_box(alpha)
    # Green outside the screen (a stray leaf, a reflection) is left alone
    keep = np.zeros_like(alpha)
    keep[max(0, y0 - 4):y1 + 4, max(0, x0 - 4):x1 + 4] = 1.0
    alpha *= keep

    bw, bh = x1 - x0, y1 - y0
    cap = Image.open(capture_path).convert("RGB")
    drift = abs((bw / bh) - (cap.width / cap.height)) / (cap.width / cap.height)
    if drift > 0.03:
        print(f"  ! {frame_path.name}: the green screen is {bw} x {bh}, a different shape from the "
              f"capture; its edges will be cropped. Ask ChatGPT to keep the phone exactly as the layout.")
    scale = max(bw / cap.width, bh / cap.height)
    cap = cap.resize((round(cap.width * scale), round(cap.height * scale)), Image.LANCZOS)
    left = (cap.width - bw) // 2
    cap = cap.crop((left, 0, left + bw, bh))  # keep the status bar: align the top

    under = np.zeros_like(rgb)
    under[y0:y1, x0:x1] = np.asarray(cap).astype(np.float32)

    # Take the green tint off the soft edges of whatever overlaps the screen
    edge = (alpha > 0) & (alpha < 1)
    rb = np.maximum(rgb[..., 0], rgb[..., 2])
    rgb[..., 1] = np.where(edge, np.minimum(rgb[..., 1], rb), rgb[..., 1])

    a = alpha[..., None]
    out = Image.fromarray(np.clip(rgb * (1 - a) + under * a, 0, 255).astype(np.uint8))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(out_path)
    medium = out_path.with_name(f"{out_path.stem}_{MEDIUM[0]}x{MEDIUM[1]}.png")
    out.resize(MEDIUM, Image.LANCZOS).save(medium)
    print(f"  {out_path.relative_to(HERE) if out_path.is_relative_to(HERE) else out_path}  (screen {bw} x {bh} at {x0},{y0})")


def main(args):
    if args == ["--all"]:
        made = 0
        for frame in sorted((HERE / "chatgpt").glob("[0-9][0-9]-*.png")):
            nn = frame.name[:2]
            captures = sorted((HERE / "captures").glob(f"{nn}-*.png"))
            if not captures:
                print(f"  skip {frame.name}: no captures/{nn}-*.png")
                continue
            compose(frame, captures[0], HERE / "final" / f"{captures[0].stem}.png")
            made += 1
        print(f"{made} frame(s) written to final/")
    elif len(args) == 3:
        compose(Path(args[0]), Path(args[1]), Path(args[2]))
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
