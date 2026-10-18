"""Re-letters frame 04's kraft tag so "2 free, then a pass" fits inside it.

ImageGen printed the words past the tag's right edge, clipping the comma and
the "a". This lifts them off the tag, paints the kraft back, and sets the
words again a little smaller, on the tag's own tilt and in its ink. The
original plate is never changed; the copy is the selected frame in
manifest.json.

    python3 -I retag_04.py

Reads chatgpt/04-smart-import.png, writes chatgpt/04-smart-import-tag-fixed.png
at 1320 x 2868 (scaled exactly as compose.py scales every plate). Needs Pillow,
numpy and opencv-python-headless.
"""

from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
SRC = HERE / "chatgpt" / "04-smart-import.png"
OUT = HERE / "chatgpt" / "04-smart-import-tag-fixed.png"
FONT = ("/System/Library/Fonts/Helvetica.ttc", 1)  # Helvetica Bold, as ImageGen drew it
W, H = 1320, 2868

# The tag on the 1320 x 2868 plate, measured: its long edges lean right going
# down (the tag is turned about 7 degrees anticlockwise).
LEFT = lambda y: 1082 + (y - 660) * 0.165
RIGHT = lambda y: 1221 + (y - 660) * 0.175
TILT = np.degrees(np.arctan(0.17))  # anticlockwise
WORDS_TOP, WORDS_BOTTOM = 652, 780  # rows the old words sit in
INK = np.array([62, 34, 14], np.float32)  # the darkest of the old ink, lifted a touch


def main():
    plate = Image.open(SRC).convert("RGB").resize((W, H), Image.LANCZOS)
    rgb = np.asarray(plate).astype(np.float32)

    ys, xs = np.mgrid[0:H, 0:W]
    inside = (xs > LEFT(ys) + 3) & (xs < RIGHT(ys) - 3) & (ys >= WORDS_TOP - 8) & (ys <= WORDS_BOTTOM + 8)
    lum = rgb @ np.array([0.299, 0.587, 0.114], np.float32)
    kraft = inside & (lum > 150)
    kraft_median = np.median(rgb[kraft], axis=0)

    # Lift the old words: their ink and its soft edge, a little wider
    words = inside & (lum < 165)
    words = cv2.dilate(words.astype(np.uint8), np.ones((5, 5), np.uint8)) > 0
    words &= inside
    work = rgb.copy()
    work[~inside & (ys >= WORDS_TOP - 40) & (ys <= WORDS_BOTTOM + 40)] = kraft_median  # keep the navy out
    filled = cv2.inpaint(np.clip(work, 0, 255).astype(np.uint8), words.astype(np.uint8) * 255, 7, cv2.INPAINT_TELEA)
    filled = filled.astype(np.float32)
    # Paper grain where the words were, like the tag's own
    rng = np.random.default_rng(4)
    grain = cv2.GaussianBlur(rng.normal(0, 1, (H, W)).astype(np.float32), (0, 0), 0.9)
    grain *= np.std(lum[kraft]) / max(np.std(grain), 1e-6) * 0.8
    filled += grain[..., None] * (kraft_median / kraft_median.mean())
    rgb = np.where(words[..., None], filled, rgb)

    # The clipped comma and "a" reached the tag's right edge itself: rebuild
    # that edge from a clean stretch of it just above the words, slid along
    # the edge's lean
    src = rgb.copy()
    for y in range(WORDS_TOP, WORDS_BOTTOM + 1):
        ys_ = 622 + (y - WORDS_TOP) % 30
        shift = (y - ys_) * 0.175
        for x in range(int(RIGHT(y)) - 8, int(RIGHT(y)) + 7):
            sx = x - shift
            fx = int(np.floor(sx))
            t = sx - fx
            rgb[y, x] = src[ys_, fx] * (1 - t) + src[ys_, fx + 1] * t

    # Set the words again, centred on the tag's axis, at 4x then down
    scale = 4
    font = ImageFont.truetype(FONT[0], 33 * scale, index=FONT[1])
    lines = ["2 free,", "then a", "pass"]
    lead = int(37 * scale)
    widths = [font.getlength(t) for t in lines]
    asc, desc = font.getmetrics()
    block_w, block_h = int(max(widths)) + 8 * scale, lead * (len(lines) - 1) + asc + desc
    layer = Image.new("L", (block_w + 40 * scale, block_h + 40 * scale), 0)
    d = ImageDraw.Draw(layer)
    for i, (t, w) in enumerate(zip(lines, widths)):
        d.text(((layer.width - w) / 2, 20 * scale + i * lead), t, font=font, fill=255)
    layer = layer.rotate(TILT, resample=Image.BICUBIC, expand=True)
    layer = layer.resize((layer.width // scale, layer.height // scale), Image.LANCZOS)
    layer = layer.filter(ImageFilter.GaussianBlur(0.35))  # printed, not vector-sharp
    cy = (WORDS_TOP + WORDS_BOTTOM) / 2 + 2
    cx = (LEFT(cy) + RIGHT(cy)) / 2
    ox, oy = round(cx - layer.width / 2), round(cy - layer.height / 2)
    alpha = np.zeros((H, W), np.float32)
    alpha[oy:oy + layer.height, ox:ox + layer.width] = np.asarray(layer).astype(np.float32) / 255 * 0.94
    # The ink takes up the paper's grain
    ink = INK * (rgb / kraft_median).clip(0.75, 1.25)
    rgb = rgb * (1 - alpha[..., None]) + ink * alpha[..., None]

    # Report how much room is left either side, on every row of the words
    rows = np.nonzero(alpha.max(axis=1) > 0.2)[0]
    gaps = []
    for y in rows:
        cols = np.nonzero(alpha[y] > 0.2)[0]
        gaps.append((cols.min() - LEFT(y), RIGHT(y) - cols.max()))
    gaps = np.array(gaps)
    print(f"words: rows {rows.min()}-{rows.max()}, margins left >= {gaps[:, 0].min():.1f}px, right >= {gaps[:, 1].min():.1f}px")

    Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8)).save(OUT)
    print(f"wrote {OUT.relative_to(HERE)}")


if __name__ == "__main__":
    main()
