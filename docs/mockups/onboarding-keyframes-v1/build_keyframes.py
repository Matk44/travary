#!/usr/bin/env python3
"""Puts the onboarding key frames on ONE camera for the films.

ChatGPT draws each frame by eye, so Travi drifts (up to ~20% in size and
~100 px sideways) and the folio wanders. A film can only join cleanly where
two films share a frame, and between frames Travi must not slide or grow, so
every frame is lined up here before any film is made:

- Travi is scaled and moved so his wheels sit exactly where they are in the
  reference (Image 1, the ID-tag pose): the same wheel span, centre and
  floor line.
- Where the folio stands at the left on its own, it's replaced by the one
  canonical folio (frame 01's) in its one place, so it never moves.
- The whole shot is then set a little smaller and further left than the
  reference (CAMERA), which stands Travi almost against the right edge:
  there, a wave or raised arm leaves the screen.
- The green is made perfectly flat #00B140.

Output: registered/NN-name.png (941 x 1672, on green, for the films) and
registered/contact.png. Needs numpy, Pillow and SciPy:
    python3 -m venv /tmp/kf && /tmp/kf/bin/pip install numpy pillow scipy
    /tmp/kf/bin/python docs/mockups/onboarding-keyframes-v1/build_keyframes.py
"""
import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
REFERENCE = os.path.join(HERE, '../../onboarding/chatgpt-poses/image-1-camera.png')
OUT = os.path.join(HERE, 'registered')
W, H = 941, 1672
GREEN = np.array([0, 177, 64], np.float32)  # #00B140

# Frames: name -> (file, how the folio is handled)
#   'standing': on its own at the left: replaced by the canonical folio.
#   'split':    standing at the left but touching Travi's prop: everything
#               left of FOLIO_SPLIT is replaced by the canonical folio.
#   'carried':  Travi holds it: it moves with him.
#   'as-is':    already on the reference camera, untouched.
FRAMES = {
    '01-empty': ('frame-01-empty-v3.png', 'empty'),
    '02-hello': ('frame-02-hello.png', 'standing'),
    '03-wow': ('frame-03-wow.png', 'standing'),
    '04-tag': ('frame-04-tag.png', 'standing'),
    '05-toss': ('frame-05-toss.png', 'standing'),
    '06-folio-open': ('frame-06-folio-open.png', 'carried'),
    '07-folio-full': ('frame-07-folio-full.png', 'full'),
    '08-reading': ('frame-08-reading.png', 'standing'),
    '09-card': ('frame-09-card.png', 'split'),
    '10-proud': ('frame-10-proud.png', 'standing'),
    'id-tag': (REFERENCE, 'as-is'),
    '11-envelope': ('frame-11-envelope.png', 'as-is'),
    '12-linked': ('frame-12-linked.png', 'carried'),
    '13-present': ('frame-13-present.png', 'standing'),
    '14-cheer': ('frame-14-cheer.png', 'standing'),
    '15-wave': ('frame-15-wave.png', 'carried'),
    '16-oops': ('frame-16-oops.png', 'standing'),
}
# The standing folio never reaches past this column; Travi's wheels start
# after it.
FOLIO_SPLIT = 440

# The final camera from the reference's: scaled about the floor (y = 1176)
# so the folio's left edge (x = 141) lands at x = 45 and the widest gesture
# (the wave's hand) still fits.
CAMERA_SCALE = 0.95


def camera(point):
    x, y = point
    return (45 + (x - 141) * CAMERA_SCALE, 1176 + (y - 1176) * CAMERA_SCALE)


def load(path):
    im = Image.open(os.path.join(HERE, path)).convert('RGB')
    if im.size != (W, H):  # one frame came back a pixel short
        im = im.resize((W, H), Image.LANCZOS)
    return np.asarray(im).astype(np.float32)


def keyed(im):
    """RGBA float: green-difference key, spill pulled from soft edges."""
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    alpha = 1 - np.clip((g - np.maximum(r, b) - 30) / 50, 0, 1)
    out = im.copy()
    edge = alpha < 0.98
    out[..., 1] = np.where(edge, np.minimum(g, np.maximum(r, b)), g)
    return np.dstack([out, alpha])


def components(alpha):
    lab, n = ndimage.label(alpha > 0.5)
    return lab, [i for i in range(1, n + 1) if (lab == i).sum() > 400]


def travi_mask(rgba, how):
    """Travi (and whatever he carries), without a standing folio."""
    alpha = rgba[..., 3]
    if how in ('carried', 'as-is', 'full'):
        return alpha > 0.02
    lab, ids = components(alpha)
    if how == 'split':
        cols = np.arange(W)[None, :]
        return (alpha > 0.02) & (cols >= FOLIO_SPLIT)
    # standing: drop the component that sits left of the split.
    keep = np.zeros_like(alpha, bool)
    for i in ids:
        xs = np.nonzero(lab == i)[1]
        if xs.mean() >= FOLIO_SPLIT:
            keep |= lab == i
    # Soft edges belong to whichever part they touch.
    grown = ndimage.binary_dilation(keep, iterations=3)
    return grown & (alpha > 0.02)


def footprint(rgba, mask):
    """Travi's footing: wheels (black pixels near his lowest point: left,
    right, bottom) and his height from the top of his handle's grip."""
    rgb = rgba[..., :3]
    ys, xs = np.nonzero(mask)
    bottom = float(ys.max())
    black = (rgb.sum(axis=2) < 110) & mask
    by, bx = np.nonzero(black)
    near = (by > bottom - 45) & (bx >= FOLIO_SPLIT - 40)
    navy = (rgb[..., 2] > rgb[..., 0] + 15) & (rgb[..., 2] > rgb[..., 1]) & (rgb[..., 0] < 90) & (rgb[..., 1] < 90) & mask
    top = float(np.nonzero(navy)[0].min())
    return dict(left=float(bx[near].min()), right=float(bx[near].max()), bottom=bottom, height=bottom - top)


def fit(src, ref):
    """Scale and the source point that lands on the reference's.

    Height (grip to wheels) sets the scale; the wheel span agrees within a
    few percent when both wheels show, and then their centre is the anchor.
    A hidden or lifted wheel (a lean back) leaves the right wheel."""
    s = ref['height'] / src['height']
    span = (ref['right'] - ref['left']) / (src['right'] - src['left'])
    if abs(span / s - 1) < 0.12:
        s = (s + span) / 2
        return s, ((src['left'] + src['right']) / 2, src['bottom']), ((ref['left'] + ref['right']) / 2, ref['bottom'])
    return s, (src['right'], src['bottom']), (ref['right'], ref['bottom'])


def place(rgba, mask, s, src, dst):
    """Scales the masked layer by `s` about `src`, landing it on `dst`."""
    (x0, y0), (x1, y1) = src, dst
    layer = rgba.copy()
    layer[..., 3] *= mask
    # Premultiply, resample, unpremultiply (no green fringes).
    pre = layer.copy()
    pre[..., :3] *= pre[..., 3:4]
    # Output pixel (x, y) samples source ((x - x1) / s + x0, (y - y1) / s + y0).
    coeffs = (1 / s, 0, x0 - x1 / s, 0, 1 / s, y0 - y1 / s)
    chans = [
        np.asarray(Image.fromarray(pre[..., c]).transform((W, H), Image.AFFINE, coeffs, Image.BICUBIC))
        for c in range(4)
    ]
    out = np.dstack(chans)
    a = np.clip(out[..., 3:4], 0, 1)
    out[..., :3] = np.where(a > 1e-4, out[..., :3] / np.maximum(a, 1e-4), 0)
    out[..., 3:4] = a
    return out


def over(dst, layer):
    a = layer[..., 3:4]
    return dst * (1 - a) + np.clip(layer[..., :3], 0, 255) * a


def main():
    os.makedirs(OUT, exist_ok=True)
    ref = keyed(load(REFERENCE))
    # The reference's wheels (its folio touches Travi, so look right of it).
    target = footprint(ref, ref[..., 3] > 0.02)
    empty = keyed(load(FRAMES['01-empty'][0]))
    anchor = (141.0, 1176.0)
    # The one canonical folio, in its one place.
    folio = place(empty, np.ones((H, W), np.float32), CAMERA_SCALE, anchor, camera(anchor))
    log = {'reference': target, 'camera_scale': CAMERA_SCALE}
    for name, (path, how) in FRAMES.items():
        rgba = keyed(load(path))
        canvas = np.broadcast_to(GREEN, (H, W, 3)).copy()
        if how == 'empty':
            canvas = over(canvas, folio)
            log[name] = {'folio': 'canonical'}
        elif how == 'full':
            # Its own shot (the folio up against the lens): kept as drawn.
            canvas = over(canvas, rgba)
            log[name] = {'untouched': True}
        elif how == 'as-is':
            layer = place(rgba, np.ones((H, W), np.float32), CAMERA_SCALE, anchor, camera(anchor))
            canvas = over(canvas, layer)
            log[name] = {'camera_only': True}
        else:
            mask = travi_mask(rgba, how)
            foot = footprint(rgba, mask)
            s, src, dst = fit(foot, target)
            layer = place(rgba, mask.astype(np.float32), s * CAMERA_SCALE, src, camera(dst))
            if how in ('standing', 'split'):
                canvas = over(canvas, folio)
            canvas = over(canvas, layer)
            log[name] = {'footing': foot, 'scale': round(s, 4), 'anchor': [src, dst],
                         'folio': 'canonical' if how in ('standing', 'split') else 'carried'}
        Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8)).save(os.path.join(OUT, f'{name}.png'))
        print(name, json.dumps(log[name]))
    with open(os.path.join(OUT, 'build.json'), 'w') as f:
        json.dump(log, f, indent=2)


if __name__ == '__main__':
    main()
