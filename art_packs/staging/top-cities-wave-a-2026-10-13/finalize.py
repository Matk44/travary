"""Verify all 60 deliverables and write a gallery and handoff manifest."""
import html,json,importlib.util
from pathlib import Path
from PIL import Image,ImageCms,ImageDraw,ImageFont

HERE=Path(__file__).resolve().parent
STAGING=HERE.parent
ROOT=HERE.parents[2]
spec=importlib.util.spec_from_file_location('city_export',HERE/'export_city.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
cities=json.loads((HERE/'cities.json').read_text())
profile=ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
reports=[]
for city in cities:
    for role in module.ROLES:
        path=STAGING/city['id']/(role+'.png')
        with Image.open(path) as image:
            im=image.convert('RGBA')
        im.save(path,icc_profile=profile)
    module.validate(city)
    module.review(city)
    report=json.loads((HERE/(city['id']+'-validation.json')).read_text())
    for result in report['results']:
        im=Image.open(ROOT/result['file'])
        assert im.info.get('icc_profile'),'Missing sRGB profile'
        result['embedded_srgb_profile']=True
    reports.append(report)
all_results=[r for report in reports for r in report['results']]
assert len(all_results)==60
(HERE/'validation.json').write_text(json.dumps({'date':'2026-10-13','wave':'A','count':60,'status':'PASS','scope':'Exact PNG dimensions, RGBA8, embedded sRGB, real alpha, corner alpha, original card alpha/structure, barcode stubs, eyelets and empty stamp label bands. Subjects and text-free art reviewed visually.','cities':reports},indent=2)+'\n')
records=[json.loads(p.read_text()) for p in sorted((HERE/'records').glob('*.json'))]
(HERE/'generation.json').write_text(json.dumps({'date':'2026-10-13','mode':'built-in imagegen; owner-authorized template compositing; uniform mechanical PNG export','brief':'docs/art_requests/GPT_TOP_CITIES_2026-10-13.md','records':records},indent=2)+'\n')

nav=''.join(f'<button data-city="{c["id"]}">{html.escape(c["name"])}</button>' for c in cities)
sections=[]
for city in cities:
    figures=[]
    for role in module.ROLES:
        src=f'../{city["id"]}/{role}.png'
        width,height=Image.open(STAGING/city['id']/(role+'.png')).size
        figures.append(f'<figure class="{("card" if role in module.ROLES[:3] else "paper")}"><a href="{src}" target="_blank"><img loading="lazy" src="{src}" alt="{city["name"]} {role}"></a><figcaption>{role}<small>{width} × {height} · PNG RGBA · sRGB</small></figcaption></figure>')
    sections.append(f'<section id="{city["id"]}" hidden><h2>{html.escape(city["name"])}</h2><p>{html.escape(city["light"].capitalize())} · {html.escape(city["palette"])}</p><div class="grid">'+''.join(figures)+f'</div><p><a href="{city["id"]}-light.png">Light contact sheet</a> · <a href="{city["id"]}-dark.png">Dark contact sheet</a> · <a href="{city["id"]}-validation.json">Checks</a></p></section>')
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Travary · Top cities · Wave A</title><style>
body{margin:0;background:#f4efe7;color:#243349;font:16px system-ui;--surface:#e9e1d4}body.dark{background:#111b2a;color:#f8f4ec;--surface:#243349}main{max-width:1450px;margin:auto;padding:30px}h1{font:40px Georgia;margin:0 0 12px}h2{font:30px Georgia;margin:26px 0 8px}p{line-height:1.6}a{color:inherit}button{font:inherit;padding:9px 16px;border:1px solid #99968e;border-radius:24px;background:transparent;color:inherit;cursor:pointer}button.active{background:#1e5b70;color:#f8f4ec;border-color:#1e5b70}nav{display:flex;flex-wrap:wrap;gap:8px;margin:24px 0}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:18px}figure{margin:0;background:var(--surface);border-radius:12px;overflow:hidden}figure a{display:flex;align-items:center;justify-content:center;padding:14px}figure.card a{height:240px}figure.paper a{height:410px}img{max-width:100%;max-height:100%;object-fit:contain}figcaption{padding:12px 16px;font-size:13px;overflow-wrap:anywhere}small{display:block;margin-top:5px;opacity:.7}.links{font-size:14px}footer{font-size:14px;margin-top:40px}@media(max-width:900px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:560px){.grid{grid-template-columns:1fr}main{padding:18px}h1{font-size:30px}}
</style><main><header><h1>Travary · Top cities · Wave A</h1><p>10 complete cities · 60 PNGs · 13 October 2026</p><p>Generated with built-in imagegen and the approved template-compositing workflow. Each city includes three cards, two postcards and one destination stamp. All delivery sizes, transparency, protected card details and empty stamp labels checked.</p><button id="theme">Switch light / dark</button><p class="links"><a href="README.md">File manifest and Claude handoff</a> · <a href="generation.json">Full prompt set</a> · <a href="validation.json">Validation record</a> · <a href="overview.png">All cities overview</a></p></header><nav>'''+nav+'''</nav>'''+''.join(sections)+'''<footer>Artwork is staged for review. App integration, pack building and publishing are separate developer steps. Wave B's eleven cities remain.</footer></main><script>
const buttons=[...document.querySelectorAll('[data-city]')];function showCity(id){document.querySelectorAll('section').forEach(s=>s.hidden=s.id!==id);buttons.forEach(b=>b.classList.toggle('active',b.dataset.city===id));history.replaceState(null,'','#'+id)}buttons.forEach(b=>b.addEventListener('click',()=>showCity(b.dataset.city)));document.getElementById('theme').onclick=()=>document.body.classList.toggle('dark');showCity(buttons.some(b=>b.dataset.city===location.hash.slice(1))?location.hash.slice(1):'london');</script></html>'''
(HERE/'index.html').write_text(page)
try:font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',28)
except OSError:font=ImageFont.load_default()
sheet=Image.new('RGB',(2000,1380),'#eee7dc');draw=ImageDraw.Draw(sheet)
draw.text((25,20),'Travary · Wave A · 10 cities / 60 PNGs',font=font,fill='#243349')
for i,city in enumerate(cities):
    x=(i%5)*400;y=80+(i//5)*640
    im=Image.open(STAGING/city['id']/'countdown_postcard.png').convert('RGBA');im.thumbnail((365,550),Image.Resampling.LANCZOS)
    sheet.paste(im,(x+(400-im.width)//2,y),im)
    draw.text((x+22,y+568),city['name'],font=font,fill='#243349')
sheet.save(HERE/'overview.png')
print('PASS: 60 final PNGs, 10 cities; gallery, overview, prompts and validation saved.')
