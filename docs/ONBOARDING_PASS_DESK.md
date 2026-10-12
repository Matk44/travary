# Travi’s pass desk

6 October 2026. The owner approved the full scenic composition and requested
that the native screen follow it instead of the compact v1 adaptation.
[Selected reference and assets](mockups/onboarding-pass-desk-v2/README.md).
The later 8 October acting studies remain browser reviews, not Flutter media.
The active browser review plays the full-frame smoothed pass film and blends
into its exact settled plate over 600 ms before live offer controls appear.
The [motion correction](mockups/onboarding-booking-handoff-v1/motion-polish-v2.json)
and [connected walkthrough](mockups/onboarding-workflow-v1/README.md) record
the current review. Flutter's approved atlas remains unchanged; the new film
is not yet native media.

## Story and placement

**9 October requested revision:** insert the [new Travi account invitation](ONBOARDING_ACCOUNT_SCENE.md)
before this desk, offering Apple/Google and a proposed email method. The new
art and connecting choreography were approved on 9 October. Generated
successful-sign-in and guest films now land on this desk in the browser
review; native account linking still follows pass/free. Sign-in must not
imply free premium file backup.

The traveller normally selects a destination and dates (or leaves them
unknown), then checks and saves a real booking on its actual day.
**Owner update, 8 October:** “Let’s sort the rest” leads to this desk; remove
the “Open my holiday with free” shortcut from booking success. Postponing
bookings and exploring before holiday setup also lead here. The purchase
remains optional: **“Continue with free” lives on the desk**. Existing pass
holders receive its ready state, without an unnecessary purchase.

Travi has done something useful and asks **“Shall I help with the rest?”**
The large coral spinner, navy folio, lush scenery, palm-decorated paper
tickets and navy notched button match the approved arrangement. The folio's
holiday label, heading and all ticket copy are native. Smart Import, shared
plans and ticket backup sit **below** the two tickets, as in the reference.
Manual bookings and access to the traveller's tickets remain free.

## Art and live layout

The v2 atlas preserves the approved full composition while removing every
letter, digit and selection mark. Flutter clips its measured hero, ticket,
button and blank-paper regions at runtime. Bali uses the exact atlas hero;
other places use their country/neutral stage and the shared transparent
Travi/folio foreground. Original masters are unchanged; no lettering or
price is painted back into an image.

Native cream/coral serif headings, pass titles, scope, localized prices,
billing suffixes, terms, selection circles and actions sit over the blank
art. The CTA says “Get [selected pass name]”, without repeating its price.
Travary adds no “US” price prefix. The typography yields to the phone's notch.
The page scrolls; long remote copy or larger accessibility text can expand
tickets/buttons. Very large type uses a flowing header with the scenic
illustration below. This keeps full-size text and actions reachable.

[Exact prompts](mockups/onboarding-pass-desk-v2/PROMPTS.md) and
[generation provenance](mockups/onboarding-pass-desk-v2/generation.json)
record the owner attachment, sources, dimensions and hashes. The earlier
[v1 materials](mockups/onboarding-pass-desk-v1/README.md) are historical.

## RevenueCat catalog and pricing

Offline preview defaults are **$14.99 Holiday Pass once** and
**$34.99 Annual Pass/year**. The owner changed Holiday Pass on 6 October.
With a configured RevenueCat key, packages and localized prices come from
the selected offering; title/scope and package mapping can be updated
remotely through its metadata. The actual price is the store product's
formatted price, not a metadata value or UI literal.
[Configuration and example metadata](REVENUECAT_OFFER_CATALOG.md).

An empty or failed configured catalog does not substitute invented USD
offers. Loading, retry and free continuation remain available. A remotely
removed selection does not silently choose Annual. The two supported billing
roles remain one-off Holiday and annual subscription; new billing models
need appropriate purchase/entitlement rules.

**Billing remains simulated** by the existing TestPurchaseService.
The preview says “Test store: nothing is charged.” RevenueCat catalog
fetching cannot grant coverage. Verified consumable claims, webhook
entitlements and live store purchase/restore QA remain separate launch work.
No live RevenueCat request, purchase, AeroData request or credentials were
used for this revision.

## Booking identity and behavior

- The desk uses the actual holiday ID and saved booking when present,
  including resumed setup. A dated holiday can choose a pass before its first
  booking. Explore before creating a holiday can offer Annual only. Neither
  path fabricates a booking or dates. An explicitly stale/mismatched supplied
  booking identity falls back to a free handoff; already covered holidays get
  a ready-to-open state.
- Holiday Pass is initially selected when eligible. Coverage uses the actual
  TripPlan dates, including bookings outside the planned range, with the
  existing 30-day limit and seven-day grace period. A longer holiday explains
  Annual; changed eligibility never silently switches an existing selection.
- Back returns to the current booking payoff, invitation or arrival without
  completing setup. Free continues through optional account linking into the
  same real holiday, or into the app if Explore has not created one.
- Purchases use the currently returned offer and actual holiday dates.
  Cancellation/failure preserves the plan and free exit. Duplicate taps
  are disabled while a request works.
- Restore checks coverage for this holiday, not a different purchased trip.
  Annual renewal/cancellation copy stays on the ticket and in live detailed
  disclosure. Terms/privacy links follow the main composition in the scroll.

## Motion and country expansion

The route fades in over 450 ms; the native cream/coral heading enters over
550 ms, then settles. Reduced motion is immediate. Controls are actionable
throughout. The exact composite keeps Travi's placement; it does not yet
animate individual eyes/hands or a hinged folio.

The next acting refinement is one shared performance: Travi gives a proud
glance, then presents the tickets with an open palm. Comparison copy stays
still, and the free exit receives the same warm handoff as a purchase.
Country-first scenery continues in [the art register](onboarding/DESTINATION_ART_REGISTER.md):
25 country stages, Bali/Kyoto exceptions, actual city names live and neutral
fallback for unillustrated destinations. New countries reuse the foreground
and ticket/button atlas; no country-specific character film is required.

## Verification

The full Flutter suite passed **734 tests**, and static analysis reports no
issues. Tests exercise remote package/name/price changes, localized euro
formatting, invalid billing periods, removal without automatic Annual
selection, overlapping refreshes, loading/failure without fabricated prices,
actual saved identity/dates, duplicate taps, purchase cancellation/failure,
restore, inherited coverage, Back/free and a 320-point phone with 2× type.

The [native iPhone 17 Pro/iOS 26.1 captures](mockups/onboarding-pass-desk-v2/README.md) verify both selections, the updated prices, Back preservation and free handoff into the same saved holiday. Final typography/spacing polish passed all 19 targeted onboarding/pass tests. Scroll reachability was verified in widgets; native pointer automation could not scroll the simulator ListView. Live dashboard/product availability, production billing, Android
and physical-device verification remain separate checks.
