#!/usr/bin/env python3
"""Onboarding films v2: Scene Studio (local) jobs from the registered key frames.

Every film starts and ends on a key frame from
`docs/mockups/onboarding-keyframes-v1/registered/` (shots.json), so any chain
of films joins seamlessly. Paid submits are recorded before they're sent and
never retried: an ambiguous one needs Scene Studio's job list checked by hand.

    python3 docs/mockups/onboarding-films-v2/films.py submit tag-toss folio-up tag-idle
    python3 docs/mockups/onboarding-films-v2/films.py poll
    python3 docs/mockups/onboarding-films-v2/films.py collect

`--set cameos` does the same for Travi's cameos (docs/mockups/travi-cameos-v1/:
its shots.json, registered/ frames, jobs and sources), square at 480p.
"""
import argparse
import hashlib
import json
import shutil
import urllib.error
import urllib.request
import uuid
from pathlib import Path

HERE = Path(__file__).resolve().parent
# Each set: its folder (shots.json, jobs, sources), its key frames, the
# films' shape and resolution.
SETS = {
    'onboarding': (HERE, HERE.parent / 'onboarding-keyframes-v1' / 'registered', '9:16', '720p'),
    'cameos': (HERE.parent / 'travi-cameos-v1', HERE.parent / 'travi-cameos-v1' / 'registered', '1:1', '480p'),
}
ROOT, FRAMES, ASPECT, RESOLUTION = SETS['onboarding']
MEDIA = Path('/Users/khairofamily/Documents/video_generator/media')
API = 'http://127.0.0.1:3717/api'


def read(name, default=None):
    path = ROOT / name
    return json.loads(path.read_text()) if path.exists() else default


def write(name, value):
    (ROOT / name).write_text(json.dumps(value, indent=2) + '\n')


def call(route, body=None, headers=None):
    req = urllib.request.Request(API + route, data=body, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=120) as response:
            return json.load(response)
    except urllib.error.HTTPError as e:
        raise SystemExit(f'{route}: HTTP {e.code}: {e.read().decode()[:500]}')


def upload(frame):
    """A key frame in Scene Studio's media (once per content)."""
    uploads = read('uploads.json', {})
    path = FRAMES / f'{frame}.png'
    content = path.read_bytes()
    digest = hashlib.sha256(content).hexdigest()
    if frame in uploads and uploads[frame]['sha256'] == digest:
        return uploads[frame]['image_path']
    boundary = 'Travary' + uuid.uuid4().hex
    body = (f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{path.name}"\r\n'
            'Content-Type: image/png\r\n\r\n').encode() + content + f'\r\n--{boundary}--\r\n'.encode()
    result = call('/cast/upload', body, {'Content-Type': 'multipart/form-data; boundary=' + boundary})
    uploads[frame] = {'source': str(path.relative_to(ROOT.parent.parent.parent)), 'sha256': digest, **result}
    write('uploads.json', uploads)
    return result['image_path']


def request_for(key, shot, shots):
    first, last = upload(shot['from']), upload(shot['to'])
    # A shot's format (a cameo's peek) adds its own rules before the common ones.
    blocks = [shot['prompt'], *([shots[shot['format']]] if 'format' in shot else []), shots['common']]
    prompt = '\n\n'.join(blocks)
    return {
        'provider': 'replicate-seedance-2',
        'prompt': prompt,
        'idea': f"Travi: {key} ({shot['from']} -> {shot['to']})",
        'cast_image_paths': [first, last],
        'first_frame_path': first,
        'last_frame_path': last,
        'aspect_ratio': ASPECT,
        'resolution': RESOLUTION,
        'duration_seconds': shot.get('seconds', 4),
        'generate_audio': False,
        'seed': shot['seed'],
        'shot_card': {'title': key, 'raw_prompt': prompt, 'camera_move': 'none'},
    }


def submit(keys, args_retry=False, retry_failed=False):
    shots = read('shots.json')
    jobs = read('jobs.json', {})
    for key in keys:
        status = jobs.get(key, {}).get('status')
        if key in jobs and not ((args_retry and status == 'submit_pending') or (retry_failed and status == 'failed')):
            print(key + ': already recorded; not resubmitted')
            continue
        # A failed attempt stays on record.
        previous = jobs.get(key, {}).get('previous', []) + ([jobs[key]] if status == 'failed' else [])
        req = request_for(key, shots['shots'][key], shots)
        requests = read('requests.json', {})
        requests[key] = req
        write('requests.json', requests)
        jobs[key] = {'status': 'submit_pending', **({'previous': previous} if previous else {})}
        write('jobs.json', jobs)
        result = call('/video/create', json.dumps(req).encode(), {'Content-Type': 'application/json'})
        jobs[key] = {**result, **({'previous': previous} if previous else {})}
        write('jobs.json', jobs)
        print(key + ': ' + json.dumps(result))


def poll():
    jobs = read('jobs.json', {})
    for key, job in jobs.items():
        if 'id' not in job:
            print(key + ': no confirmed job ID; check Scene Studio by hand')
            continue
        if job.get('local_path') or job.get('status') == 'failed':
            print(key + ': ' + job['status'])
            continue
        row = call('/video/' + job['id'])['job']
        for field in ['status', 'local_path', 'error', 'seed', 'updated_at']:
            if field in row:
                job[field] = row[field]
        write('jobs.json', jobs)
        print(key + ': ' + str(job['status']) + (' / ' + job['error'] if job.get('error') else ''))


def collect():
    jobs = read('jobs.json', {})
    for key, job in jobs.items():
        name = job.get('local_path')
        if job.get('status') != 'completed' or not name:
            continue
        source = (MEDIA / name).resolve()
        if source.parent != MEDIA.resolve():
            raise ValueError('Unexpected media path')
        target = ROOT / 'source' / f'{key}.mp4'
        target.parent.mkdir(exist_ok=True)
        if not target.exists():
            shutil.copy2(source, target)
        job['source'] = str(target.relative_to(ROOT))
        job['source_sha256'] = hashlib.sha256(target.read_bytes()).hexdigest()
        print(key + ': saved ' + job['source'])
    write('jobs.json', jobs)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['submit', 'poll', 'collect'])
    parser.add_argument('keys', nargs='*')
    parser.add_argument('--set', choices=SETS, default='onboarding')
    # Only after checking Scene Studio's job list shows no job for them.
    parser.add_argument('--retry-pending', action='store_true')
    # Scene Studio confirmed these failed: safe to send again.
    parser.add_argument('--retry-failed', action='store_true')
    args = parser.parse_args()
    ROOT, FRAMES, ASPECT, RESOLUTION = SETS[args.set]
    actions = {'submit': lambda: submit(args.keys, args.retry_pending, args.retry_failed), 'poll': poll, 'collect': collect}
    actions[args.action]()
