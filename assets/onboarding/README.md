# Travi onboarding assets

Bundled 6 October 2026 for the first native Flutter integration. These are unchanged copies of the approved local review assets; no image or video was generated for this integration.

| Bundled file | Original |
|---|---|
| `empty-stage-v1.png` | `docs/mockups/onboarding-journey-v1/empty-stage-v1.png` |
| `kyoto-stage-v1.png` | `docs/mockups/onboarding-journey-v1/kyoto-stage-v1.png` |
| `travi-cutout-v2.png` | `docs/mockups/onboarding-journey-v1/travi-cutout-v2.png` |
| `travi-entrance-playback-v1.mp4` | `docs/mockups/onboarding-journey-v1/travi-entrance-playback-v1.mp4` |
| `travi-idle-loop-v1.mp4` | `docs/mockups/onboarding-journey-v1/travi-idle-loop-v1.mp4` |
| `travi-settled-v1.png` | `docs/mockups/onboarding-intro-v1/travi-settled-v1.png` |
| `entrance-start-v1.png` | `docs/mockups/onboarding-intro-v1/entrance-start-v1.png` |
| `bali-stage-prop-free-v1.png` | `docs/mockups/onboarding-folio-motion-v1/bali-stage-prop-free-v1.png` |
| `closed-folio-v1.png` | `docs/mockups/onboarding-folio-motion-v1/closed-folio-v1.png` |
| `open-folio-v2.png` | `docs/mockups/onboarding-booking-folio-v1/open-folio-v2.png` |
| `travi-receiving-v1.png` | `docs/mockups/onboarding-booking-folio-v1/travi-receiving-v1.png` |

Original prompts, references, generation records and motion seam checks remain with those mockup folders. `closed-folio-v1.png` now appears as a separate prop in the optional pass desk; hinged choreography remains future work. The existing Kyoto plate still contains foreground props; separate them before adding independent prop movement there.

The next pass-desk prototype adds three unchanged built-in imagegen masters on 6 October. **Owner still-art review is pending**, and no new film was generated. Their prompts, exact original paths, hashes and alpha metadata are in [the review folder](../../docs/mockups/onboarding-pass-desk-v1/README.md).

| New preview file | Original review master |
|---|---|
| `travi-handoff-v1.png` | `docs/mockups/onboarding-pass-desk-v1/travi-handoff-v1.png` |
| `holiday-pass-shell-v1.png` | `docs/mockups/onboarding-pass-desk-v1/holiday-pass-shell-v1.png` |
| `annual-pass-shell-v1.png` | `docs/mockups/onboarding-pass-desk-v1/annual-pass-shell-v1.png` |

The v1 full pass-desk composition was a review image only. The owner then
approved that composition and rejected the smaller native adaptation. V2
uses a new **text-free atlas**, preserving the full landscape, large Travi,
palm stubs, paper tickets and navy notched button. Its originals, exact edit
prompts and hashes are retained in [the v2 folder](../../docs/mockups/onboarding-pass-desk-v2/README.md).

| Approved-layout file | Purpose |
|---|---|
| `pass-desk-art-v2.png` | Exact Bali composition with lettering, digits and selection controls removed; runtime crops provide hero, shells, button and blank paper |
| `pass-desk-foreground-v2.png` | Shared transparent Travi/folio layer for other country stages; review matte and alignment as each stage is added |

Prices, pass titles/scope, selected state and actions are native. The old
US$7.99 reference is not a runtime price. Offline defaults are $14.99 and
$34.99; a configured RevenueCat offering supplies actual packages and
localized store prices. [Configuration](../../docs/REVENUECAT_OFFER_CATALOG.md).
No new film was generated.

Country-first expansion remains in [the art register](../../docs/onboarding/DESTINATION_ART_REGISTER.md), with [the prop-free reference](../../docs/ONBOARDING_DESTINATION_ART.md). Add one approved country stage to this folder and its ISO code/path to `onboardingCountryStages` in `lib/logic/onboarding_art.dart`. Its cities inherit it. Bali and Kyoto remain specific exceptions; unillustrated places use the neutral workshop with their actual name in live text. No destination-specific film is required.

See [the native integration notes](../../docs/ONBOARDING_NATIVE.md) for playback, draft persistence and QA limits.

## 9 October: account films and destination stages

At the owner's request (“the films should change with the destination”):

| Folder | Contents |
|---|---|
| `films/` | Unchanged copies of the six approved account films from `docs/mockups/onboarding-account-motion-v1/` (entry, idle, email gesture and idle, signed-in and guest handoffs to the desk), plus WebP renditions (quality 86) of their settled stills: `account-text-free-v1`, `email-text-free-v1`, `proof-text-free-v1`, `pass-text-free-v1`. These have Bali's scenery in them, so only Bali plays them. |
| `stages/` | The 30 review-ready city stages from `art_packs/pending/onboarding/` (latest version of each), as 851-wide WebP (quality 84). The originals stay there. |

Other places show their own stage behind the settled Travi and folio. The
request for shared green-screen films that would let Travi move on every
stage is in `docs/onboarding/ART_REQUESTS_2026-10-09.md`.

Later on 9 October: GPT's 24 country stages, the place-neutral Anywhere stage
and a prop-free Kyoto (`art_packs/pending/onboarding/`) were added to
`stages/` the same way. The old bundled `kyoto-stage-v1.png` (painted folio
and tickets) was removed from the bundle; its identical master stays in
`docs/mockups/onboarding-journey-v1/`.
