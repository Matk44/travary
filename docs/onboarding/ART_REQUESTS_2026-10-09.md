# Art requests for GPT — 9 October 2026

The owner wants Travi's films to follow the destination the traveller chose,
not only Bali. Today every post-destination film (booking reaction, sign-in,
pass presentation) has the Bali scenery baked in, and no other destination
has a film. The 30 city stages in `art_packs/pending/onboarding/` share the
Bali stage's exact layout (851 × 1848, same wall, scenery band, floor line).

**The plan:** generate Travi's approved acting once, on a flat chroma-green
background. The app keys out the green and plays Travi as a transparent layer
over whichever stage fits the destination (city → country → the default
"Anywhere" stage). One set of films then covers every destination, and a new
destination only ever needs one still stage. A test key of the existing
transparent pass-desk Travi over the Paris stage came out clean, at about
1.3–1.7 MB per 4-second shot.

**Approval order is unchanged:** GPT makes the stills below, the owner
approves them, and only then are the films generated.

## A. Green-screen plates for the films (top priority)

These are green versions of the five plates the approved films were made
from. They are not new compositions. Use each original as the reference and
change only the background.

| New file | Approved original (reference) | Films it feeds |
|---|---|---|
| `green-folio-v1.png` | `docs/mockups/onboarding-booking-handoff-v1/folio-text-free-v1.png` | save reaction (first frame) |
| `green-proof-v1.png` | `docs/mockups/onboarding-booking-handoff-v1/proof-text-free-v1.png` | save reaction (last), card reaction, pass presentation (first), account entry (first) |
| `green-account-v1.png` | `docs/mockups/onboarding-account-motion-v1/account-text-free-v1.png` | account entry (last), invitation idle, email gesture (first), success and guest handoffs (first) |
| `green-email-v1.png` | `docs/mockups/onboarding-account-motion-v1/email-text-free-v1.png` | email gesture (last), email idle |
| `green-pass-v1.png` | `docs/mockups/onboarding-booking-handoff-v1/pass-text-free-v1.png` | pass presentation, success and guest handoffs (last) |

Save them in `docs/mockups/onboarding-green-plates-v1/` with the exact prompt
used for each.

Prompt (fill in the bracket for each plate):

```text
Use case: compositing (chroma key).
Input 1 is an owner-approved Travary frame: [ORIGINAL FILE].
Keep Travi (the coral ribbed spinner suitcase), the navy folio, and any card,
identity tag, envelope or blank pass exactly as they are: same pose, scale,
position, expression, lighting and paper detail, pixel-aligned to Input 1.

Replace everything else (sky, wall, theatre wings, scenery and the cream
floor) with one perfectly flat, evenly lit chroma green, #00B140, edge to edge.
No floor, horizon, shadow, reflection, gradient, vignette or texture on the
green. No green tones or green spill on Travi, the folio or the paper.
Crisp edges, no motion blur.

Output a 941 × 1672 portrait PNG (the films' 9:16 frame), same framing as
Input 1. No text, labels, buttons, prices, UI, logo, watermark or extra
objects.
```

Check before handing over: Travi and the folio overlay the original exactly
(flip between the two), wheels and the folio's base sit on the same line as
in the original, and nothing green remains on the characters. The plates stay
in the films' 9:16 frame; the app lines Travi's floor up with each stage's
floor when it composites them.

**Films afterwards (after owner approval, not GPT):** Scene Studio regenerates
the same nine shots with the same prompts (`requests.json` in
`onboarding-account-motion-v1/` and the booking handoff jobs), using the green
plates as first/last frames, plus: *"locked-off camera, no zoom, pan or
reframing; flat #00B140 background throughout."* The camera has to stay still
because the stage behind Travi is a still image. Claude keys and packages them.

## B. The default "Anywhere" stage (top priority)

For every destination without its own stage. Today those fall back to the
neutral workshop (`assets/onboarding/empty-stage-v1.png`). That image is
890 × 1767, framed differently and has a folio and tickets painted on its
floor, so the shared Travi/folio layers can't sit on it.

- `art_packs/pending/onboarding/anywhere/onboarding_stage_v1.png`, 851 × 1848.
- Follow the composition contract and brief in
  [ONBOARDING_DESTINATION_ART.md](../ONBOARDING_DESTINATION_ART.md), with the
  prop-free Bali stage as Input 1.
- The scenery band shows a place-neutral paper holiday (sea, rolling hills,
  sun, clouds, a winding road), in the spirit of the app's
  `trip_postcard_anywhere`. No landmark, flag, architecture style or
  vegetation that reads as one country. It sits behind "Paris" just as well
  as behind "Grandma's".

## C. Country stages (fills the gaps between cities)

A traveller going to Kyoto, Paris or one of the other 30 cities gets that
city's stage. Anyone else in those countries (Nice, Hiroshima, Cairns) needs
a country stage, otherwise they get the Anywhere stage. 24 are needed;
Singapore reuses its city stage. The register lists each with its reference
postcard: [DESTINATION_ART_REGISTER.md](DESTINATION_ART_REGISTER.md).

Suggested order (most-travelled first): United States, United Kingdom,
France, Italy, Spain, Japan, Australia, Mexico, Thailand, Greece, Portugal,
Germany, Canada, Turkey, United Arab Emirates, Netherlands, Indonesia,
New Zealand, South Korea, Switzerland, India, China, Brazil, South Africa.

Save each as `art_packs/pending/onboarding/country_<code>/onboarding_stage_v1.png`.

## D. Kyoto without props

`assets/onboarding/kyoto-stage-v1.png` still has the folio and tickets painted
on its floor, so the shared folio layer would appear twice. One edit: remove
them and continue the floor, changing nothing else. Save as
`art_packs/pending/onboarding/city_jp_kyoto/onboarding_stage_v1.png`.

## Not needed

- Per-destination films (the green layer covers every place).
- Sign-in buttons, the "Signed in" check, pass names and prices: all live UI.
- The arrival films: they play before a destination is chosen, on the neutral
  workshop, and stay as they are.

## Delivery — 9 October 2026

**31/31 stills generated for owner review** with built-in imagegen, saved at every requested path. [Review gallery](../mockups/onboarding-art-requests-2026-10-09/index.html) · [Claude handoff and exact prompts](../mockups/onboarding-art-requests-2026-10-09/README.md) · [Manifest / sizes / hashes](../mockups/onboarding-art-requests-2026-10-09/manifest.json).

The 24 countries, Anywhere and prop-free Kyoto are review-ready still candidates. The five green plates are drafts: their green has slight colour variation, and the model did not preserve foreground pixels exactly. Check original/generated overlay registration and prepare a flat key/matte before films. Proof is 940 × 1672 (the original is also 940 wide); Greece is 851 × 1847. All other measured sizes match this request. These technical findings are recorded in the handoff; the masters remain unchanged.

No new film generated and no native assets replaced. Owner approval of these new stills remains pending; the film step in section A follows that approval and technical preparation.

## Integrated — 9 October 2026

- The 24 country stages, Anywhere and the prop-free Kyoto are in the app
  (`assets/onboarding/stages/`, WebP). All floors measure 1.41 widths, the same
  as the city stages, so the shared Travi and folio stand on each one.
- The five green plates were keyed and put back on perfectly flat `#00B140`
  (`docs/mockups/onboarding-green-plates-v1/green-*-clean-v1.png`, 941 × 1672;
  the proof's missing column is key green, nothing stretched). A difference
  check against the approved frames shows hairline edges only (the proof
  drifts most, about a pixel or two on Travi's right side).
- Next, after the owner approves the plates: Scene Studio regenerates the
  nine shots from the clean plates with a locked camera, then Claude keys
  them into transparent layers.
