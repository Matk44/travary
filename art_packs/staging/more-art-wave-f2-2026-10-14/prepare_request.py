"""Prepare one stamp request for the built-in imagegen tool; no API execution."""
import json,sys
from pathlib import Path
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
def prepare(place):
    prompt='\n'.join([
      'Use case: illustration-story',
      'Asset type: Travary Documents destination stamp for '+place.get('name',place['id'])+'.',
      'Input image 1 is the Paris stamp PAPER/GEOMETRY reference only. Replace all Paris scenery; retain ivory cotton paper, fine fibres, perforations, thin navy keyline and completely blank bottom label.',
      'Tactile mid-century travel-poster screen print: flat layered shapes, fine risograph grain, soft paper fibres, warm low sun, limited navy/teal/coral/sage/mustard/cream family. Never photographic. Exactly ONE sun disc in the entire composition; no second sun, nested sun, orange semicircle behind a yellow sun, or moon. Compose for a small portrait stamp with one clear bold geographic subject and only one or two supporting cues, no fine clutter.',
      'Required destination scene: '+place['scene']+'. The geographic scope is '+('whole country' if place['id'].startswith('country_') else 'only this named US city or region')+'. No incorrect Paris landmarks.',
      'One straight-on portrait postage stamp 1024 × 1280 PNG RGBA, genuine transparency outside the paper/shadow. Keep Paris paper/perforation/keyline geometry. Picture confined to upper measured box x123..901,y115..947. Leave bottom label x123..901,y986..1152 plain completely blank ivory for live place name. No opaque backdrop, no rotation, no perspective.',
      'No words, letters, numbers, pseudo-text, decorative script, hieroglyphs, Arabic or Chinese characters even as pattern. No signs, inscriptions, logos, flags, denominations, postmarks, watermarks, UI, faces or copyrighted characters. Featureless tiny silhouettes only if necessary. Exclude theme parks, Hollywood sign, Space Needle, Cloud Gate and casino buildings. Vehicles/boats unmarked. Trams and trains have NO route-board housing, plaque, badge or sign: roof is continuous plain curve, windows featureless dark glass. No flagpoles or pennants even on bridge tops, rooftops or boat masts; bridge arches have clean bare tops. Clock faces use hands and ticks only, no Arabic/Roman numerals.'])
    record={'id':place['id']+'/documents_destination_stamp','prompt':prompt,
      'referenced_image_paths':[str(ROOT/'art_packs/originals/city_fr_paris/common/documents_destination_stamp.png')],
      'transparent_background':True,'status':'prepared'}
    path=HERE/'records'/(place['id']+'-documents_destination_stamp.json')
    if path.exists():raise FileExistsError(path)
    path.write_text(json.dumps(record,indent=2,ensure_ascii=False)+'\n')
    print(json.dumps({'recordPath':str(path),'args':{k:record[k] for k in ['prompt','referenced_image_paths','transparent_background']}}))
if __name__=='__main__':prepare(json.loads((HERE/'places.json').read_text())[int(sys.argv[1])])
