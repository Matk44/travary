#!/usr/bin/env python3
"""Package and verify loop revision 2; preserve earlier reviewed exports."""
import json
import shutil
from fractions import Fraction

import numpy as np
from PIL import Image

import compose_reuse as reuse
import repair_loop_scale as repair
from package_motion import run, decoded_frame

HERE = reuse.HERE
SETTINGS = {
    'header': {'art':'v4','size':(3840,1646),'safe':(1097,493,2743,1154),
               'character_box':(1864,664,2188,1102),'source':'tag-idle'},
    'search': {'art':'v5','size':(3840,2560),'safe':(836,765,3004,1795),
               'character_box':(1782,1144,2378,1762),'source':'present-idle'},
}


def motion_steps(name):
    layers=[Image.open(repair.CACHE/name/f'{i:04d}.png').convert('RGBa') for i in range(repair.COUNT)]
    steps=[]
    for i in range(repair.COUNT):
        a=np.asarray(layers[i],dtype=np.int16)
        b=np.asarray(layers[(i+1)%repair.COUNT],dtype=np.int16)
        steps.append(float(np.abs(a-b).mean()))
    p95=float(np.percentile(steps[:-1],95))
    assert steps[-1] <= max(.25,p95), f'Unexpected wrap jump in {name}'
    return {'cyclic_frame_steps_mean_absolute_premultiplied_rgba':steps,
            'wrap_step':steps[-1],'interior_95th_percentile':p95,
            'wrap_within_normal_motion_range':True}


def main():
    diagnosis=json.loads((HERE/'review/loop-scale-repair-v2.json').read_text())
    known={a['file']:a for a in json.loads((HERE/'manifest.json').read_text())['assets']}
    report={'prepared':'2026-10-18','revision':'v2',
            'owner_request':'Fix Travi zooming in/out around each loop transition.',
            'approved_artwork_preserved':True,'new_character_generation':False,
            'paid_video_jobs_submitted':0,'new_scene_transition':False,'upload_performed':False,
            'source_repair_report':'review/loop-scale-repair-v2.json','placements':{},'files':[],
            'approval_scope':'Technical repair of the approved scenes and performances at the owner\'s request; final playback awaits owner review.'}
    for name, settings in SETTINGS.items():
        art,size,safe=settings['art'],settings['size'],settings['safe']
        video=HERE/f'review/{name}-repaired-loop-v2.mp4'
        still=HERE/f'review/{name}-start-{art}.png'
        new_start=HERE/f'review/{name}-repaired-start-v2.png'
        assert reuse.digest(still)==known[str(still.relative_to(HERE))]['sha256']
        # At RGB master level, every pixel outside Travi's fixed layer remains
        # identical: the app UI, headlines, scenery, props and shadows are fixed.
        approved=np.asarray(Image.open(still).convert('RGB'))
        revised=np.asarray(Image.open(new_start).convert('RGB'))
        Image.fromarray(revised).crop(safe).save(HERE/f'review/{name}-repaired-detail-v2.png')
        unchanged=np.ones(approved.shape[:2],bool)
        x0,y0,x1,y1=settings['character_box'];unchanged[y0:y1,x0:x1]=False
        assert np.array_equal(approved[unchanged],revised[unchanged]),name
        metadata=json.loads(run('ffprobe','-v','error','-count_frames','-show_streams',
                            '-show_format','-of','json',str(video)))
        assert len(metadata['streams'])==1
        stream=metadata['streams'][0]
        duration=float(metadata['format']['duration']);count=int(stream['nb_read_frames'])
        assert stream['codec_name']=='h264' and stream['pix_fmt']=='yuv420p'
        assert (stream['width'],stream['height'])==size
        assert Fraction(stream['avg_frame_rate'])==30 and 5<=duration<=30
        assert count==round(duration*30)
        run('ffmpeg','-v','error','-xerror','-i',str(video),'-f','null','-')
        first=decoded_frame(video,0,size)
        last=decoded_frame(video,count-1,size)
        join_error=float(np.abs(first.astype(np.int16)-last.astype(np.int16))[safe[1]:safe[3],safe[0]:safe[2]].mean())
        preview=HERE/f'review/{name}-motion-detail-loop-v2.mp4'
        run('ffmpeg','-v','error','-y','-i',str(video),'-an','-vf',
            f'crop={safe[2]-safe[0]}:{safe[3]-safe[1]}:{safe[0]}:{safe[1]}:exact=1,pad=ceil(iw/2)*2:ceil(ih/2)*2',
            '-c:v','libx264','-preset','medium','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(preview))
        files=[]
        for source,suffix,kind in [(video,'.mp4','locally_repaired_video'),(still,'.png','approved_opaque_static_fallback')]:
            filename=f'travary-{name}-{art}'+('-loop-v2' if suffix=='.mp4' else '')+suffix
            target=HERE/'exports'/filename
            shutil.copyfile(source,target)
            entry={'file':str(target.relative_to(HERE)),'placement':'product_page_header' if name=='header' else 'search_results',
                   'kind':kind,'width':size[0],'height':size[1],'bytes':target.stat().st_size,
                   'sha256':reuse.digest(target),'status':'loop_scale_repair_for_final_playback_review',
                   'final_export':True,'scene_and_reuse_approved':True,'final_playback_approved':False,
                   'owner_approved':suffix=='.png','new_character_generation':False,
                   'video_generated':suffix=='.mp4','tool':'Local registration, same-pose wrap and ffmpeg; existing Travi performance only'}
            if suffix=='.mp4':entry.update({'fps':30,'duration_seconds':duration,'audio_streams':0})
            else:entry['mode']='RGB'
            report['files'].append(entry);files.append(entry['file'])
        source=diagnosis['performances'][settings['source']]
        report['placements'][name]={'size':list(size),'fps':30,'duration_seconds':duration,
             'decoded_frames':count,'audio_streams':0,'full_decode_passed':True,
             'approved_master_pixels_outside_character_identical':True,
             'source_cycle_frames':repair.COUNT,'source_cycle_repeats':2,
             'constant_registration_scale':source['constant_scale'],
             'old_join_height_range_pixels':source['old_join_height_range_pixels'],
             'new_join_height_range_pixels':source['new_join_height_range_pixels'],
             'new_join_max_height_step_pixels':source['new_join_max_height_step_pixels'],
             'source_temporal_check':motion_steps(settings['source']),
             'decoded_first_last_safe_area_mae_255':join_error,
             'endpoint_note':'Adjacent moving poses need not be identical. Join-window scale and normal motion continuity are checked instead of endpoint identity alone.',
             'delivery_files':files,'review_crop':str(preview.relative_to(HERE)),
             'seam_storyboard':f'review/{name}-seam-storyboard-v2.jpg'}
    (HERE/'review/motion-qa-report-v2.json').write_text(json.dumps(report,indent=2)+'\n')
    (HERE/'exports/delivery-manifest.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({name:{k:v for k,v in record.items() if k not in ['source_temporal_check']}
                      for name,record in report['placements'].items()},indent=2))


if __name__=='__main__':main()
