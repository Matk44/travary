# Tavi v3: arrival and enthusiasm

The owner approved the paper suitcase and holiday world, and requested a wheeled entrance plus a more excited face. This iteration keeps the character and art direction while changing the performance.

## Artwork

- `empty-stage-v1.png`: the empty teal-and-cream theatre used for the first frame of the entrance.
- `tavi-ready-v1.png`: the edited closed-case character, eager and bright-eyed.
- `tavi-delighted-world-v1.png`: the rich Bali ending with the more enthusiastic expression.

All three were edited using the built-in imagegen tool. The earlier references remain in `../onboarding-v2/`. Exact image and video prompts are in `PROMPTS.md`; full local render requests are saved separately.

## How generation works

1. Generate/edit the character and scene keyframes with built-in imagegen. Copy selected outputs into this project.
2. Upload the artwork to the running local Scene Studio at `http://localhost:3717` using `POST /api/cast/upload`. It saves the images in the generator's local `media/` folder.
3. Write a performance prompt and submit it with the first/last-frame filenames to `POST /api/video/create`, selecting the configured `replicate-seedance-2` provider.
4. Scene Studio sends the render to Seedance 2.0 on Replicate, using the configured account. Video generation happens remotely and uses that account's credits; Scene Studio is the local interface and storage layer.
5. Poll `GET /api/video/<job_id>`. On completion Scene Studio downloads the MP4 to its local media library. Copy that finished local file into Travary's project.
6. Inspect extracted frames for the entrance, identity and acting. Join selected shots locally using ffmpeg for a review film. Keep the shots separate for later interactive use.

The custom shot prompts were written directly for this concept; the Director expansion endpoint was not used. No generator source, credentials or provider settings were changed. Calls used its local API rather than operating its UI. The v3 eager pose was also registered in its Cast library as **Travary — Tavi enthusiastic pose v3**.

## Shot settings

Completed and reviewed:

- [Entrance](tavi-entrance-v1.mp4): 4.04 seconds. Visible left-to-right arrival, lively braking recovery, expressive eager greeting.
- [Reveal](tavi-reveal-v1.mp4): 8.04 seconds. Bright open-eyed expression through the unfolding, with brief blinks and happy presentation. The earlier prolonged half-lidded look is resolved in this selected take.
- [Combined preview](tavi-arrival-and-reveal-v1.mp4): 12.08 seconds, joined locally with ffmpeg without re-encoding.

All three are H.264 at 720 × 1280 with no audio. Contact sheets provide the visual inspection record. These remain generated motion studies: small wheel lifts in the entrance and continuity at the clip join need authored polish for a shipping rig.

| Shot | Duration requested | Size | Audio | Seed | Scene Studio job |
|---|---|---|---|---|---|
| Entrance | 4 seconds | 720p, 9:16 | Off | 140993 | 27e188b4c8520902 |
| Reveal | 8 seconds | 720p, 9:16 | Off | 140994 | 4e62e17fcc2751e1 |

The arrival should happen once on the welcome stage. The holiday reveal follows the destination choice. The joined film is a review asset, not a twelve-second required wait in the app. Production character states and humour are defined in [TAVI_PERFORMANCE.md](../../TAVI_PERFORMANCE.md).

These request files refer to this Scene Studio installation's local media filenames. If moving the project to another installation, upload these PNGs and update the paths. The requests contain no credentials.
