#!/usr/bin/env python3
"""Fit the complete header theatre inside the art safe area, without cropping.

Default: stills and storyboard only. --video is local reuse assembly after
owner approval, never new character generation or a paid provider request.
"""
import argparse
import json
import subprocess

import numpy as np
from PIL import Image, ImageOps

import compose_reuse as reuse

HERE = reuse.HERE
VERSION = 'v4'
CAMERA = (1916, 821)
FINAL = (3840, 1646)
SCENE_SIZE = (747, 320)
SCENE_AT = (584, 250)
SAFE = reuse.SAFE['header']


def tile(patch, size):
    """Mirror repeat existing paper grain to avoid hard texture joins."""
    out = Image.new('RGBA', size)
    for y in range(0, size[1], patch.height):
        for x in range(0, size[0], patch.width):
            piece = patch
            if (x // patch.width) % 2:
                piece = ImageOps.mirror(piece)
            if (y // patch.height) % 2:
                piece = ImageOps.flip(piece)
            out.alpha_composite(piece, (x, y))
    return out


def bases():
    source = Image.open(HERE/'layers/header-background-v1.png').convert('RGBA')
    source = source.resize(CAMERA, Image.Resampling.LANCZOS)
    # The outer stage meets the scaled inner scene's original floor horizon.
    floor = SCENE_AT[1] + round(613 * SCENE_SIZE[1] / CAMERA[1])
    wall = tile(source.crop((520, 365, 1000, 600)), (CAMERA[0], floor))
    paper = tile(source.crop((280, 650, 1470, 815)), (CAMERA[0], CAMERA[1]-floor))
    outer = Image.new('RGBA', CAMERA)
    outer.alpha_composite(wall)
    outer.alpha_composite(paper, (0, floor))
    # Same existing performance and full-size composition as the earlier fit
    # study; only the complete theatre's placement changes for this revision.
    scene = reuse.shadow(source, (935, 722, 1255, 757), 55, 14)
    for x, y in [(953, 714), (1038, 703), (1160, 736), (1213, 716)]:
        scene = reuse.shadow(scene, (x-27, y-4, x+27, y+6), 100, 4)
    outer.save(HERE/'layers/header-outer-stage-v4.png')
    scene.save(HERE/'layers/header-complete-scene-base-v4.png')
    return outer, scene


def frame(index, outer, scene, final_size=True):
    travi, crop = reuse.isolate('tag-idle', index)
    travi = reuse.held_tag_text(travi, crop)
    travi = travi.resize((398, 537), Image.Resampling.LANCZOS)
    full_scene = scene.copy()
    full_scene.alpha_composite(travi, (895, 218))
    full_scene = full_scene.resize(SCENE_SIZE, Image.Resampling.LANCZOS)
    # Blend only the perimeter into the matching paper stage, avoiding the
    # appearance of a hard rectangular image pasted onto the outer canvas.
    yy, xx = np.mgrid[:SCENE_SIZE[1], :SCENE_SIZE[0]]
    edge = np.minimum.reduce([xx, yy, SCENE_SIZE[0]-1-xx, SCENE_SIZE[1]-1-yy])
    full_scene.putalpha(Image.fromarray(np.clip(edge/9*255, 0, 255).astype(np.uint8)))
    out = outer.copy()
    out.alpha_composite(full_scene, SCENE_AT)
    out = out.convert('RGB')
    return out.resize(FINAL, Image.Resampling.LANCZOS) if final_size else out


def video(outer, scene):
    out = HERE/'review/header-reuse-loop-v4.mp4'
    cmd = ['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pixel_format', 'rgb24',
           '-video_size', '1916x821', '-framerate', '24', '-i', '-', '-an',
           '-vf', 'fps=30,scale=3840:1646:flags=lanczos', '-c:v', 'libx264',
           '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p',
           '-movflags', '+faststart', str(out)]
    pipe = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    try:
        for _ in range(2):
            for index in range(97):
                pipe.stdin.write(frame(index, outer, scene, final_size=False).tobytes())
    finally:
        pipe.stdin.close()
    if pipe.wait():
        raise RuntimeError('Local ffmpeg encoding failed')
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--video', action='store_true', help='Local assembly only after owner approval')
    args = parser.parse_args()
    outer, scene = bases()
    report = {'prepared': '2026-10-18', 'owner_request': 'Complete header image inside the safe area, as for search.',
              'status': 'revised_header_stills_for_owner_review', 'source_crop': False,
              'source_scene': 'layers/header-background-v1.png', 'source_scene_camera': CAMERA,
              'scene_size_on_production_camera': SCENE_SIZE, 'scene_position_on_production_camera': SCENE_AT,
              'safe_area_on_final_canvas': SAFE, 'paid_video_jobs_submitted': 0,
              'new_character_generation': False, 'motion_composited': args.video, 'stills': []}
    box = [SCENE_AT[0], SCENE_AT[1], SCENE_AT[0]+SCENE_SIZE[0], SCENE_AT[1]+SCENE_SIZE[1]]
    final_box = [box[0]*FINAL[0]/CAMERA[0], box[1]*FINAL[1]/CAMERA[1],
                 box[2]*FINAL[0]/CAMERA[0], box[3]*FINAL[1]/CAMERA[1]]
    assert final_box[0]>=SAFE[0] and final_box[1]>=SAFE[1] and final_box[2]<=SAFE[2] and final_box[3]<=SAFE[3]
    report['complete_scene_bounds_on_final_canvas'] = [round(n, 2) for n in final_box]
    images = []
    for index, label in reuse.SAMPLES:
        im = frame(index, outer, scene)
        path = HERE/f'review/header-{label}-v4.png'
        im.save(path)
        images.append(im)
        report['stills'].append({'file': str(path.relative_to(HERE)), 'width': im.width, 'height': im.height,
                                 'mode': im.mode, 'sha256': reuse.digest(path), 'source_frame': index,
                                 'source_film': 'tag-idle'})
    assert np.array_equal(np.asarray(images[0]), np.asarray(images[-1]))
    report['first_last_still_identical'] = True
    # Reuse the review helpers while writing the new version beside v3.
    previous = reuse.VERSION
    reuse.VERSION = VERSION
    try:
        reuse.storyboard('header', images)
        reuse.safe_area_review('header', images[0])
    finally:
        reuse.VERSION = previous
    if args.video:
        print(video(outer, scene))
    (HERE/'review/header-reuse-report-v4.json').write_text(json.dumps(report, indent=2)+'\n')
    print('Complete header scene fits the safe area without cropping; four review stills ready; paid jobs: 0')


if __name__ == '__main__':
    main()
