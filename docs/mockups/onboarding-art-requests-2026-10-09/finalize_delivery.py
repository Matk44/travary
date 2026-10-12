"""Merge this art batch into its manifest and the planning ledger; no app or image edits."""
from pathlib import Path
import json
import copy

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[2]
manifest = json.loads((HERE / 'manifest.json').read_text())
qa = {x['id']: x for x in json.loads((HERE / 'QA.json').read_text())['items']}
requests = {}
for log in sorted(HERE.glob('requests-*.json')):
    requests.update({x['id']: x for x in json.loads(log.read_text())})
assert len(requests) == 31
for row in manifest['items']:
    row['ownerApproval'] = 'pending'
    row['nativeIntegrated'] = False
    row['animationGenerated'] = False
    row['qa'] = qa[row['id']]
    row['status'] = 'generated' if row['kind'] == 'chroma_plate' else 'review_ready'
manifest.update(status='all_stills_generated_owner_review_pending', generationComplete=True,
                generatedCount=31, qaPath='docs/mockups/onboarding-art-requests-2026-10-09/QA.json',
                reviewGalleryPath='docs/mockups/onboarding-art-requests-2026-10-09/index.html')
(HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
green = PROJECT / 'docs/mockups/onboarding-green-plates-v1'
(green / 'PROMPTS.json').write_text(json.dumps([requests[x['id']] for x in manifest['items'] if x['kind'] == 'chroma_plate'], indent=2) + '\n')

ledger_path = PROJECT / 'docs/onboarding/destination-art-registry.json'
ledger = json.loads(ledger_path.read_text())
destinations = {x['destinationId']: x for x in ledger['destinations']}
def stage_record(row):
    request = requests[row['id']]
    return {'status': row['status'], 'masterPath': row['target'], 'dimensions': row['dimensions'],
            'stagingPath': row['target'], 'sha256': row['sha256'],
            'promptLogPath': row['promptLog'], 'generationMode': 'built_in_imagegen',
            'originalGenerationOutputPath': row['source'],
            'inputReferencePaths': request.get('refs', [request.get('ref')]),
            'exactSubmittedPrompt': request['prompt'], 'ownerApproval': 'pending',
            'flutterIntegrated': False, 'publicationEvidence': None, 'lastReviewed': '2026-10-09',
            'qaNotes': row['qa'],
            'nextAction': 'Owner artwork review, then native overlays, floor alignment and rendition checks. Master is unchanged; do not generate motion before approval.'}
for row in manifest['items']:
    if row['kind'] == 'country_stage':
        destinations[row['id']]['onboardingStage'].update(stage_record(row))
    elif row['kind'] == 'prop_removal':
        # Preserve the existing integrated Kyoto asset until the candidate is reviewed/integrated.
        destinations[row['id']]['onboardingStage']['propFreeCandidate'] = stage_record(row)
        destinations[row['id']]['onboardingStage']['nextAction'] = 'Review new prop-free candidate; existing baked-prop native Kyoto remains until Claude integrates the replacement.'
sg = destinations.get('country_sg')
sg_city = destinations.get('city_sg_singapore')
if sg and sg_city and sg_city['onboardingStage'].get('flutterIntegrated'):
    sg['onboardingStage'] = copy.deepcopy(sg_city['onboardingStage'])
    sg['onboardingStage'].update(reusesDestinationId='city_sg_singapore', nextAction='Reuse existing integrated Singapore city-state stage; no new country image requested on 9 October.')
    sg['generationPriority'] = 'reuse'
shared = {x['assetId']: x for x in ledger['sharedAssets']}
for row in manifest['items']:
    if row['kind'] not in ('chroma_plate', 'neutral_stage'):
        continue
    asset_id = 'anywhere_stage_candidate' if row['kind'] == 'neutral_stage' else row['id'].replace('-', '_') + '_candidate'
    record = {'assetId': asset_id, 'storyBeat': 'place-neutral destination fallback' if row['kind'] == 'neutral_stage' else 'shared foreground film keyframe',
              'requiredForEveryNewDestination': False, 'path': row['target'],
              'status': row['status'], 'dimensions': row['dimensions'], 'sha256': row['sha256'],
              'ownerApproval': 'pending', 'nativeIntegrated': False, 'animationRendered': False,
              'promptLogPath': row['promptLog'], 'generationLogPath': 'docs/mockups/onboarding-art-requests-2026-10-09/manifest.json',
              'lastReviewed': '2026-10-09', 'qaNotes': row['qa'],
              'nextAction': 'Owner still review; green cleanup/registration before approved film work.' if row['kind'] == 'chroma_plate' else 'Owner still review, then native fallback integration; neutral arrival workshop stays separate.'}
    if asset_id in shared:
        shared[asset_id].update(record)
    else:
        ledger['sharedAssets'].append(record)
ledger['updatedAt'] = '2026-10-09'
ledger['coveragePolicy']['countryBatch20261009'] = {'requestPath': 'docs/onboarding/ART_REQUESTS_2026-10-09.md',
    'generatedCountryCount': 24, 'status': 'review_ready', 'ownerApproval': 'pending', 'flutterIntegrated': False,
    'singaporeReuse': 'city_sg_singapore', 'galleryPath': manifest['reviewGalleryPath'],
    'anywhereFallback': 'generated candidate; native integration pending', 'animationGenerated': False}
entry = {'date': '2026-10-09', 'action': 'art_requests_still_batch_generated',
         'summary': '31 built-in imagegen stills: five green keyframe drafts, Anywhere, 24 countries, prop-free Kyoto. Green cleanup/registration needed; two measured dimension exceptions. Owner approval and native integration remain separate; no new film generated.',
         'manifestPath': 'docs/mockups/onboarding-art-requests-2026-10-09/manifest.json'}
if not any(x.get('action') == entry['action'] for x in ledger['changeLog'] if isinstance(x, dict)):
    ledger['changeLog'].append(entry)
ledger_path.write_text(json.dumps(ledger, indent=2) + '\n')
print('Recorded 31 stills, exact green prompts and country/shared candidate status; preserved existing native Kyoto.')
