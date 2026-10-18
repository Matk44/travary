#!/usr/bin/env python3
"""Locally composite existing Travi footage; no generation service calls.

Default: layered stills and a storyboard for review. --video renders the same
compositions from the existing keyed frame sequences after movement approval.
Needs Pillow, numpy and ffmpeg. Uses the bundled Codex Python runtime.
"""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

HERE = Path(__file__).resolve().parents[1]
PROJECT = HERE.parents[2]
FILMS = PROJECT / 'docs/mockups/onboarding-films-v2'
FONTS = PROJECT / 'assets/widget/fonts'
SAMPLES = [(0, 'start'), (30, 'blink'), (66, 'gesture'), (96, 'settle')]
INK = '#1C2A47'
VERSION = 'v3'
SAFE = {'header': (1097, 493, 2743, 1154), 'search': (418, 382, 1502, 898)}


def font(size, serif=False):
    name = 'widget_serif_bold.ttf' if serif else 'widget_sans_semibold.ttf'
    return ImageFont.truetype(str(FONTS / name), size)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def isolate(name, index):
    """Remove the old separate folio while retaining Travi's coral hand.

    Mask coordinates belong to the existing registered 941x1672 camera.
    No character pixels are generatively redrawn. The presenter is mirrored
    as a complete character so his open palm and gaze point to the phone.
    """
    image = Image.open(FILMS / 'keyed' / name / f'{index:04d}.png').convert('RGBA')
    a = np.array(image)
    if image.size != (941, 1672):
        raise ValueError('Existing film camera changed; review masks before use')
    if name == 'tag-idle':
        a[:, :326, 3] = 0
        crop = (320, 540, 805, 1195)
    elif name == 'present-idle':
        r, g, b = [a[:, :330, c].astype(float) for c in range(3)]
        coral = (r > 65) & (r > g * 1.50) & (r > b * 1.90) & (g > 25)
        coral[:500] = False
        coral[900:] = False
        # Some warm brass on the separate folio passes a coral color test.
        # Keep the main hand component, with a small margin for its fold lines.
        raw = ((coral[500:900] & (a[500:900, :330, 3] > 16))*255).astype(np.uint8)
        ys, xs = np.nonzero(raw)
        # Copy the numpy-backed image: floodfill silently skips a readonly buffer.
        hand = Image.fromarray(raw).copy()
        nearest = np.argmin((xs-xs.mean())**2 + (ys-ys.mean())**2)
        ImageDraw.floodfill(hand, (int(xs[nearest]), int(ys[nearest])), 127)
        connected = np.zeros(coral.shape, bool)
        core = Image.fromarray(((np.asarray(hand)==127)*255).astype(np.uint8))
        connected[500:900] = np.asarray(core.filter(ImageFilter.MaxFilter(5))) > 0
        a[:, :330, 3] = np.where(connected, a[:, :330, 3], 0)
        crop = (180, 540, 815, 1200)
    else:
        raise ValueError(name)
    a[a[..., 3] == 0, :3] = 0
    layer = Image.fromarray(a).crop(crop)
    if name == 'present-idle':
        layer = remove_presenter_specks(layer)
    return layer, crop


def remove_presenter_specks(layer):
    """Remove tiny detached source/matte remnants, preserving the character.

    The complete body, arm, tag and wheels are one alpha component. Fourteen
    existing source frames also contain detached marks (at most 60 pixels),
    including a brass fleck from the removed folio beside the waving hand.
    Keep the character's antialiasing and reject unexpected large components
    rather than silently discarding a newly changed source performance.
    """
    pixels = np.asarray(layer).copy()
    solid = pixels[..., 3] > 8
    assert solid[350, 400], 'Presenter registration changed; inspect mask seed'
    mask = Image.fromarray((solid*255).astype(np.uint8)).copy()
    ImageDraw.floodfill(mask, (400, 350), 127)
    core = np.asarray(mask) == 127
    stray = solid & ~core
    if stray.any():
        assert int(stray.sum()) <= 128, 'Unexpected detached character part; inspect before masking'
        removal = Image.fromarray((stray*255).astype(np.uint8)).filter(ImageFilter.MaxFilter(7))
        fringe = Image.fromarray((core*255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3))
        kill = (np.asarray(removal) > 0) & (np.asarray(fringe) == 0)
        pixels[kill] = 0
    return Image.fromarray(pixels)


def held_tag_text(layer, crop):
    """Register editable countdown type to the existing tag's cream face.

    A small local cream-color search follows the gentle idle's translation
    and size changes. The frame-by-frame result still needs video QA.
    """
    a = np.array(layer)
    x0, y0, _, _ = crop
    r, g, b = [a[..., c].astype(float) for c in range(3)]
    cream = (r > 165) & (g > 135) & (b > 100) & (r < g * 1.42) & (a[..., 3] > 200)
    roi = np.zeros(cream.shape, bool)
    roi[920-y0:1090-y0, 420-x0:620-x0] = True
    ys, xs = np.nonzero(cream & roi)
    if len(xs) < 3000:
        raise ValueError('Tag tracking failed; inspect the cream face')
    cx = float(np.median(xs))
    top, bottom = float(np.percentile(ys, 2)), float(np.percentile(ys, 98))
    scale = (bottom - top) / 155
    patch = Image.new('RGBA', layer.size)
    draw = ImageDraw.Draw(patch)
    draw.text((cx, top + 64 * scale), '30', fill=INK, font=font(round(72 * scale), True), anchor='mm')
    draw.text((cx, top + 118 * scale), 'DAYS TO GO', fill=INK, font=font(round(13 * scale)), anchor='mm')
    # Keep all text on the cream face and off the hands/outline.
    text = np.array(patch)
    text[..., 3] = (text[..., 3].astype(float) * cream).astype(np.uint8)
    return Image.alpha_composite(layer, Image.fromarray(text))


def shadow(base, box, opacity=55, blur=12):
    mask = Image.new('L', base.size)
    ImageDraw.Draw(mask).ellipse(box, fill=opacity)
    mask = mask.filter(ImageFilter.GaussianBlur(blur))
    shade = Image.new('RGBA', base.size, (61, 39, 22, 0))
    shade.putalpha(mask)
    return Image.alpha_composite(base, shade)


def search_capture(plate):
    rgb = np.asarray(plate.convert('RGB')).astype(float)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    green = np.clip((g - np.maximum(r, b) - 35) / 70, 0, 1)
    # Restrict keying to the observed phone so the postcard remains intact.
    green[:, :990] = 0
    solid = green > .90
    ys, xs = np.nonzero(solid)
    x0, x1, y0, y1 = int(xs.min()), int(xs.max())+1, int(ys.min()), int(ys.max())+1
    cap_path = PROJECT / 'docs/mockups/app-store-screenshots-v1/captures/01-today.png'
    cap = Image.open(cap_path).convert('RGB')
    k = min((x1-x0)/cap.width, (y1-y0)/cap.height)
    cap = cap.resize((round(cap.width*k), round(cap.height*k)), Image.Resampling.LANCZOS)
    # Keep the complete authentic UI, including tab labels and home indicator.
    # The generated phone is a little wider than the capture: extend only its
    # edge paper pixels into narrow side gutters rather than stretching/cropping UI.
    left = ((x1-x0)-cap.width)//2
    cap_full = Image.new('RGB', (x1-x0, y1-y0))
    cap_full.paste(cap, (left, 0))
    if left:
        cap_full.paste(cap.crop((0, 0, 1, cap.height)).resize((left, cap.height)), (0, 0))
    right = (x1-x0)-left-cap.width
    if right:
        cap_full.paste(cap.crop((cap.width-1, 0, cap.width, cap.height)).resize((right, cap.height)), (left+cap.width, 0))
    under = np.zeros_like(rgb)
    under[y0:y1, x0:x1] = np.asarray(cap_full)
    edge = (green > 0) & (green < 1)
    rgb[..., 1] = np.where(edge, np.minimum(g, np.maximum(r, b)), g)
    out = rgb*(1-green[..., None]) + under*green[..., None]
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).convert('RGBA'), {
        'source': str(cap_path.relative_to(PROJECT)), 'source_sha256': digest(cap_path),
        'screen_box_on_1536x1024': [x0, y0, x1, y1],
        'capture_scale': k, 'capture_resized_size': list(cap.size),
        'horizontal_paper_gutters': [left, right], 'capture_crop': False,
        'policy': 'Complete authentic capture, proportional contain, edge-paper side gutters, no UI redraw',
    }


def resting_tag_text(base):
    patch = Image.new('RGBA', (250, 145))
    draw = ImageDraw.Draw(patch)
    draw.text((125, 53), '30', fill=INK, font=font(56, True), anchor='mm')
    draw.text((125, 99), 'DAYS TO GO', fill=INK, font=font(15), anchor='mm')
    patch = patch.rotate(10, Image.Resampling.BICUBIC, expand=True)
    base.alpha_composite(patch, (round(445-patch.width/2), round(898-patch.height/2)))
    return base


def bases():
    header = Image.open(HERE/'layers/header-background-v2.png').convert('RGBA')
    # Normalize the production camera once; layer geometry uses this canvas.
    header = header.resize((1916, 821), Image.Resampling.LANCZOS)
    draw = ImageDraw.Draw(header)
    draw.text((568, 320), 'Where are we', fill='#FFF1D9', font=font(64, True), anchor='lt')
    draw.text((682, 402), 'off to?', fill='#FA815A', font=font(80, True), anchor='lt')
    plate, info = search_capture(Image.open(HERE/'layers/search-background-v1.png'))
    plate = resting_tag_text(plate)
    # Recompose the actual objects inside Apple's safe area. Keep the complete
    # UI and paper objects; do not flatten the entire scene into a small inset.
    linen = Image.open(PROJECT/'art_masters/bundled/art/common/linen.png').convert('RGBA')
    search = ImageOps.fit(linen, (1536, 1024), Image.Resampling.LANCZOS)
    postcard = plate.crop((32, 370, 790, 971))
    yy, xx = np.mgrid[:postcard.height, :postcard.width]
    edge = np.minimum.reduce([xx, yy, postcard.width-1-xx, postcard.height-1-yy])
    postcard.putalpha(Image.fromarray(np.clip(edge/12*255, 0, 255).astype(np.uint8)))
    postcard = postcard.resize((318, 252), Image.Resampling.LANCZOS)
    search.alpha_composite(postcard, (350, 450))
    phone = plate.crop((993, 44, 1455, 940))
    mask = Image.new('L', phone.size)
    ImageDraw.Draw(mask).rounded_rectangle((1, 1, phone.width-2, phone.height-2), radius=81, fill=255)
    phone.putalpha(mask.filter(ImageFilter.GaussianBlur(1)))
    phone = phone.resize((192, 373), Image.Resampling.LANCZOS)
    search.alpha_composite(phone, (1003, 324))
    draw = ImageDraw.Draw(search)
    draw.text((350, 322), 'Your holiday,', fill=INK, font=font(54, True), anchor='lt')
    draw.text((350, 386), 'sorted into days.', fill='#CF5F3C', font=font(54, True), anchor='lt')
    header = shadow(header, (1120, 548, 1330, 570), 45, 8)
    for x, y in [(1135, 542), (1187, 536), (1263, 556), (1296, 543)]:
        header = shadow(header, (x-17, y-2, x+17, y+4), 95, 3)
    search = shadow(search, (740, 686, 915, 705), 55, 7)
    for x, y in [(794, 695), (875, 682), (832, 687), (758, 686)]:
        search = shadow(search, (x-13, y-2, x+13, y+4), 95, 3)
    header.save(HERE/f'layers/header-ready-{VERSION}.png')
    search.save(HERE/f'layers/search-ready-{VERSION}.png')
    info['phone_assembly'] = {'plate_crop': [993, 44, 1455, 940], 'resized_size': [192, 373],
                              'position_on_1536x1024': [1003, 324]}
    return {'header': header, 'search': search}, info


def frame(which, index, base, full_size=True, save_layer=False):
    name = 'tag-idle' if which == 'header' else 'present-idle'
    layer, crop = isolate(name, index)
    if which == 'header':
        layer = held_tag_text(layer, crop)
        size, at, final = (244, 330), (1100, 246), (3840, 1646)
    else:
        layer = ImageOps.mirror(layer)
        size, at, final = (233, 242), (715, 460), (1920, 1280)
    if save_layer:
        layer.save(HERE/f'layers/{which}-travi-frame-{index:04d}-{VERSION}.png')
    layer = layer.resize(size, Image.Resampling.LANCZOS)
    out = base.copy()
    out.alpha_composite(layer, at)
    out = out.convert('RGB')
    return out.resize(final, Image.Resampling.LANCZOS) if full_size else out


def storyboard(which, images):
    images = [im.crop(SAFE[which]) for im in images]
    w = 960
    h = round(images[0].height * w / images[0].width)
    sheet = Image.new('RGB', (w*2+48, (h+62)*2+48), '#EEE8DE')
    draw = ImageDraw.Draw(sheet)
    for j, ((index, label), im) in enumerate(zip(SAMPLES, images)):
        x, y = 16+(j%2)*(w+16), 16+(j//2)*(h+62+16)
        sheet.paste(im.resize((w, h), Image.Resampling.LANCZOS), (x, y))
        shown_label = 'wave' if which == 'search' and label == 'blink' else label
        text = f'{index/24:.2f}s · {shown_label} · existing {"tag-idle" if which=="header" else "present-idle"}'
        draw.text((x+4, y+h+14), text, fill=INK, font=font(20))
    sheet.save(HERE/f'review/{which}-reuse-storyboard-{VERSION}.jpg', quality=93)


def safe_area_review(which, image):
    image.crop(SAFE[which]).save(HERE/f'review/{which}-safe-area-detail-{VERSION}.png')
    mask = Image.new('L', image.size, 155)
    ImageDraw.Draw(mask).rectangle(SAFE[which], fill=0)
    shade = Image.new('RGBA', image.size, (6, 15, 29, 0))
    shade.putalpha(mask)
    overlay = Image.alpha_composite(image.convert('RGBA'), shade)
    ImageDraw.Draw(overlay).rectangle(SAFE[which], outline='#63DE9D', width=4)
    overlay.convert('RGB').save(HERE/f'review/{which}-safe-area-overlay-{VERSION}.jpg', quality=93)


def render_video(which, base):
    """Local encoding only. Invoke after owner approves the reuse storyboard."""
    paths = sorted((FILMS/'keyed'/('tag-idle' if which=='header' else 'present-idle')).glob('*.png'))
    size = (1916, 821) if which == 'header' else (1536, 1024)
    target = (3840, 1646) if which == 'header' else (1920, 1280)
    out = HERE/f'review/{which}-reuse-loop-{VERSION}.mp4'
    cmd = ['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pixel_format', 'rgb24',
           '-video_size', f'{size[0]}x{size[1]}', '-framerate', '24', '-i', '-', '-an',
           '-vf', f'fps=30,scale={target[0]}:{target[1]}:flags=lanczos', '-c:v', 'libx264',
           '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(out)]
    pipe = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    try:
        # Two exact copies of the existing 4.04s loop, no new scene transition.
        for _ in range(2):
            for p in paths:
                pipe.stdin.write(frame(which, int(p.stem), base, full_size=False).tobytes())
    finally:
        pipe.stdin.close()
    if pipe.wait() != 0:
        raise RuntimeError('ffmpeg failed')
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--video', action='store_true', help='Only after reuse storyboard approval; encodes locally')
    args = parser.parse_args()
    base, capture = bases()
    report = {'prepared': '2026-10-18', 'status': 'reuse_stills_for_owner_review',
              'paid_video_jobs_submitted': 0, 'new_animation_generated': False,
              'new_motion_composited': args.video, 'capture': capture, 'stills': [],
              'safe_area_reference': '../references/apple-safe-areas.json',
              'safe_area_boxes_on_outputs': SAFE,
              'review_note': 'v3 replaces v2 fit studies. Headline, tag and entire character/phone are arranged in the official art safe areas. App Store Connect Preview remains a final placement check.'}
    for which in ['header', 'search']:
        images = []
        for index, label in SAMPLES:
            im = frame(which, index, base[which], save_layer=True)
            path = HERE/f'review/{which}-{label}-{VERSION}.png'
            im.save(path)
            report['stills'].append({'file': str(path.relative_to(HERE)), 'width': im.width,
                                     'height': im.height, 'mode': im.mode, 'sha256': digest(path),
                                     'source_frame': index, 'source_film': 'tag-idle' if which=='header' else 'present-idle'})
            images.append(im)
        storyboard(which, images)
        safe_area_review(which, images[0])
        if args.video:
            print(render_video(which, base[which]).relative_to(PROJECT))
    (HERE/f'review/reuse-report-{VERSION}.json').write_text(json.dumps(report, indent=2)+'\n')
    print('Prepared both reuse storyboards and finished still compositions; paid video jobs: 0')


if __name__ == '__main__':
    main()
