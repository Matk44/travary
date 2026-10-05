# First onboarding screen: meet Travi

5 October 2026. The owner asked to start with the first screen's art direction, approve it, then generate video. This still uses the selected **coral ribbed spinner**. The approved direction now has an [entrance, waiting loop and playable intro](../onboarding-intro-v1/README.md); production onboarding integration remains separate.

## Purpose and composition

The traveller meets Travi in a small destination-neutral paper departure workshop. He has just arrived and is eager to learn where they are going. The holiday landscape appears after their own destination choice, preserving a meaningful first reveal.

[arrival-screen-v1.png](arrival-screen-v1.png) shows the intended settled end pose of the roll-in. Its quiet header contains the Travary wordmark, “Where are we off to?” and “Let's bring your holiday to life.” The middle stage gives Travi physical space, a grounded wheeled silhouette and a clear entry path from the left. A small closed folio and blank ticket slips hint at his organising role.

The cream floor holds one luggage-tag primary action, **Choose a destination**, followed by **Already have a booking?** and **Joining a holiday?** The primary action opens the native destination search. Using a single selector avoids asking someone to tap both an empty destination field and a duplicate Continue button. This interaction is proposed for the new onboarding; it has not been implemented.

## Review before animation

Reviewed the generated still for coral spinner identity, vertical ribs, closed case, joyful open eyes, two folded-paper arms, grounded wheels, a destination-neutral set, the single destination tag and the requested copy. The folio sits farther back than the wheel path; maintain this depth separation when animating the arrival.

The owner welcomed this direction and subsequently asked to create the intro with a waiting loop. This still does not demonstrate actual touch targets, screen-reader behaviour, keyboard handling, responsive layout or device performance. The local intro prototype begins that interaction review; native device performance remains to be checked during integration.

## Motion handoff after art approval

1. Lock the selected screen composition and create separate text-free artwork for the stage and character. Keep all headings, destination controls and links as live Flutter UI.
2. Prepare an empty-stage start and the approved settled pose as matching references. Maintain the same locked camera, character identity, light and control-safe areas.
3. Use the local Scene Studio workflow to explore Travi rolling in from the left, braking a little too eagerly, recovering with a grin and giving a welcoming gesture. The result ends in the settled pose. No destination unfolds in the arrival shot.
4. Evaluate a roughly 1–2 second product entrance while allowing the destination selector to work immediately. This is a design target, not a mandatory wait; interruption and Reduce Motion need equivalent settled states.
5. A confirmed destination then triggers the separate world-reveal sequence and introduces date selection. Do not concatenate the arrival and reveal into a compulsory full-screen film.

Video generation was subsequently authorised and completed in [onboarding-intro-v1](../onboarding-intro-v1/README.md). The storyboard and screen assets are separate from the parked app-icon work.

Generated with built-in imagegen. [Exact prompt and reference roles](PROMPTS.md). The current app and launcher resources were not changed.
