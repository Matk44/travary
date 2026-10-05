# Your holiday comes to life

5 October 2026. Connected interaction prototype for the approved coral ribbed spinner and full colourful destination stage.

## Review

Open **http://127.0.0.1:55370/**. Choose Bali or Kyoto, let the destination world open, then select dates or choose **Dates not decided**. **Restart journey** clears this prototype's temporary draft and replays the arrival; **Replay reveal** repeats the shared destination choreography.

To reopen the local preview from the project root:

```sh
python3 docs/mockups/onboarding-intro-v1/serve.py --port 55370 --directory docs/mockups/onboarding-journey-v1
```

The included server supports video byte ranges. Serve through it rather than opening the HTML as a file.

## The connected story

1. **Meet your porter.** Travi rolls into the destination-neutral workshop once, then waits in the existing six-second idle film. Destination selection is available immediately.
2. **Choose your holiday world.** Travi makes a small anticipatory lean while the full destination illustration opens across the stage. Bali and Kyoto use the same mask, rise and settle. The landscape is a full background, continuing into the cream control floor.
3. **Give it a departure tag.** After the main reveal, the live headline rises word by word: **When do we leave?**, with **leave?** in coral. The destination name, date fields and buttons remain live UI. Native date inputs validate the range; no dates are invented.
4. **Acknowledge the choice.** Confirmed dates appear on a departure tag with **Dates set**, a brief stamp and Travi's proud rock. **Dates not decided** leaves both dates empty and changes the tag to **Dates to come / To be continued**.
5. **Open the folio next.** **Bring in a booking** currently reveals a review note explaining the next unit: importing or manually adding a booking, reviewing its details and seeing it in the itinerary. This booking flow is not implemented by the prototype.

The reveal lasts about 1.2 seconds. The headline starts at 900 ms, as the scene settles. These are design targets for review, not evidence of optimal timing. Controls remain usable; opening a sheet or pausing settles the reveal immediately. Headlines stop moving after their entrance. Travi's destination waiting state is a restrained whole-layer sway.

## Reusable assets

| Asset | Purpose |
|---|---|
| [bali-stage-v1.png](bali-stage-v1.png) | Clean 851 × 1848 full-stage Bali plate derived from the approved composition, without text, controls or Travi |
| [kyoto-stage-v1.png](kyoto-stage-v1.png) | Matching 851 × 1848 full-stage Kyoto plate, drawing on the existing Kyoto artwork |
| [travi-cutout-v2.png](travi-cutout-v2.png) | Complete excited coral spinner on genuine transparency, 1254 × 1254 RGBA |
| empty-stage-v1.png | Existing neutral workshop and fallback |
| travi-entrance-playback-v1.mp4 | Existing four-second faststart entrance film |
| travi-idle-loop-v1.mp4 | Existing six-second waiting film |
| entrance-start-v1.png / idle-start-v1.png | Existing playback posters |

The three new raster assets were made using **built-in imagegen**. [Exact prompts and reference paths](PROMPTS.md) preserve the selected generation inputs. The workshop, movies and posters are copies of the [reviewed intro assets](../onboarding-intro-v1/README.md). No additional videos were generated for this unit.

For each future destination, follow the [destination art expansion guide](../../ONBOARDING_DESTINATION_ART.md), using the clean Bali plate as the layout reference. The [continuing asset register](../../onboarding/DESTINATION_ART_REGISTER.md) logs destination stage gaps and shared story assets; update it as new requirements appear.

The destination plates are flattened illustrations. The transparent Travi asset is a complete pose, not an articulated rig. CSS moves the whole character and scene; independently animated eyes, hands, wheels, buildings or foliage require additional authored layers or a rig. The existing intro video contains facial acting, but its baked-in workshop cannot be reused as a transparent overlay.

## Behaviour and scope

Destination and ISO dates live in sessionStorage under `travary-onboarding-journey-v1`. Reloading restores the settled local draft; closing the browser session or restarting the journey clears it. Bali/Ubud/Denpasar resolve to the Bali plate, Kyoto to Kyoto. Other destinations use the neutral workshop, preserving their real name without falsely showing Bali.

The prototype provides pause/resume, a still version, system reduced-motion handling, dialog focus, semantic live text, error messages and media fallback. [Browser verification](QA.md) records the actual checks and limitations.

This is a local browser prototype, not an installed Flutter flow. It does not create real trips, import bookings, authenticate travellers, change purchases or apply the parked icon. Production integration still needs deliberate video framing, controller handoff, destination art resolution, native date UI, draft persistence and device/accessibility validation.

## Next unit

Build the **booking folio → review → first itinerary day** interaction with the actual product's import/manual-booking capabilities. Show a useful outcome before offering Holiday Pass or Annual Pass. Keep an honest free continuation. Once the connected story and motion are reviewed, port the approved flow into Flutter rather than embedding this HTML prototype.
