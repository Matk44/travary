# Travary intro — exact prompts and requests

5 October 2026. Image edits used built-in imagegen, with opaque backgrounds. Videos used the existing local Scene Studio API, provider `replicate-seedance-2` (Seedance 2.0 on Replicate). The generator's settings and credentials were unchanged.

## Settled keyframe — travi-settled-v1.png

Edit target: `../onboarding-arrival-v1/arrival-screen-v1.png`, inspected before editing. Output source: `/Users/khairofamily/.codex/generated_images/01a10645-84b8-7482-bc0f-5b5d42d880ca/exec-e7f82f33-38d2-4c14-bda1-07ae016d9987.png`.

```text
Use case: precise-object-edit.
Asset type: clean animation END KEYFRAME for Travary's first onboarding screen.
Input image 1 is the approved screen and exact edit target.
Primary request: remove ALL typography and ALL interface elements from this image, leaving ONLY the illustrated paper workshop and the coral ribbed spinner character Travi. Remove the Travary wordmark, headline, subtitle, destination tag/button with eyelet and icons, and both footer text links. Reconstruct their areas seamlessly as the same teal wall or warm cream paper floor. There must be no readable text, lettering, search icon, button, arrow or new mark anywhere.
Invariants: preserve exactly the same portrait framing and aspect ratio, camera, wall/floor boundary, rich teal curved paper-theatre wings, cream stage floor, warm lighting, fine tactile paper grain and soft physical shadows. Preserve the closed teal folio and two blank cream tickets at the lower left, well behind the character's wheel path.
Preserve Travi EXACTLY: his large middle-right position and scale, tall coral hard-shell spinner with sculpted vertical ribs, navy clamshell zipper edge, four dark grounded swivel wheel assemblies, twin warm-brass telescopic rails and navy pull grip, separate short grab handle, cream palm luggage tag, exactly two folded-paper arms, bright open cream/navy eyes, lifted brows and joyful open smile. The current small inviting gesture, body tilt and enthusiastic expression stay unchanged.
Composition: retain the now empty upper wall for future live animated heading, and the now empty lower cream floor for future live accessible controls. Do not enlarge or shift Travi into these safe zones. No destination scenery or extra props.
Constraints: focused removal of text and UI only, one character, no redesign, no new landscape, no new objects, no watermark, no glossy plastic. This is clean underlying video artwork; the app will draw all words and controls separately.
```

## Empty keyframe — empty-stage-v1.png

Edit target: the selected text-free `travi-settled-v1.png`. Output source: `/Users/khairofamily/.codex/generated_images/01a10645-84b8-7482-bc0f-5b5d42d880ca/exec-2993d32d-0cde-4db6-9b10-aba87d04a538.png`.

```text
Use case: precise-object-edit.
Asset type: matching empty START KEYFRAME for Travary's first onboarding roll-in.
Input image 1 is the exact edit target: text-free workshop with settled Travi.
Primary request: remove Travi completely, including his coral suitcase body, both folded-paper arms, all wheels, both handles and rails, luggage tag and his contact shadow. Reconstruct the exposed area as a perfectly coherent continuation of the existing petrol-teal paper wall and cream floor. The result is an EMPTY stage, with no trace of the character, ready for him to roll in from the left.
Invariants: preserve the EXACT original pixel canvas dimensions and portrait aspect ratio, locked camera, teal curved paper-theatre side wings, wall/floor boundary and geometry, cream floor texture, warm directional lighting, and the existing closed teal folio plus two blank cream tickets at the lower LEFT. Their position, scale, lighting and shadows stay unchanged. Keep the large blank upper wall and lower cream floor.
Constraints: focused character removal only. No new shadows, props, scenery, landmarks, letters, logos, controls or objects. Do not brighten, recolour, recompose or move the stage. Maintain the same exquisite tactile layered cardstock materials and paper grain. This is the matched first frame of the same shot.
```

## Video prompts

The complete submitted prompts, frame filenames, seeds and shot cards are saved verbatim in [entrance-request-v1.json](entrance-request-v1.json) and [idle-request-v1.json](idle-request-v1.json). Both requested `adaptive`, 720p and silent output. Scene Studio returned 720 × 1280, H.264, 24 fps.

| Shot | Requested duration | Seed | Scene Studio job | Local media |
|---|---:|---:|---|---|
| Entrance | 4 s | 510051 | 16a49b261ef31000 | 1791186979898-e58b5bca6a062360.mp4 |
| Idle | 6 s | 510052 | 4b997875b0c09f6e | 1791186979268-22e2e5e6a631ac1b.mp4 |

## Local delivery processing

`travi-entrance-v1.mp4` is a copy of the original entrance output. `travi-idle-source-v1.mp4` preserves the original idle. `travi-idle-loop-v1.mp4` keeps its first 144 frames at 24 fps, omitting the extra endpoint frame, and encodes H.264 with CRF 19, yuv420p, faststart and no audio. No reversing, boomerang, optical-flow interpolation or synthetic blink was added. `travi-intro-review-v1.mp4` concatenates the entrance and two passes of the idle as a finite review film; it is not the interactive asset.

PNG frame extracts and contact sheets are inspection records. In the playable HTML all typography, animation and controls remain live HTML/CSS. No words or controls are baked into the MP4 files.

Playback repair: `travi-entrance-playback-v1.mp4` copies the original entrance video stream into a faststart MP4 container using `-c copy -movflags +faststart`. This changes container packaging without re-encoding or regenerating the artwork. The new local `serve.py` supports byte ranges.
