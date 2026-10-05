# Onboarding reveal: shared motion, destination stills

5 October 2026. The owner welcomed the new coral spinner arrival screen, raised the cost of generating destination-specific videos, and suggested reusing the earlier scenic background. They subsequently authorised starting the reusable reveal and asked for colourful animated text. This proposal preserves the destination reveal while avoiding a video library for every place. A [Bali reveal still and live text-motion study](mockups/onboarding-reveal-v1/README.md) now explore it; no new video was generated.

## Recommended structure

Use **one shared reveal choreography**, a separate Travi foreground performance, and the selected destination's existing still artwork. The destination controls which illustration appears; it does not require a newly rendered film.

Proposed sequence:

1. Confirm the chosen destination in the normal picker and preserve its real name in live UI.
2. Travi glances towards the workshop, makes a small anticipatory lean, then presents the view with delighted surprise.
3. The teal paper stage opens like a theatre. The destination illustration rises into view as a full scenic background, continuing behind Travi into the cream workshop floor. Animate the whole image with native masks and transforms for the first prototype. The owner confirmed the full colourful composition; the small postcard in the early typography study does not define this screen's final layout.
4. Travi returns his gaze to the traveller and gives a proud small nod. The destination remains visible as the heading changes to “When do we leave?” and date controls become available.

Keep the camera, cream control floor and character scale coherent with [the arrival screen](mockups/onboarding-arrival-v1/README.md). Motion can settle immediately when the traveller advances; the selected destination and useful controls remain reliable.

## Existing artwork and limitations

The repository has **30 countdown postcard images** in destination art-pack sources: 25 country scenes and five more specific city/region scenes. Five landscape trip postcards are already in the source packs. An additional [25 generated country landscape postcards](../art_packs/generated/trip_postcards/README.md) are staged for import; their README explicitly says they are not installed or published by that batch.

Existing source art includes [Bali](../art_packs/originals/region_id_bali/common/trip_postcard.png) and [Kyoto](../art_packs/originals/city_jp_kyoto/common/trip_postcard.png). The app already animates a still postcard and luggage tag in [CountdownTripHero](../lib/design/widgets/countdown_trip_hero.dart), and resolves verified destination artwork in [TravelStore](../lib/state/travel_store.dart). The proposed onboarding reveal is a new composition; these existing components are evidence of reusable material and motion patterns, not an implemented onboarding.

These images are flattened illustrations. Moving one picture can create an attractive reveal, but cannot independently unfold buildings, mountains, water or foliage. True internal paper unfolding or parallax needs deliberately authored separate layers. Do not claim those layers already exist.

The owner's supplied scenic reference is clearly Balinese: temple gates, tiered shrine, terraces and a volcanic coast. Use that exact imagery for Bali, or as an art-direction reference. Resolve matching city/region/country art for other destinations, and use a beautiful place-neutral illustration where matching art is unavailable. Do not label a Bali scene as another selected destination.

The older scenic reference includes part of the earlier wide suitcase at the bottom. A clean scene asset must remove that earlier character before combining it with the selected coral spinner. Background preparation is separate from video generation.

## Production scope

First prove the shared native reveal with Bali and a second existing destination still. Make one neutral fallback. Reuse Travi's poses or an articulated character animation across all scenes; add independent scenic layers only where they materially improve the result.

A generated arrival clip can still use the fixed workshop setting. A full-scene MP4 containing Travi and Bali cannot simply become a reusable character overlay for other backgrounds; it has the backdrop baked in. Keep character animation and scene artwork separate for the destination reveal.

No per-destination video rendering or per-user image generation is needed for this approach. There is still work in character animation, clean artwork, motion implementation and device validation. Inspect cropping, quiet copy areas, fallback/loading states and Reduce Motion in the prototype.

The [reveal composition](mockups/onboarding-reveal-v1/bali-reveal-screen-v1.png) combines the approved spinner with the Bali reference and a single coral headline accent. The owner selected the word-based **Paper words** entrance. The early typography study compares small Bali and Kyoto postcards; a newer [connected journey prototype](mockups/onboarding-journey-v1/README.md) now proves the full colourful stage with separate clean Bali/Kyoto plates, a transparent Travi pose, the existing arrival/idle films and real local date selection.

The destination reveal moves the whole scene and character pose. Internal scenic parallax and articulated facial/hand acting remain separate production work. The booking-folio interaction and Flutter integration are still to build. No new video was generated for the connected reveal.

Future scenery follows the [destination art expansion guide](ONBOARDING_DESTINATION_ART.md). Its approved clean-stage reference, reusable generation brief and [continuing asset register](onboarding/DESTINATION_ART_REGISTER.md) make each new place one scenic plate rather than another full-scene video. Record new destination/shared asset requirements there as onboarding work proceeds.
