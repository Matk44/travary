"""Preserve source movies; produce silent, smooth browser review deliveries."""
from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parent
records = {}
keys = ['account-entry', 'account-idle', 'account-success-pass',
        'account-guest-pass', 'account-email-gesture', 'account-email-idle']

for key in keys:
    source = ROOT / (key + '-source-v1.mp4')
    target = ROOT / (key + '-v1.mp4')
    args = ['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(source)]
    detail = {'source': source.name, 'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest()}
    interpolate = 'minterpolate=fps=60:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1'
    if key in ['account-success-pass', 'account-guest-pass']:
        # The generator inserted a vertical stage cut at its endpoint. Offset
        # that first post-cut frame, dissolve, then ease to the actual endpoint.
        # Guest uses the neutral presentation tail, after the linked acting,
        # rather than its rejected floating-ticket shot. No success cue is reused.
        guest = key == 'account-guest-pass'
        pre_cut = 57 if guest else 65
        pre_time = pre_cut / 24
        if guest:
            args += ['-i', str(ROOT / 'account-success-pass-source-v1.mp4')]
        tail_input = '1:v' if guest else '0:v'
        graph = (
            f'[0:v]trim=end_frame={pre_cut},setpts=PTS-STARTPTS,'
            f'tpad=stop_mode=clone:stop_duration=0.35,{interpolate}[a];'
            f'[{tail_input}]trim=start_frame=65,setpts=PTS-STARTPTS,split[base][shift];'
            "[base][shift]overlay=x=0:y='64*(1-3*pow(min(t/0.8,1),2)+2*pow(min(t/0.8,1),3))':eval=frame[aligned];"
            f'[aligned]tpad=start_mode=clone:start_duration=0.3:stop_mode=clone:stop_duration=0.15,{interpolate}[b];'
            f'[a][b]xfade=transition=fade:duration=0.3:offset={pre_time},'
            'tpad=stop_mode=clone:stop_duration=0.2,trim=duration=4.35,setpts=PTS-STARTPTS[out]'
        )
        args += ['-filter_complex', graph, '-map', '[out]']
        detail.update({'source_cut_frame': pre_cut, 'source_cut_seconds': pre_time,
                       'vertical_compensation_px': 64, 'easing_seconds': 0.8,
                       'dissolve_seconds': 0.3,
                       'neutral_presentation_tail': 'account-success-pass-source-v1.mp4' if guest else source.name,
                       'tail_start_frame': 65})
    else:
        args += ['-vf', interpolate]
        detail['processing'] = '60 fps motion interpolation; same approved acting'
    args += ['-an', '-c:v', 'libx264', '-preset', 'slow', '-crf', '18',
             '-pix_fmt', 'yuv420p', '-fps_mode', 'cfr', '-movflags', '+faststart', str(target)]
    subprocess.run(args, check=True)
    probe = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries',
        'stream=codec_name,width,height,r_frame_rate,nb_frames:format=duration,size', '-of', 'json', str(target)]))
    detail.update({'delivery': target.name, 'delivery_sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
                   'probe': probe, 'ffmpeg_args': args[1:]})
    records[key] = detail
    (ROOT / 'processing.json').write_text(json.dumps(records, indent=2) + '\n')
    print(key + ': delivery saved', flush=True)
