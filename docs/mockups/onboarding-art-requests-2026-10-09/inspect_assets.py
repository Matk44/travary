"""Read-only checks of image masters; writes JSON measurements, never image pixels."""
from pathlib import Path
from collections import Counter
import hashlib
import json
from PIL import Image

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[2]
manifest = json.loads((HERE / 'manifest.json').read_text())
report = {'date': '2026-10-09', 'imagesModified': False, 'items': []}
for row in manifest['items']:
    path = PROJECT / row['target']
    with Image.open(path) as image:
        image.load()
        actual = list(image.size)
        rgb = image.convert('RGB')
    desired = [941, 1672] if row['kind'] == 'chroma_plate' else [851, 1848]
    result = {'id': row['id'], 'path': row['target'], 'actualDimensions': actual,
              'requestedDimensions': desired, 'dimensionsMatchRequest': actual == desired,
              'sourceCopyHashMatches': hashlib.sha256(path.read_bytes()).hexdigest() == row['sha256']}
    if row['kind'] == 'chroma_plate':
        sample = list(rgb.crop((200, 40, 600, 150)).getdata())
        colors = Counter(sample)
        mode, count = colors.most_common(1)[0]
        result['greenSample'] = {'boundsXYXY': [200, 40, 600, 150], 'modeRGB': mode,
                                'uniqueRGBCount': len(colors),
                                'exactRequestedRGBFraction': round(colors.get((0, 177, 64), 0) / len(sample), 6),
                                'maxChannelDeviationFromRequest': max(abs(c[i] - (0, 177, 64)[i]) for c in colors for i in range(3))}
        with Image.open(PROJECT / row['reference']) as original:
            old = original.convert('RGB')
        height = min(old.height, rgb.height)
        width = min(old.width, rgb.width)
        old, new = old.crop((0, 0, width, height)), rgb.crop((0, 0, width, height))
        # Broad green exclusion is a measurement heuristic, not an alpha matte.
        compared, exact, total_diff = 0, 0, 0
        for a, b in zip(old.getdata(), new.getdata()):
            r, g, blue = b
            if g > 110 and g > r * 1.8 and g > blue * 1.4:
                continue
            compared += 1
            exact += a == b
            total_diff += sum(abs(a[i] - b[i]) for i in range(3))
        result['foregroundComparisonHeuristic'] = {
            'overlapPixelsCompared': compared,
            'meanAbsoluteRGBDifference': round(total_diff / (3 * compared), 3),
            'exactRGBPixelFraction': round(exact / compared, 6),
            'note': 'Unregistered same-coordinate RGB comparison using broad green exclusion; not a validated matte or alignment proof.'}
        result['productionStatus'] = 'needs_flat_key_and_foreground_registration_validation'
    else:
        result['productionStatus'] = 'owner_review_then_native_overlay_checks'
    report['items'].append(result)
(HERE / 'QA.json').write_text(json.dumps(report, indent=2) + '\n')
print('Decoded and hashed', len(report['items']), 'masters; all source copies match:', all(x['sourceCopyHashMatches'] for x in report['items']))
print('Dimension exceptions:', [(x['id'], x['actualDimensions']) for x in report['items'] if not x['dimensionsMatchRequest']])
print('Green measurements:', [(x['id'], x.get('greenSample')) for x in report['items'] if 'greenSample' in x])
