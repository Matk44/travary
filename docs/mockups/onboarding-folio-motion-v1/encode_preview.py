"""Delivery-only resizing/encoding; never edit or overwrite imagegen masters."""
from pathlib import Path
import base64
import json
import hashlib
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[2]
FRAGMENT = Path('/Users/khairofamily/.codex/visualizations/2026/10/04/01a10645-84b8-7482-bc0f-5b5d42d880ca/travary-folio-motion.html')
SOURCES = {
    'STAGE': (Path('/Users/khairofamily/.codex/generated_images/01a10645-84b8-7482-bc0f-5b5d42d880ca/exec-bf842b16-16cd-482e-ab9e-8af6ddb2745b.png'), 'bali-stage-prop-free-v1.png', 600, 74),
    'CLOSED': (Path('/Users/khairofamily/.codex/generated_images/01a10645-84b8-7482-bc0f-5b5d42d880ca/exec-a248a182-e24a-4874-a16f-e9b05f45e61e.png'), 'closed-folio-v1.png', 680, 77),
    'OPEN': (PROJECT / 'docs/mockups/onboarding-booking-folio-v1/open-folio-v2.png', 'open-folio-delivery.webp', 800, 81),
    'GREETING': (PROJECT / 'docs/mockups/onboarding-journey-v1/travi-cutout-v2.png', 'travi-greeting-delivery.webp', 640, 81),
    'RECEIVING': (PROJECT / 'docs/mockups/onboarding-booking-folio-v1/travi-receiving-v1.png', 'travi-receiving-delivery.webp', 640, 81),
}
fragment = (ROOT / 'motion-fragment.template.html').read_text()
manifest = []
for key, (source, name, width, quality) in SOURCES.items():
    if name.endswith('.png'):
        master = ROOT / name
        if not master.exists():
            shutil.copy2(source, master)
        assert master.read_bytes() == source.read_bytes()
    else:
        master = source
    img = Image.open(master)
    record = {'key': key, 'source': str(source), 'master': str(master), 'size': list(img.size), 'mode': img.mode, 'sha256': hashlib.sha256(master.read_bytes()).hexdigest()}
    if img.mode == 'RGBA':
        alpha = img.getchannel('A')
        record['alphaExtrema'] = list(alpha.getextrema())
        record['fullyTransparentFraction'] = alpha.histogram()[0] / (img.width * img.height)
    delivery = ROOT / (Path(name).stem + '.webp')
    img.thumbnail((width, width * 3), Image.Resampling.LANCZOS)
    img.save(delivery, 'WEBP', quality=quality, method=6)
    record['delivery'] = str(delivery)
    record['deliveryBytes'] = delivery.stat().st_size
    record['deliveryDimensions'] = list(img.size)
    manifest.append(record)
    placeholder = '__' + key + '__'
    assert placeholder in fragment, 'Run this only on the literal fragment with image placeholders.'
    fragment = fragment.replace(placeholder, 'data:image/webp;base64,' + base64.b64encode(delivery.read_bytes()).decode())
assert len(fragment.encode()) < 1_000_000
FRAGMENT.write_text(fragment)
(ROOT / 'delivery-manifest.json').write_text(json.dumps({'purpose': 'Display-only WebP size/encoding derivatives; unmodified PNG masters preserved.', 'assets': manifest, 'fragmentBytes': len(fragment.encode())}, indent=2) + '\n')
print(json.dumps({'fragmentBytes': len(fragment.encode()), 'assets': manifest}, indent=2))
