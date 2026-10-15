"""Validate a finished stamp-only wave and make provenance, gallery and handoff."""
import hashlib,html,io,json,sys,shutil
from pathlib import Path
from PIL import Image,ImageCms,ImageDraw,ImageFont,ImageChops
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2]
WAVE='F1' if 'wave-f1-' in HERE.name else 'F2'
places=json.loads((HERE/'places.json').read_text())
assert len(places)==(25 if WAVE=='F1' else 13)
all_places=places
partial='--partial' in sys.argv
if partial:
    places=[p for p in all_places if (HERE/'records'/(p['id']+'-documents_destination_stamp.json')).exists() and json.loads((HERE/'records'/(p['id']+'-documents_destination_stamp.json')).read_text()).get('status')=='review_ready']
remaining=[p['id'] for p in all_places if p not in places]
template=Image.open(ROOT/'art_packs/staging/top-cities-wave-b-2026-10-13/stamp-template.png').convert('RGBA')
records=[];results=[];figures=[]
try: font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',22)
except OSError:font=ImageFont.load_default()
for place in places:
    p=HERE/'records'/(place['id']+'-documents_destination_stamp.json');r=json.loads(p.read_text())
    assert r.get('visuallyInspected') and r['status']=='review_ready', 'Visual acceptance required: '+place['id']
    for i,a in enumerate(r.get('attempts',[])):
        master=HERE/'originals'/(place['id']+'-attempt-'+str(i+1)+'-'+Path(a['source']).stem+'.png')
        if not master.exists():shutil.copy2(a['source'],master)
        a['originalWorkspacePath']=str(master.relative_to(ROOT))
    p.write_text(json.dumps(r,indent=2,ensure_ascii=False)+'\n')
    path=ROOT/r['finalPath'];im=Image.open(path)
    assert im.size==(1024,1280) and im.mode=='RGBA'
    assert path.read_bytes()[24:26]==bytes([8,6]),'PNG must be RGBA8'
    assert 'srgb' in ImageCms.getProfileDescription(ImageCms.ImageCmsProfile(io.BytesIO(im.info['icc_profile']))).lower()
    mask=Image.new('L',im.size,255);ImageDraw.Draw(mask).rectangle((123,115,900,946),fill=0)
    assert ImageChops.multiply(ImageChops.difference(im.getchannel('A'),template.getchannel('A')),mask).getbbox() is None
    assert im.crop((123,115,901,947)).getchannel('A').getextrema()[0]>=250
    assert all(im.getpixel(v)[3]==0 for v in [(0,0),(1023,0),(0,1279),(1023,1279)])
    assert ImageChops.difference(im.crop((123,986,901,1152)).convert('RGB'),template.crop((123,986,901,1152)).convert('RGB')).getbbox() is None
    sha=hashlib.sha256(path.read_bytes()).hexdigest();assert sha==r['sha256']
    results.append({'file':r['finalPath'],'size':[1024,1280],'mode':'RGBA8','embeddedSrgb':True,'realAlpha':True,
      'transparentCorners':True,'exteriorAlphaMatchesParisTemplate':True,'blankLabelMatchesParisTemplate':True,'sha256':sha})
    records.append(r)
    label=place.get('name',place['id']);src='../'+place['id']+'/documents_destination_stamp.png'
    figures.append(f'<figure><a href="{src}" target="_blank"><img loading="lazy" src="{src}" alt="{html.escape(label)}"></a><figcaption>{html.escape(label)} · 1024 × 1280</figcaption></figure>')
    for theme,bg,ink in [('light','#eee7dc','#243349'),('dark','#182233','#f8f4ec')]:
        sheet=Image.new('RGB',(620,830),bg);draw=ImageDraw.Draw(sheet)
        thumb=im.copy();thumb.thumbnail((570,740),Image.Resampling.LANCZOS);sheet.paste(thumb,((620-thumb.width)//2,30),thumb)
        draw.text((25,790),label,font=font,fill=ink);sheet.save(HERE/(place['id']+'-'+theme+'.png'))
(HERE/'generation.json').write_text(json.dumps({'date':'2026-10-14','mode':'built-in imagegen','brief':'docs/art_requests/GPT_MORE_ART_2026-10-14.md','partial':partial,'remaining':remaining,'records':records},indent=2,ensure_ascii=False)+'\n')
(HERE/'validation.json').write_text(json.dumps({'date':'2026-10-14','wave':WAVE,'status':'PASS','count':len(results),'results':results},indent=2)+'\n')
for theme,bg,ink in [('light','#eee7dc','#243349'),('dark','#182233','#f8f4ec')]:
    cols=5;rows=(len(places)+cols-1)//cols;sheet=Image.new('RGB',(1500,rows*420+60),bg);draw=ImageDraw.Draw(sheet)
    draw.text((20,15),'Travary · Wave '+WAVE+' · '+str(len(places))+' stamps',font=font,fill=ink)
    for i,(place,r) in enumerate(zip(places,records)):
        im=Image.open(ROOT/r['finalPath']);im.thumbnail((270,350),Image.Resampling.LANCZOS)
        x=(i%cols)*300;y=60+(i//cols)*420;sheet.paste(im,(x+(300-im.width)//2,y),im)
        draw.text((x+16,y+365),place.get('name',place['id']),font=font,fill=ink)
    sheet.save(HERE/('overview-'+theme+'.png'))
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{background:#eee7dc;color:#243349;font:16px system-ui;padding:24px}body.dark{background:#182233;color:#f8f4ec}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:20px}figure{margin:0}img{width:100%}a{color:inherit}button{padding:10px;margin:15px 0}figcaption{padding:10px}</style><h1>Travary · Wave '''+WAVE+'''</h1><p>Stills ready for owner review · 14 October 2026</p><p><a href="README.md">Handoff</a> · <a href="generation.json">Exact prompts</a> · <a href="validation.json">Checks and hashes</a></p><button onclick="document.body.classList.toggle('dark')">Switch light / dark</button><div class="grid">'''+''.join(figures)+'</div></html>'
(HERE/'index.html').write_text(page)
completion='Partial delivery' if partial else 'Completed'
partial_note=('\n**Wave incomplete:** '+str(len(places))+' of '+str(len(all_places))+' stamps checked. Built-in imagegen returned HTTP429 usage_limit_reached. Remaining: '+', '.join(remaining)+'. Reset reported for 14 October 2026 at 19:59:24 Australia/Sydney. Resume at the first remaining place using its existing prepared record; CLI/API fallback requires explicit user authorization.\n') if partial else ''
rejections='\n'.join('- `'+r['id']+'`, attempt '+str(i+1)+': '+a.get('rejection','See record.') for r in records for i,a in enumerate(r.get('attempts',[]))) or 'No rejected illustration attempts.'
rows='\n'.join('| '+p.get('name',p['id'])+' | [PNG](../'+p['id']+'/documents_destination_stamp.png) |' for p in places)
readme=f'''# Travary — more art, Wave {WAVE}

{completion} 14 October 2026: **{len(places)} destination stamps**, generated with built-in imagegen and the authorized Paris-template compositing workflow. Artwork is review_ready; owner approval, integration and publication remain separate.
{partial_note}
[Review gallery](index.html) · [Light overview](overview-light.png) · [Dark overview](overview-dark.png) · [Exact prompts and source paths](generation.json) · [Validation and SHA-256 hashes](validation.json)

| Place | Final PNG |
|---|---|
{rows}

All files are 1024 × 1280 PNG RGBA8 with embedded sRGB, true alpha and transparent corners. The Paris stamp's exact paper, perforations, navy keyline, exterior alpha and blank label band are retained. Generated scenery is uniformly fitted into the measured picture box (123,115)–(901,947), never stretched by axis. No colour-key removal. Every source and final stamp was visually inspected, including light/dark review sheets for text, flags, faces and halos. Card blank-area speckle and key-card sheets do not apply to this stamp-only wave.

`records/` holds all prompt/source/acceptance records, including any rejected attempts; `originals/` preserves generated masters. `export_stamp.py` implements the documented mechanical export and protected-pixel checks. `finalize.py` verifies final files and builds this delivery.

## Rejected attempts and corrections

{rejections}

Generated ink is composited onto opaque Paris paper inside the picture box; exterior template alpha remains unchanged. Originals and rejected attempts are preserved in `originals/`.

## Handoff to Claude

> The {len(places)} delivered Wave {WAVE} stamps are checked. {('The wave remains incomplete; see the remaining queue above.' if partial else 'The full wave is complete.')} Use the final PNGs in the named staging folders and the recorded hashes above. Owner approval is pending; follow the original brief's developer instructions for source-pack integration/building, and publish only when authorized. This artwork delivery changed no runtime assets, source packs, catalogues or WebP. Preserve unrelated working-tree changes.
'''
(HERE/'README.md').write_text(readme)
status_path=HERE.parent/'more-art-2026-10-14-status.json';status=json.loads(status_path.read_text())
status['waves'][WAVE].update(status=('blocked_usage_limit' if partial else 'complete_review_ready'),completed=len(results),reviewFolder=str(HERE.relative_to(ROOT)))
status_path.write_text(json.dumps(status,indent=2)+'\n')
print('PASS:',WAVE,len(results),'checked stamps; partial='+str(partial)+'. Inspect both overview sheets before reporting completion.')
