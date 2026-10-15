import html
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
STAGING=HERE.parent
records=json.loads((HERE/'generation.json').read_text())['records']
try: font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',24)
except OSError: font=ImageFont.load_default()
groups=[('Cards',[r for r in records if not r['id'].startswith('interface/')],2,760,400),
        ('Surfaces and icons',[r for r in records if '/icons/' in r['id'] or r['id'].endswith(('/leather','/pill'))],3,440,320),
        ('Dining and postcard',[r for r in records if '/dining/' in r['id'] or r['id'].endswith('countdown_postcard_anywhere')],2,620,660)]
sections=[]
for title,items,cols,cw,ch in groups:
    cards=[]
    for r in items:
        name=r['id']
        src='../'+name+'.png'
        im=Image.open(STAGING/(name+'.png'))
        cards.append(f'<figure><a href="{src}" target="_blank"><img src="{src}" alt="{html.escape(name)}"></a><figcaption>{html.escape(name)}<small>{im.width} × {im.height} · PNG</small></figcaption></figure>')
    sections.append(f'<section><h2>{title}</h2><div class="grid">'+''.join(cards)+'</div></section>')
    for theme,bg,ink in [('light','#eee7dc','#243349'),('dark','#182233','#f8f4ec')]:
        sheet=Image.new('RGB',(cols*cw,70+((len(items)+cols-1)//cols)*ch),bg)
        draw=ImageDraw.Draw(sheet)
        draw.text((22,18),f'{title} — {theme} background',font=font,fill=ink)
        for i,r in enumerate(items):
            x=(i%cols)*cw;y=70+(i//cols)*ch
            art=Image.open(STAGING/(r['id']+'.png')).convert('RGBA')
            art.thumbnail((cw-36,ch-78),Image.Resampling.LANCZOS)
            sheet.paste(art,(x+(cw-art.width)//2,y+10+(ch-78-art.height)//2),art)
            label=r['id'].replace('interface/','').replace('themepark_','')
            draw.text((x+18,y+ch-53),label,font=font,fill=ink)
        sheet.save(HERE/(title.lower().replace(' ','-')+'-'+theme+'.png'))
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Travary — Remaining artwork</title>
<style>body{margin:0;background:#f4efe7;color:#243349;font:16px system-ui;--stage:#e9e1d4}body.dark{background:#111b2a;color:#f8f4ec;--stage:#243349}main{max-width:1300px;margin:auto;padding:32px}h1{font:42px Georgia;margin:0 0 12px}h2{font:28px Georgia;margin-top:42px}p{max-width:780px;line-height:1.6}button,a{color:inherit}button{padding:10px 18px;border:1px solid #9b9b91;border-radius:24px;background:none;cursor:pointer}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:20px}figure{margin:0;border-radius:12px;overflow:hidden;background:var(--stage)}figure a{display:flex;height:340px;align-items:center;justify-content:center;padding:14px}img{max-width:100%;max-height:100%;object-fit:contain}figcaption{padding:16px;font-size:13px;overflow-wrap:anywhere}small{display:block;opacity:.7;margin-top:6px}header a{margin-right:20px}footer{margin-top:40px;font-size:14px}@media(max-width:700px){.grid{grid-template-columns:1fr}main{padding:20px}h1{font-size:32px}}</style>
<main><header><h1>Travary · Remaining artwork</h1><p>17 PNGs · 13 October 2026 · Staged for review</p><p>Generated with built-in imagegen and exported using the approved template-compositing workflow. Exact delivery sizes and transparency checked. The six cards preserve the original template alpha and protected shell pixels. No app assets replaced or packs published.</p><button onclick="document.body.classList.toggle('dark')">Switch light / dark background</button><p><a href="generation.json">Full prompt set</a><a href="validation.json">Validation record</a><a href="README.md">Delivery notes</a></p></header>'''+''.join(sections)+'''<footer>Click any image to inspect the delivered PNG at full size.</footer></main></html>'''
(HERE/'index.html').write_text(page)
print('Review gallery and six contact sheets saved.')
