#!/usr/bin/env python3
"""Check and package the approved, locally assembled App Store loops.

No generation services, uploads or app runtime assets are used. Review crops
are inspection aids; the complete canvases in exports/ are the delivery files.
"""
import json
import shutil
import subprocess
from fractions import Fraction

import numpy as np
from PIL import Image, ImageDraw

import compose_reuse as reuse

HERE = reuse.HERE
APPROVAL = 'much better, lets go ahead and do the rest'
PLACEMENTS = {
    'header': {'version': 'v4', 'size': (3840, 1646),
               'safe': (1097, 493, 2743, 1154), 'source': 'tag-idle'},
    'search': {'version': 'v5', 'size': (3840, 2560),
               'safe': (836, 765, 3004, 1795), 'source': 'present-idle'},
}


def run(*args):
    return subprocess.run(args, check=True, capture_output=True).stdout


def decoded_frame(path, index, size):
    data = run('ffmpeg', '-v', 'error', '-i', str(path), '-vf',
               f'select=eq(n\\,{index})', '-frames:v', '1', '-f', 'rawvideo',
               '-pix_fmt', 'rgb24', '-')
    return np.frombuffer(data, dtype=np.uint8).reshape(size[1], size[0], 3)


def main():
    delivery = HERE/'exports'
    delivery.mkdir(exist_ok=True)
    report = {'prepared': '2026-10-18', 'owner_approval_quote': APPROVAL,
              'approval_scope': 'Header v4, search v5 and local reuse of the presented existing performances; no new transition or paid generation.',
              'paid_video_jobs_submitted': 0, 'new_character_generation': False,
              'new_scene_transition': False, 'upload_performed': False,
              'source_matte_cleanup': {'performance': 'present-idle', 'affected_source_frames': 14,
                                       'maximum_detached_component_pixels': 60,
                                       'method': 'Remove tiny detached remnants only; preserve connected character and its antialiasing.'},
              'specification_checked': '2026-10-18',
              'specification_source': 'https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications',
              'placements': {}, 'files': []}
    manifest_path = HERE/'manifest.json'
    manifest = json.loads(manifest_path.read_text())
    known = {asset['file']: asset for asset in manifest['assets']}
    for name, settings in PLACEMENTS.items():
        version, size, safe = settings['version'], settings['size'], settings['safe']
        video = HERE/f'review/{name}-reuse-loop-{version}.mp4'
        still = HERE/f'review/{name}-start-{version}.png'
        # Detect accidental changes to an approved still before packaging.
        assert reuse.digest(still) == known[str(still.relative_to(HERE))]['sha256']
        with Image.open(still) as image:
            image.load()
            assert image.mode == 'RGB' and image.size == size
        probe = json.loads(run('ffprobe', '-v', 'error', '-count_frames',
                              '-show_streams', '-show_format', '-of', 'json', str(video)))
        assert len(probe['streams']) == 1, 'Expected silent video only'
        stream = probe['streams'][0]
        duration = float(probe['format']['duration'])
        count = int(stream['nb_read_frames'])
        assert stream['codec_type'] == 'video' and stream['codec_name'] == 'h264'
        assert (stream['width'], stream['height']) == size
        assert Fraction(stream['avg_frame_rate']) == 30
        assert stream['pix_fmt'] == 'yuv420p'
        assert 5 <= duration <= 30 and count == round(duration*30)
        # Decode the whole file: ffprobe metadata alone does not prove it plays.
        run('ffmpeg', '-v', 'error', '-xerror', '-i', str(video), '-f', 'null', '-')
        first = decoded_frame(video, 0, size)
        last = decoded_frame(video, count-1, size)
        x0, y0, x1, y1 = safe
        difference = np.abs(first.astype(np.int16)-last.astype(np.int16))
        join_mae = float(difference[y0:y1, x0:x1].mean())
        # The source poses are identical. Lossy encoding may differ slightly.
        assert join_mae < 2, f'Inspect loop join: safe-area MAE {join_mae}'
        reference = np.asarray(Image.open(still).convert('RGB'))
        still_mae = float(np.abs(first.astype(np.int16)-reference.astype(np.int16)).mean())
        assert still_mae < 3, f'Encoded frame differs unexpectedly from approved still: {still_mae}'
        preview = HERE/f'review/{name}-motion-detail-{version}.mp4'
        run('ffmpeg', '-v', 'error', '-y', '-i', str(video), '-an', '-vf',
            f'crop={x1-x0}:{y1-y0}:{x0}:{y0}:exact=1,pad=ceil(iw/2)*2:ceil(ih/2)*2',
            '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt',
            'yuv420p', '-movflags', '+faststart', str(preview))
        width = 640
        height = round((y1-y0)*width/(x1-x0))
        sheet = Image.new('RGB', (width*3+48, (height+36)*3+48), '#EEE8DE')
        draw = ImageDraw.Draw(sheet)
        # Nine decoded samples span one full 4.04-second performance.
        for tile_index, frame_index in enumerate(range(0, 121, 15)):
            pixels = first if frame_index == 0 else decoded_frame(video, frame_index, size)
            sample = Image.fromarray(pixels).crop(safe).resize((width, height), Image.Resampling.LANCZOS)
            x, y = 12+(tile_index%3)*(width+12), 12+(tile_index//3)*(height+48)
            sheet.paste(sample, (x, y))
            draw.text((x+5, y+height+7), f'{frame_index/30:.1f}s · {settings["source"]}',
                      fill=reuse.INK, font=reuse.font(16))
        sheet_path = HERE/f'review/{name}-motion-qa-{version}.jpg'
        sheet.save(sheet_path, quality=94)
        files = []
        for source_path, suffix, kind in [(video, '.mp4', 'locally_composited_video'),
                                           (still, '.png', 'opaque_static_fallback')]:
            target = delivery/f'travary-{name}-{version}{suffix}'
            shutil.copyfile(source_path, target)
            entry = {'file': str(target.relative_to(HERE)), 'kind': kind,
                     'placement': 'product_page_header' if name == 'header' else 'search_results',
                     'width': size[0], 'height': size[1], 'bytes': target.stat().st_size,
                     'sha256': reuse.digest(target), 'status': 'rendered_and_checked_for_final_playback_review',
                     'owner_approved': False, 'scene_and_reuse_approved': True,
                     'final_playback_approved': False, 'upload_performed': False,
                     'final_export': True, 'video_generated': suffix == '.mp4',
                     'tool': 'Local Pillow compositing and ffmpeg encoding of existing keyed Travi footage'}
            if suffix == '.mp4':
                entry.update({'fps': 30, 'duration_seconds': duration, 'audio_streams': 0})
            else:
                entry['mode'] = 'RGB'
            report['files'].append(entry)
            files.append(entry['file'])
        source_report = json.loads((HERE/f'review/{name}-reuse-report-{version}.json').read_text())
        assert source_report['first_last_still_identical']
        report['placements'][name] = {'size': list(size), 'fps': 30,
             'duration_seconds': duration, 'decoded_frames': count, 'codec': stream['codec_name'],
             'pixel_format': stream['pix_fmt'], 'audio_streams': 0,
             'full_decode_passed': True, 'source_start_end_pixel_identical': True,
             'decoded_join_safe_area_mean_absolute_error_255': round(join_mae, 6),
             'first_frame_vs_approved_still_mean_absolute_error_255': round(still_mae, 6),
             'safe_area': list(safe), 'delivery_files': files,
             'review_crop': str(preview.relative_to(HERE)), 'qa_contact_sheet': str(sheet_path.relative_to(HERE))}
    report_path = HERE/'review/motion-qa-report-v1.json'
    report_path.write_text(json.dumps(report, indent=2)+'\n')
    (delivery/'delivery-manifest.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report['placements'], indent=2))


if __name__ == '__main__':
    main()
