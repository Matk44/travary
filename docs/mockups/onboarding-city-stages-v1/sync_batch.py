"""Copy visually reviewed built-in PNGs unchanged and sync review records."""
import hashlib, html, json, shutil, sys
from pathlib import Path
from PIL import Image
BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
DATE = '2026-10-07'
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v): p.write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n')
m = json.loads((BASE/'batch-manifest.json').read_text())
results_path = Path(sys.argv[1]).resolve()
results = json.loads(results_path.read_text())
for r in results:
    c = next(c for c in m['cities'] if c['destinationId']==r['destinationId'])
    c.update({k:r[k] for k in ['sourceUrls','qa','attempts']})
    c['prompt'] = c['attempts'][0]['exactSubmittedPrompt']
    for a in c['attempts']:
        src = Path(a['originalGenerationOutputPath'])
        with Image.open(src) as im:
            im.load()
            a.update(dimensions=list(im.size), imageMode=im.mode, opaque='A' not in im.getbands() or im.getchannel('A').getextrema()==(255,255))
        a['sha256']=digest(src)
        if not a['opaque']: raise ValueError(f'Unexpected transparency: {src}')
        if a['selected']:
            dst=ROOT/a['selectedWorkspacePath']
            dst.parent.mkdir(parents=True,exist_ok=True)
            if dst.exists() and digest(dst)!=a['sha256']: raise ValueError(f'Use versioned sibling; preserve {dst}')
            if not dst.exists(): shutil.copy2(src,dst)
            assert digest(dst)==a['sha256']
            c.update(selectedWorkspacePath=a['selectedWorkspacePath'],dimensions=a['dimensions'],sha256=a['sha256'],originalGenerationOutputPath=str(src),selectedPromptPath=a['promptPath'])
    c.update(status='review_ready',lastReviewed=DATE,flutterIntegrated=False,publicationEvidence=None)
m['firstTwoGate']={'status':'passed','cities':['city_fr_paris','city_it_rome'],'inspectedBeforeContinuing':True,'notes':'Compared Paris and Rome visually with approved Bali before continuing. Quiet teal headline space, cream floor near 65%, matching wings and tactile city layers; no character/folio/text. Paris 851x1848; Rome 851x1847. Symbolic compositions, not literal viewpoints.'}
m['completedBatches']=[b for b in range(1,7) if all(c['status']=='review_ready' for c in m['cities'] if c['batch']==b)]
m['completedCount']=sum(c['status']=='review_ready' for c in m['cities'])
m['status']='review_ready' if m['completedCount']==30 else 'in_progress'
m['updatedAt']=DATE
m['resumeInstructions']='Check selected hashes; skip review_ready cities and continue queued batch order. One built-in imagegen call per city. Persist exact prompt/input/output/source/QA records after each batch. Use versioned siblings for revisions. Integration/publication separate.'
save(BASE/'batch-manifest.json',m)
rp=ROOT/'docs/onboarding/destination-art-registry.json'
reg=json.loads(rp.read_text()); reg['updatedAt']=DATE
reg['coveragePolicy']['explicitCityAdditions']={'authorizedAt':DATE,'manifestPath':str((BASE/'batch-manifest.json').relative_to(ROOT)),'requestedCount':30,'reviewReadyCount':m['completedCount'],'status':m['status'],'fallbackPolicy':'Country default and neutral fallback retained. Explicit city overrides await owner review and separate integration.'}
for c in m['cities']:
    if c['status']!='review_ready': continue
    e=next((e for e in reg['destinations'] if e['destinationId']==c['destinationId']),None)
    if e is None:
        e={'destinationId':c['destinationId'],'label':c['label'],'scope':'city','selectors':{'countryCodes':[c['countryCode']],'cities':[c['citySlug']]},'sourcePackVersion':None,'references':{}}
        reg['destinations'].append(e)
    a=next(a for a in c['attempts'] if a['selected'])
    e.update(coverageTier='explicitly_requested_city_override',generationPriority='owner_requested_city_batch',selectorNote=c['selectorNote'],geographicScope=c['qa']['geography'])
    e['onboardingStage']={'status':'review_ready','masterPath':c['selectedWorkspacePath'],'dimensions':c['dimensions'],'promptLogPath':c['selectedPromptPath'],'stagingPath':c['selectedWorkspacePath'],'flutterIntegrated':False,'publicationEvidence':None,'lastReviewed':DATE,'nextAction':'Owner review; integration/publication separate. Country and neutral fallbacks retained.','generationMode':'built_in_imagegen','originalGenerationOutputPath':c['originalGenerationOutputPath'],'inputReferencePaths':a['inputReferencePaths'],'referenceSourceUrls':c['sourceUrls'],'exactSubmittedPrompt':a['exactSubmittedPrompt'],'attemptsLogPath':str(results_path.relative_to(ROOT)),'sha256':c['sha256'],'qaNotes':c['qa']}
b=results[0]['batch']; tag=f'city_batch_{b:02d}_2026_10_07'
if not any(e.get('id')==tag for e in reg['changeLog']):
    labels=', '.join(c['label'] for c in m['cities'] if c['batch']==b)
    reg['changeLog'].append({'id':tag,'date':DATE,'change':f'Owner-authorized city batch {b}: {labels}. Built-in imagegen, unmodified selected masters, measured dimensions and exact prompts/sources retained. review_ready; country baseline and existing artwork preserved. No integration/publication.'})
save(rp,reg)
ready=[c for c in m['cities'] if c['status']=='review_ready']
rows=['| Batch | City / ID / selectors | Selected master | Actual pixels | QA / status |','|---|---|---|---|---|']
for c in m['cities']:
    sel=f'[Master](../../{c["selectedWorkspacePath"]})' if c['status']=='review_ready' else 'Pending'
    dim=' × '.join(map(str,c['dimensions'])) if c['status']=='review_ready' else '—'
    qa=c['qa']['summary'] if c['qa'] else 'queued'
    rows.append(f'| {c["batch"]} | {c["label"]} · {c["destinationId"]} · {c["countryCode"]}/{c["citySlug"]} | {sel} | {dim} | {c["status"]} · {qa} |')
start='<!-- city-stage-batch:start -->'; end='<!-- city-stage-batch:end -->'
section='\n'.join([start,'## Explicit city additions — 7 October 2026','',f'Owner explicitly authorized this 30-city library. **{m["completedCount"]}/30 selected masters are review_ready.** Country baseline and neutral fallback remain. These deliberate city overrides await owner review; integration/publication are separate. The historical deferred Paris/Orlando rows are superseded for this batch.','',
'[Gallery](../mockups/onboarding-city-stages-v1/gallery.html) · [Exact prompts and sources](../mockups/onboarding-city-stages-v1/PROMPTS.md) · [Resumable manifest](../mockups/onboarding-city-stages-v1/batch-manifest.json)','',*rows,'',
'No substitutions. New York reuses new_york; Hong Kong uses HK; Singapore uses SG. Hong Kong/Singapore city-state overrides need a deliberate resolver decision during future integration.',end])
mp=ROOT/'docs/onboarding/DESTINATION_ART_REGISTER.md'; md=mp.read_text()
if start in md: md=md[:md.index(start)]+section+md[md.index(end)+len(end):]
else: md=md.replace('## Primary queue: countries',section+'\n\n## Primary queue: countries',1)
mp.write_text(md)
prompts=['# City scenery exact prompts and provenance','',
'Built-in imagegen. All selected masters are review_ready, awaiting owner review. Official sources were used to verify geographic cues, not downloaded as image inputs. Approved Bali supplies materials/composition only.','',
'[Manifest](batch-manifest.json) · [Gallery](gallery.html)','']
for c in m['cities']:
    prompts += [f'## {c["order"]:02d}. {c["label"]} — batch {c["batch"]}','',f'{c["destinationId"]} · {c["countryCode"]}/{c["citySlug"]} · {c["status"]}',f'[Initial exact prompt](prompts/{c["destinationId"]}.txt)','', 'Inputs: '+', '.join(c['inputReferencePaths'])]
    prompts += [f'- [Official source]({u}) — checked {DATE}.' for u in c['sourceUrls']]
    if c['status']=='review_ready':
        prompts += [f'[Selected master](../../../{c["selectedWorkspacePath"]}) · '+ ' × '.join(map(str,c['dimensions'])),f'SHA-256: {c["sha256"]}','QA: '+c['qa']['summary']+' '+c['qa'].get('notes','')]
        for a in c['attempts']:
            prompts += [f'- Attempt {a["version"]}, '+('selected' if a['selected'] else 'superseded')+f': [exact submitted prompt](../../../{a["promptPath"]}); original output: {a["originalGenerationOutputPath"]}.']
    prompts += ['']
(BASE/'PROMPTS.md').write_text('\n'.join(prompts)+'\n')
readme=['# Travary city onboarding scenery library','',f'7 October 2026 · {m["completedCount"]}/30 selected masters · {m["status"]}. Built-in imagegen in six batches of five.','',
'Country baseline and existing Bali/Kyoto/shared art remain. No app code, pricing, billing, animation, integration or publication changed.','',
'[Review gallery](gallery.html) · [Exact prompts and sources](PROMPTS.md) · [Resumable manifest](batch-manifest.json) · [Art register](../../onboarding/DESTINATION_ART_REGISTER.md)','',
'Selected PNG masters are copied byte-for-byte to art_packs/pending/onboarding/<canonical-city-id>/. No pixel editing, resizing, cropping or encoding changes. Actual dimensions, opacity and hashes are measured.','',
'Paris and Rome were inspected against approved Bali before continuing. Every result was visually inspected for geography, paper layers, quiet text zones, cream floor, character clearance and baked-in props/type. Stage imagery is symbolic, not a literal photographic viewpoint. Live overlay/device QA remains for integration.','',
'Resume from manifest: check existing selected file/hash and skip review_ready entries. Continue earliest queued batch. Keep exact prompts and all attempt metadata; choose sibling v2/v3 filenames for corrections. sync_batch.py is a local persistence/copy utility, not a generation API runner.','',
'## Selected masters','']
readme += [f'- Batch {c["batch"]}: [{c["label"]}](../../../{c["selectedWorkspacePath"]}) — '+ ' × '.join(map(str,c['dimensions']))+' · review_ready.' for c in ready]
(BASE/'README.md').write_text('\n'.join(readme)+'\n')
cards=[]
for b in range(1,7):
    cards += [f'<section id="batch-{b}"><h2>Batch {b}</h2><div class="grid">']
    for c in ready:
        if c['batch']!=b: continue
        rel='../../../'+c['selectedWorkspacePath']; name=html.escape(c['label']); qa=html.escape(c['qa']['summary'])
        cards += [f'<figure><a href="{rel}" target="_blank"><img src="{rel}" loading="lazy" alt="{name} paper scenery"></a><figcaption><strong>{name}</strong><small>{c["countryCode"]}/{c["citySlug"]} · {c["dimensions"][0]} × {c["dimensions"][1]} · review_ready</small><p>{qa}</p><a href="{rel}" target="_blank">Open master</a> · <a href="../../../{c["selectedPromptPath"]}">Exact prompt</a></figcaption></figure>']
    cards += ['</div></section>']
nav=' '.join(f'<a href="#batch-{b}">Batch {b}</a>' for b in range(1,7))
style='*{box-sizing:border-box}body{margin:0;background:#f7f0e3;color:#142f37;font:16px/1.5 system-ui}header,main{max-width:1600px;margin:auto;padding:24px}header{position:sticky;top:0;background:#f7f0e3;z-index:2;border-bottom:1px solid #d2c7b4}h1{font-size:27px;margin:0}nav{display:flex;gap:12px;flex-wrap:wrap}a{color:#146275}nav a{background:#e6dbca;border-radius:8px;padding:5px 12px}section{scroll-margin-top:190px;margin-bottom:42px}.grid{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:16px}figure{margin:0;background:#fff9ed;border:1px solid #d9cebb;border-radius:12px;overflow:hidden}img{display:block;width:100%;height:auto}figcaption{padding:12px}strong,small{display:block}strong{font-size:18px}small{font-size:12px;color:#51686b}figcaption p,figcaption a{font-size:13px}@media(max-width:1050px){.grid{grid-template-columns:repeat(3,minmax(0,1fr))}}@media(max-width:650px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}header,main{padding:16px}}@media(max-width:400px){.grid{grid-template-columns:1fr}}'
gallery=f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Travary city scenery review</title><style>{style}</style><header><h1>Travary city scenery review</h1><p>{m["completedCount"]}/30 selected masters · review_ready · captions outside artwork</p><nav>{nav}</nav></header><main>'+ '\n'.join(cards)+'</main></html>'
(BASE/'gallery.html').write_text(gallery)
print(json.dumps({k:m[k] for k in ['completedCount','completedBatches','status']}))
