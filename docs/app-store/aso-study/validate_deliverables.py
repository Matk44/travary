#!/usr/bin/env python3
"""Validate saved study without network or external mutation; regenerate QA/handover."""
from pathlib import Path
from PIL import Image
import json,hashlib,re,collections
OUT=Path(__file__).resolve().parent
F=json.loads((OUT/'listing-fields.json').read_text())
A=json.loads((OUT/'asset-map.json').read_text())
R=(OUT/'REPORT.md').read_text()
required='store app_id locale page_type page_reference_name console_section field_label action value source_file character_count utf8_byte_count limit limit_unit asset_path device_bucket upload_order dependencies status source_references navigation_verified'.split()
fail=[];checks=collections.Counter()
for f in F:
 for k in required:
  if k not in f:fail.append(f"{f['id']} lacks {k}")
 if f['status'].startswith('owner-approved'):fail.append('Unauthorized approval')
 if isinstance(f['value'],str):
  raw=Path(f['source_file']).read_bytes();v=raw.decode('utf-8')
  if v!=f['value']:fail.append(f"File mismatch {f['id']}")
  if len(v)!=f['character_count'] or len(raw)!=f['utf8_byte_count']:fail.append(f"Count mismatch {f['id']}")
  needle=f"<!-- COPY:{f['id']} -->\n```text\n{v}\n```\n<!-- END_COPY:{f['id']} -->"
  if needle not in R:fail.append(f"Report mismatch {f['id']}")
  if '\r' in v or raw.startswith(b'\xef\xbb\xbf') or v.endswith('\n'):fail.append(f"Encoding/newline {f['id']}")
  if f['limit'] is not None:
   n=len(raw) if f['limit_unit']=='UTF-8 bytes' else len(v)
   if n>f['limit'] or f['remaining_capacity']!=f['limit']-n:fail.append(f"Limit {f['id']}")
   checks['limited_copy_fields']+=1
  checks['exact_text_files']+=1
  if f['field_label'] in ['Name','App name'] and f['value']!='Itinerary App - Travary':fail.append('Title changed')
  if f['field_label'] in ['Name','App name']:
   assert len(v)==23 and len(raw)==23
   checks['fixed_titles']+=1
  if f['store']=='apple' and f['field_label']=='Keywords':
   assert v.isascii() and all(len(x)>2 for x in v.split(','))
   assert not any(w in v.lower().split(',') for w in ['itinerary','app','travary','trip','planner','offline','tickets','travel'])
   checks['apple_keyword_strings']+=1
 else:
  assert f['character_count'] is None and f['utf8_byte_count'] is None
 if f['action']=='upload' and (not f['asset_path'] or not Path(f['asset_path']).is_file()):fail.append(f"Missing upload path {f['id']}")
 if f['value'] is None and not f['asset_path']:checks['explicit_null_rows']+=1
 assert isinstance(f['navigation_verified'],bool)
assert len(set(f['id'] for f in F))==len(F)
assert len(set(a['id'] for a in A['assets']))==len(A['assets'])
unique={}
for a in A['assets']:
 p=a['asset_path']
 if p:
  p=Path(p)
  if not p.is_file():fail.append(f'Missing asset {p}');continue
  if p not in unique:
   sha=hashlib.sha256(p.read_bytes()).hexdigest()
   if sha!=a['sha256']:fail.append(f'Asset changed {p}')
   unique[p]=sha
   if p.suffix=='.png':
    im=Image.open(p)
    if (im.width,im.height)!=(a['width'],a['height']):fail.append(f'Dimension {p}')
    if 'A' in im.getbands():fail.append(f'Alpha {p}')
  if a['placement'].endswith('optional loop'):
   assert a['duration_seconds']==7 and a['fps']==30 and a['audio_streams']==0 and not a['active_assignment']
 else:assert 'missing' in a['status'].lower() or any('capture' in x.lower() or 'graphic' in x.lower() for x in a['requirements'])
for store,lim in [('apple',10),('google',8)]:
 for loc in ['en-US','en-GB','en-AU']:
  for page in ['default','family']:
   groups=collections.defaultdict(list)
   for a in A['assets']:
    if a['store']==store and a['locale']==loc and a['page']==page and a['active_assignment'] and a['upload_order'] is not None:groups[(a['placement'],a['device_bucket'])].append(a)
   for key,items in groups.items():
    order=sorted(x['upload_order'] for x in items)
    if order!=list(range(1,len(items)+1)) or len(items)>lim:fail.append(f'Order {store} {loc} {page} {key}')
checks['unique_assets_checked']=len(unique)
checks['field_records']=len(F);checks['asset_assignments_and_inventory']=len(A['assets'])
for store in ['apple','google']:
 for loc in ['en-US','en-GB','en-AU']:
  desc=[f for f in F if f['store']==store and f['locale']==loc and f['page_type']=='default' and f['field_label'] in ['Description','Full description']]
  assert len(desc)==1 and 1000<len(desc[0]['value'])<=4000
checks['complete_default_listings']=6
checks['google_complete_family_listings']=sum(f['page_type']=='custom_store_listing' and f['field_label']=='Full description' for f in F)
checks['apple_family_promotional_localizations']=sum(f['page_type']=='custom_product_page' and f['field_label']=='Promotional Text' for f in F)

handover=(OUT/'handover-intro.md').read_text()+ '\n\n## Exact field/action appendix\n\n'
for store in ['apple','google']:
 for page in dict.fromkeys(f['page_type'] for f in F if f['store']==store):
  handover+=f'### {store.title()} — {page}\n\n'
  handover+='| Record / locale | Section / exact field | Action / exact value or absolute source | Count / cap / remaining | Bucket / order | Dependencies / observed |\n|---|---|---|---|---|---|\n'
  for f in F:
   if f['store']!=store or f['page_type']!=page:continue
   if f['source_file']:val=f"[UTF-8 source]({f['source_file']})" + (f" — {f['value']}" if '\n' not in f['value'] and len(f['value'])<100 else '')
   elif f['asset_path']:val=f"[Asset]({f['asset_path']})"
   else:val=json.dumps(f['value'],ensure_ascii=False)
   count=f"{f['character_count']} chars / {f['utf8_byte_count']} bytes; cap {f['limit']} {f['limit_unit']}; remaining {f['remaining_capacity']}" if isinstance(f['value'],str) else 'N/A'
   row=[f"{f['id']} / {f['locale'] or 'shared'}",f"{f['console_section']} > **{f['field_label']}**",f"**{f['action']}**: {val}",count,f"{f['device_bucket'] or 'N/A'} / {f['upload_order'] or 'N/A'}",'; '.join(f['dependencies'])+f"; navigation observed: {f['navigation_verified']}; {f['status']}"]
   handover+='| '+' | '.join(x.replace('|','/').replace('\n',' ⏎ ') for x in row)+' |\n'
  handover+='\n'
(OUT/'BROWSER_HANDOVER.md').write_text(handover)
ledger=dict(status='TEMPLATE ONLY; no execution performed',entries=[dict(record_id=None,store=None,app_id=None,locale=None,page=None,field_label=None,before_value=None,after_value=None,before_asset_paths=None,after_asset_paths=None,console_count=None,saved_state=None,screenshot_path=None,observed_at=None,verification=None)])
(OUT/'execution-log.template.json').write_text(json.dumps(ledger,indent=2)+'\n')
summary=dict(date='2026-10-18',result='PASS' if not fail else 'FAIL',checks=dict(checks),failures=fail,unknown_limit_fields=[f['id'] for f in F if isinstance(f['value'],str) and f['limit'] is None])
(OUT/'validation-results.json').write_text(json.dumps(summary,indent=2)+'\n')
lines=['# Validation and unresolved dependencies\n','Prepared18October2026. Proposed/unapproved. **'+summary['result']+'** for local consistency; this does not certify store approval or release behavior.\n','## Reproducible checks\n','Run `python3 docs/app-store/aso-study/build_deliverables.py` then `python3 docs/app-store/aso-study/validate_deliverables.py` from the project root. The scripts write only this study directory and do not call live services. `report-research.md` and `handover-intro.md` are source documents; generated REPORT/BROWSER files should not be hand-edited.\n','| Check | Result |\n|---|---:|']
for k,v in checks.items():lines.append(f'| {k.replace("_"," ")} | {v} |')
lines+=['\nCounts use Python `len(saved_string)` for Unicode code points and `len(saved_string.encode("utf-8"))` for bytes, including spaces/punctuation/LF line breaks. No BOM, CRLF or trailing newline is inserted. All listing copy and ASCII keyword fields avoid grapheme/UTF-16 ambiguity. Some language-selection strings contain an en dash; byte and character counts correctly differ. They are selectors, not pasted description text.\n','Apple Keywords UI says Characters remaining while technical documentation says100UTF-8bytes. Proposed ASCII strings make those counts identical. No padding to maximum. Unknown URL/selection/internal-name caps are recorded null and counted, without claiming a verified pass against an invented limit. Product names/descriptions use conservative30/45IAP limits; subscription form counter remains a check.\n','Descriptions are plain UTF-8; report code blocks, JSON values and files were compared exactly. Full six default listings present. Google family full descriptions and Apple family promotional text supplied for all3locales; Apple CPP inherits default name/subtitle/description. Counts for every proposed text field are below and in REPORT. No app tests were run: app source was not changed.\n','## Limits and minimal owner decisions\n','1. Approve the proposed copy, default/family orders and still creative assignments. Existing still approval is preserved; this recommendation is not self-approved. Loops await playback approval.\n2. Supply actual copyright holder/year and review contact/access, and confirm privacy/rating/rights/account/commercial declarations from release evidence. No secrets or guessed legal values are populated.\n3. Complete and approve real Android/iPad captures plus Google feature graphics. The current universal iOS target makes iPad a blocker. Optional Google tablet promotion work is distinct.\n4. Confirm release candidate, physical-device feature tests and intended manual/managed publication. Apple currently automatically releases on approval; Google requires closed test/production access.\n','These decisions do not authorize live changes in this run. Detailed null rows in listing-fields identify each dependent action.\n','## Evidence limitations\n','- Native store query ranks, volumes, difficulty and a first-party conversion baseline are unavailable. Apple API/Google desktop observations are clearly labeled proxies, not paid/organic rank measurements.\n- Apple official instructions establish latest-approved-version Keywords as the CPP source; they do not expressly enumerate title/subtitle exclusion. The real selector is unavailable preapproval. Exact title-query routing is therefore unverified and blocked; supported recommendation keeps it on default. No deduplication rule is passed off as proof.\n- Google custom keyword bundles and exact matching variations cannot be inspected until the main listing exists/published and controls are available. Candidate targeting is a proposal requiring selector verification.\n- Public pricing catalogs can include multiple offers and old entries. No competitor paywall or Travary price/trial is invented. Annual AU59.99/year was observed; other product/region prices not fully audited.\n- Real-device widget, offline saved-file, pass-sharing, purchase and flight checks remain release gates. Daily import limit25 is in local server code; deployed parity must be checked.\n- Store declarations are not certified by public policy-page reachability. Analytics retention/integration/attribution and genuine-booking event coverage need checks. No deterministic page-to-revenue attribution is established.\n- Counter/preview/publishing verification was not simulated through a live save. The handover distinguishes observed and documented paths; no live modification occurred.\n','## Every text-field count\n','Exact value appears at its record in REPORT and in linked source. RemainingN/A means no verified cap or a non-text selector; not a failed required field.\n','| Record | Characters | UTF-8 bytes | Limit / unit | Remaining | Result |\n|---|---:|---:|---|---:|---|']
for f in F:
 if isinstance(f['value'],str):lines.append(f"| [{f['id']}]({f['source_file']}) | {f['character_count']} | {f['utf8_byte_count']} | {str(f['limit'])+' '+str(f['limit_unit']) if f['limit'] is not None else 'Unverified/N/A'} | {f['remaining_capacity'] if f['remaining_capacity'] is not None else 'N/A'} | {f['validation']} |")
if fail:lines+=['\n## Failures\n']+fail
(OUT/'VALIDATION.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({k:v for k,v in summary.items() if k!='unknown_limit_fields'},indent=2))
if fail:raise SystemExit(1)
