"""Write the final handoff only after the whole wave and visual sheets pass."""
import json
from pathlib import Path
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2]
WAVE=HERE.name.split('wave-')[1].split('-2026')[0].upper()
places=json.loads((HERE/'cities.json').read_text());base_count=len(places)*6
validation=json.loads((HERE/'validation.json').read_text())
assert validation['status']=='PASS' and validation['count']==base_count
assert json.loads((HERE/'key-card-visual-review.json').read_text())['inspected']
roles=['featured_ticket','room_card','reservation_card','countdown_postcard','trip_postcard','documents_destination_stamp']
records=[json.loads(p.read_text()) for p in (HERE/'records').glob('*.json')]
selected=[r for r in records if r.get('status')=='review_ready']
for place in places:
    for role in roles:
        options=[r for r in selected if r['id'] in [place['id']+'/'+role,place['id']+'/'+role+'-corrected']]
        assert options and all(r.get('visuallyInspected') for r in options),(place['id'],role)
stage_count=0;stage_note=''
if WAVE=='E1':
    stages=json.loads((HERE/'stages-validation.json').read_text());assert stages['status']=='PASS' and stages['count']==7
    stage_count=7
    stage_note='\nSeven additional **851 × 1848 opaque onboarding stages** are in `art_packs/pending/onboarding/country_<cc>/onboarding_stage_v1.png`. [Stage overview](stages-overview.png) · [Stage validation/prompts/hashes](stages-validation.json). Both destination registers are updated as review_ready, with approval/integration pending. The stages use their own new postcards as geographic references, the clean Bali theatre as material/layout reference, and the specified sibling stages. Original stage masters and exact prompt logs are preserved under `docs/mockups/onboarding-city-stages-v1/more-art-2026-10-14/`. Stage exports use uniform scaling/centred cropping only where needed to deliver exact dimensions.\n'
count=base_count+stage_count
rows='\n'.join('| '+p['name']+' | ['+p['id']+'/](../'+p['id']+'/) | 6 |' for p in places)
rejected=[r for r in records if r.get('status')=='rejected']
corrections='\n'.join('- `'+r['id']+'`: '+r.get('rejection','See per-asset record.') for r in rejected) or 'No rejected illustration attempts in this wave.'
readme=f'''# Travary — more art, Wave {WAVE}

Completed 14 October 2026: **{count} final PNGs**. Built-in imagegen, one call per illustration/asset; independent assets were generated concurrently within the same place. Places were completed one at a time. Artwork is **review_ready**, awaiting owner approval. App integration and publishing are separate.

[Review gallery](index.html) · [Overview](overview.png) · [All key cards, right 60%](key-card-right-60-percent.png) · [Exact prompts and source paths](generation.json) · [Validation and SHA-256 hashes](validation.json) · [Speckle counts](speckle-validation.json)

| Place | Final staging folder | Pictures |
|---|---|---|
{rows}

| Filename | Exact pixels |
|---|---|
| featured_ticket.png | 1774 × 887 |
| room_card.png | 1774 × 887 |
| reservation_card.png | 1983 × 793 |
| countdown_postcard.png | 1122 × 1402 |
| trip_postcard.png | 1536 × 1024 |
| documents_destination_stamp.png | 1024 × 1280 |
{stage_note}
## Export and checks

All six-picture deliverables are PNG RGBA8 with embedded sRGB, genuine alpha outside the object and transparent corners. The approved clean-backdrop compositor preserves original card alpha, outlines, notches, perforations, barcode stub, cord, brass eyelet and protected shell/exterior pixels; existing stripe geometry is retained and recoloured, tags left unprinted. The key-card backdrop samples only x430–630, avoiding scenery bleed. All card text areas pass the requested median-filter speckle check (counts recorded above). The final right-60% key-card sheet and each place's light/dark sheet were visually inspected for clean paper, scenery placement and halos.

Postcards use uniformly scaled, centred exports, never independent-axis stretching. Generated alpha at or below 4/255 is cleared as in the approved workflow; no colour-key removal. Stamps use the shared Paris paper/perforation/keyline template, with generated scenery uniformly fitted into (123,115)–(901,947); the label band (123,986)–(901,1152) stays exactly blank ivory. Card protected pixels, barcode, eyelet, blank reservation centre and stamp label checks pass. Every source illustration and final contact sheet was visually inspected for style, geographic scope, forbidden text/script/flags/faces and excluded attractions.

`records/` retains exact prompts, input paths, original tool output paths, acceptance notes and any corrections. `originals/` preserves generated masters; `normalised/` contains mechanical donors, not extra deliverables. `export_city.py`, `finalize.py` and the clean-backdrop compositor document the export/validation workflow.

## Rejected attempts and corrections

{corrections}

No unresolved delivery-rule exceptions. New artwork approval remains pending. No animation/video was created.

## Handoff to Claude

> Wave {WAVE}'s {count} final PNGs are complete and checked. Use the final named staging PNGs (and E1 pending onboarding PNGs where applicable), with the hashes and source records above. Do not use rejected originals or intermediate donors. Follow the original brief's developer instructions for source packs, selectors/palettes, WebP/building and onboarding integration. This artwork delivery changed no runtime assets, source packs, catalogue, WebP or publication; preserve unrelated working-tree changes. Owner still approval is separate, and animation/video requires scene approval before production. Publish only when authorized.
'''
(HERE/'README.md').write_text(readme)
p=HERE.parent/'more-art-2026-10-14-status.json';s=json.loads(p.read_text())
s['waves'][WAVE].update(status='complete_review_ready',completed=count,completedPlaces=[p['id'] for p in places],reviewFolder=str(HERE.relative_to(ROOT)))
p.write_text(json.dumps(s,indent=2)+'\n')
print(WAVE+': handoff saved; '+str(count)+' final PNGs complete.')
