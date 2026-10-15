"""Build a light/dark QA sheet, or record a completed visual inspection."""
import json,sys
from pathlib import Path
from PIL import Image,ImageDraw
BASE=Path(__file__).resolve().parent;ROOT=BASE.parents[1]
wave,index=sys.argv[1],int(sys.argv[2]);h=BASE/f'more-art-wave-{wave}-2026-10-14'
place=json.loads((h/'places.json').read_text())[index];p=h/'records'/(place['id']+'-documents_destination_stamp.json');r=json.loads(p.read_text())
if len(sys.argv)==3:
    im=Image.open(ROOT/r['finalPath']);sheet=Image.new('RGB',(1240,830),'#eee7dc');d=ImageDraw.Draw(sheet);d.rectangle((620,0,1239,829),fill='#182233')
    for i,ink in enumerate(['#243349','#f8f4ec']):
        thumb=im.copy();thumb.thumbnail((570,740),Image.Resampling.LANCZOS);sheet.paste(thumb,(i*620+(620-thumb.width)//2,30),thumb);d.text((i*620+25,790),place.get('name',place['id']),fill=ink)
    sheet.save(h/(place['id']+'-review.png'))
else:
    r.update(status='review_ready',visuallyInspected=True,ownerApproval='pending',qaNotes=sys.argv[3]);p.write_text(json.dumps(r,indent=2,ensure_ascii=False)+'\n')
    sp=BASE/'more-art-2026-10-14-status.json';s=json.loads(sp.read_text());done=[p['id'] for p in json.loads((h/'places.json').read_text()) if (h/'records'/(p['id']+'-documents_destination_stamp.json')).exists() and json.loads((h/'records'/(p['id']+'-documents_destination_stamp.json')).read_text()).get('status')=='review_ready'];s['waves'][wave.upper()].update(completed=len(done),completedPlaces=done);sp.write_text(json.dumps(s,indent=2)+'\n')
    print(place['id']+': stamp visually reviewed')
