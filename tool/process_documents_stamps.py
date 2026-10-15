#!/usr/bin/env python3
"""Normalize and validate the generated Documents stamp asset family.

Writes PNGs into assets/art/. Bundled art ships as WebP: afterwards run
`dart run tool/art_packs.dart bundled-webp --replace`, which makes the
`.webp` files the app bundles and moves these PNGs to art_masters/bundled/.
"""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "tmp" / "documents_stamps_raw"
NAVY = (0x1C, 0x2A, 0x47)
CREAM = (0xF8, 0xF4, 0xEC)
RESAMPLE = Image.Resampling.LANCZOS


def alpha_bbox(image: Image.Image, threshold: int) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value > threshold else 0).getbbox()
    if bbox is None:
        raise ValueError("image has no visible alpha")
    return bbox


def crop_visible(image: Image.Image) -> Image.Image:
    return image.crop(alpha_bbox(image, 8))


def normalize_body_width(
    source: Path,
    destination: Path,
    canvas_size: tuple[int, int],
    body_width: int,
) -> None:
    image = crop_visible(Image.open(source).convert("RGBA"))
    body = alpha_bbox(image, 128)
    scale = body_width / (body[2] - body[0])
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        RESAMPLE,
    )
    body = alpha_bbox(resized, 128)
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    x = round(canvas_size[0] / 2 - (body[0] + body[2]) / 2)
    y = round(canvas_size[1] / 2 - (body[1] + body[3]) / 2)
    canvas.alpha_composite(resized, (x, y))
    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination, format="PNG", optimize=True)


def recolor_ink(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    alpha = image.getchannel("A")
    solid = Image.new("RGBA", image.size, (*NAVY, 0))
    solid.putalpha(alpha)
    return solid


def remove_coral_keyline(image: Image.Image) -> Image.Image:
    """Turn the airmail frame's coral ink back into warm-ivory paper."""
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha and red > 145 and red > green + 18 and red > blue + 42:
                pixels[x, y] = (0xF3, 0xEC, 0xE2, alpha)
    return image


def process_postmark(source: Path, destination: Path) -> None:
    image = crop_visible(Image.open(source).convert("RGBA"))
    body = alpha_bbox(image, 128)
    scale = 881 / max(body[2] - body[0], body[3] - body[1])
    image = image.resize((round(image.width * scale), round(image.height * scale)), RESAMPLE)
    image = recolor_ink(image)
    body = alpha_bbox(image, 128)
    canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    x = round(512 - (body[0] + body[2]) / 2)
    y = round(512 - (body[1] + body[3]) / 2)
    canvas.alpha_composite(image, (x, y))
    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination, format="PNG", optimize=True)


def process_cancel_lines(source: Path, destination: Path) -> None:
    image = Image.open(source).convert("RGBA")
    scale = 1536 / image.width
    image = image.resize((1536, round(image.height * scale)), RESAMPLE)
    body = alpha_bbox(image, 16)
    centre_y = (body[1] + body[3]) // 2
    top = max(0, min(image.height - 384, centre_y - 192))
    image = image.crop((0, top, 1536, top + 384))
    image = recolor_ink(image)
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination, format="PNG", optimize=True)


def process_icon_sheet(source: Path, destinations: list[Path]) -> None:
    sheet = Image.open(source).convert("RGBA")
    for index, destination in enumerate(destinations):
        column = index % 3
        row = index // 3
        left = round(column * sheet.width / 3)
        right = round((column + 1) * sheet.width / 3)
        top = round(row * sheet.height / 2)
        bottom = round((row + 1) * sheet.height / 2)
        cell = sheet.crop((left, top, right, bottom))
        visible = alpha_bbox(cell, 8)
        icon = cell.crop(visible)
        body = alpha_bbox(icon, 128)
        scale = 696 / max(body[2] - body[0], body[3] - body[1])
        icon = icon.resize((round(icon.width * scale), round(icon.height * scale)), RESAMPLE)
        icon = recolor_ink(icon)
        body = alpha_bbox(icon, 128)
        canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
        x = round(512 - (body[0] + body[2]) / 2)
        y = round(512 - (body[1] + body[3]) / 2)
        canvas.alpha_composite(icon, (x, y))
        destination.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(destination, format="PNG", optimize=True)


def flood_window(image: Image.Image) -> tuple[tuple[int, int, int, int], Image.Image]:
    width, height = image.size
    alpha = image.getchannel("A")
    pixels = alpha.load()
    centre = (width // 2, height // 2)
    seen = {centre}
    queue = deque([centre])
    x0 = x1 = centre[0]
    y0 = y1 = centre[1]
    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (
                0 <= nx < width
                and 0 <= ny < height
                and (nx, ny) not in seen
                and pixels[nx, ny] < 250
            ):
                seen.add((nx, ny))
                queue.append((nx, ny))
                x0, x1 = min(x0, nx), max(x1, nx)
                y0, y1 = min(y0, ny), max(y1, ny)
    mask = Image.new("L", image.size, 0)
    mask_pixels = mask.load()
    for x, y in seen:
        mask_pixels[x, y] = 255
    return (x0, y0, x1 + 1, y1 + 1), mask


def measure(path: Path, window: bool = False) -> dict[str, object]:
    image = Image.open(path).convert("RGBA")
    width, height = image.size
    alpha = image.getchannel("A")
    pixels = alpha.load()

    def fractions(box: tuple[int, int, int, int]) -> list[float]:
        return [
            round(box[0] / width, 4),
            round(box[1] / height, 4),
            round(box[2] / width, 4),
            round(box[3] / height, 4),
        ]

    result: dict[str, object] = {
        "size": [width, height],
        "corner_alpha": [
            pixels[0, 0],
            pixels[width - 1, 0],
            pixels[0, height - 1],
            pixels[width - 1, height - 1],
        ],
        "body": fractions(alpha_bbox(image, 128)),
    }
    if window:
        window_box, _ = flood_window(image)
        result["window_centre_alpha"] = pixels[width // 2, height // 2]
        result["window"] = fractions(window_box)
    return result


def ink_check(path: Path, tolerance: int = 6) -> dict[str, object]:
    image = Image.open(path).convert("RGBA")
    ink = [pixel for pixel in image.getdata() if pixel[3] > 16]
    off = sum(
        1
        for pixel in ink
        if max(abs(pixel[index] - NAVY[index]) for index in range(3)) > tolerance
    )
    return {
        "ink_pixels": len(ink),
        "off_colour_share": round(off / max(len(ink), 1), 4),
    }


def fit_thumbnail(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    copy = image.copy()
    copy.thumbnail(size, RESAMPLE)
    return copy


def composite_stamp_scene(frame: Image.Image, scene_path: Path) -> Image.Image:
    window_box, mask = flood_window(frame)
    x0, y0, x1, y1 = window_box
    scene = Image.open(scene_path).convert("RGBA")
    target_w, target_h = x1 - x0, y1 - y0
    scale = max(target_w / scene.width, target_h / scene.height)
    scene = scene.resize((round(scene.width * scale), round(scene.height * scale)), RESAMPLE)
    left = max(0, (scene.width - target_w) // 2 + round(target_w * 0.06))
    top = max(0, (scene.height - target_h) // 2)
    scene = scene.crop((left, top, left + target_w, top + target_h))
    layer = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    layer.alpha_composite(scene, (x0, y0))
    layer.putalpha(Image.composite(layer.getchannel("A"), Image.new("L", frame.size, 0), mask))
    return Image.alpha_composite(layer, frame)


def make_preview(paths: list[Path], preview_path: Path) -> None:
    tile_w, tile_h = 252, 270
    rows = (len(paths) + 3) // 4
    panel_w = tile_w * 4
    sheet = Image.new("RGB", (panel_w * 2, rows * tile_h + 410), CREAM)
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    backgrounds = [CREAM, NAVY]
    for panel, background in enumerate(backgrounds):
        x_panel = panel * panel_w
        draw.rectangle((x_panel, 0, x_panel + panel_w, rows * tile_h), fill=background)
        label_color = NAVY if background == CREAM else CREAM
        for index, path in enumerate(paths):
            row, column = divmod(index, 4)
            x0 = x_panel + column * tile_w
            y0 = row * tile_h
            image = fit_thumbnail(Image.open(path).convert("RGBA"), (220, 216))
            x = x0 + (tile_w - image.width) // 2
            y = y0 + 12 + (216 - image.height) // 2
            tile = Image.new("RGBA", (tile_w, tile_h), (*background, 255))
            tile.alpha_composite(image, (x - x0, y - y0))
            sheet.paste(tile.convert("RGB"), (x0, y0))
            draw.text((x0 + 8, y0 + 236), path.name, font=font, fill=label_color)

    row_top = rows * tile_h
    draw.rectangle((0, row_top, panel_w * 2, row_top + 410), fill=CREAM)
    draw.text((28, row_top + 18), "MOCK ROW — 3x phone-scale relationship preview", font=font, fill=NAVY)
    card = Image.new("RGBA", (1850, 320), (250, 247, 241, 255))
    card_draw = ImageDraw.Draw(card)
    card_draw.rounded_rectangle((2, 2, 1847, 317), radius=32, outline=(220, 211, 198, 255), width=3)
    postmark = fit_thumbnail(Image.open(ROOT / "assets/art/common/documents_postmark.png").convert("RGBA"), (236, 236))
    lines = fit_thumbnail(Image.open(ROOT / "assets/art/common/documents_cancel_lines.png").convert("RGBA"), (420, 110))
    card.alpha_composite(postmark, (45, 42))
    card.alpha_composite(lines, (210, 104))
    frame = Image.open(ROOT / "assets/art/common/documents_stamp_01.png").convert("RGBA")
    scenic_stamp = composite_stamp_scene(frame, ROOT / "art_masters/bundled/art/transport/any_car_01_scene.png")
    scenic_stamp = fit_thumbnail(scenic_stamp, (300, 264))
    stamp_x, stamp_y = 380, 28
    card.alpha_composite(scenic_stamp, (stamp_x, stamp_y))
    badge = Image.new("RGBA", (66, 66), (248, 244, 236, 255))
    ImageDraw.Draw(badge).rounded_rectangle((0, 0, 65, 65), radius=12, outline=(220, 211, 198, 255), width=2)
    icon = fit_thumbnail(Image.open(ROOT / "assets/art/icons/transport.png").convert("RGBA"), (40, 40))
    badge.alpha_composite(icon, ((66 - icon.width) // 2, (66 - icon.height) // 2))
    card.alpha_composite(badge, (stamp_x + scenic_stamp.width - 58, stamp_y + 8))
    draw_sheet_x = (sheet.width - card.width) // 2
    sheet.paste(card.convert("RGB"), (draw_sheet_x, row_top + 62))
    preview_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(preview_path, format="PNG", optimize=True)


def main() -> None:
    frames = [
        ROOT / "assets/art/common/documents_stamp_01.png",
        ROOT / "assets/art/common/documents_stamp_02.png",
        ROOT / "assets/art/common/documents_stamp_03.png",
    ]
    # Classic and airmail intentionally share exact geometry. Deriving the
    # classic finish from the generated airmail frame avoids a one-pixel
    # window mismatch while preserving the ImageGen paper and perforations.
    frame_sources = [RAW / "stamp_02.png", RAW / "stamp_02.png", RAW / "stamp_03.png"]
    for source, destination in zip(frame_sources, frames):
        normalize_body_width(source, destination, (1024, 896), 942)
    classic = remove_coral_keyline(Image.open(frames[0]).convert("RGBA"))
    classic.save(frames[0], format="PNG", optimize=True)

    postmark = ROOT / "assets/art/common/documents_postmark.png"
    cancel_lines = ROOT / "assets/art/common/documents_cancel_lines.png"
    process_postmark(RAW / "postmark.png", postmark)
    process_cancel_lines(RAW / "cancel_lines.png", cancel_lines)

    icons = [
        ROOT / "assets/art/icons/stay.png",
        ROOT / "assets/art/icons/attraction.png",
        ROOT / "assets/art/icons/transport.png",
        ROOT / "assets/art/icons/activity.png",
        ROOT / "assets/art/icons/event.png",
        ROOT / "assets/art/icons/note.png",
    ]
    process_icon_sheet(RAW / "icons_grid.png", icons)

    destinations = [
        ("destination_orlando.png", ROOT / "art_packs/sources/city_us_orlando/common/documents_destination_stamp.png"),
        (
            "destination_lake_district.png",
            ROOT / "art_packs/sources/region_gb_lake_district/common/documents_destination_stamp.png",
        ),
        ("destination_kyoto.png", ROOT / "art_packs/sources/city_jp_kyoto/common/documents_destination_stamp.png"),
        ("destination_paris.png", ROOT / "art_packs/sources/city_fr_paris/common/documents_destination_stamp.png"),
        ("destination_bali.png", ROOT / "art_packs/sources/region_id_bali/common/documents_destination_stamp.png"),
    ]
    for source_name, destination in destinations:
        normalize_body_width(RAW / source_name, destination, (1024, 1280), 942)

    measurements: dict[str, object] = {}
    for path in frames:
        measurements[str(path.relative_to(ROOT))] = measure(path, window=True)
    for path in [postmark, cancel_lines, *icons]:
        result = measure(path)
        result.update(ink_check(path))
        measurements[str(path.relative_to(ROOT))] = result
    for _, path in destinations:
        measurements[str(path.relative_to(ROOT))] = measure(path)

    report = ROOT / "tmp/documents_stamps_measurements.json"
    report.write_text(json.dumps(measurements, indent=2) + "\n")
    preview_paths = [*frames, postmark, cancel_lines, *icons, *(path for _, path in destinations)]
    make_preview(
        preview_paths,
        ROOT / "docs/mockups/documents-themed-v2/documents-stamps-production-preview.png",
    )
    print(json.dumps(measurements, indent=2))


if __name__ == "__main__":
    main()
