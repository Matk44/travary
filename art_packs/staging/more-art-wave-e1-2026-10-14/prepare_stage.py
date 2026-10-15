"""Prepare one country-first scenery stage after its own postcard is exported."""
import json,sys
from pathlib import Path
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2]
SIBLINGS={'country_at':'country_ch','country_hr':'country_gr','country_ie':'country_gb','country_vn':'country_th','country_ma':'country_tr','country_eg':'country_ae','country_hu':'city_cz_prague'}
def prepare(country):
    postcard=ROOT/'art_packs/staging'/country['id']/'countdown_postcard.png'
    assert postcard.exists(),'Generate/export this country postcard first'
    refs=[str(ROOT/'docs/mockups/onboarding-folio-motion-v1/bali-stage-prop-free-v1.png'),str(postcard),str(ROOT/'assets/onboarding/stages'/(SIBLINGS[country['id']]+'.webp'))]
    prompt='\n'.join([
      'Use case: style-transfer',
      'Asset type: clean Travary onboarding country stage for '+country['name']+' ('+country['id']+'). COUNTRY scope, broad coverage, not one city.',
      'Input 1: approved clean Bali stage, authoritative portrait camera, tactile paper material, teal theatre wings, quiet headline sky and cream floor reference only. Input 2: this country\'s OWN newly generated countdown postcard, geographic content, palette and light reference; remove its border. Input 3: sibling stage for consistency of camera/paper richness ONLY; do not copy its geographic landmarks.',
      'Replace the entire landscape with a lavish handmade miniature country world: '+country['scene']+'. Symbolic staged country composition, not a claim that distant landmarks share one literal viewpoint. Preserve correct local architecture, landscapes, plants and animal shapes. '+country['light']+'.',
      'Rich sculpted folded cardstock, fine embossed grain, visible cut edges, convincing miniature depth, shadows BETWEEN scenery layers, warm physical light. Match Bali richness and sibling family; not flat poster, photograph or glossy plastic. Use this country\'s postcard colours, not a universal Bali tint.',
      'One full uncropped opaque portrait 851 × 1848 PNG, reference aspect 0.4605. Upper 0–27% quiet petrol-teal paper sky through centre for live wordmark and headline. Side foliage may frame the sky like Bali and sibling; detailed landmark tops must remain below28%, and no rainbow/sun/cloud cuts through central headline sky. Middle 27–65% expansive country scenery filling theatre width. Lower 65–100% uninterrupted warm cream control floor with matching camera and gentle light, scenery ends at 65%. Teal curved side wings with fine cream edging. Right foreground x62–92%,y42–71% clear of bulky close landmarks for shared Travi; scenery continues quietly behind.',
      'Remove Bali temples, gates, terraces, volcano and tropical vegetation unless genuinely present in this country\'s required scene. No people, faces, Travi, character, character shadow, folio, luggage, loose tickets, UI, labels, prices, dates, text, letters, numerals, decorative script, inscriptions, hieroglyphs, Arabic/Chinese characters even as pattern, signs, logos, flags, flagpoles, watermark, postcard border or device. Clocks use hands/ticks only; transport panels and windows plain/unmarked. One complete clean opaque scenery still.'])
    r={'id':country['id']+'/onboarding_stage_v1','destinationId':country['id'],'label':country['name'],'scope':'country','selectors':{'countryCodes':[country['id'][-2:].upper()]},'geographicScope':country['scene'], 'prompt':prompt,'referenced_image_paths':refs,'transparent_background':False,'status':'prepared'}
    p=HERE/'records'/(country['id']+'-onboarding_stage_v1.json');assert not p.exists();p.write_text(json.dumps(r,indent=2,ensure_ascii=False)+'\n')
    print(json.dumps({'recordPath':str(p),'args':{k:r[k] for k in ['prompt','referenced_image_paths','transparent_background']}}))
if __name__=='__main__':prepare(json.loads((HERE/'cities.json').read_text())[int(sys.argv[1])])
