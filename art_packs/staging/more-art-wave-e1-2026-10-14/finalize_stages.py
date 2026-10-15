"""Validate E1's seven country stages and append their review-only ledger entries once."""
import hashlib,io,json
from pathlib import Path
from PIL import Image,ImageCms,ImageDraw,ImageFont
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2]
countries=json.loads((HERE/'cities.json').read_text());assert len(countries)==7
records=[]
for country in countries:
    r=json.loads((HERE/'records'/(country['id']+'-onboarding_stage_v1.json')).read_text())
    assert r['status']=='review_ready' and r.get('visuallyInspected'),country['id']
    p=ROOT/r['selectedWorkspacePath'];im=Image.open(p)
    assert im.size==(851,1848) and im.mode=='RGBA' and im.getchannel('A').getextrema()==(255,255)
    assert p.read_bytes()[24:26]==bytes([8,6])
    assert 'srgb' in ImageCms.getProfileDescription(ImageCms.ImageCmsProfile(io.BytesIO(im.info['icc_profile']))).lower()
    assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256']
    records.append(r)
(HERE/'stages-validation.json').write_text(json.dumps({'date':'2026-10-14','status':'PASS','count':7,'records':records},indent=2,ensure_ascii=False)+'\n')
sheet=Image.new('RGB',(2240,800),'#eee7dc');draw=ImageDraw.Draw(sheet)
try:font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',22)
except OSError:font=ImageFont.load_default()
for i,r in enumerate(records):
    im=Image.open(ROOT/r['selectedWorkspacePath']);im.thumbnail((295,710),Image.Resampling.LANCZOS)
    sheet.paste(im,(i*320+(320-im.width)//2,30));draw.text((i*320+20,755),r['label'],font=font,fill='#243349')
sheet.save(HERE/'stages-overview.png')
rp=ROOT/'docs/onboarding/destination-art-registry.json';registry=json.loads(rp.read_text())
existing={r['destinationId'] for r in registry['destinations']}
assert not any(r['destinationId'] in existing for r in records),'Registry already contains these countries; do not append twice'
for r in records:
    registry['destinations'].append({'destinationId':r['destinationId'],'label':r['label'],'scope':'country',
      'selectors':r['selectors'],'coverageTier':'baseline_country','generationPriority':'owner_requested_more_art_wave_e1',
      'geographicScope':r['geographicScope'],'references':{'countdownPostcard':r.get('originalInputReferencePaths',r['referenced_image_paths'])[1]},
      'onboardingStage':{'status':'review_ready','masterPath':r['selectedWorkspacePath'],'dimensions':r['dimensions'],
        'generationMode':'built_in_imagegen','exactSubmittedPrompt':r['prompt'],'inputReferencePaths':r['referenced_image_paths'],
        'originalGenerationOutputPath':r['source'],'promptLogPath':'docs/mockups/onboarding-city-stages-v1/more-art-2026-10-14/'+r['destinationId']+'-prompt.txt',
        'sha256':r['sha256'],'qaNotes':r['qaNotes'],'flutterIntegrated':False,'publicationEvidence':None,
        'lastReviewed':'2026-10-14','nextAction':'Owner still approval, then separate native integration; no motion or publishing authorized by this status.'}})
registry['updatedAt']='2026-10-14';registry['changeLog'].append({'date':'2026-10-14','change':'Wave E1: seven new country baseline stages generated, measured and reviewed; owner approval pending. New stages are not integrated or published.'})
rp.write_text(json.dumps(registry,indent=2,ensure_ascii=False)+'\n')
rp=ROOT/'docs/onboarding/DESTINATION_ART_REGISTER.md';text=rp.read_text();marker='<!-- more-art-wave-e1-2026-10-14 -->';assert marker not in text
text+='\n'+marker+'\n\n## Additional country baseline stages — 14 October 2026 (Wave E1)\n\nSeven broad country stages are **review_ready**, expanding the artwork baseline beyond the original 25 countries. Owner approval, native integration and publishing remain separate. Existing runtime coverage is unchanged by this artwork task.\n\n[Stage overview](../../art_packs/staging/more-art-wave-e1-2026-10-14/stages-overview.png) · [Prompt/source/check manifest](../../art_packs/staging/more-art-wave-e1-2026-10-14/stages-validation.json)\n\n| Country | ID | Master | Pixels | Status |\n|---|---|---|---|---|\n'
for r in records:text+=f'| {r["label"]} | `{r["destinationId"]}` | [PNG](../../{r["selectedWorkspacePath"]}) | 851 × 1848 | review_ready; approval pending; not integrated |\n'
rp.write_text(text)
print('PASS: seven E1 stages; registry updated once. Inspect stages-overview.png before reporting completion.')
