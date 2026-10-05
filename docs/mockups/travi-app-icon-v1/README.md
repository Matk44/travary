# Travary: Travi app-icon exploration

5 October 2026. The owner has selected **coral Travi, ribbed spinner** as the mascot and **B — Ticket heritage** as the app-icon direction. [Ticket Heritage variants](TICKET_HERITAGE.md) explore refinements. **Icon work is parked at the owner's request while onboarding proceeds.** The final variant is still open; the owner requested a decision before applying an icon.

## Recommendation

Make Travi the main symbol of the app icon. His suitcase connects to the whole holiday, and the same character can welcome the traveller after they open the app. This is an art-direction judgement, not evidence of a measured recognition or conversion improvement.

The current icon is a cream airplane on a textured navy airline ticket with coral and mustard stripes. Its materials and colours fit the new mascot. The ticket motif can continue in booking cards and other brand artwork.

## Concepts

[icon-directions-v1.png](icon-directions-v1.png) compares three directions:

- **A — Travi portrait:** close-up, tilted ribbed shell and cheerful face on navy. Retained as an exploration record.
- **B — Ticket heritage, selected:** Travi in front of a simplified ticket, retaining the current stripes. The new variants explore face size, ticket framing and stripe treatment within this direction.
- **C — Travi mark:** centred coral suitcase with broad ribs and a cheerful face on petrol teal. Retained as an exploration record.

For the selected Ticket Heritage direction, preserve Travi's raised brows, delighted smile, ribbed shell and clamshell edge. Simplify handle hardware and surface grain in the final refinement. Keep the larger onboarding character's full anatomy and accessories in the character artwork; the icon is a deliberate reduction.

## Validation and production handoff

Reviewed the generated board for mascot identity, coral colour, vertical ribs, expression, composition and labels. These are illustration concepts with rounded corners shown for preview, not platform-ready exports. Actual-size and device-mask checks have not yet been performed.

For the chosen icon, generate a standalone square master and inspect it at 24, 32, 48 and 60 pixels against the existing icon. Evaluate the silhouette and expression without relying on fine texture. Prepare platform-specific exports and layers only after the direction is selected.

[Apple's app-icon guidance](https://developer.apple.com/design/human-interface-guidelines/app-icons) recommends a simple distinctive core idea, a simple background and minimal nonessential text. Supply unmasked artwork for the system's corner treatment.

[Android adaptive-icon guidance](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive) requires foreground and background layers, with critical artwork inside the central safe zone; a separate monochrome layer supports themed icons. [Google Play listing specifications](https://developer.android.com/distribute/google-play/resources/icon-design-specifications) call for a 512 × 512 full-square PNG and apply their own corners and outer shadow. The listing asset and launcher layers are separate deliverables.

Generated with built-in imagegen. [Exact prompt and reference roles](PROMPTS.md). Current assets under `assets/branding`, Android resources and the iOS asset catalog were not changed.
