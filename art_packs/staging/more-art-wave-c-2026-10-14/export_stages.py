"""Exact-size mechanical exports; preserve original ImageGen masters and provenance."""
import hashlib, json, shutil, io
from pathlib import Path
from PIL import Image, ImageCms, ImageOps, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
LOG = ROOT / 'docs/mockups/onboarding-city-stages-v1/more-art-2026-10-14'
PROFILE = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()

def export(record_path):
    record = json.loads(Path(record_path).read_text())
    source = Path(record['source'])
    raw = LOG / 'originals' / (record['destinationId'] + '.png')
    raw.parent.mkdir(parents=True, exist_ok=True)
    if not raw.exists(): shutil.copy2(source, raw)
    dest = ROOT / 'art_packs/pending/onboarding' / record['destinationId'] / 'onboarding_stage_v1.png'
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists(): raise FileExistsError(dest)
    with Image.open(source) as src:
        record['originalDimensions'] = list(src.size)
        image = src.convert('RGBA')
    assert image.getchannel('A').getextrema() == (255, 255), 'Stage must be opaque'
    # Uniform cover only: no independent-axis stretching; subpixel centre crop.
    if image.size != (851, 1848): image = ImageOps.fit(image, (851, 1848), Image.Resampling.LANCZOS)
    image.save(dest, icc_profile=PROFILE)
    record.update(status='review_ready', selectedWorkspacePath=str(dest.relative_to(ROOT)),
                  dimensions=list(image.size), mode=image.mode, embeddedSrgb=True,
                  opaque=True, originalWorkspacePath=str(raw.relative_to(ROOT)),
                  sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),
                  export='Uniform LANCZOS cover to 851 × 1848, centre crop only; original preserved',
                  ownerApproval='pending', flutterIntegrated=False, published=False)
    Path(record_path).write_text(json.dumps(record, indent=2, ensure_ascii=False)+'\n')
    LOG.mkdir(parents=True, exist_ok=True)
    (LOG/(record['destinationId']+'-prompt.txt')).write_text(record['prompt']+'\n')
    (LOG/(record['destinationId']+'-record.json')).write_text(json.dumps(record,indent=2,ensure_ascii=False)+'\n')
    print(json.dumps({k:record[k] for k in ['destinationId','originalDimensions','dimensions','status','sha256']}))

def finalize():
    records=[json.loads(p.read_text()) for p in sorted((HERE/'records').glob('*-onboarding_stage_v1.json'))]
    assert len(records)==4 and all(r['status']=='review_ready' for r in records)
    for record in records:
        image=Image.open(ROOT/record['selectedWorkspacePath'])
        assert image.size==(851,1848) and image.mode=='RGBA' and image.info.get('icc_profile')
        assert 'srgb' in ImageCms.getProfileDescription(ImageCms.ImageCmsProfile(io.BytesIO(image.info['icc_profile']))).lower()
        assert image.getchannel('A').getextrema()==(255,255)
        assert record.get('visuallyInspected'), 'Visual QA missing'
        (LOG/(record['destinationId']+'-record.json')).write_text(json.dumps(record,indent=2,ensure_ascii=False)+'\n')
    (HERE/'generation.json').write_text(json.dumps({'date':'2026-10-14','mode':'built-in imagegen','records':records},indent=2,ensure_ascii=False)+'\n')
    (HERE/'validation.json').write_text(json.dumps({'date':'2026-10-14','wave':'C','status':'PASS','count':4,'records':records},indent=2,ensure_ascii=False)+'\n')
    sheet=Image.new('RGB',(1280,800),'#eee7dc');draw=ImageDraw.Draw(sheet)
    try: font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',22)
    except OSError: font=ImageFont.load_default()
    for i,r in enumerate(records):
        im=Image.open(ROOT/r['selectedWorkspacePath']);im.thumbnail((295,710),Image.Resampling.LANCZOS)
        sheet.paste(im,(i*320+(320-im.width)//2,35));draw.text((i*320+20,755),r['id'].split('/')[0].title(),font=font,fill='#243349')
    sheet.save(HERE/'overview.png')
    registry_path=ROOT/'docs/onboarding/destination-art-registry.json'
    registry=json.loads(registry_path.read_text());existing={r['destinationId'] for r in registry['destinations']}
    for r in records:
        if r['destinationId'] in existing: raise ValueError('Existing registry entry: '+r['destinationId'])
        registry['destinations'].append({'destinationId':r['destinationId'],'label':r['label'],'scope':r['scope'],
          'selectors':r['selectors'],'references':{'countdownPostcard':r.get('originalInputReferencePaths',r['referenced_image_paths'])[1]},
          'coverageTier':'explicitly_requested_'+r['scope']+'_override','generationPriority':'owner_requested_more_art_wave_c',
          'geographicScope':r['geographicScope'],
          'onboardingStage':{'status':'review_ready','masterPath':r['selectedWorkspacePath'],'dimensions':r['dimensions'],
            'promptLogPath':str((LOG/(r['destinationId']+'-prompt.txt')).relative_to(ROOT)),
            'generationMode':'built_in_imagegen','originalGenerationOutputPath':r['source'],
            'inputReferencePaths':r['referenced_image_paths'],'exactSubmittedPrompt':r['prompt'],
            'sha256':r['sha256'],'qaNotes':r['qaNotes'],'flutterIntegrated':False,'publicationEvidence':None,
            'lastReviewed':'2026-10-14','nextAction':'Owner still review; app integration and publication are separate.'}})
    registry['updatedAt']='2026-10-14'
    registry['changeLog'].append({'date':'2026-10-14','change':'Wave C: Antalya, Phuket, Milan and Taipei still stages generated and validated at 851 × 1848; review_ready, owner approval pending; no native integration or publication.'})
    registry_path.write_text(json.dumps(registry,indent=2,ensure_ascii=False)+'\n')
    print('PASS: four Wave C stages; provenance, validation, overview and registry saved.')

if __name__=='__main__':
    import sys
    if sys.argv[1]=='finalize': finalize()
    else: export(sys.argv[1])
