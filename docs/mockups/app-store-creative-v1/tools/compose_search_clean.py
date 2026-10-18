#!/usr/bin/env python3
"""Search v4: quiet cream paper and direct full-resolution composition.

Reuses existing artwork, real UI and existing Travi frames. No generation
service calls. Default is still/keyframe review; --video is local assembly
only after approval of the revised still artwork.
"""
import argparse
import json
import subprocess

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageOps

import compose_reuse as reuse

HERE = reuse.HERE
VERSION = 'v4'
SIZE = (3840, 2560)
SCALE = 2.5  # Same normalized geometry as the existing 1536x1024 layout.
SAFE = (836, 765, 3004, 1795)


def pos(x, y):
    return round(x*SCALE), round(y*SCALE)


def fine_paper():
    reference = Image.open(reuse.PROJECT/'docs/mockups/app-store-screenshots-v1/chatgpt/01-today.png').convert('RGB')
    cream = np.median(np.asarray(reference.crop((180, 5, 670, 75))), axis=(0, 1))
    source = Image.open(reuse.PROJECT/'art_masters/bundled/art/common/note_paper.png').convert('RGB')
    patch = source.crop((500, 125, 1500, 225))  # Unprinted paper, above the first rule.
    a = np.asarray(patch).astype(float)
    low = np.asarray(patch.filter(ImageFilter.GaussianBlur(5))).astype(float)
    # Retain only quiet, fine paper fibers; no enlarged fabric weave.
    detail = np.mean(a-low, axis=2)*0.35
    grain = np.empty((SIZE[1], SIZE[0]), dtype=np.float32)
    for y in range(0, SIZE[1], patch.height):
        for x in range(0, SIZE[0], patch.width):
            tile = detail
            if (x//patch.width)%2:
                tile = np.fliplr(tile)
            if (y//patch.height)%2:
                tile = np.flipud(tile)
            h, w = min(patch.height, SIZE[1]-y), min(patch.width, SIZE[0]-x)
            grain[y:y+h, x:x+w] = tile[:h, :w]
    rgb = np.clip(cream[None, None, :] + grain[..., None], 0, 255).round().astype(np.uint8)
    paper = Image.fromarray(rgb)
    paper.save(HERE/f'layers/search-paper-{VERSION}.png')
    return paper.convert('RGBA'), {
        'cream_rgb': [int(c) for c in cream],
        'cream_reference': 'docs/mockups/app-store-screenshots-v1/chatgpt/01-today.png',
        'cream_reference_crop': [180, 5, 670, 75],
        'grain_source': 'art_masters/bundled/art/common/note_paper.png',
        'grain_source_crop': [500, 125, 1500, 225],
        'texture_detail_gain': 0.35,
        'native_background_size': SIZE,
        'method': 'Existing fine-paper fibers, low contrast, native pixel scale; screenshot-matched cream tone.'}


def phone_layer(plate):
    # Composite authentic UI directly into the phone at its final pixel size.
    # This avoids the former intermediate downsize to a 192px-wide phone.
    phone = plate.crop((993, 44, 1455, 940)).convert('RGB').resize(pos(192, 373), Image.Resampling.LANCZOS)
    rgb = np.asarray(phone).astype(float)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    green = np.clip((g-np.maximum(r, b)-35)/70, 0, 1)
    ys, xs = np.nonzero(green>.90)
    x0, y0, x1, y1 = int(xs.min()), int(ys.min()), int(xs.max())+1, int(ys.max())+1
    cap_path = reuse.PROJECT/'docs/mockups/app-store-screenshots-v1/captures/01-today.png'
    capture = Image.open(cap_path).convert('RGB')
    scale = min((x1-x0)/capture.width, (y1-y0)/capture.height)
    capture = capture.resize((round(capture.width*scale), round(capture.height*scale)), Image.Resampling.LANCZOS)
    left = ((x1-x0)-capture.width)//2
    right = x1-x0-left-capture.width
    under = np.zeros_like(rgb)
    full = Image.new('RGB', (x1-x0, y1-y0))
    full.paste(capture, (left, 0))
    if left:
        full.paste(capture.crop((0, 0, 1, capture.height)).resize((left, capture.height)), (0, 0))
    if right:
        full.paste(capture.crop((capture.width-1, 0, capture.width, capture.height)).resize((right, capture.height)), (left+capture.width, 0))
    under[y0:y1, x0:x1] = np.asarray(full)
    edge = (green>0)&(green<1)
    rgb[..., 1] = np.where(edge, np.minimum(g, np.maximum(r, b)), g)
    phone = Image.fromarray(np.clip(rgb*(1-green[..., None])+under*green[..., None], 0, 255).astype(np.uint8)).convert('RGBA')
    mask = Image.new('L', phone.size)
    ImageDraw.Draw(mask).rounded_rectangle((1, 1, phone.width-2, phone.height-2), radius=round(81*phone.width/462), fill=255)
    phone.putalpha(mask.filter(ImageFilter.GaussianBlur(1)))
    return phone, {'source': str(cap_path.relative_to(reuse.PROJECT)), 'source_sha256': reuse.digest(cap_path),
                   'capture_crop': False, 'capture_resize_count': 1,
                   'capture_resized_size': list(capture.size), 'phone_size': list(phone.size),
                   'phone_position': pos(1003, 324), 'paper_gutters': [left, right]}


def bases():
    base, info = fine_paper()
    plate = Image.open(HERE/'layers/search-background-v1.png').convert('RGBA')
    plate_with_tag = reuse.resting_tag_text(plate.copy())
    # Preserve the original painted paper, tag and rope pixels while removing
    # the rectangular patch of old linen around them. These bounds belong to
    # the fixed existing artwork plate, with a narrow allowance for its shadows.
    matte = Image.new('L', plate.size)
    draw = ImageDraw.Draw(matte)
    draw.polygon([(88, 374), (783, 414), (738, 914), (35, 865)], fill=255)
    draw.polygon([(316, 846), (551, 811), (597, 838), (602, 893),
                  (578, 935), (340, 969), (320, 958)], fill=255)
    def rope(points, width):
        p = np.asarray(points, float)
        t = np.linspace(0, 1, 90)[:, None]
        curve = (1-t)**3*p[0] + 3*(1-t)**2*t*p[1] + 3*(1-t)*t**2*p[2] + t**3*p[3]
        draw.line([tuple(x) for x in curve], fill=255, width=width, joint='curve')
    rope([(563, 855), (603, 856), (638, 919), (677, 924)], 21)
    rope([(563, 861), (610, 858), (628, 940), (678, 929)], 21)
    rope([(677, 924), (692, 928), (703, 921), (713, 911)], 20)
    matte = matte.filter(ImageFilter.GaussianBlur(2))
    postcard = plate_with_tag.crop((32, 370, 790, 971))
    postcard.putalpha(matte.crop((32, 370, 790, 971)))
    postcard = postcard.resize(pos(318, 252), Image.Resampling.LANCZOS)
    postcard.save(HERE/'layers/search-postcard-tag-cutout-v4.png')
    shade = Image.new('RGBA', postcard.size, (65, 43, 24, 0))
    shade.putalpha(postcard.getchannel('A').filter(ImageFilter.GaussianBlur(8)).point(lambda a: round(a*.18)))
    base.alpha_composite(shade, pos(350, 452))
    base.alpha_composite(postcard, pos(350, 450))
    phone, capture = phone_layer(plate)
    base.alpha_composite(phone, pos(1003, 324))
    draw = ImageDraw.Draw(base)
    draw.text(pos(350, 322), 'Your holiday,', fill=reuse.INK, font=reuse.font(135, True), anchor='lt')
    draw.text(pos(350, 386), 'sorted into days.', fill='#CF5F3C', font=reuse.font(135, True), anchor='lt')
    def scaled_box(box):
        return tuple(round(n*SCALE) for n in box)
    base = reuse.shadow(base, scaled_box((740, 686, 915, 705)), 55, 7*SCALE)
    for x, y in [(794, 695), (875, 682), (832, 687), (758, 686)]:
        base = reuse.shadow(base, scaled_box((x-13, y-2, x+13, y+4)), 95, 3*SCALE)
    base.save(HERE/'layers/search-ready-v4.png')
    return base, info, capture


def frame(index, base):
    layer, _ = reuse.isolate('present-idle', index)
    layer = ImageOps.mirror(layer).resize(pos(233, 242), Image.Resampling.LANCZOS)
    out = base.copy()
    out.alpha_composite(layer, pos(715, 460))
    return out.convert('RGB')


def video(base):
    out = HERE/f'review/search-reuse-loop-{VERSION}.mp4'
    cmd = ['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pixel_format', 'rgb24',
           '-video_size', '3840x2560', '-framerate', '24', '-i', '-', '-an', '-vf', 'fps=30',
           '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p',
           '-movflags', '+faststart', str(out)]
    pipe = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    try:
        for _ in range(2):
            for index in range(97):
                pipe.stdin.write(frame(index, base).tobytes())
    finally:
        pipe.stdin.close()
    if pipe.wait():
        raise RuntimeError('Local ffmpeg encoding failed')
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--video', action='store_true', help='Local assembly only after revised artwork approval')
    args = parser.parse_args()
    base, paper, capture = bases()
    report = {'prepared': '2026-10-18', 'status': 'cleaner_paper_search_still_for_review',
              'owner_request': 'Cleaner cream material similar to screenshot backgrounds; improve zoomed presentation.',
              'paper': paper, 'capture': capture, 'layout_geometry': 'Same normalized positions and sizes as search v3.',
              'size': SIZE, 'safe_area': SAFE, 'paid_video_jobs_submitted': 0,
              'new_image_generation': False, 'new_character_generation': False,
              'motion_composited': args.video, 'stills': []}
    images = []
    for index, label in reuse.SAMPLES:
        im = frame(index, base)
        path = HERE/f'review/search-{label}-v4.png'
        im.save(path)
        images.append(im)
        report['stills'].append({'file': str(path.relative_to(HERE)), 'width': im.width, 'height': im.height,
                                 'mode': im.mode, 'sha256': reuse.digest(path), 'source_frame': index,
                                 'source_film': 'present-idle'})
    assert np.array_equal(np.asarray(images[0]), np.asarray(images[-1]))
    report['first_last_still_identical'] = True
    previous, previous_safe = reuse.VERSION, reuse.SAFE['search']
    reuse.VERSION, reuse.SAFE['search'] = VERSION, SAFE
    try:
        reuse.storyboard('search', images)
        reuse.safe_area_review('search', images[0])
    finally:
        reuse.VERSION, reuse.SAFE['search'] = previous, previous_safe
    if args.video:
        print(video(base))
    (HERE/'review/search-reuse-report-v4.json').write_text(json.dumps(report, indent=2)+'\n')
    print('Search v4 prepared at native 3840x2560: quiet screenshot-matched cream, real UI, existing Travi; paid jobs: 0')


if __name__ == '__main__':
    main()
