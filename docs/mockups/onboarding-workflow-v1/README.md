# Connected onboarding walkthrough

8 October 2026: one browser route connected the existing owner-approved Bali
studies without new generated media. **9 October update:** the owner-approved
[account motion](../onboarding-account-motion-v1/README.md) now connects proof
to an optional sign-in invitation before passes. It adds new generated acting
with live controls and simulated provider/email outcomes.

## Try the whole visual journey

[Open the walkthrough](http://127.0.0.1:55378/onboarding-workflow-v1/).

1. Meet Travi and choose Bali.
2. Set departure and return dates, or choose **Dates not decided**.
3. Add a manual booking, review the example PDF import, use the example flight
   board, or leave bookings until later.
4. Save checked details and watch the existing Travi booking reaction. Choose
   **Let’s sort the rest**: Travi files that booking and offers an identity tag.
5. Try Apple/Google, the email-link preview, or **Continue as a guest**.
   Successful verification links the tag; cancellation/failure stays here.
   Guest continuation has its own equally warm pass handoff.
6. Select a pass or **Continue with free**, then see the same example booking
   in the final example holiday.

The sidebar has **Restart from the beginning**, **Back to holiday setup**,
430/390/320 px phone widths, a settled-stills option and controlled purchase
success/cancellation/failure, plus independent simulated sign-in outcomes.
No email is sent; the email waiting screen has an explicit demo-verification
button. Choosing later enters the invitation directly without filing a card.
Choices survive a reload in that tab's browser
session. Restart clears only this walkthrough's session state.

For the flight-board example, use **TV123** and the date already shown in its
departure field. Other numbers/dates return an unavailable example result.
These are fixture details, not an AeroDataBox lookup or a confirmed reservation.

Unknown dates disable Holiday Pass. The browser example also disables it for
holidays longer than 30 days; Annual remains available. Tickets use live HTML
text and an explicitly labelled example catalog ($14.99 once / $34.99 per year),
not a RevenueCat request. No payment is made. An edited imported or manually
entered booking keeps its checked title, day, time and place through the proof
and completion screens. Choosing later does not invent a saved booking or play
the card-filing film.

This is a **visual review**, not the Flutter app or an account signup. PDF data
is an example with no file upload; flight responses and purchase outcomes are
examples. The final holiday is an example screen, not the app's itinerary.
The browser booking form is intentionally a single-day example; use the native
editor to verify overnight journeys, attachments and conflict handling.

Bali is the only full-motion destination in this route because these existing
films have an opaque Bali background. They cannot be used behind other
destinations. The country-first [art register](../../onboarding/DESTINATION_ART_REGISTER.md)
and neutral fallback remain the plan for the actual app.

## Native application testing

For real in-memory holiday creation, booking save and navigation, run:

```sh
flutter run --dart-define=TRAVARY_BACKEND=demo --dart-define=TRAVARY_PREVIEW_ONBOARDING=true
```

Demo mode uses in-memory holiday/booking data and simulated purchases. It
does not expose Apple/Google authentication or live flight lookup. It is
**not wholly offline**: the existing art-catalog refresh can contact Firebase,
and selecting a real Smart Import file uses the existing cloud import service,
including its normal limits. Use manual entry for a local functional test.

For the optional account invitation and configured live flight lookup, use
the existing cloud configuration:

```sh
flutter run --dart-define=TRAVARY_PREVIEW_ONBOARDING=true
```

Cloud mode uses the configured Firebase backend and may create real account
and holiday records. Live lookup uses the existing authenticated server
integration. Production billing is still separate work; the application's
current `TestPurchaseService` simulates purchases. No live auth, import,
provider or billing request was tested for this browser revision.

The new first-booking acting and smoothed pass film are still **browser
reviews**. Flutter currently has the documented native booking proof and
approved pass atlas; this walkthrough does not integrate these new films.
See [native implementation and checks](../../ONBOARDING_NATIVE.md).

## Rebuild or reopen

From the Travary project root:

```sh
python3 docs/mockups/onboarding-workflow-v1/build_workflow.py
python3 docs/mockups/onboarding-intro-v1/serve.py --port 55378 --directory docs/mockups
```

The second command is only needed if the existing loopback preview server
has stopped. It serves media with byte-range support for video playback.
The builder adapts copies of the journey, folio and handoff studies; their
originals and media masters are unchanged. `sources.json` records the inputs.

[Recorded checks and screenshots](QA.md).
