"""Export built-in ImageGen artwork without stretching; preserve original shells."""
import json, subprocess, sys, hashlib, shutil
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageOps, ImageFont, ImageCms, ImageFilter

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
STAGING=HERE.parent
ROLES=['featured_ticket','room_card','reservation_card','countdown_postcard','trip_postcard','documents_destination_stamp']
SIZES=[(1774,887),(1774,887),(1983,793),(1122,1402),(1536,1024),(1024,1280)]

def uniform(im,size):
    if im.size==size:return im
    scaled=ImageOps.contain(im.convert('RGBa'),size,Image.Resampling.LANCZOS).convert('RGBA')
    out=Image.new('RGBA',size)
    out.alpha_composite(scaled,((size[0]-scaled.width)//2,(size[1]-scaled.height)//2))
    return out

def diff(a,b):
    r,g,b=ImageChops.difference(a.convert('RGB'),b.convert('RGB')).split()
    return ImageChops.lighter(ImageChops.lighter(r,g),b)

def stray_pixels(path,kind):
    zones={'featured_ticket':(.08,.42),'room_card':(.10,.62),'reservation_card':(.30,.62)}
    im=Image.open(path).convert('RGBA');left,right=zones[kind]
    crop=im.crop((int(im.width*left),int(im.height*.18),int(im.width*right),int(im.height*.82)))
    rgb=crop.convert('RGB');r,g,b=ImageChops.difference(rgb,rgb.filter(ImageFilter.MedianFilter(7))).split()
    noisy=ImageChops.lighter(ImageChops.lighter(r,g),b).point(lambda v:255 if v>30 else 0)
    inside=crop.getchannel('A').point(lambda a:255 if a>250 else 0)
    return ImageChops.multiply(noisy,inside).histogram()[255]

def export(city):
    records={}
    for p in sorted((HERE/'records').glob(city['id']+'-*.json')):
        r=json.loads(p.read_text());key=r['id'].split('/')[-1]
        if key.endswith('-corrected'):key=key.removesuffix('-corrected')
        if key not in records or r['id'].endswith('-corrected'):records[key]=r
    assert all(k in records for k in ROLES),(city['id'],list(records))
    originals=HERE/'originals';originals.mkdir(exist_ok=True)
    for role,record in records.items():
        raw=originals/(city['id']+'-'+role+'.png')
        if not raw.exists():shutil.copy2(record['source'],raw)
        record['originalWorkspacePath']=str(raw.relative_to(ROOT))
    jobs=[]
    for role,size in zip(ROLES[:3],SIZES[:3]):
        record=records[role]
        im=Image.open(record['source']).convert('RGBA')
        source=HERE/'normalised'/f"{city['id']}-{role}.png"
        source.parent.mkdir(exist_ok=True)
        uniform(im,size).save(source)
        jobs.append({'place':city['id'],'role':role,'source':str(source),'palette':city['colors']})
    jobs_path=HERE/f"{city['id']}-card-export.json"
    jobs_path.write_text(json.dumps(jobs,indent=2)+'\n')
    subprocess.run(['node',str(ROOT/'art_packs/staging/key-card-backdrop-fix-2026-10-14/export_cards_clean_backdrop.cjs'),str(ROOT),str(jobs_path)],check=True)
    for role,size in zip(ROLES[3:],SIZES[3:]):
        record=records[role]
        im=uniform(Image.open(record['source']).convert('RGBA'),size)
        assert im.getchannel('A').getextrema()[0]==0,'Opaque generation: '+role
        if role.endswith('postcard'):
            im.putalpha(im.getchannel('A').point(lambda a:0 if a<=4 else a))
        if role=='documents_destination_stamp':
            # The supplied reference fixes the perforations and label geometry.
            base=Image.open(ROOT/'art_packs/originals/city_fr_paris/common/documents_destination_stamp.png').convert('RGBA')
            # Build a blank measured stamp template from its existing ivory band.
            # Native-scale paper copies remove the old reference illustration.
            paper=base.crop((112,1015,906,1100))
            for y in range(124,1002,85):
                base.paste(paper.crop((0,0,794,min(85,1002-y))),(112,y))
            template=HERE/'stamp-template.png'
            if not template.exists():base.save(template)
            donor=im.crop((112,124,906,1002))
            art=ImageOps.fit(donor.convert('RGBa'),(778,832),Image.Resampling.LANCZOS,centering=(.5,.5)).convert('RGBA')
            base.paste(art,(123,115))
            im=base
        dest=STAGING/city['id']/(role+'.png')
        if dest.exists():raise FileExistsError(dest)
        im.save(dest)
    profile=ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
    for role in ROLES:
        path=STAGING/city['id']/(role+'.png')
        with Image.open(path) as image:
            rgba=image.convert('RGBA')
        rgba.save(path,icc_profile=profile)
    validate(city)
    review(city)

def validate(city):
    result=[]
    for role,size in zip(ROLES,SIZES):
        path=STAGING/city['id']/(role+'.png')
        im=Image.open(path).convert('RGBA')
        assert im.size==size,(role,im.size)
        alpha=im.getchannel('A')
        assert alpha.getextrema()[0]==0,role
        assert max(alpha.getextrema())>=250,role
        assert all(alpha.getpixel(p)==0 for p in [(0,0),(im.width-1,0),(0,im.height-1),(im.width-1,im.height-1)]),'corner alpha '+role
        item={'file':str(path.relative_to(ROOT)),'size':size,'mode':'RGBA','alpha_extrema':alpha.getextrema(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
        if role in ROLES[:3]:
            base=Image.open(ROOT/'art_packs/prompts/city_card_references'/(role+'.png')).convert('RGBA')
            assert ImageChops.difference(alpha,base.getchannel('A')).getbbox() is None
            d=diff(base,im)
            mask=Image.new('L',size,255);draw=ImageDraw.Draw(mask)
            boxes=[(48,108,1360,789),(1394,108,1485,785)] if role=='featured_ticket' else [(700,96,1483,793),(1484,96,1677,789)] if role=='room_card' else [(1423,165,1949,712),(1406,192,1412,691),(170,190,514,685)]
            for b in boxes:draw.rectangle(b,fill=0)
            assert ImageChops.multiply(d,mask).getbbox() is None,'protected shell '+role
            exterior=base.getchannel('A').point(lambda a:255 if a<240 else 0)
            assert ImageChops.multiply(d,exterior).getbbox() is None,'exterior '+role
            count=stray_pixels(path,role)
            assert count<=10,(city['id'],role,'stray pixels',count)
            item.update(alpha_matches_template=True,protected_shell_pixels_match=True,stray_pixels=count)
            if role=='featured_ticket':
                assert diff(base.crop((1490,110,1680,785)),im.crop((1490,110,1680,785))).getbbox() is None
                item['barcode_stub_matches_template']=True
            if role=='reservation_card':
                eyelet=Image.new('L',size,0)
                ImageDraw.Draw(eyelet).ellipse((270,232,344,306),fill=255)
                assert ImageChops.multiply(d,eyelet).getbbox() is None,'brass eyelet'
                assert diff(base.crop((535,170,1395,710)),im.crop((535,170,1395,710))).getbbox() is None,'blank centre'
                item.update(brass_eyelet_matches_template=True,blank_centre_matches_template=True)
        if role=='documents_destination_stamp':
            base=Image.open(HERE/'stamp-template.png').convert('RGBA')
            band=(123,986,901,1152)
            assert diff(base.crop(band),im.crop(band)).getbbox() is None,'blank label'
            item['blank_label_matches_reference']=True
            item['printed_illustration_box']=[123,115,901,947]
        result.append(item)
    (HERE/(city['id']+'-validation.json')).write_text(json.dumps({'city':city['name'],'count':6,'status':'PASS','results':result},indent=2)+'\n')
    print(city['name']+': six PNGs PASS',flush=True)

def review(city):
    try:font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',24)
    except OSError:font=ImageFont.load_default()
    for theme,bg,ink in [('light','#eee7dc','#243349'),('dark','#182233','#f8f4ec')]:
        sheet=Image.new('RGB',(1600,1520),bg);draw=ImageDraw.Draw(sheet)
        draw.text((25,20),city['name']+' — '+theme+' background',font=font,fill=ink)
        for i,role in enumerate(ROLES):
            x=(i%3)*533;y=70+(i//3)*710
            im=Image.open(STAGING/city['id']/(role+'.png')).convert('RGBA')
            im.thumbnail((495,625),Image.Resampling.LANCZOS)
            sheet.paste(im,(x+(533-im.width)//2,y+(625-im.height)//2),im)
            draw.text((x+18,y+640),role,font=font,fill=ink)
        sheet.save(HERE/(city['id']+'-'+theme+'.png'))

if __name__=='__main__':
    city=json.loads((HERE/'cities.json').read_text())[int(sys.argv[1])]
    export(city)
