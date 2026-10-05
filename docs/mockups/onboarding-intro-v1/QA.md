# Intro review — 5 October 2026

Inspected the actual generated entrance and idle through extracted full frames, contact sheets and a 24-frame expression sheet. The selected character retains coral vertical ribs, navy zipper trim, pull/grab handles, folded-paper arms, grounded caster wheels and his palm tag. The face has bright open eyes between short blinks and moves between an open delighted smile and a smaller friendly grin.

The delivered idle removes the extra endpoint frame, producing exactly 144 frames / 6 seconds. The finite review film contains 385 frames / 16.041667 seconds: entrance plus two idle passes. H.264, 720 × 1280, 24 fps, silent. Seam comparison values are recorded separately and preserve the fact that generated frames are close, not pixel-identical.

Verified in the Codex browser against the local playable HTML:

- Entrance finishes once, then the separate six-second idle starts and repeats. An observed run reached eight actual repeats, with the entrance paused at its end and idle playing.
- Opening destination search pauses both clips immediately.
- Closing the sheet resumes the interrupted clip.
- Selecting Kyoto and confirming retains the paused state and displays the temporary destination handoff. No trip is saved.
- Replay resets the entrance, headline and loop counter, stopping the old clip.
- Pause/resume stops both clips and resumes the active clip.
- Still version displays the settled rendered-frame poster, fully visible text and working controls; replay while still mode is selected remains still.
- 320 × 780 viewport: no horizontal overflow; both shortcut controls have 44 px hit height and at least 14 px text. The destination sheet fits the screen width and scrolls vertically when needed.
- Restored the viewport override after testing. No browser warnings or errors in the final run.

The review has code paths for reduced-motion preference changes, hidden-document pause and media/autoplay failure fallback. OS accessibility settings and native Flutter lifecycle behaviour were not exercised. No production app implementation or automated test suite was changed. `intro-preview-v1.jpg` records the completed local review screen; the live browser tab is retained as a deliverable.

## Replay repair after owner feedback

The original generic local server returned HTTP 200 and the full MP4 when asked for a byte range. The replacement `serve.py` was verified to return HTTP 206 with exact bytes and lengths for first, middle and suffix ranges, a ranged HEAD with no body, and HTTP 416 for a range beyond the file. The entrance playback copy is a lossless faststart remux: still 97 frames / 4.041667 seconds, H.264, 720 × 1280, 24 fps.

The prototype now reveals the active video before calling play, ignores superseded play-promise outcomes, and refreshes the media decoder on explicit replay. A fresh browser review exercised repeated replay. In the final run, actual video-frame callbacks reported 97 entrance frames and 1,875 idle frames across 13 repeats; this verifies frame presentation beyond a moving playback clock. No console warnings/errors were reported. `replay-fixed-v2.jpg` records the repaired preview. The exact original failure in the owner's browser was not conclusively reproduced; refreshing picks up the repaired page and media URLs. No new AI video was generated for the fix.
