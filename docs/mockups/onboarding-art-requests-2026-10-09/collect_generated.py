"""Copy built-in outputs unchanged and record dimensions/hashes; no image edits."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[2]
manifest_path = ROOT / 'manifest.json'
manifest = json.loads(manifest_path.read_text())
items = {item['id']: item for item in manifest['items']}
for log in sorted(ROOT.glob('requests-*.json')):
    for request in json.loads(log.read_text()):
        row = items[request['id']]
        source = Path(request['source'])
        target = PROJECT / row['target']
        target.parent.mkdir(parents=True, exist_ok=True)
        source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
        if target.exists():
            assert hashlib.sha256(target.read_bytes()).hexdigest() == source_hash, target
        else:
            shutil.copy2(source, target)
        with Image.open(target) as im:
            dimensions = list(im.size)
        row.update(status='generated', source=str(source), dimensions=dimensions,
                   sha256=source_hash, promptLog=str(log.relative_to(PROJECT)))
manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
print(f"Saved {sum(x['status'] != 'needed' for x in manifest['items'])}/{len(items)} unchanged outputs")
