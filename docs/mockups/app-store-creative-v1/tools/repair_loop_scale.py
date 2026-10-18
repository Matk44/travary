#!/usr/bin/env python3
"""Repair scale pumping in existing Travi loops, without new generation.

The onboarding processor blended a smaller registered still into the first
and last five source frames. Matching endpoints concealed that size pulse.
Reuse only its unblended frames, apply one constant similarity transform to
match the approved character scale, and overlap calm matching poses locally.
App runtime assets and earlier marketing exports remain untouched.
"""
import argparse
import json
import subprocess
from functools import lru_cache

import numpy as np
from PIL import Image, ImageDraw

import compose_reuse as reuse
import compose_header_safe as header
import compose_search_clean as search

HERE = reuse.HERE
REVISION = 'v2'
FIRST, LAST, OVERLAP = 5, 91, 3
COUNT = LAST-FIRST+1-OVERLAP  # 84 frames; two repeats render to exactly 7 s.
ORIGINAL_ISOLATE = reuse.isolate
CACHE = HERE/f'layers/loop-repair-{REVISION}'


def bounds(layer):
    ys, xs = np.nonzero(np.asarray(layer.getchannel('A')) > 128)
    return np.array([xs.min(), ys.min(), xs.max()+1, ys.max()+1], dtype=float)


def mix(a, b, t):
    """Blend premultiplied color and alpha, avoiding dark/keyed edge halos."""
    aa, bb = np.asarray(a, dtype=np.float32), np.asarray(b, dtype=np.float32)
    alpha_a, alpha_b = aa[..., 3:]/255, bb[..., 3:]/255
    alpha = alpha_a*(1-t)+alpha_b*t
    rgb = (aa[..., :3]*alpha_a*(1-t)+bb[..., :3]*alpha_b*t)/np.maximum(alpha, 1e-6)
    return Image.fromarray(np.clip(np.dstack([rgb, alpha*255]).round(), 0, 255).astype(np.uint8))


def prepare(name):
    target, crop = ORIGINAL_ISOLATE(name, 0)
    layers = {index: ORIGINAL_ISOLATE(name, index)[0] for index in range(FIRST, LAST+1)}
    reference = bounds(target)
    neutral = np.median([bounds(layers[index]) for index in list(range(5,13))+list(range(84,92))], axis=0)
    scale = (reference[3]-reference[1])/(neutral[3]-neutral[1])
    # One fixed transform for the entire performance, anchored at the wheels.
    # Per-frame bounding-box fitting would mistake the wave for camera zoom.
    dx = (reference[0]+reference[2])/2-scale*(neutral[0]+neutral[2])/2
    dy = reference[3]-scale*neutral[3]
    matrix = (1/scale, 0, -dx/scale, 0, 1/scale, -dy/scale)
    aligned = {index: layer.convert('RGBa').transform(layer.size, Image.Transform.AFFINE,
               matrix, Image.Resampling.BICUBIC).convert('RGBA') for index,layer in layers.items()}
    sequence, recipe = [], []
    for j in range(OVERLAP):
        t = j/(OVERLAP-1)
        t = t*t*(3-2*t)
        tail, head = LAST-OVERLAP+1+j, FIRST+j
        sequence.append(mix(aligned[tail], aligned[head], t))
        recipe.append({'tail_frame':tail, 'head_frame':head, 'head_weight':round(t,8)})
    for index in range(FIRST+OVERLAP, LAST-OVERLAP+1):
        sequence.append(aligned[index])
        recipe.append({'source_frame':index})
    assert len(sequence) == COUNT
    destination = CACHE/name
    destination.mkdir(parents=True, exist_ok=True)
    for index, layer in enumerate(sequence):
        layer.save(destination/f'{index:04d}.png')
    old_boxes = [bounds(ORIGINAL_ISOLATE(name,index)[0]) for index in [91,92,93,94,95,96,0,1,2,3,4,5]]
    seam_indices = list(range(COUNT-6,COUNT))+list(range(0,OVERLAP+6))
    new_boxes = [bounds(sequence[index]) for index in seam_indices]
    old_heights = [float(b[3]-b[1]) for b in old_boxes]
    new_heights = [float(b[3]-b[1]) for b in new_boxes]
    # These calm-pose windows expose the old size pulse, unlike endpoint equality.
    assert np.ptp(new_heights) <= 3, f'Inspect residual size pulse in {name}: {new_heights}'
    assert np.ptp(new_heights) < np.ptp(old_heights)*.35
    return {'source_film':name, 'source_camera_crop':list(crop), 'source_frames_kept':[FIRST,LAST],
            'discarded_mismatched_endpoint_frames':[list(range(0,FIRST)),list(range(LAST+1,97))],
            'constant_scale':float(scale), 'constant_translation':[float(dx),float(dy)],
            'registration_reference_frame':0, 'registration_reference_bounds':reference.tolist(),
            'neutral_source_bounds':neutral.tolist(), 'overlap_frames':OVERLAP,
            'overlap_method':'Premultiplied alpha, smoothstep, same-pose wrap; no still-image endpoint dissolve.',
            'source_fps':24, 'cycle_frames':COUNT, 'recipe':recipe,
            'old_join_window_height_pixels':old_heights,
            'new_join_window_indices':seam_indices, 'new_join_window_height_pixels':new_heights,
            'old_join_height_range_pixels':float(np.ptp(old_heights)),
            'new_join_height_range_pixels':float(np.ptp(new_heights)),
            'new_join_max_height_step_pixels':float(np.abs(np.diff(new_heights)).max())}


@lru_cache(maxsize=COUNT*2)
def repaired_isolate(name, index):
    crop = (320,540,805,1195) if name=='tag-idle' else (180,540,815,1200)
    return Image.open(CACHE/name/f'{index:04d}.png').convert('RGBA'), crop


def encode(which, frame_at, size, final):
    path = HERE/f'review/{which}-repaired-loop-{REVISION}.mp4'
    filters = 'fps=30'
    if size != final:
        filters += f',scale={final[0]}:{final[1]}:flags=lanczos'
    command = ['ffmpeg','-v','error','-y','-f','rawvideo','-pixel_format','rgb24',
               '-video_size',f'{size[0]}x{size[1]}','-framerate','24','-i','-','-an',
               '-vf',filters,'-c:v','libx264','-preset','medium','-crf','18',
               '-pix_fmt','yuv420p','-movflags','+faststart',str(path)]
    pipe = subprocess.Popen(command, stdin=subprocess.PIPE)
    try:
        for _ in range(2):
            for index in range(COUNT):
                pipe.stdin.write(frame_at(index).tobytes())
    finally:
        pipe.stdin.close()
    assert pipe.wait()==0
    return path


def render(which):
    # Reuse the exact approved plates and production framing. Only the
    # isolated performance and its technical seam preparation are replaced.
    if which=='header':
        outer=Image.open(HERE/'layers/header-outer-stage-v4.png').convert('RGBA')
        scene=Image.open(HERE/'layers/header-complete-scene-base-v4.png').convert('RGBA')
        frame_at=lambda index:header.frame(index,outer,scene,final_size=False)
        full_at=lambda index:header.frame(index,outer,scene)
        size,final,safe=header.CAMERA,header.FINAL,header.SAFE
    else:
        base=Image.open(HERE/'layers/search-ready-v5.png').convert('RGBA')
        frame_at=lambda index:search.frame(index,base)
        full_at=frame_at
        size=final=search.SIZE
        safe=search.SAFE
    samples=[COUNT-3,COUNT-2,COUNT-1,0,1,2,3,4,5,6,7,8]
    width=480;height=round((safe[3]-safe[1])*width/(safe[2]-safe[0]))
    sheet=Image.new('RGB',(width*4+60,(height+36)*3+48),'#eee8de')
    draw=ImageDraw.Draw(sheet)
    for j,index in enumerate(samples):
        image=full_at(index)
        if index==0:image.save(HERE/f'review/{which}-repaired-start-{REVISION}.png')
        x=12+(j%4)*(width+12);y=12+(j//4)*(height+48)
        sheet.paste(image.crop(safe).resize((width,height),Image.Resampling.LANCZOS),(x,y))
        draw.text((x+5,y+height+6),f'cycle frame {index}',fill=reuse.INK,font=reuse.font(16))
    sheet.save(HERE/f'review/{which}-seam-storyboard-{REVISION}.jpg',quality=94)
    return str(encode(which,frame_at,size,final).relative_to(HERE))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare-only',action='store_true')
    args=parser.parse_args()
    report={'prepared':'2026-10-18','revision':REVISION,
            'owner_request':'Fix the zoom in/out at the loop transition in both approved scenes.',
            'diagnosis':'Onboarding endpoint fades mix a roughly 2% smaller still into the video; exact endpoint identity missed the surrounding size pulse.',
            'new_generation':False,'paid_generation_jobs':0,'new_scene_transition':False,
            'approved_artwork_preserved':True,'performances':{}}
    for name in ['tag-idle','present-idle']:
        report['performances'][name]=prepare(name)
        print(name,'join height range:',report['performances'][name]['old_join_height_range_pixels'],
              '->',report['performances'][name]['new_join_height_range_pixels'],flush=True)
    reuse.isolate=repaired_isolate
    if not args.prepare_only:
        report['videos']={which:render(which) for which in ['header','search']}
    (HERE/f'review/loop-scale-repair-{REVISION}.json').write_text(json.dumps(report,indent=2)+'\n')
    print('Prepared repaired loops from the approved performances; new generation: 0',flush=True)


if __name__=='__main__':main()
