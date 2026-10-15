"""Record a human/model visual review after inspecting the generated and exported art."""
import json,sys
from pathlib import Path
BASE=Path(__file__).resolve().parent
wave,place,note=sys.argv[1:4]
folder=BASE/f'more-art-wave-{wave}-2026-10-14'
roles=['featured_ticket','room_card','reservation_card','countdown_postcard','trip_postcard','documents_destination_stamp']
for role in roles:
    p=folder/'records'/f'{place}-{role}-corrected.json'
    if not p.exists():p=folder/'records'/f'{place}-{role}.json'
    r=json.loads(p.read_text());assert r.get('status')!='rejected'
    r.update(status='review_ready',visuallyInspected=True,ownerApproval='pending',qaNotes=note)
    p.write_text(json.dumps(r,indent=2,ensure_ascii=False)+'\n')
print(place+': six exports visually reviewed')
