"""Prepare one prompt for the built-in imagegen tool; this never invokes an API."""
import json, sys
from pathlib import Path
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
ROLES=['featured_ticket','room_card','reservation_card','countdown_postcard','trip_postcard','documents_destination_stamp']
STYLE='''Tactile mid-century travel-poster screen print: flat layered shapes, fine risograph grain, soft paper fibres, calm elegant Travary navy/teal/coral/sage/mustard/cream family, never photographic. No words, letters, numbers, pseudo-text, decorative script, inscriptions, signs, logos, watermarks, flags, faces or copyrighted characters. All vehicle panels/plates, boat hulls, tram windows and shopfronts blank and unmarked. Every tram/train destination board and front oval/badge is a COMPLETELY SOLID BLANK PANEL: no monogram, emblem, oval outline, route label, letter-like scratches or painted symbol. Windows empty dark glass. NO FLAGS OR FLAGPOLES, including tiny bridge-top pennants, roof flags, boat flags or decorative banners. Bridge arches have clean uninterrupted bare tops. Small people may only be featureless silhouettes; prefer empty streets. Exclude theme parks, Hollywood sign, Space Needle, Cloud Gate and casino buildings. Replace ALL unrelated American template scenery. Even for San Francisco, remove original desert mesas, cactus, snowy peaks and road-trip scenery; retain only this place's specified scene. Famous buildings belong within a balanced country composition, not giant isolated objects.'''
CONTRACTS={
'featured_ticket':'''One finished featured ticket 1774 × 887 PNG, genuine transparency outside. Preserve original canvas, outline, notches, perforation, contact shadow, barcode stub and stripe pattern geometry. LEFT 42% plain navy at ALL heights, no scenic ink, silhouettes, flowers or grain speckles there. Scenery flows toward barcode in right picture panel, feathering from x746; full scene confined to x746..1360, y108..789. Recolour only original thin stripe to the three specified ink colours.''',
'room_card':'''One finished hotel key card 1774 × 887 PNG, genuine transparency outside. Preserve original canvas, rounded outline, edge, paper, contact shadow, stripe geometry and ivory right end cap. Country hotel view WITHOUT window frame. Critical: pure blank ivory paper LEFT OF X700 at every height, no speckle, haze, texture, scenery echo or dither in that protected area. x430..630 MUST be completely clean paper because this region is sampled for export. Scenic ink feathers in only after x700; final key card left 62% remains completely blank for live text; key subject in right x1100..1483. Recolour existing stripe only to specified colours.''',
'reservation_card':'''One finished reservation card 1983 × 793 PNG, genuine transparency outside. Preserve original outline, rounded corners, contact shadow, exact cord and brass eyelet, tag shape and position. Small compact scene confined to far-right framed illustration x1423..1950,y165..713. Large middle ivory paper area COMPLETELY blank. Recolour thin existing separator and tag to the place palette. Tag plain solid first palette colour, no original flag, no stars, stripes, text or printing. Keep grommet/cord intact.''',
'countdown_postcard':'''One upright portrait vintage postcard 1122 × 1402 PNG. Thin deckled warm-cream paper edge about 2% width, faint soft contact shadow, centred and straight-on with generous genuine transparent margin outside. Illustration fills paper inside edge. Upper-right quarter quiet open sky, main subjects in left and lower two-thirds. No tag, postmark, stamp, UI or surrounding backdrop.''',
'trip_postcard':'''One landscape 3:2 vintage postcard 1536 × 1024 PNG. Thin deckled warm-cream edge, faint soft shadow, centred and straight-on. Genuine transparency outside, NO opaque presentation backdrop. Same country scene recomposed with key subject in LEFT 60%; RIGHT 35% quieter, particularly upper right. No tags, postmarks, stamps or UI.''',
'documents_destination_stamp':'''One portrait postage stamp 1024 × 1280 PNG, matching Paris stamp paper/perforations/navy keyline and genuine alpha outside. Illustration in measured upper box x123..901,y115..947, with one clear bold subject from this country scene, simple shapes suitable at small size. Plain warm-ivory label band x123..901,y986..1152 MUST remain completely blank. Same palette and light as the city's other pictures. No denomination, text, numerals or postal marks.'''}

def prepare(city,role):
    refs=[]
    if role in ROLES[:3]:
        refs=[str(ROOT/'art_packs/prompts/city_card_references'/(role+'.png'))]
        intro='Input image 1 is the EDIT TARGET finished Travary card. Preserve structural geometry; change only printed country scenery and allowed stripe/tag colours.'
    else:
        refs=[str(ROOT/'art_packs/staging/london/trip_postcard.png' if role=='trip_postcard' else ROOT/'art_packs/originals/city_fr_paris/common'/(role+'.png'))]
        intro='Input image 1 is the paper-object/style reference ONLY; replace reference geography completely with this country.'
        prior=HERE/'records'/(city['id']+'-featured_ticket.json')
        if prior.exists():
            r=json.loads(prior.read_text())
            if r.get('source'):
                refs.append(r['source']);intro+=' Input image 2 is supporting country colour/scenery reference ONLY, discard ticket structure.'
    colors=', '.join('#'+''.join(f'{v:02x}' for v in c) for c in city['colors'])
    prompt='\n'.join(['Use case: '+('precise-object-edit' if role in ROLES[:3] else 'illustration-story'),intro,STYLE,
      f"Country: {city['name']}. Scene: {city['scene']}. Light: {city['light']}. Stripe and tag: {city['palette']} ({colors}). Keep all six pictures coherent in light, palette and landmarks.",CONTRACTS[role]])
    record={'id':city['id']+'/'+role,'prompt':prompt,'referenced_image_paths':refs,'transparent_background':True,'status':'prepared'}
    path=HERE/'records'/(city['id']+'-'+role+'.json')
    if path.exists(): raise FileExistsError(path)
    path.write_text(json.dumps(record,indent=2,ensure_ascii=False)+'\n')
    print(json.dumps({'recordPath':str(path),'args':{k:record[k] for k in ['prompt','referenced_image_paths','transparent_background']}}))
if __name__=='__main__':
    cities=json.loads((HERE/'cities.json').read_text())
    prepare(cities[int(sys.argv[1])],sys.argv[2])
