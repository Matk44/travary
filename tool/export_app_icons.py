#!/usr/bin/env python3
"""Export launcher assets from the ImageGen Travi close-up (requires Pillow)."""

import json
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets/branding"
REVIEW = ROOT / "docs/mockups/travi-passport-app-icon-v2"
BACKGROUND = "#35C5DA"
SOURCE = BRANDING / "travi_passport_closeup_source.png"
ADAPTIVE_SOURCE = BRANDING / "travi_passport_closeup_bleed_source.png"


def character(side, adaptive=False):
    """Keep the tight crop; Android uses extra lower-body bleed for its mask."""
    if not adaptive:
        return Image.open(SOURCE).convert("RGBA").resize((side, side), Image.Resampling.LANCZOS)
    source = Image.open(ADAPTIVE_SOURCE).convert("RGBA")
    # The face and passport's title/globe stay central. The shell and wave may
    # extend into the mask, rather than shrinking the whole portrait to fit.
    width = round(side * 68 / 108)
    height = round(source.height * width / source.width)
    resized = source.resize((width, height), Image.Resampling.LANCZOS)
    position = (round((side - width) / 2), round(side * 14.5 / 108))
    layer = Image.new("RGBA", (side, side))
    layer.alpha_composite(resized, position)
    return layer


def flatten(layer, color):
    background = Image.new("RGBA", layer.size, color)
    return Image.alpha_composite(background, layer).convert("RGB")


def font(size):
    return ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", size)


def preview(master_layer, adaptive):
    REVIEW.mkdir(parents=True, exist_ok=True)
    board = Image.new("RGB", (1008, 820), "#F7F4EC")
    draw = ImageDraw.Draw(board)
    draw.text((24, 20), "Travi · a closer app icon", font=font(30), fill="#132842")
    draw.text((24, 62), "Same turquoise · larger face and passport · actual-size previews below", font=font(17), fill="#58636B")
    old = Image.open(REVIEW / "previous-icon.png").convert("RGB")
    old_adaptive = Image.open(REVIEW / "previous-adaptive-art.png").convert("RGBA")
    new = flatten(master_layer, BACKGROUND)
    new.save(REVIEW / "icon-closeup.png")
    for index, (name, icon, foreground) in enumerate([("Previous full-body icon", old, old_adaptive), ("New top-half close-up", new, adaptive)]):
        x = 24 + index * 492
        draw.text((x, 106), name, font=font(23), fill="#132842")
        large = icon.resize((384, 384), Image.Resampling.LANCZOS)
        mask = Image.new("L", large.size)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, 383, 383), radius=82, fill=255)
        board.paste(large, (x, 146), mask)
        for size, offset in [(60, 0), (48, 98), (32, 184), (24, 254)]:
            small = icon.resize((size, size), Image.Resampling.LANCZOS)
            board.paste(small, (x + offset, 556))
            draw.text((x + offset, 624), f"{size}px", font=font(14), fill="#58636B")
        # Android's visible viewport is the central 72 dp of a 108 dp layer.
        masked = flatten(foreground, BACKGROUND).crop((72, 72, 360, 360)).resize((128, 128), Image.Resampling.LANCZOS)
        circle = Image.new("L", (128, 128))
        ImageDraw.Draw(circle).ellipse((0, 0, 127, 127), fill=255)
        board.paste(masked, (x, 670), circle)
        draw.text((x + 145, 716), "Android circle", font=font(16), fill="#58636B")
    board.save(REVIEW / "size-comparison.png")


def main():
    master_layer = character(1024)
    master = flatten(master_layer, BACKGROUND)
    master.save(BRANDING / "travary_app_icon_master.png")
    master.resize((512, 512), Image.Resampling.LANCZOS).save(BRANDING / "google_play_icon.png")

    catalog = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    entries = json.loads((catalog / "Contents.json").read_text())["images"]
    for entry in entries:
        size = round(float(entry["size"].split("x")[0]) * float(entry["scale"].rstrip("x")))
        master.resize((size, size), Image.Resampling.LANCZOS).save(catalog / entry["filename"])

    resources = ROOT / "android/app/src/main/res"
    for density, size in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
        master.resize((size, size), Image.Resampling.LANCZOS).save(resources / f"mipmap-{density}/ic_launcher.png")
    adaptive = character(432, adaptive=True)
    adaptive.save(resources / "drawable-nodpi/ic_launcher_adaptive_art.png")
    colors = resources / "values/colors.xml"
    colors.write_text(re.sub(r'(<color name="ic_launcher_background">)[^<]+', rf'\g<1>{BACKGROUND}', colors.read_text()))
    preview(master_layer, adaptive)
    print("Exported iOS, Android, Google Play and review previews.")


if __name__ == "__main__":
    main()
