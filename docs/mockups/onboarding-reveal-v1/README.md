# Bali reveal and headline motion

5 October 2026. The owner authorised starting the shared reveal and asked whether colourful animated text would add delight or become too busy.

## Still composition

[bali-reveal-screen-v1.png](bali-reveal-screen-v1.png) combines the selected coral ribbed spinner with the owner's Balinese paper world. The old wide suitcase has been removed. Travi remains on the cream workshop floor, slightly smaller than in the arrival screen so the landscape can take focus. The folio and blank tickets continue from the first scene.

The headline reads **“When do we leave?”** in cream with **“leave?”** in coral; the supporting line is **“Bali, here we come.”** Departure and Return tags, Set my dates and Dates not decided remain separate from the scenic composition in the production plan.

Reviewed the still for the selected spinner identity, closed ribbed shell, enthusiastic open eyes, grounded wheels, two paper arms, removal of the old character, headline colours and copy, Bali scenery, and quiet control space. This is an art-direction still, not production UI.

Generated with built-in imagegen. [Exact prompt and references](PROMPTS.md). [Original supplied scenic reference](reference-bali-original.png).

## Text-motion comparison

The in-conversation motion study compares:

- **Paper words, recommended:** words rise 14 pixels with a small rotation settling to zero; most text is cream, with one coral accent word. A 55 ms stagger and 560 ms entrance give the final word about 725 ms to settle after the headline starts.
- **Quiet title:** the entire cream headline enters as one unit with an 8-pixel rise and a gentle fade.
- **Playful letters:** the accented word arrives letter by letter with a small rotation and cream/coral/mustard alternation. More expressive, but it competes more with the scene.

The replay opens simple paper wings and introduces the existing postcard over 900 ms. The headline starts at 950 ms, after the scenic movement has largely settled. These are adjustable design targets, not measured optimal timings. Text stays still afterwards. Motion does not loop, and the date controls remain available throughout.

The scene selector switches **Bali / Kyoto** using the same choreography. This proves a reusable motion treatment with two existing illustrations, without rendering destination-specific films. The preview focuses on typography and whole-postcard motion; Travi's articulated acting and the full scenic stage shown in the still are separate production work.

Preview verification checked all three treatment selections, replay entering an active animation state and settling afterwards, scene switching, the reduced-motion toggle, and layouts at 320 and 736 pixels. The narrow date rows were adjusted so the input format remains visible. The final browser console showed no errors. The 177 KB fragment embeds two local display copies and makes no API requests; only its optional font resources load remotely. These are browser-prototype checks, not validation of the Flutter app or native accessibility.

Reduced motion supplies the settled composition immediately. System motion preferences are respected, and the preview includes an explicit comparison toggle. Dates in the study stay local; no trip is created, booking saved or purchase initiated.

The small WebP display copies [Bali](bali-motion-preview.webp) and [Kyoto](kyoto-motion-preview.webp) were encoded locally at 600 × 400 from the existing source postcards for the conversation's payload budget. They are delivery derivatives, not changed artwork; originals and pack manifests were preserved. The source art and native Flutter components are listed in [the shared reveal plan](../../ONBOARDING_REVEAL.md).

## Apply the type language across the story

The same treatment can carry into the first screen: **“Where are we off to?”**, with **“off to?”** as the coral accent. For the date prompt, accent **“leave?”**. Keep the Travary wordmark stable, supporting copy quieter, and all booking details, dates and prices readable and motionless while they are being used.

Take turns: Travi's short reaction, then the world, then the headline. Avoid continuously moving text, shimmer, repeated bouncing or a new colour palette for each word. Keep the headline as live semantic text; no rendered user destination or booking data goes into a video.

## Next production unit

Review the still and choose a headline treatment. Then separate the workshop, Travi and scene into clean assets and reproduce the chosen timing in a playable Flutter scene. The full still is not a reusable background layer because it includes the character and illustrative controls. The motion study is not yet installed in the app. No new video was generated.
