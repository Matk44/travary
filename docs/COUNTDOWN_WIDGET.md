# The home-screen countdown widget

Today's countdown on the phone's home screen: the trip's postcard with the
luggage tag hung on it, counting down to the next trip, then the days left
on it. iOS (WidgetKit, iOS 17+) and Android (an app widget), free for
everyone like Today. Built 16 Oct 2026.

## How it works

The widget runs without the app, so the app works out **every day ahead**
and the widget only picks the one for the phone's date. The count turns
over at midnight even if Travary isn't opened for weeks.

1. `lib/logic/countdown_widget.dart` (pure, tested): which trip each day
   shows (Today's rule, `focusFor`), its wording (the Trips tab's,
   `tripPostcardTextFor`: "58 DAYS TO GO", "3 DAYS LEFT"), Travi's mood
   that morning (`countdownReactionFor`, a wave once the trip is on), the
   idle face (an undated holiday, else "Where to next?"), and the file's
   JSON. Up to 400 days ahead, ending when the last trip ends.
2. `lib/state/countdown_widget_sync.dart`: listens to `TravelStore`, waits
   two seconds for things to settle, and writes only when what the widget
   would show has changed (a cheap signature first, so the minute's tick
   costs nothing). It copies the art Today draws with (the trip's
   countdown postcard or the neutral one, its landscape Trips postcard,
   the trip's tag and linen, its palette's ink and paper), Travi's peek
   stills, each as a PNG no larger than the widget draws it (see Memory),
   and the tag's fonts. Never while "Preview a different time" is on.
3. `lib/data/countdown_widget_bridge.dart`: the folder (`countdown.json`
   plus `art/`, `travi/`, `fonts/`, files named by their SHA-1 so a changed
   picture gets a new name) and a `reload` call, over the
   `travary/countdown_widget` channel. On iOS the folder is
   `CountdownWidget/` in the App Group `group.com.travary.app`
   (`ios/Runner/CountdownWidgetChannel.swift`); on Android it's
   `files/countdown_widget` (`widget/CountdownWidgetChannel.kt`).

The fonts are `assets/widget/fonts/` (Source Serif 4 Bold, Inter SemiBold
and Medium, SIL Open Font License): byte for byte the files google_fonts
downloads for the app (their SHA-256s are google_fonts 8.2.1's), renamed
so google_fonts never takes them for its own.

The file's `version` is mirrored in Swift and Kotlin
(`test/tool/countdown_widget_config_test.dart` keeps them equal, with the
channel, folder, App Group, embedding and URL scheme).

## Getting it onto the home screen

An app can't see the home screen, only whether a widget of its own is on it,
and only Android can be asked to place one. One sheet
(`features/widget/countdown_widget_sheet.dart`, wording in
`logic/countdown_widget_setup.dart`) and two ways in:

- **Today's countdown**: a note beside the tag under "Packing list" ("Home
  screen · Add this countdown ›"). It's a second `CountdownNote` because the
  countdown fills a 390 × 844 phone down to the tabs, so a row under it is
  off screen, and its title is short because "Home screen widget" is cut off
  in the room beside the tag. Offered while the widget can be had, isn't on
  the home screen, never was, and wasn't turned down; the sheet's "Not now"
  (from Today only) puts it away for good.
- **Profile → Home screen → Countdown widget**: always there where the phone
  can have the widget, with a tick once it's added.

| Phone | The sheet |
|---|---|
| Android, launcher can place it | "Add to home screen" asks the launcher (`requestPinAppWidget`); its own dialog does the rest. |
| iOS 17 and later | Three steps (touch and hold, tap +, pick a size, Add Widget): there is no call to add one. |
| Android, launcher can't or won't | Android's three steps, and "Your phone didn't open its widget picker." if it refused. |
| iOS 15 and 16 | No widget exists: no note, no Profile row. |

`CountdownWidgetStore` asks the phone (`status` on the channel: Android
`getAppWidgetIds`, iOS `WidgetCenter.getCurrentConfigurations` for kind
`CountdownWidget`) at launch and every time the app returns to the
foreground, so an open sheet turns into "It's on your home screen" when the
widget lands. `declined` and `everAdded` are kept on this phone
(`countdown_widget_settings`); someone who has had it and removed it isn't
offered it again. Nothing here is ever asked at launch or in onboarding.

## Sizes

| Size | Layout |
|---|---|
| Small | The portrait postcard filling the height, the tag over its right side (count, "DAYS TO GO", place). |
| Medium | The Trips tab's landscape postcard (else the portrait's picture cropped to a print, as a trip's screen does), the tag on its right edge, Travi popping up beside it. |
| Large | Today: "NEXT ADVENTURE" over the portrait postcard, the tag on its lower right reaching past its edge, Travi behind its top right. |

The geometry is the same on both platforms (`CountdownStage.swift`,
`CountdownWidgetStage.kt`), as shares of the widget and of the rasters'
measured cards. Android picks a layout from the size it's given: wide
(at least 1.6 times as wide as tall) is medium, under 220 dp either way is
small, else large. The tag's words shrink together when they don't fit,
never one alone, and a place name stays on one line if it fits a little
smaller, as on the app's tag.

## Memory

A widget is stopped by the phone when its process uses too much memory,
about 30 MB (Apple doesn't publish the figure). **The simulator never stops
it**, so a widget can look right there and show blank on a real iPhone: the
grey placeholder is what the home screen draws when the widget couldn't be
produced.

An empty widget process already sits at about 14 MB. Reading a picture then
costs three to four times its decoded size while it's made (the engine
decodes the whole file and then a reduced copy), and a bundled postcard is
1122 × 1402. What was measured on the simulator (iPhone 17, iOS 26.1), as
the extension process's `phys_footprint_peak` from a fresh process
(`footprint -p <pid>`; kill the process, then reload the widget):

| Render | Before | After |
|---|---|---|
| Large widget, real data | 43 MB | 20 MB (with the small and medium widgets rendered too) |
| The widget gallery's preview (small, medium, large) | 36 MB | 21 MB |

What changed it:

1. **The app writes smaller pictures** (`lib/data/countdown_widget_art.dart`,
   `CountdownWidgetArtSize`): PNGs, the postcard at most 800 pixels on its
   longest side, the landscape 900, the tag 600, the linen tile 512, Travi
   480. The large widget on a 3x phone draws the postcard about 1000 pixels
   tall, so it's enlarged by about a quarter, which its grain hides (checked
   side by side on the simulator). Android decodes them with `inSampleSize`
   as before.
2. **The widget reads a picture as it is** when it's no larger than 1100
   pixels (`ArtFile.image`), instead of making a reduced copy first, and
   keeps one trip's pictures (about 6 MB) so the days of a timeline share
   them. Holding every trip's made the peak higher, not lower. A larger
   picture (an older app's, before it writes again) is still reduced as it's
   read.
3. **The gallery's preview uses small copies inside the extension**
   (`ios/CountdownWidget/SampleArt/`: the three fonts and the sample
   postcard, landscape, tag, linen and Travi), not the app's full-size
   bundled art, which was also read from the app's own folder. They're made
   from `assets/art/common/` (`countdown_postcard_anywhere`,
   `trip_postcard_anywhere`, `countdown_luggage_tag`, `linen`) and
   `assets/travi/cameos/stills/peek-cheer`, scaled to the same sizes (ImageIO,
   `CGImageDestination`); they add about 4 MB to the app.
4. **The linen tile is drawn 341 points across whatever its pixels**
   (`LinenView`), so the smaller tile is softer, never denser.

Keep it that way: a new picture goes through `CountdownWidgetArtSize`, and a
change to how the widget draws is measured again, on the largest family
with all three placed, before it's trusted. The numbers aren't a promise
about a phone: its baseline differs, so leave room.

## Travi, and what moves

Widgets can't play the app's films, so Travi rises and ducks as one move
between his peek stills:

- **Each morning** he's up from midnight until `traviUntilHour` (noon) with
  how he feels about the days left; then he ducks.
- **Tapping the tag** brings him up for four seconds (iOS 17 App Intent,
  `TraviTapIntent`; Android a broadcast), and on iOS the tag swings.
  Tapping anywhere else opens the trip (`travary://trip/<id>`, handled by
  `AppSession` and `HomeShell`), or Today.
- iOS animates the change between timeline entries (an offset transition
  for Travi, a spring for the tag, the count rolling down at midnight with
  `numericText`). It only plays if the widget is on screen at that moment.
- Android draws three layers (linen, Travi, postcard and tag) and flips
  Travi's layer with a rise/duck animation (`ViewFlipper`); an alarm that
  doesn't wake the phone redraws it at noon and midnight.

## Setup for device builds

- iOS: the widget is the `CountdownWidget` target (bundle ID
  `com.travary.app.CountdownWidget`, iOS 17), embedded beside the share
  extension. Its App ID is registered in the Apple Developer account (16
  Oct, "Travary Countdown Widget") with the App Group
  `group.com.travary.app`, which device and store builds need. The
  simulator needs nothing.
- Android: nothing to set up. The picker's preview is
  `res/drawable-nodpi/countdown_widget_preview.webp`, a capture of the real
  widget.

## Not yet

- The memory figures (see Memory) are from the simulator. Run the widget
  on a real iPhone (Xcode's debug gauge on the `CountdownWidget` process, or
  Settings → Privacy & Security → Analytics Data for a `JetsamEvent`) before
  release.
- Lock Screen and StandBy (`accessoryRectangular`) are easy additions.
- Interactive taps need iOS 17; on iOS 15 and 16 there's no widget at all
  (the extension's minimum is 17).
- Analytics count opens from the widget (`countdown_widget_opened`) and the
  first time it's seen on a home screen (`countdown_widget_added`); a
  widget added while Travary was never reopened isn't seen until it is.
- The setup sheet's three iOS steps are worded for iOS 17 and 18: check them
  on a real iPhone (and on iOS 26) before release.
