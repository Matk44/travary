"""Embed existing delivery assets in the full-screen rehearsal; no art generation."""
from pathlib import Path
import base64
import json

ROOT = Path(__file__).resolve().parent
PREVIOUS = ROOT.parent / 'onboarding-folio-motion-v1'
OUTPUT = ROOT / 'travary-folio-fullscreen.html'
ASSETS = {'STAGE':'bali-stage-prop-free-v1.webp','CLOSED':'closed-folio-v1.webp','OPEN':'open-folio-delivery.webp','GREETING':'travi-greeting-delivery.webp','RECEIVING':'travi-receiving-delivery.webp'}
fragment = (ROOT / 'motion-fragment.template.html').read_text()
for key, name in ASSETS.items():
    fragment = fragment.replace('__' + key + '__', 'data:image/webp;base64,' + base64.b64encode((PREVIOUS/name).read_bytes()).decode())
assert len(fragment.encode()) < 1_000_000
OUTPUT.write_text(fragment)
print(json.dumps({'output':str(OUTPUT),'bytes':len(fragment.encode()),'assetsReused':len(ASSETS)}))
