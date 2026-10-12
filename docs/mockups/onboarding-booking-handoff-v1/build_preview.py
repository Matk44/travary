"""Bundle existing art for the motion rehearsal; preserve original masters."""
from pathlib import Path
import base64
import hashlib
import json

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[2]
FRAGMENT = Path('/Users/khairofamily/.codex/visualizations/2026/10/04/01a10645-84b8-7482-bc0f-5b5d42d880ca/travary-booking-handoff.html')
PREVIOUS = ROOT.parent / 'onboarding-folio-motion-v1'
ASSETS = {
    'STAGE': PREVIOUS / 'bali-stage-prop-free-v1.webp',
    'CLOSED': PREVIOUS / 'closed-folio-v1.webp',
    'RECEIVING': PREVIOUS / 'travi-receiving-delivery.webp',
    'PROUD': ROOT / 'travi-proud-delivery.webp',
    'ROOM': ROOT / 'room-card-delivery.webp',
    'ATLAS': ROOT / 'pass-desk-delivery.webp',
}
fragment = (ROOT / 'motion-fragment.template.html').read_text()
for key, source in ASSETS.items():
    fragment = fragment.replace('__' + key + '__', 'data:image/webp;base64,' + base64.b64encode(source.read_bytes()).decode())
assert len(fragment.encode()) < 1_000_000
assert '__STAGE__' not in fragment
FRAGMENT.write_text(fragment)
masters = [PROJECT / name for name in [
    'assets/onboarding/bali-stage-prop-free-v1.png',
    'assets/onboarding/closed-folio-v1.png',
    'assets/onboarding/travi-receiving-v1.png',
    'assets/onboarding/travi-handoff-v1.png',
    'assets/art/common/coastal_resort_room_card.png',
    'assets/onboarding/pass-desk-art-v2.png',
]]
manifest = {
    'date':'2026-10-07',
    'purpose':'Existing-art choreography review. No new artwork, film or native app change.',
    'fragmentBytes':len(fragment.encode()),
    'fragmentPath':str(FRAGMENT),
    'masters':[{'path':str(path.relative_to(PROJECT)), 'sha256':hashlib.sha256(path.read_bytes()).hexdigest()} for path in masters],
    'deliveries':[{'key':key,'path':str(path.relative_to(PROJECT)),'bytes':path.stat().st_size} for key,path in ASSETS.items()],
    'newDeliveryEncoding':'cwebp quality 82; proud pose width 660; atlas and room card width 720; original PNGs unchanged.',
    'characterMotion':'Whole-layer translation/rotation and pose crossfade; not independently animated eyes/hands.',
    'services':'Example data only. No import, actual save, live lookup, auth, RevenueCat or purchase.',
}
(ROOT / 'delivery-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({'fragment':str(FRAGMENT),'bytes':len(fragment.encode()),'assets':len(ASSETS)}))
