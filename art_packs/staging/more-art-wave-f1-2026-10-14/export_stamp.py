"""Owner-authorized Paris stamp-template compositing and exact PNG checks."""
import hashlib, json, io, sys, shutil
from pathlib import Path
from PIL import Image, ImageOps, ImageChops, ImageCms
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
PROFILE=ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
TEMPLATE=ROOT/'art_packs/staging/top-cities-wave-b-2026-10-13/stamp-template.png'

def export(place):
    record_path=HERE/'records'/(place['id']+'-documents_destination_stamp.json')
    record=json.loads(record_path.read_text())
    raw=Image.open(record['source']).convert('RGBA')
    assert raw.getchannel('A').getextrema()[0]==0,'Opaque generation: regenerate with real alpha'
    original=HERE/'originals'/(place['id']+'-'+Path(record['source']).stem+'.png');original.parent.mkdir(exist_ok=True)
    if not original.exists():shutil.copy2(record['source'],original)
    # Reuse Wave B's uniform normalization and measured donor/print boxes.
    if raw.size!=(1024,1280):
        fitted=ImageOps.contain(raw.convert('RGBa'),(1024,1280),Image.Resampling.LANCZOS).convert('RGBA')
        raw=Image.new('RGBA',(1024,1280));raw.alpha_composite(fitted,((1024-fitted.width)//2,(1280-fitted.height)//2))
    donor=raw.crop((112,124,906,1002))
    art=ImageOps.fit(donor.convert('RGBa'),(778,832),Image.Resampling.LANCZOS,centering=(.5,.5)).convert('RGBA')
    result=Image.open(TEMPLATE).convert('RGBA');result.alpha_composite(art,(123,115))
    target=HERE.parent/place['id']/'documents_destination_stamp.png';target.parent.mkdir(exist_ok=True)
    if target.exists():raise FileExistsError(target)
    template=Image.open(TEMPLATE).convert('RGBA')
    assert result.crop((123,115,901,947)).getchannel('A').getextrema()[0]>=250, 'Picture must be opaque ink/paper'
    assert ImageChops.difference(result.crop((123,986,901,1152)).convert('RGB'),template.crop((123,986,901,1152)).convert('RGB')).getbbox() is None
    assert all(result.getpixel(p)[3]==0 for p in [(0,0),(1023,0),(0,1279),(1023,1279)])
    mask=Image.new('L',result.size,255)
    from PIL import ImageDraw
    ImageDraw.Draw(mask).rectangle((123,115,900,946),fill=0)
    assert ImageChops.multiply(ImageChops.difference(result.getchannel('A'),template.getchannel('A')),mask).getbbox() is None, 'Exterior alpha changed'
    d=ImageChops.difference(result.convert('RGB'),template.convert('RGB'))
    assert all(ImageChops.multiply(c,mask).getbbox() is None for c in d.split()),'Protected stamp paper/keyline/perforation changed'
    result.save(target,icc_profile=PROFILE)
    record.update(status='exported_pending_visual_review',finalPath=str(target.relative_to(ROOT)),
                  originalWorkspacePath=str(original.relative_to(ROOT)),dimensions=[1024,1280],mode='RGBA8',embeddedSrgb=True,
                  realAlpha=True,transparentCorners=True,blankLabelMatchesTemplate=True,
                  protectedStampMatchesTemplate=True,sha256=hashlib.sha256(target.read_bytes()).hexdigest())
    record_path.write_text(json.dumps(record,indent=2,ensure_ascii=False)+'\n')
    print(json.dumps({k:record[k] for k in ['id','finalPath','sha256']}))

if __name__=='__main__':
    places=json.loads((HERE/'places.json').read_text());export(places[int(sys.argv[1])])
