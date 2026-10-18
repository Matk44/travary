#!/usr/bin/env python3
"""Search v5: regenerated postcard alpha asset and padded local shadows.

Default is still review. --video uses existing Travi footage locally after
scene approval. This compositor never calls a generation provider.
"""
import argparse
import json
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

import compose_reuse as reuse
import compose_search_clean as clean

HERE = reuse.HERE
VERSION = 'v5'
ASSET_AT = (875, 1125)


def cutout():
    source = HERE/'layers/search-postcard-tag-source-v5.png'
    raw = Image.open(source).convert('RGBA')
    a = np.asarray(raw).copy()
    # The generated production cutout has only very faint alpha specks below
    # 3.2% opacity outside its real contour. Keep the original source intact;
    # discard that invisible residue in the derived compositing layer.
    removed = int(((a[..., 3]>0)&(a[..., 3]<=8)).sum())
    a[..., 3] = np.where(a[..., 3]<=8, 0, a[..., 3])
    a[a[..., 3]==0, :3] = 0
    layer = Image.fromarray(a)
    box = layer.getchannel('A').getbbox()
    crop = (max(0, box[0]-16), max(0, box[1]-16), min(layer.width, box[2]+16), min(layer.height, box[3]+16))
    layer = layer.crop(crop)
    k = min(795/layer.width, 630/layer.height)
    layer = layer.resize((round(layer.width*k), round(layer.height*k)), Image.Resampling.LANCZOS)
    layer.save(HERE/'layers/search-postcard-tag-clean-v5.png')
    # Sharp editable typography, registered to the regenerated blank tag.
    alpha_before = np.asarray(layer.getchannel('A')).copy()
    text = Image.new('RGBA', (240, 150))
    draw = ImageDraw.Draw(text)
    draw.text((120, 51), '30', font=reuse.font(62, True), fill=reuse.INK, anchor='mm')
    draw.text((120, 103), 'DAYS TO GO', font=reuse.font(17), fill=reuse.INK, anchor='mm')
    text = text.rotate(9, Image.Resampling.BICUBIC, expand=True)
    overlay = Image.new('RGBA', layer.size)
    overlay.alpha_composite(text, (round(435-text.width/2), round(548-text.height/2)))
    text_alpha = np.asarray(overlay.getchannel('A'))
    assert int(alpha_before[text_alpha>0].min())>=240, 'Type spills outside the solid tag face'
    layer.alpha_composite(overlay)
    # Preserve the source silhouette even where the generated paper is 99%
    # opaque: adding ink must not change the cutout's alpha.
    layer.putalpha(Image.fromarray(alpha_before))
    layer.save(HERE/'layers/search-postcard-tag-lettered-v5.png')
    alpha = np.asarray(layer.getchannel('A'))
    assert all(int(edge.max())==0 for edge in [alpha[0], alpha[-1], alpha[:, 0], alpha[:, -1]])
    return layer, {'source': str(source.relative_to(HERE)), 'source_sha256': reuse.digest(source),
                   'source_crop_with_transparent_padding': crop, 'derived_size': list(layer.size),
                   'low_alpha_residue_removed_pixels': removed, 'low_alpha_cutoff': 8,
                   'derived_alpha_boundaries_zero': True, 'tag_text_inside_opaque_face': True,
                   'position_on_final_canvas': ASSET_AT}


def padded_shadow(layer, blur, opacity, offset, name):
    pad = math.ceil(blur*5 + max(abs(n) for n in offset) + 2)
    mask = Image.new('L', (layer.width+pad*2, layer.height+pad*2))
    mask.paste(layer.getchannel('A'), (pad, pad))
    mask = mask.filter(ImageFilter.GaussianBlur(blur)).point(lambda a: round(a*opacity))
    a = np.asarray(mask)
    edge_max = max(int(e.max()) for e in [a[0], a[-1], a[:, 0], a[:, -1]])
    assert edge_max==0, 'Shadow still reaches its canvas boundary'
    shadow = Image.new('RGBA', mask.size, (65, 43, 24, 0))
    shadow.putalpha(mask)
    shadow.save(HERE/f'layers/search-postcard-shadow-{name}-v5.png')
    at = (ASSET_AT[0]-pad+offset[0], ASSET_AT[1]-pad+offset[1])
    return shadow, at, {'name': name, 'padding': pad, 'blur': blur, 'opacity': opacity,
                         'offset': offset, 'outer_alpha_max': edge_max, 'size': list(mask.size)}


def bases():
    previous = clean.VERSION
    clean.VERSION = VERSION
    try:
        base, paper = clean.fine_paper()
    finally:
        clean.VERSION = previous
    postcard, asset = cutout()
    shadows = []
    for blur, opacity, offset, name in [(10, .20, (0, 8), 'soft'), (3, .14, (0, 3), 'contact')]:
        shade, at, info = padded_shadow(postcard, blur, opacity, offset, name)
        base.alpha_composite(shade, at)
        shadows.append(info)
    base.alpha_composite(postcard, ASSET_AT)
    plate = Image.open(HERE/'layers/search-background-v1.png').convert('RGBA')
    phone, capture = clean.phone_layer(plate)
    base.alpha_composite(phone, clean.pos(1003, 324))
    draw = ImageDraw.Draw(base)
    draw.text(clean.pos(350, 322), 'Your holiday,', fill=reuse.INK, font=reuse.font(135, True), anchor='lt')
    draw.text(clean.pos(350, 386), 'sorted into days.', fill='#CF5F3C', font=reuse.font(135, True), anchor='lt')
    def scaled_box(box):
        return tuple(round(n*clean.SCALE) for n in box)
    base = reuse.shadow(base, scaled_box((740, 686, 915, 705)), 55, 7*clean.SCALE)
    for x, y in [(794, 695), (875, 682), (832, 687), (758, 686)]:
        base = reuse.shadow(base, scaled_box((x-13, y-2, x+13, y+4)), 95, 3*clean.SCALE)
    base.save(HERE/'layers/search-ready-v5.png')
    return base, paper, capture, asset, shadows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--video', action='store_true', help='Local assembly only after revised scene approval')
    args = parser.parse_args()
    base, paper, capture, asset, shadows = bases()
    report = {'prepared': '2026-10-18', 'status': 'postcard_alpha_and_shadow_correction_for_review',
              'owner_request': 'Rough edges visible around the tag; consider regeneration.',
              'diagnosis': 'V4 retained matte background and blurred a shadow without padding; its bottom boundary alpha was nonzero.',
              'paper': paper, 'capture': capture, 'postcard_asset': asset, 'shadows': shadows,
              'size': clean.SIZE, 'safe_area': clean.SAFE, 'paid_video_jobs_submitted': 0,
              'imagegen_asset_generated': True, 'new_character_generation': False,
              'motion_composited': args.video, 'stills': []}
    images = []
    for index, label in reuse.SAMPLES:
        im = clean.frame(index, base)
        path = HERE/f'review/search-{label}-v5.png'
        im.save(path)
        images.append(im)
        report['stills'].append({'file': str(path.relative_to(HERE)), 'width': im.width, 'height': im.height,
                                 'mode': im.mode, 'sha256': reuse.digest(path), 'source_frame': index,
                                 'source_film': 'present-idle'})
    assert np.array_equal(np.asarray(images[0]), np.asarray(images[-1]))
    report['first_last_still_identical'] = True
    # Inspect the same type of close-up the owner supplied, at native pixels.
    images[0].crop((1140, 1510, 1700, 1790)).save(HERE/'review/search-tag-closeup-v5.png')
    previous, previous_safe = reuse.VERSION, reuse.SAFE['search']
    reuse.VERSION, reuse.SAFE['search'] = VERSION, clean.SAFE
    try:
        reuse.storyboard('search', images)
        reuse.safe_area_review('search', images[0])
    finally:
        reuse.VERSION, reuse.SAFE['search'] = previous, previous_safe
    if args.video:
        previous = clean.VERSION
        clean.VERSION = VERSION
        try:
            print(clean.video(base))
        finally:
            clean.VERSION = previous
    (HERE/'review/search-reuse-report-v5.json').write_text(json.dumps(report, indent=2)+'\n')
    print('Search v5 ready: genuine alpha cutout, fully padded shadows, native tag close-up; no new Travi or paid video jobs.')


if __name__ == '__main__':
    main()
