"""Frame 11: the countdown widget pops out of the phone.

Composes frame 11 as compose.py does (the capture under ChatGPT's green
screen), then lifts a larger copy of the real widget, cut from the same
capture, off the screen with a soft shadow, so it reaches past the phone's
edges. The widget is the app's own pixels, never redrawn.

    python3 -I popout_11.py

Reads chatgpt/11-widget.png and captures/11-widget.png; writes
final/11-widget.png and final/11-widget_1206x2622.png. compose.py --all
writes frame 11 without the pop-out, so run this after it. Needs Pillow and
numpy.
"""

import importlib.util
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = Path(__file__).resolve().parent
PLATE = HERE / "chatgpt" / "11-widget.png"
CAPTURE = HERE / "captures" / "11-widget.png"
OUT = HERE / "final" / "11-widget.png"

# The medium widget in the 1320 x 2868 capture, measured: its box and corner
WIDGET = (93, 282, 1227, 812)
RADIUS = 90
LIFT = 1.38  # how much bigger than in the screen
RAISE = 24  # px it rises above where it sits
TILT = -3.0  # degrees; negative turns it clockwise


def load_compose():
    spec = importlib.util.spec_from_file_location("compose", HERE / "compose.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def rounded_mask(size, radius, scale=4, inset=1.5):
    """The widget's shape, anti-aliased, a hair inside so no wallpaper shows."""
    w, h = size
    big = Image.new("L", (w * scale, h * scale), 0)
    i = inset * scale
    ImageDraw.Draw(big).rounded_rectangle((i, i, w * scale - i, h * scale - i), radius * scale, fill=255)
    return big.resize(size, Image.LANCZOS)


def main():
    compose = load_compose()
    compose.compose(PLATE, CAPTURE, OUT)  # the plain frame first
    frame = Image.open(OUT).convert("RGB")

    # Where the capture landed in the frame (compose.py's own geometry)
    plate = compose.load_frame(PLATE)
    x0, y0, x1, y1 = compose.screen_box(compose.green_alpha(np.asarray(plate).astype(np.float32)))
    cap = Image.open(CAPTURE).convert("RGB")
    scale = max((x1 - x0) / cap.width, (y1 - y0) / cap.height)
    shift = (round(cap.width * scale) - (x1 - x0)) // 2

    def to_frame(x, y):
        return x0 + x * scale - shift, y0 + y * scale

    wx0, wy0, wx1, wy1 = WIDGET
    fx0, fy0 = to_frame(wx0, wy0)
    fx1, fy1 = to_frame(wx1, wy1)
    cx, cy = (fx0 + fx1) / 2, (fy0 + fy1) / 2 - RAISE

    # The real widget, cut out, at its lifted size
    widget = cap.crop(WIDGET).convert("RGBA")
    widget.putalpha(rounded_mask(widget.size, RADIUS))
    k = scale * LIFT
    size = (round(widget.width * k), round(widget.height * k))
    widget = widget.resize(size, Image.LANCZOS)
    if TILT:
        widget = widget.rotate(TILT, resample=Image.BICUBIC, expand=True)
    left, top = round(cx - widget.width / 2), round(cy - widget.height / 2)

    # Two shadows: a wide soft one for the lift, a tight one to seat it
    shape = widget.getchannel("A")
    out = frame.convert("RGBA")
    for offset, blur, strength in ((48, 46, 0.42), (14, 12, 0.28)):
        pad = blur * 3
        layer = Image.new("L", (widget.width + pad * 2, widget.height + pad * 2), 0)
        layer.paste(shape, (pad, pad))
        layer = layer.filter(ImageFilter.GaussianBlur(blur)).point(lambda v: round(v * strength))
        shadow = Image.new("RGBA", layer.size, (16, 24, 44, 0))
        shadow.putalpha(layer)
        out.alpha_composite(shadow, (left - pad, top - pad + offset))
    out.alpha_composite(widget, (left, top))

    out = out.convert("RGB")
    out.save(OUT)
    out.resize(compose.MEDIUM, Image.LANCZOS).save(OUT.with_name(f"{OUT.stem}_{compose.MEDIUM[0]}x{compose.MEDIUM[1]}.png"))
    shown = OUT.relative_to(HERE) if OUT.is_relative_to(HERE) else OUT
    print(f"  widget lifted to {widget.width} x {widget.height} at {left},{top} "
          f"(phone screen {x0}-{x1}); wrote {shown} and its 1206 x 2622 copy")


if __name__ == "__main__":
    main()
