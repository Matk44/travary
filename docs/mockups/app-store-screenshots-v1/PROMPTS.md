# Prompts for ChatGPT: Travary App Store screenshots

Paste these into ChatGPT (image generation) in order. Each frame prompt says
which files from `references/` to attach. How to run the whole session, and
what to do with the results, is in [README.md](README.md).

The frames are **edits of our layouts**, not new drawings: attaching the green
layout and asking for an edit keeps the phone the same size and in the same
place in every frame. ChatGPT adds the finish (light, paper, depth, props and
Travi's integration). The phone's screen stays flat green; the real app screen
goes in afterwards with `compose.py`, so the store shows the app exactly as it
is (Apple 2.3.3).

---

## 1. Series brief (send once, first)

Attach: `references/style/style-board.jpg`, `references/contact-sheet.jpg`,
`references/travi/travi-hello.png`, `references/travi/travi-envelope.png`,
`references/travi/travi-proud.png`, `references/travi/travi-wave.png`.

```text
You're the illustrator and art director for Travary's App Store screenshots: a set of ten
portrait images that will sit side by side on the App Store. Travary is a holiday organiser
app: you add your bookings and it sorts them into days, with tickets one tap away.

I'll send one frame at a time. Each time I'll attach my layout for that frame (with the
phone screen in flat green) and ask you to edit it into a finished, polished screenshot.
Please don't start drawing until I send frame 01. Confirm you've got the brief.

THE LOOK: "travel ephemera". Hand-made, warm and tactile, like a beautifully kept travel
folio: woven linen paper, deep navy painted walls with arched doorways opening onto
illustrated destinations, cream floors, kraft luggage tags on string, rubber-stamp
postmarks, perforated stamps, ticket stubs. Soft, warm daylight from the upper left.
Gentle paper grain. Gouache and papercraft illustration, never glossy 3D render, never
neon, no mesh gradients, no stock-photo people, no clutter. Think premium, calm and
characterful. The attached style board has the palette, type and materials; the contact
sheet shows all ten layouts together, so the set must feel like one family.

PALETTE: linen #EFE8DC, paper #F8F4EC, ink #1C2A47, navy wall #024A6D, folio navy
#102B46, coral #FA815A, coral on linen #CF5F3C, cream #FFF1D9, kraft #C9A77D,
brass #D1AB68.

CANVAS: 1320 x 2868 pixels, portrait (9:19.5). If you can't output that exact size, use
the closest portrait size with the same shape (for example 1312 x 2848) and never crop or
re-frame the layout.

THE PHONE (identical in every frame): an iPhone 17 Pro Max in Silver, straight-on, no
tilt, no perspective, centred. Brushed silver aluminium rim, a thin even black border, the
Dynamic Island (a black pill) at the top of the screen, side buttons. Keep its outline
exactly where my layout puts it: outer edge x 130 to 1190, y 590 to 2809; screen
x 166 to 1154, y 626 to 2773. A soft, realistic shadow beneath it.

THE SCREEN: flat chroma green #00B140, perfectly even, edge to edge inside the screen's
rounded corners. No reflections, glare, gradient, texture or UI on it. I'll put the real
app screen in afterwards. The Dynamic Island stays black on top of the green.

THE WORDS: only the headline (two lines, centred, top of the frame) and the one line under
it. Headline in a bold old-style serif like Source Serif 4 Bold; line 1 in ink (or cream
on navy), line 2 in coral. The line under it in a clean sans like Inter Medium. Spell
everything exactly as I give it, keep my line breaks, and add no other words, numbers,
logos or labels anywhere (the kraft "pass" tags in frames 04 and 06 are the only
exception, and I give their words too).

TRAVI: our mascot, a friendly coral-orange hard-shell suitcase. Match the attached poses
exactly, never redesign him: vertical ribbed coral shell, navy telescopic handle on brass
posts, navy corner guards and trim, four black wheels with brass hubs, a cream luggage tag
with a navy palm tree hanging from a brass chain on his top right, big glossy cartoon eyes
with small brows, a small open smile, faceted papercraft arms and hands. He's the same
size in every frame he's in. He stands on the floor in front of the phone's lower corner,
overlapping the phone a little, with a soft contact shadow and light that matches the
scene. He never covers the upper two-thirds of the screen. He only appears in the frames
where I ask for him.

NEVER: Apple logos or other devices, app store badges, prices, "free" banners, ratings or
awards, real brands or company names, maps, people, watermarks, extra text, a tilted or
resized phone, anything drawn on the green screen.
```

---

## 2. The frames

Send one at a time. For every frame after 01, also attach the **approved frame
01** as the style anchor and add: *"Match the finish of the attached approved
frame 01: same light, paper, phone, shadow and type."*

Common to every frame prompt: attach the green layout first (it's the image to
edit), then the layout with the stand-in screen (shows intent), then Travi's
pose if he's in it.

### Frame 01: Today

Attach: `references/green/01-today-green.jpg`, `references/layout/01-today.jpg`,
`references/travi/travi-hello.png`

```text
Frame 01 of 10. Edit the first attached image (01-today-green) into the finished
screenshot. Keep its composition exactly: same phone, same size and position, same
headline position, green screen untouched. The second image shows what will be on the
screen, for your reference only; don't draw it.

Background: warm linen paper filling the frame, with visible weave and soft daylight from
the upper left. Tuck two pieces of ephemera behind the phone so only their edges show in
the side margins: a faded navy postmark ring on the left, a coral palm-tree postmark on
the right (as in my layout). Keep them subtle; the phone and the words lead.

Words, exactly:
  Line 1 (ink #1C2A47): Your holiday,
  Line 2 (coral #CF5F3C): sorted into days.
  Under it (soft ink #56617A): Flights, stays, tickets and tables, in order.

Travi: the attached hello pose, waving, standing on the bottom edge in front of the
phone's lower-right corner as in my layout, his open hand reaching across the bottom of
the screen. Soft contact shadow on the linen, warm rim light.

Polish: give the phone a crisp silver rim with a soft highlight and a realistic, slightly
warm shadow on the linen. Everything else as the brief.
```

### Frame 02: Countdown

Attach: `references/green/02-countdown-green.jpg`, `references/layout/02-countdown.jpg`,
approved frame 01

```text
Frame 02 of 10. Edit the first attached image (02-countdown-green) into the finished
screenshot, keeping its composition exactly (phone, size, position, green screen).

Background: Travi's workshop, a deep navy painted wall (#024A6D) with tall rounded
arches at both sides opening onto an English countryside scene: green hills, a lake,
a stone cottage, a low orange sun. The phone stands in front, so the scene shows only at
the sides. Cream floor at the bottom. Soft warm light spilling from the arches onto the
floor.

Words, exactly:
  Line 1 (cream #FFF1D9): Counting down
  Line 2 (coral #FA815A): to the next one.
  Under it (warm cream #E6D6BD): A postcard from where you're going.

No Travi in this frame (he appears inside the app screen that goes in later).
```

### Frame 03: Inside a trip

Attach: `references/green/03-trip-green.jpg`, `references/layout/03-trip.jpg`,
approved frame 01

```text
Frame 03 of 10. Edit the first attached image (03-trip-green) into the finished
screenshot, keeping its composition exactly (phone, size, position, green screen).

Background: linen paper as in frame 01. Behind the phone's left edge, the corner of a
paper planner page with a dashed line; behind the right edge, a coral postmark. Subtle.

Words, exactly:
  Line 1 (ink #1C2A47): It spots
  Line 2 (coral #CF5F3C): what's missing.
  Under it (soft ink #56617A): The night without a stay. The flight home.

No Travi in this frame.
```

### Frame 04: Smart Import

Attach: `references/green/04-smart-import-green.jpg`,
`references/layout/04-smart-import.jpg`, approved frame 01

```text
Frame 04 of 10. Edit the first attached image (04-smart-import-green) into the finished
screenshot, keeping its composition exactly (phone, size, position, green screen).

Background: Travi's workshop with no destination: the deep navy wall (#024A6D) with plain
navy arches at both sides and a cream floor. Calm and simple.

Words, exactly:
  Line 1 (cream #FFF1D9): Hand Travi
  Line 2 (coral #FA815A): the confirmation.
  Under it (warm cream #E6D6BD): Smart Import reads screenshots and PDFs.

Keep the kraft luggage tag hanging over the phone's top-right corner, on its string, as
in my layout. Its words, exactly, handwritten-print style in dark brown:
  2 free,
  then a pass

No Travi outside the phone (he's inside the app screen that goes in later).
```

### Frame 05: Departures board

Attach: `references/green/05-flight-green.jpg`, `references/layout/05-flight.jpg`,
approved frame 01

```text
Frame 05 of 10. Edit the first attached image (05-flight-green) into the finished
screenshot, keeping its composition exactly (phone, size, position, green screen).

Background: linen paper as in frame 01. Behind the phone's edges, the torn stub of a
paper boarding pass on the left and a navy postmark on the right, edges only. No airline
names, codes or logos on them.

Words, exactly:
  Line 1 (ink #1C2A47): Just the
  Line 2 (coral #CF5F3C): flight number.
  Under it (soft ink #56617A): The board flips in the times and airports.

No Travi in this frame.
```

### Frame 06: Family

Attach: `references/green/06-family-green.jpg`, `references/layout/06-family.jpg`,
`references/travi/travi-envelope.png`, approved frame 01

```text
Frame 06 of 10. Edit the first attached image (06-family-green) into the finished
screenshot, keeping its composition exactly (phone, size, position, green screen).

Background: Travi's workshop, the deep navy wall (#024A6D) with arches at both sides
opening onto a tropical coast: palms, a temple roof, terraced green hills, blue sea, a
low orange sun. Cream floor. Warm light from the arches.

Words, exactly:
  Line 1 (cream #FFF1D9): Everyone on
  Line 2 (coral #FA815A): the same page.
  Under it (warm cream #E6D6BD): Up to 6 people, each with their own tickets.

Kraft luggage tag over the phone's top-right corner, as in my layout. Its words, exactly:
  With
  a pass

Travi: the attached envelope pose, facing right, holding out the sealed cream envelope
towards the phone like an invitation, standing on the floor in front of the phone's
lower-left corner as in my layout. Soft contact shadow.
```

### Frame 07: Tickets offline

Attach: `references/green/07-tickets-green.jpg`, `references/layout/07-tickets.jpg`,
approved frame 01

```text
Frame 07 of 10. Edit the first attached image (07-tickets-green) into the finished
screenshot, keeping its composition exactly (phone, size, position, green screen).

Background: linen paper as in frame 01. Two or three perforated postage stamps with small
illustrated landscapes tucked behind the phone's edges, with a faded postmark ring.
Edges only, nothing readable on them.

Words, exactly:
  Line 1 (ink #1C2A47): Tickets that work
  Line 2 (coral #CF5F3C): with no signal.
  Under it (soft ink #56617A): Every booking and ticket, on every plan.

No Travi in this frame.
```

### Frame 08: Passports

Attach: `references/green/08-passport-green.jpg`, `references/layout/08-passport.jpg`,
approved frame 01

```text
Frame 08 of 10. Edit the first attached image (08-passport-green) into the finished
screenshot, keeping its composition exactly (phone, size, position, green screen).

Background: Travi's workshop, the deep navy wall (#024A6D) with arches at both sides
opening onto a sunny coastline: green headlands, a winding road, turquoise sea, a low
orange sun. Cream floor. Calm, safe, settled light.

Words, exactly:
  Line 1 (cream #FFF1D9): Your passport stays
  Line 2 (coral #FA815A): on your phone.
  Under it (warm cream #E6D6BD): Behind Face ID. Checked against your next trip.

No Travi in this frame, and no passport drawn anywhere (the real screen goes in later).
```

### Frame 09: Packing list

Attach: `references/green/09-packing-green.jpg`, `references/layout/09-packing.jpg`,
`references/travi/travi-proud.png`, approved frame 01

```text
Frame 09 of 10. Edit the first attached image (09-packing-green) into the finished
screenshot, keeping its composition exactly (phone, size, position, green screen).

Background: linen paper as in frame 01, with a folded sun hat brim and a kraft packing
tag peeking from behind the phone's left edge, edges only.

Words, exactly:
  Line 1 (ink #1C2A47): Packed
  Line 2 (coral #CF5F3C): together.
  Under it (soft ink #56617A): One list for everyone, ticked off as you pack.

Travi: the attached proud pose, hands on hips, beaming, standing on the bottom edge in
front of the phone's lower-right corner as in my layout. Soft contact shadow.
```

### Frame 10: Every trip a postcard

Attach: `references/green/10-trips-green.jpg`, `references/layout/10-trips.jpg`,
`references/travi/travi-wave.png`, approved frame 01

```text
Frame 10 of 10, the last of the set. Edit the first attached image (10-trips-green) into
the finished screenshot, keeping its composition exactly (phone, size, position, green
screen).

Background: Travi's workshop, the deep navy wall (#024A6D) with arches at both sides
opening onto Kyoto in autumn: red maple leaves, a pagoda, a torii gate, warm sunset sky.
Cream floor.

Words, exactly:
  Line 1 (cream #FFF1D9): Every trip gets
  Line 2 (coral #FA815A): its own postcard.
  Under it (warm cream #E6D6BD): Drawn for where you're going.

Travi: the attached wave pose, holding his navy folio and waving goodbye, standing on the
floor in front of the phone's lower-left corner as in my layout. Soft contact shadow.
```

---

## 3. Fixes to send when a frame drifts

- **Text wrong:** "The words must be exactly: [line 1] / [line 2] / [line under it]. Change only the text; keep everything else identical."
- **Phone moved, resized or tilted:** "Put the phone back exactly as in the attached green layout: same outline, size and position, straight-on. Change nothing else."
- **Green not flat:** "Make the screen one flat, even #00B140 with no reflection, glare, shading or texture. Keep the Dynamic Island black."
- **Travi redesigned:** "Travi must match the attached pose exactly: coral ribbed shell, navy handle on brass posts, four black wheels with brass hubs, the cream palm-tree tag on a brass chain. Redraw only Travi."
- **Too busy:** "Remove the props from the side margins except [one]. Keep the background calm."
- **Something invented:** "Remove [the extra text / logo / badge / second phone]. Keep everything else identical."

ChatGPT's selection tool (paint over an area, then describe the change) is the
quickest way to fix one spot without the rest of the frame shifting.

---

## 4. Optional: the product page header (iOS 27)

This is the still the owner approves before any header film is made.

Attach: `references/style/style-board.jpg`, `references/travi/travi-hello.png`,
and from the repo `assets/onboarding/stages/workshop.webp`,
`assets/onboarding/stages/city_jp_kyoto.webp`.

```text
A wide App Store header image for Travary, 21:9, 3840 x 1646 pixels (or the widest you
can, keeping 21:9). No transparency.

Travi's workshop: a deep navy painted wall (#024A6D) running the full width, with three
tall rounded arches in the right two-thirds, each opening onto an illustrated destination
in the same gouache travel-poster style: Kyoto in autumn (left arch), a Balinese coast
with temple and terraces (middle), England's Lake District with a lake and fells (right).
A warm cream floor along the bottom. Travi, exactly as the attached pose, stands on the
floor in front of the middle arch, waving hello, with a soft shadow.

Words, top left, exactly, in the serif from the style board:
  Line 1 (cream #FFF1D9): Where are we
  Line 2 (coral #FA815A): off to?

Bottom left on the floor: a cream luggage tag on brass string reading "NEXT TRIP / 58 /
DAYS TO GO". No other words. Keep Travi, the words and the tag inside the central safe
area, away from all four edges. No prices, logos or badges.
```
