"""Explicit local Scene Studio actions; never read keys or retry paid submits."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parent
MEDIA = Path('/Users/khairofamily/Documents/video_generator/media')
API = 'http://127.0.0.1:3717/api'


def write(name, value):
    (ROOT / name).write_text(json.dumps(value, indent=2) + '\n')


def request(route, body=None, headers=None):
    req = urllib.request.Request(API + route, data=body, headers=headers or {})
    with urllib.request.urlopen(req, timeout=60) as response:
        return json.load(response)


def upload(key, path):
    records = json.loads((ROOT / 'uploads.json').read_text()) if (ROOT / 'uploads.json').exists() else {}
    content = path.read_bytes()
    digest = hashlib.sha256(content).hexdigest()
    if key in records and records[key]['sha256'] == digest:
        return records[key]['image_path']
    boundary = 'Travary' + uuid.uuid4().hex
    body = (f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{path.name}"\r\n'
            'Content-Type: image/png\r\n\r\n').encode() + content + f'\r\n--{boundary}--\r\n'.encode()
    result = request('/cast/upload', body, {'Content-Type': 'multipart/form-data; boundary=' + boundary})
    records[key] = {'source': str(path), 'sha256': digest, **result}
    write('uploads.json', records)
    return result['image_path']


def submit(keys):
    requests = json.loads((ROOT / 'requests.json').read_text())
    jobs = json.loads((ROOT / 'jobs.json').read_text()) if (ROOT / 'jobs.json').exists() else {}
    for key in keys:
        if key in jobs:
            print(key + ': already recorded; not resubmitted')
            continue
        # Persist intent before the remote call. An ambiguous timeout needs an
        # explicit audit of Scene Studio's job list before another paid submit.
        jobs[key] = {'status': 'submit_pending', 'request': key}
        write('jobs.json', jobs)
        result = request('/video/create', json.dumps(requests[key]).encode(), {'Content-Type': 'application/json'})
        jobs[key] = {'request': key, **result}
        write('jobs.json', jobs)
        print(key + ': ' + json.dumps(result))


def poll():
    jobs = json.loads((ROOT / 'jobs.json').read_text())
    for key, job in jobs.items():
        if 'id' not in job:
            print(key + ': no confirmed job ID; audit required')
            continue
        if job.get('local_path') or job.get('status') == 'failed':
            print(key + ': ' + job['status'])
            continue
        result = request('/video/' + job['id'])
        row = result['job']
        for field in ['status', 'local_path', 'error', 'task_id', 'seed', 'provider', 'updated_at']:
            if field in row:
                job[field] = row[field]
        if result.get('poll_error'):
            job['poll_error'] = result['poll_error']
        write('jobs.json', jobs)
        print(key + ': ' + job['status'] + (' / ' + job['poll_error'] if job.get('poll_error') else ''))


def collect():
    jobs = json.loads((ROOT / 'jobs.json').read_text())
    for key, job in jobs.items():
        name = job.get('local_path')
        if job.get('status') != 'completed' or not name:
            continue
        source = (MEDIA / name).resolve()
        if source.parent != MEDIA.resolve():
            raise ValueError('Unexpected media path')
        target = ROOT / (key + '-source-v1.mp4')
        if not target.exists():
            shutil.copy2(source, target)
        job['source'] = target.name
        job['source_sha256'] = hashlib.sha256(target.read_bytes()).hexdigest()
        print(key + ': saved ' + target.name)
    write('jobs.json', jobs)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['submit', 'poll', 'collect'])
    parser.add_argument('keys', nargs='*')
    args = parser.parse_args()
    {'submit': lambda: submit(args.keys), 'poll': poll, 'collect': collect}[args.action]()
