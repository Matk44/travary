# Profile depth and complete stationery — 15 October 2026

**Rejected and superseded:** the owner rejected this rendering for visible
card seams and unrealistic shadows. See [the corrected implementation and
native simulator screenshots](../profile-refinement-v3/README.md).

Owner correction: the initial implementation looked flat, the Annual Pass
had too much space, and the remaining profile rows needed the same care.
The approved `../profile-travi-v1/profile-travi-still-v1.png` remains the
art reference. No new image or animation was generated.

## Changes

- The folio and Annual Pass now have additional ambient and contact shadows
  painted behind their silhouettes. Pass shadows respect both pairs of
  notches and leave transparent corners clear.
- Annual Pass uses smaller internal gaps, a tighter allowance badge and
  less space between the benefits and action. Its empty animation region
  is 112 × 124 logical points at regular sizes. On narrow screens or with
  large text, the benefits take the width without an empty extra row.
- The document pocket has the same raised paper edge and shadows as the
  remaining profile cards.
- Reminders is a coral-ruled memo; data is a sage-marked folder card; debug
  design tools sit on faint teal grid paper. Support/email use a coral
  correspondence edge, privacy/terms share a perforated paper panel, and
  About is a navy bookplate with a brass frame.
- Sign-in, renewal/restore, document navigation, reminders, demo reset,
  design tools, time preview and every help/legal action retain their
  existing handlers and conditions. Navigation and the separate Travi
  image are unchanged.

The new paper styling lives in `lib/design/widgets/profile_stationery.dart`;
colour/type tokens remain in `lib/design/tokens.dart`.

## Rendered review

Real fonts and actual soft shadows, at 402 × 874 points:

- [Profile top](profile-top.png).
- [Pass and document pocket](profile-pass-documents.png).
- [Reminders and data](reminders-data.png).
- [Design tools](design-tools.png).
- [Help, legal and About](help-legal-about.png).
- [Lower cards at 320 × 568 and 2× text](large-type.png).

The visual helper enables Flutter shadows during capture, then restores the
test setting; the standard test setting otherwise produces solid shadow
shapes instead of the blurred depth seen on a device.

## Verification

- Full Flutter suite: **1,207 tests pass**.
- Focused profile/account/documents/reminder checks: **24 tests pass**.
- Final spacing review: profile/account checks pass with real fonts.
- Static analysis reports no issues; `git diff --check` is clean.
- iOS simulator debug build succeeds.

The new lower-screen checks cover the reminder switch, every section's
reachability, and overflow on a small phone with double-size text. No
production purchase, sign-in, email or support message was sent.
