# Profile seams and paper depth correction — 15 October 2026

This supersedes the rejected `profile-polish-v2` rendering. The approved
`../profile-travi-v1/profile-travi-still-v1.png` remains the visual reference.

## What caused the defects

Nine-slicing the textured folio and ticket created visible horizontal and
vertical discontinuities. The separately approximated shadow silhouette
also disagreed with the actual artwork's cut-outs and read as a hard grey
block. The lower settings cards had unnecessary ruled and grid decoration.

## Corrections

- Folio and ticket each paint as one continuous image, with no slicing.
- Their warm, restrained shadow comes from the image's actual alpha,
  translated down and blurred. It follows every corner and notch.
- The Annual Pass paper was refined with built-in imagegen: its tear line
  sits below the native button, and the heavy moulded bevel was replaced
  with a delicate cut-paper edge. The selected bundled asset is
  `assets/art/common/profile_annual_pass_paper.png`; prompts and edit
  provenance are in [PROMPTS.md](PROMPTS.md).
- Lower cards use continuous cream paper, subtle contact/ambient shadows
  and coloured icons. Extra grids, rules and border decorations are removed.
  Help/legal retain the functional row separators. About keeps a simple
  navy surface.
- The compact Annual Pass layout, native controls and purchase/account
  handlers are retained. Travi's regular-size 112 × 124 area is empty for
  the owner's animation. Navigation and the removed leather strip are
  untouched by this correction.

## Native visual verification

These are captures from the running iPhone 17 Pro simulator, after reloading
the corrected implementation, rather than a mockup or a widget-only render:

- [Profile top and Annual Pass](iphone-profile-top.png)
- [Documents, reminders and data](iphone-documents-reminders-data.png)
- [Design tools](iphone-design-tools.png)
- [Help, legal and About](iphone-help-legal-about.png)
- [Passport artwork inside Travel documents](iphone-travel-documents.png)

[Small phone with double-size text](large-type.png) is an additional widget
render using real fonts and enabled shadows.

## Checks

- Full Flutter suite: **1,207 tests pass** in the final isolated run.
- Focused profile/account/documents/reminder checks: **24 tests pass**.
- Final real-font profile render and interaction suite: **6 tests pass**.
- Static analysis: no issues. Changed Dart files are formatted, and
  `git diff --check` is clean.

An earlier full run overlapped a separate Flutter visual-test process and
encountered shared build-asset failures in two city artwork tests. The
complete suite was rerun alone and passed; no city or test logic was changed.

No purchase, sign-in, email or notification action was triggered in the
running app during this visual review.
