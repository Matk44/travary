"""Mechanical PNG export; all illustration pixels originate in built-in imagegen."""
import json
import re
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[3]
RECORDS = Path(__file__).with_name('generation.json')

def resize(im, size):
    return im.convert('RGBa').resize(size, Image.Resampling.LANCZOS).convert('RGBA')

def export(record):
    key = record['id']
    source = Path(re.search(r'as (/\S+\.png) by default', record['output_hint'])[1])
    im = Image.open(source).convert('RGBA')
    notes = []
    if '/icons/' in key:
        bbox = im.getchannel('A').point(lambda a: 255 if a > 16 else 0).getbbox()
        art = im.crop(bbox)
        scale = 512 / max(art.size)
        size = tuple(round(v * scale) for v in art.size)
        art = resize(art, size)
        im = Image.new('RGBA', (1024, 1024))
        im.alpha_composite(art, ((1024-size[0])//2, (1024-size[1])//2))
        notes.append('Uniformly scaled to 512px maximum content extent; centred with transparent padding.')
    elif key.endswith('/pill'):
        im = resize(im, (1536, 512))
        notes.append('Uniform downsample to exact 3:1 delivery dimensions; generated alpha retained.')
    elif key.endswith('/leather'):
        im = im.convert('RGB')
        # Locate stitch centre and end gaps so the repeat has a complete stitch cadence.
        scores = [sum(sum(im.getpixel((x,y))) > 390 for x in range(im.width)) for y in range(50,180)]
        stitch_y = 50 + scores.index(max(scores))
        xs = [x for x in range(im.width) if sum(im.getpixel((x,stitch_y))) > 390]
        runs = []
        for x in xs:
            if not runs or x > runs[-1][-1]+1: runs.append([x])
            else: runs[-1].append(x)
        runs = [r for r in runs if len(r)>3]
        start = (runs[0][-1]+runs[1][0])//2 if runs[0][0] == 0 else 0
        end = (runs[-1][-1]+im.width)//2
        im = im.crop((start,0,end,im.height)).resize((1536,1024),Image.Resampling.LANCZOS)
        delta = 123-stitch_y
        im = ImageChops.offset(im,0,delta)
        # Match both edge columns, feathering only 16px of generated texture.
        pixels = im.load()
        for y in range(im.height):
            target = tuple(round((pixels[0,y][c]+pixels[1535,y][c])/2) for c in range(3))
            for n in range(16):
                weight = (1-n/16)**2
                for x in (n,1535-n):
                    old=pixels[x,y]
                    pixels[x,y]=tuple(round(old[c]*(1-weight)+target[c]*weight) for c in range(3))
        notes.append(f'End-gap crop {start}..{end}; stitch centre moved from y={stitch_y} to y=123; 16px feather joins original texture, matching left/right edge columns exactly.')
    else:
        size = (1536,1024) if key.endswith('_scene') else (1122,1402) if key.endswith('countdown_postcard_anywhere') else (1024,1024)
        if im.size != size:
            im=resize(im,size)
            notes.append('Resampled generated artwork to required delivery canvas.')
    destination=ROOT/'art_packs/staging'/f'{key}.png'
    destination.parent.mkdir(parents=True,exist_ok=True)
    if destination.exists():
        return None
    im.save(destination)
    return {'id':key,'path':str(destination.relative_to(ROOT)),'size':im.size,'mode':im.mode,'notes':notes}

if __name__ == '__main__':
    exports=[]
    for record in json.loads(RECORDS.read_text())['records']:
        if record['id'].startswith('interface/'):
            item=export(record)
            if item: exports.append(item)
    log=Path(__file__).with_name('interface-export.json')
    previous=json.loads(log.read_text()) if log.exists() else []
    log.write_text(json.dumps(previous+exports,indent=2)+'\n')
    print(json.dumps(exports,indent=2))
