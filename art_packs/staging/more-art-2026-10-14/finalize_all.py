"""Recheck the 163 final deliverables and refresh the combined review handoff."""
import hashlib, json
from pathlib import Path
from PIL import Image, ImageCms

HERE=Path(__file__).resolve().parent
STAGING=HERE.parent
ROOT=HERE.parents[2]
WAVES=[('C',4,'Four onboarding stages'),('D',54,'Nine city sets'),('E1',49,'Seven country sets and stages'),('F1',25,'Country stamps'),('E2',18,'Three country sets'),('F2',13,'US stamps')]
rows=[]
for wave,count,label in WAVES:
    folder=STAGING/f'more-art-wave-{wave.lower()}-2026-10-14'
    d=json.loads((folder/'validation.json').read_text())
    assert d['status']=='PASS'
    if wave=='C':
        records=d['records']
    elif wave in ['F1','F2']:
        records=d['results']
    else:
        records=[r for c in d['cities'] for r in c['results']]
        if wave=='E1':records+=json.loads((folder/'stages-validation.json').read_text())['records']
    assert len(records)==count,(wave,len(records))
    for r in records:
        file=r.get('file') or r['selectedWorkspacePath']
        path=ROOT/file
        im=Image.open(path)
        size=r.get('size') or r['dimensions']
        assert list(im.size)==list(size),(file,im.size)
        assert im.mode=='RGBA' and path.read_bytes()[24:26]==bytes([8,6]),file
        assert im.info.get('icc_profile'),file
        profile=ImageCms.ImageCmsProfile(__import__('io').BytesIO(im.info['icc_profile']))
        assert 'srgb' in ImageCms.getProfileDescription(profile).lower(),file
        sha=hashlib.sha256(path.read_bytes()).hexdigest()
        assert sha==r['sha256'],('hash changed',file)
        a=im.getchannel('A')
        if path.name=='onboarding_stage_v1.png':assert a.getextrema()==(255,255)
        else:
            assert a.getextrema()[0]==0 and a.getextrema()[1]>=250,file
            assert all(a.getpixel(p)==0 for p in [(0,0),(im.width-1,0),(0,im.height-1),(im.width-1,im.height-1)]),file
        rows.append(dict(wave=wave,file=file,size=list(im.size),mode='RGBA8',embeddedSrgb=True,alphaExtrema=list(a.getextrema()),sha256=sha))
assert len(rows)==163 and len({r['file'] for r in rows})==163
noise=[]
for wave in ['d','e1','e2']:
    noise+=json.loads((STAGING/f'more-art-wave-{wave}-2026-10-14'/'speckle-validation.json').read_text())
assert len(noise)==57 and all(r['strayPixels']<=10 for r in noise)
(HERE/'validation.json').write_text(json.dumps(dict(date='2026-10-14',status='PASS',count=163,scope='Rechecked final hashes, exact dimensions, PNG RGBA8, embedded sRGB, and alpha. Per-wave manifests contain template, blank-area, speckle and visual checks.',cardSpeckleChecks=noise,results=rows),indent=2)+'\n')
status_path=STAGING/'more-art-2026-10-14-status.json'
s=json.loads(status_path.read_text())
assert all(s['waves'][w]['status']=='complete_review_ready' for w,_,_ in WAVES)
s.update(completedImages=163,remainingImages=0,overallStatus='complete_review_ready',nextAsset=None,resumeInstructions='All requested still artwork is saved and checked. Review final staged PNGs and per-wave handoffs. Owner approval, app integration and publication remain separate.')
if 'usageLimit' in s:s['usageLimit'].update(status='historical; reset and all remaining images completed with built-in imagegen',fallbackAuthorization='not used')
status_path.write_text(json.dumps(s,indent=2)+'\n')
table='\n'.join(f'| {w} — {label} | {n}/{n} | [Gallery](../more-art-wave-{w.lower()}-2026-10-14/index.html) · [README](../more-art-wave-{w.lower()}-2026-10-14/README.md) |' for w,n,label in WAVES)
readme=f'''# Travary — more art, 14 October 2026

**All 163 requested final PNGs are checked and saved.** Generated with built-in imagegen, one call per asset. All remaining images were completed after the earlier usage limit reset; CLI/API fallback was not used.

[Combined review gallery](index.html) · [Cross-wave validation and hashes](validation.json) · [Completion ledger](../more-art-2026-10-14-status.json)

| Wave | Checked/requested | Review |
|---|---:|---|
{table}

All 163 files pass the cross-wave exact size, PNG RGBA8, embedded sRGB, alpha and SHA-256 checks. The three card waves retain their structural, barcode, grommet, blank-area and speckle checks. All 57 card speckle counts are recorded in validation.json; the right-60% key-card sheets and each place's light/dark exports were visually inspected. Stages are opaque. Postcards and stamps have genuine exterior transparency. Stamp label bands and Paris template geometry are preserved.

The per-wave generation.json files and records/ directories contain the exact prompt sets, input references, original tool paths, selected sources and correction histories. Generated masters are preserved in workspace originals/ folders. Rejected attempts are documented in the wave READMEs. No unresolved delivery-rule exceptions.

Artwork is **review_ready**; owner approval remains distinct from delivery. This artwork task made no runtime, source-pack, catalogue, WebP, animation/video or publishing changes. Other chats' integration work remains separate.

## Handoff to Claude

> C, D, E1, F1, E2 and F2 are artwork-complete: 163 final PNGs. Use only final named staging/pending PNGs with the hashes above, not rejected originals or export donors. Follow the original brief's separate developer integration/build/publishing instructions. Preserve unrelated working-tree changes. Owner approval is required before motion/video for each new scene; publishing requires the owner's go-ahead.
'''
(HERE/'README.md').write_text(readme)
cards=[]
for wave,n,label in WAVES:
    folder=f'../more-art-wave-{wave.lower()}-2026-10-14'
    overview='overview-light.png' if wave.startswith('F') else 'overview.png'
    cards.append(f'<article><a href="{folder}/index.html"><img src="{folder}/{overview}" alt="Wave {wave} overview"><h2>{wave} · {label}</h2></a><p>{n} / {n} checked PNGs</p><a href="{folder}/README.md">Manifest, prompts and handoff</a></article>')
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Travary · More art · Complete</title><style>body{margin:0;background:#f4efe7;color:#243349;font:16px system-ui}main{max-width:1300px;margin:auto;padding:32px}h1{font:42px Georgia}h2{font:25px Georgia}p{line-height:1.6}a{color:inherit}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:24px}article{padding:18px;background:#e9e1d4;border-radius:12px}article img{width:100%;height:290px;object-fit:contain}article a{text-decoration:none}@media(max-width:850px){.grid{grid-template-columns:repeat(2,1fr)}}@media(max-width:520px){.grid{grid-template-columns:1fr}}</style><main><h1>Travary · More art</h1><p>All 163 requested PNGs are saved and checked · 14 October 2026 · Built-in imagegen</p><p><a href="README.md">Full handoff</a> · <a href="validation.json">Validation and hashes</a> · <a href="../more-art-wave-e1-2026-10-14/stages-overview.png">E1 onboarding stages</a></p><div class="grid">'''+''.join(cards)+'''</div><p>Stills are ready for owner review. Approval, app integration and publication are separate.</p></main></html>'''
(HERE/'index.html').write_text(page)
print('PASS: all 163 final PNGs rechecked; combined gallery, manifest and completion ledger refreshed.')
