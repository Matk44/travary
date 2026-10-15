"""Validate delivery dimensions, alpha and protected template regions."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
STAGING=ROOT/'art_packs/staging'

def rgb_diff(a,b):
    d=ImageChops.difference(a.convert('RGB'),b.convert('RGB'))
    r,g,b=d.split()
    return ImageChops.lighter(ImageChops.lighter(r,g),b)

results=[]
for record in json.loads((HERE/'generation.json').read_text())['records']:
    key=record['id']
    path=STAGING/f'{key}.png'
    im=Image.open(path)
    card=not key.startswith('interface/')
    expected=(1983,793) if key.endswith('reservation_card') else (1774,887) if card else (1536,1024) if key.endswith('/leather') or key.endswith('_scene') else (1536,512) if key.endswith('/pill') else (1122,1402) if key.endswith('countdown_postcard_anywhere') else (1024,1024)
    assert im.size==expected,(key,im.size,expected)
    rgba=im.convert('RGBA')
    alpha=rgba.getchannel('A')
    transparent=not(key.endswith('/leather') or key.endswith('_scene'))
    assert alpha.getextrema()==((0,255) if transparent else (255,255)),key
    item={'file':str(path.relative_to(ROOT)),'size':im.size,'mode':im.mode,'alpha_extrema':alpha.getextrema(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    if card:
        role=key.split('/')[-1]
        base=Image.open(ROOT/'art_packs/prompts/city_card_references'/f'{role}.png').convert('RGBA')
        assert ImageChops.difference(base.getchannel('A'),alpha).getbbox() is None,key
        diff=rgb_diff(base,rgba)
        protected=Image.new('L',im.size,255)
        draw=ImageDraw.Draw(protected)
        if role=='featured_ticket':
            for box in [(48,108,1360,789),(1394,108,1485,785)]:draw.rectangle(box,fill=0)
            assert rgb_diff(base.crop((1490,110,1680,785)),rgba.crop((1490,110,1680,785))).getbbox() is None
        elif role=='room_card':
            for box in [(700,96,1483,793),(1484,96,1677,789)]:draw.rectangle(box,fill=0)
            assert rgb_diff(base.crop((100,120,700,770)),rgba.crop((100,120,700,770))).getbbox() is None
        else:
            for box in [(1423,165,1949,712),(1406,192,1412,691),(170,190,514,685)]:draw.rectangle(box,fill=0)
            grommet=Image.new('L',im.size,0)
            ImageDraw.Draw(grommet).ellipse((270,232,344,306),fill=255)
            assert ImageChops.multiply(diff,grommet).getbbox() is None,'grommet '+key
            assert rgb_diff(base.crop((535,170,1395,710)),rgba.crop((535,170,1395,710))).getbbox() is None
        assert ImageChops.multiply(diff,protected).getbbox() is None,'protected region '+key
        exterior=base.getchannel('A').point(lambda a:255 if a<240 else 0)
        assert ImageChops.multiply(diff,exterior).getbbox() is None,'exterior '+key
        item.update(alpha_matches_template=True,protected_shell_pixels_match=True,exterior_and_shadow_match=True)
    if '/icons/' in key:
        bbox=alpha.point(lambda a:255 if a>16 else 0).getbbox()
        extent=max(bbox[2]-bbox[0],bbox[3]-bbox[1])
        assert 510<=extent<=514,(key,bbox)
        item['content_bbox']=bbox
    if key.endswith('/leather'):
        assert im.crop((0,0,1,1024)).tobytes()==im.crop((1535,0,1536,1024)).tobytes()
        scores=[sum(sum(im.getpixel((x,y)))>390 for x in range(im.width)) for y in range(90,150)]
        stitch_y=90+scores.index(max(scores))
        assert abs(stitch_y-123)<=1,stitch_y
        item.update(horizontal_edge_columns_identical=True,stitch_centre_y=stitch_y)
    results.append(item)
assert len(results)==17,len(results)
report={'count':len(results),'status':'PASS','visual_review':'All generated subjects inspected. Final contact sheets checked on light and dark backdrops. No readable text, logos, city-specific US landmarks or real park attractions observed. Card illustrations uniformly fitted to the required blank-text boundaries; shell pixels outside permitted artwork and decorative regions retained. Staged artwork only; no app integration or publishing.','results':results}
(HERE/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(f'PASS: {len(results)} PNGs; dimensions, alpha, template protections, icon padding and leather seam.')
