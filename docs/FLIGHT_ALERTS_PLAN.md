# Flight alerts: plan and provider brief

Status: **built 12 Oct 2026, not deployed** (see "As built" below and the
Flight alerts section of CLAUDE.md). Launched on AeroDataBox Pro behind
the `FlightProvider` interface; gates and belts are shown and announced
only when the data has them.

## As built (12 Oct 2026)

Differences from the plan below, and why:

- **Polling:** 3 days before (schedule changes), the day before, every 4
  hours on the day, every 40 then 20 minutes in the last 3 hours, at
  take-off until it's gone, 30 minutes before landing then every 10, and
  the belt every 15 minutes for 45 minutes after landing. About 20 checks
  (40 units) for a typical flight with units to spare; 13 when spending runs
  ahead of the month (`tight`), 10 when under a tenth is left (`low`: only
  the last 3 hours and the flight itself), none below a reserve kept for
  the flight page (`out`). So 5,000 units cover roughly 125 flights a month
  at the normal pace, more as the guard slows down. Airport-board sharing
  and AeroDataBox webhooks aren't used yet.
- **Change detection** compares with what was last *announced*, not the
  last answer, so small drifts add up to news. The first answer is the
  baseline (silent) unless it's a cancellation. Gate, terminal and belt
  are announced when they appear or change, never when they vanish.
- **Push tokens** live in `pushTokens/{sha256(token)}` {uid, token,
  platform} instead of `users/{uid}/devices`: one doc per phone, so
  registering on another account moves the phone (no pushes to an account
  signed out of it). Deleted with the account and on guest adoption.
- **Who hears:** everyone on the trip with premium on it (the trip's
  stamp, their own Plus, or `tester`), the same rule as `hasPremium`. On a
  trip with a Holiday Pass or its organiser's Plus that's everyone.
- **Kill switch:** `config/flightAlerts` {paused: true} in Firestore
  (params need a deploy). `FLIGHT_ALERTS_ENABLED` turns the checker off at
  deploy time.
- **Permission:** asked the first time a flight on a paid trip is opened,
  once; the flight page's "Flight alerts" row shows where things stand
  (or sells alerts on a free trip).
- **On sale** in release builds only with `--dart-define=TRAVARY_FLIGHT_ALERTS=true`.

Before turning it on: deploy functions, rules and index
(`firebase deploy --only functions,firestore`), upload an APNs auth key
to Firebase (Cloud Messaging), enable Push Notifications on the App ID,
set `FLIGHT_BILLING_DAY` to the day the API.Market plan renews, update
`privacy.html` and the store forms (`docs/ANALYTICS.md`), then build with
`TRAVARY_FLIGHT_ALERTS=true`. Mark accounts `tester: true` to try it
without a purchase.

## The plan (11 Oct 2026)

Originally: planned, not built (11 Oct 2026). The provider isn't chosen yet:
AeroDataBox is tested and works for flight *changes*; the question is
whether another service also gives **gates and baggage belts** at UK and
US airports at a sensible price. Provider research was done the same day
(see "Provider research (11 Oct 2026)" at the end): launch on AeroDataBox.
Owner budget, 11 Oct 2026: about $30 a month for the data provider, so
FlightAware (from $100) and a Cirium alerts contract are out; Cirium is
worth only a free check of its pay-as-you-go price.

## What we want to offer (paid: Holiday Pass or Plus)

"Flight changes, the moment they happen, for everyone on the trip": a push
to every phone on the trip, and a live line on the flight's card on Today.

| Change | Must have | Nice to have |
|---|---|---|
| Delay, new departure or arrival time | ✓ | |
| Schedule change (moved earlier or later days ahead) | ✓ | |
| Cancelled, diverted | ✓ | |
| Check-in open / boarding / gate closed / departed / landed | ✓ | |
| Terminal | ✓ | |
| Gate number and gate changes | | ✓ (UK and US matter most) |
| Baggage belt | | ✓ |
| Check-in desk or zone | | ✓ |

Free users keep the on-demand status on the flight's own page on the day
(already built, cached); pushed alerts to the whole family come with a pass.

Markets that matter most: UK departures (LHR, LGW, MAN, BHX, STN, BRS,
EDI, GLA, DUB) and US arrivals (MCO, MIA, JFK, LAX, LAS, HNL), plus Spain,
Portugal, Greece, Italy, France for European holidays.

Owner, 11 Oct 2026: the UK is only a small part of the audience, so this
list is a guess. Gate and belt coverage turned out to depend on the airline
and airport, not the country, so decide on the airports users actually
book (see the research's next steps).

## What we found with AeroDataBox

Tested 11 Oct 2026 about 06:20 UK time with our key, API v1.15.4, through
API.Market (`functions/src/flightStatus.ts` already calls it).

- **Plan:** Pro is $7.50 a month for 5,000 units, a hard limit (calls fail
  once used up), 1 request per second. Commercial use is allowed on Pro, not
  on the free Basic plan. No B2B sublicensing.
- **Cost per call:** flight status by number (single day) and airport boards
  (FIDS) are Tier 2, 2 units. Webhook subscriptions are free to create, list
  and remove; a balance refill is 1 unit.
- **Push alerts (Flight Alert API, 2026 credit model):** subscribe by flight
  number or airport; each flight item in a notification costs 1 credit
  (1 credit = 1 unit, refilled from the monthly units). A flight-number
  subscription covers that number from 6 hours ago to 72 hours ahead, so a
  daily flight also sends updates for the next days' flights. Delivery is
  best effort ("might be missing or delayed"), 10-second timeout, retries
  cost extra. Payload: `FlightNotificationContract` with full flight items.
- **Coverage:** live feeds report OK at LHR, LGW, MAN, BHX, DUB, PMI, MCO,
  JFK, LAX, LAS, HNL (free check: `GET /health/services/airports/{icao}/feeds`).
- **Fields in practice** (airport boards, next ~4 hours):

  | Airport | Flights | Revised times | Status | Terminal | Gate | Belt |
  |---|---|---|---|---|---|---|
  | LHR | 132 | all | Boarding, Delayed, Cancelled, Arrived | all | **0** | 1 |
  | LGW | 132 | all | Boarding, GateClosed | most | **0** | 0 |
  | MCO | 51 | all | Departed, Arrived, Approaching | most | **0** | 0 |
  | LAX | 253 | all | Departed, Arrived | most | **0** | 0 |
  | AMS | 215 | all | all of them | most | 82 of 95 departures | 29 arrivals |

  Gates and belts exist only where the airport shares them with
  AeroDataBox (Amsterdam yes; Heathrow, Gatwick, Orlando, LAX no). Its own
  coverage page marks gate, check-in desk and belt as "sometimes".

## How we'd build it (provider-agnostic)

1. **Watch list, server-side.** When a flight booking with a flight number
   is saved in a trip with premium (`trip.premium` active), a Firestore
   trigger upserts `watchedFlights/{NUMBER_date}`: flight number, local
   departure date and airport, the trips and users to tell, last known
   state, next check time. One document per flight per day, shared by
   everyone on it. Removed when the booking goes, premium ends, or the
   flight is done (landed plus the belt window).
2. **Checking.** A scheduled function every 5 minutes checks only the
   watched flights that are due, through one `FlightProvider` interface (so
   the provider can change):

   | When | How often |
   |---|---|
   | Booked until 24 hours before | Not at all (one check at 24 hours) |
   | 24 to 3 hours before | Every 2 hours |
   | 3 hours before to departure | Every 15 minutes |
   | In the air | Once 30 minutes before landing, then every 10 until landed |
   | After landing | Every 10 minutes until a belt appears, at most 1 hour |

   About 10–15 checks per flight. Several watched flights at one airport on
   one day can share one airport-board call. With webhooks instead, the
   same watch list subscribes about 24 hours before departure and removes
   the subscription after landing.
3. **Change detection.** Compare each result with the stored state; only a
   change in departure or arrival time (beyond 5 minutes), status, terminal,
   gate, belt or cancellation sends anything. Store the new state; the
   app's Today card reads it for its live line.
4. **Push.** Firebase Cloud Messaging: device tokens in
   `users/{uid}/devices/{token}` (the app asks for notification permission
   the first time someone opens a flight in a paid trip, not at launch),
   one notification per change to everyone on the trip: "BA2037 now leaves
   at 09:40, an hour earlier." Quiet hours aren't needed: changes are what
   people want, day or night.
5. **Budget guard.** Count units per day against the plan; when the month
   runs short, check only flights within 3 hours of departure and stop
   pre-departure checks; never fail the app (status shows "last checked at").
   A kill switch param turns alerts off without a deploy.
6. **Gating.** Only trips with `premium` active are watched (server-side, so
   it can't be faked); the on-demand page status stays for everyone.

Configuration: the provider key as a Secret Manager secret (now
`AERODATABOX_API_KEY`), plan limits and the polling table as
`functions/.env` params (`FLIGHT_ALERTS_ENABLED`, `FLIGHT_UNITS_PER_MONTH`,
`FLIGHT_RATE_PER_SECOND`), APNs key in Firebase for iOS push.

Rough cost on AeroDataBox Pro: 20–30 units per flight, so 5,000 units cover
about 170–250 flights a month (roughly 100 paid trips with a flight out and
home), about $0.09 of calls per paid trip.

Effort: about 1–2 weeks (push setup, watch list, scheduler, change
detection, Today card line, tests).

## Brief for evaluating other providers

Questions to answer for each candidate:

1. Gates, gate changes and baggage belts at LHR, LGW, MAN, MCO, JFK, LAX
   in practice (not just in the schema). Test the same flights.
2. Delays, schedule changes, cancellations, statuses: coverage and latency.
3. Push alerts or webhooks: billing (per alert, per flight, per month),
   reliability, payload, subscription by flight and date.
4. Price at our scale: about 200 flights a month at launch, 5,000+ later.
   Minimum monthly commitment.
5. Commercial use allowed for a consumer app on the plan; display or
   caching restrictions; attribution.
6. Rate limits; how quota overage behaves.
7. How to look up a flight: by flight number and local date, IATA codes.

Candidates to check (not verified): FlightAware AeroAPI (widely used for
US gates, alerts available), Cirium/FlightStats, OAG, Flightradar24 API,
AirLabs, Aviationstack, FlightAPI.io, and airline or airport feeds directly.

A fair test: pick 10 real flights departing LHR, LGW and MAN and arriving
MCO, JFK and LAX on one day; query each provider at 3 hours, 1 hour and 15
minutes before departure and 15 minutes after landing; record which
fields are present.

## Provider research (11 Oct 2026)

Desk research against the brief above. No provider keys were used. The only
data seen first-hand is Cirium's, read from its public FlightStats flight
pages (same data family as its Flex API, but not the API itself). Everything
else comes from each provider's own pricing and documentation pages, and
forum threads, linked under Sources.

### Recommendation

1. **Cirium (FlightStats / Flex) has the best gate data, but doesn't fit a
   budget of about $30 a month.** It is the only candidate where gate
   numbers actually appeared, and its alerts have departure-gate,
   arrival-gate and baggage events. But Alerts are on the Contract plan
   only with no public price (enterprise scale), and belts and arrival
   gates were patchy. Don't chase the contract. The one cheap thing worth
   doing is the free evaluation, to read the self-serve Commercial plan's
   price per Flight Status call (login-gated). Only consider it as an
   on-demand or few-checks-per-flight gate layer, and only if a call costs
   about 2 cents or less (about 1,200 calls a month for 200 flights).
2. **Launch on AeroDataBox** ($7.50 a month) for what it does well (delays,
   new times, cancellations, boarding, landed, terminals) behind the
   `FlightProvider` interface. FlightAware's $100 minimum is also over
   budget, and its webhooks skip ordinary delays anyway.
3. **Treat gates and belts as best effort with any provider.** Coverage
   follows the airline and the airport, not the country. Sell "flight
   changes"; show a gate or belt only when the data has one; never promise
   one.

### What Cirium showed (all airports, not just the UK)

Morning of Sunday 11 Oct 2026 (about 09:10 to 09:55 BST), about 40 flights
touching more than 30 airports, one snapshot each (some flights read for
both 10 and 11 Oct). Not the brief's 3 h / 1 h / 15 min
protocol, and no live gate *changes* were observed, so gate-change alerts
are untested.

| Measure | Result |
|---|---|
| Departure gate on flights that had already departed | **18 of 24** |
| Departures with no gate | Rome FCO 0 of 3 (ITA, Air India, TAP), Lisbon (TAP), Athens (Aegean), Chicago O'Hare (BA) |
| Arrival gate on flights that had landed | 5 of 17 |
| Baggage belt on flights that had landed | **5 of 17** (LHR, MCO, MXP, ORY, ZRH) |
| Gates shown hours before departure | US airlines at JFK, MIA, LAS, SFO (AA, DL, UA, WN) |

By airport (departure gate unless stated):

| Airport | What appeared |
|---|---|
| LHR | 5 of 5 departed had a gate (BA T5, VS T3); BA283 showed B39 with 1h23 to go. Arrival belt on 1 of 1 landed (VS4, belt 03) |
| LGW | Gate 27 on the previous day's departure, but none 1h40 before takeoff on the day. Arrival: terminal only |
| MAN | VS127 gate C14 almost 6 hours ahead. Arrival gate C7 on VS128, no belt |
| JFK | Gates on AA, DL and (once departed) VS; none on BA178 3h40 ahead or AF7. Arrivals: no gate or belt on any of the 6 seen, 2 of them landed |
| MCO | Departure gate 242; arrival gate 242 and belt C66, identical two days running (may be an airline default, not live) |
| LAX | AA1 arrival: gate 41, belt T4C2. BA283 arrival: nothing, even after landing |
| FRA, AMS, MAD, PMI, CDG, MIA, LAS, SFO, DXB, AKL | Gates on every flight sampled (AMS matches AeroDataBox's own Amsterdam result) |
| FCO | 0 of 3 departures (ITA, Air India, TAP), all already departed |
| LIS, ATH | Mixed by airline: Swiss and Lufthansa had gates, TAP and Aegean did not |

Limits of this evidence: one morning, mostly large carriers, read by a
summarising fetch tool, from the consumer site rather than the API. A gate
being present does not mean it is right.

### Against AeroDataBox

AeroDataBox's boards had 0 gates at LHR, LGW, MCO and LAX, and almost no
belts. Cirium had departure gates at LHR and MCO and arrival gate and belt
at MCO and LAX (AA) on the same days. At Amsterdam both have gates, so the
gap is at the airports that don't share gates with AeroDataBox. We have not
yet tested AeroDataBox on FRA, CDG, MAD, PMI, MIA, LAS or SFO, where Cirium
looked good; it may match there. Test before assuming it doesn't.

### Providers compared

| Provider | Gates and belts in practice | Push alerts | Price at ~200 flights/month | Commercial use |
|---|---|---|---|---|
| AeroDataBox (tested) | None at LHR, LGW, MCO, LAX; belts almost none; Amsterdam good | Yes, 1 credit per flight item, best effort, 6 h back to 72 h ahead | $7.50/month (Pro, 5,000 units) | Yes on Pro |
| Cirium (FlightStats / Flex) | Seen, see above; belts patchy | Gate, arrival gate and baggage events exist, **Contract plan only**; one rule per flight ends with the flight | Unpublished. Flight Status by flight is on the self-serve Commercial plan (login-gated price). Eval: 30 days, 20,000 calls, Alerts capped at 1,000 | Not stated; ask sales |
| FlightAware AeroAPI | Fields exist (`gate_origin`, `gate_destination`, `terminal_*`, `baggage_claim`, all nullable); coverage unverified | From Standard, $0.02 per push. A reply in April 2026 says webhooks don't push ordinary delays (only diversion or hold): poll `/flights/{ident}`. Failed pushes aren't retried; 2026 threads report undelivered alerts | Standard $100/month minimum. Polling 200 flights x 15 checks x $0.005 is about $15, inside the minimum | Yes, consumer (B2C), on Standard and up |
| AirLabs | `dep_gate`, `arr_baggage` fields; schedules look at most 10 hours ahead | Webhooks in beta (unverified) | Third-party figures only; pricing page not read | Free plan unclear |
| Aviationstack | Fields exist; sample values null | None found | $49.99/month for 10,000 requests | Yes from Basic |
| Aviation Edge | Gate in schedules; no belts | None found | $299/month (the $7 is a first-month trial) | Not stated |
| Flightradar24 | None found (ADS-B, runway times) | None found | Credit plans from about $9/month | Unclear |
| OAG | Gate and baggage in its data description | Yes; webhook reliability poorly documented | Pricing after signup; 14-day, 100-call trial | Unclear |
| FlightAPI.io | Gate "where available"; no belts | None found | From $49/month | Unclear |

Notes:

- Cirium rates a D on one third-party API report card (docs split across
  three portals, static key auth, no SDK). Contract spend is enterprise
  scale; one buyer guide averages about $31,000 a year across all Cirium
  products, which says nothing exact about Flex Alerts.
- FlightAware prices differ across third-party articles ($25 and $100 for
  10,000 calls appear); the figures here are from FlightAware's own page.
- A FlightAware forum reply (Jan 2024; the poster isn't labelled as
  staff) says they usually get gate identity from airline-specific feeds
  they pay for or reach by partnership. That fits the airline-by-airline
  pattern above, and likely applies to every provider.

### What this changes in the build

- Gate, belt, check-in desk and terminal are optional fields everywhere
  (state, change detection, push wording, the Today card line). No alert
  for a field that was never present; "gate not announced yet" is a normal
  state, not an error.
- Change detection stays provider-side-agnostic: poll and diff. Even with
  FlightAware or Cirium alerts, time changes still need a poller, so the
  scheduler in the build section stays as designed.
- If Cirium Alerts are bought, subscribe per flight when the watch list
  adds it (the rule ends with the flight), and keep the poller as the
  fallback for missed pushes.
- Add a post-landing check for the belt (already in the polling table) and
  a last check about 15 minutes before departure, since gates often appear
  late (Gatwick showed none 1h40 out).

### Next steps

1. **Find the real airports.** Count departure and arrival airports across
   users' flight bookings in Firestore and take the top 10 to 20. Replace
   the UK and US assumption above with that list.
2. **AeroDataBox on the same flights first** (cheapest, already paid for),
   including FRA, CDG, MAD, PMI, MIA, LAS and SFO, where Cirium had gates.
   `GET /health/services/airports/{icao}/feeds` is free and airport boards
   are 2 units a call. If it fills gates at the airports that matter, the
   gate question is closed at no extra cost.
3. **Cirium free evaluation** (30 days, 20,000 calls; Alerts capped at
   1,000): read the Commercial plan's price per call, and only if it is
   about 2 cents or less, run the brief's protocol on the top airports at
   3 h, 1 h, 15 min and after landing. Skip the Contract and sales route
   at this budget.
4. **FlightAware Personal key** is for testing only (free under $5 of
   queries a month, personal and academic use only, no alerts). Useful to
   see whether it fills gates outside the US, but it can't ship.
5. Decide per the results, within about $30 a month: gate and belt data
   only where AeroDataBox already has it. Otherwise ship AeroDataBox
   "flight changes" and show a gate or belt when present. Revisit a paid
   gate layer when paid trips make $100 a month affordable. Cost scales
   with paid trips, so any gate layer should run only for paid trips.

### Sources

- Cirium: [Alerts API](https://developer.flightstats.com/api-docs/alerts/v1),
  [getting started and plans](https://developer.flightstats.com/getting-started/),
  [Flight Status](https://developer.flightstats.com/api-docs/flightstatus/v2),
  [example flight page](https://www.flightstats.com/v2/flight-tracker/BA/283),
  [report card](https://supergood.ai/api-report-card/cirium),
  [Vendr](https://www.vendr.com/buyer-guides/cirium)
- FlightAware: [AeroAPI pricing](https://www.flightaware.com/commercial/aeroapi/),
  [OpenAPI spec](https://static.flightaware.com/rsrc/aeroapi/aeroapi-openapi.yml),
  [delays and webhooks](https://discussions.flightaware.com/t/flight-delay-notifications-via-webhook/100256),
  [alerts and polling](https://discussions.flightaware.com/t/is-aeroapi-the-right-tool-to-automate-alerts/100557),
  [undelivered alerts](https://discussions.flightaware.com/t/aeroapi-alerts-not-being-delivered-confirmed-flight-event-without-notification-alert-id-106060439/100235),
  [gate and terminal change alerts](https://discussions.flightaware.com/t/flight-gate-and-terminal-changes/73932),
  [gate coverage reply, 2013](https://discussions.flightaware.com/t/gate-information/13915),
  [where gate data comes from, 2024](https://discussions.flightaware.com/t/departure-and-arrival-gates-and-runways/19038)
- Others: [AirLabs schedules](https://airlabs.co/docs/schedules),
  [Aviationstack pricing](https://aviationstack.com/pricing),
  [Aviation Edge plans](https://aviation-edge.com/premium/),
  [OAG report card](https://supergood.ai/api-report-card/oag),
  [OAG flight status data](https://www.oag.com/flight-status-data),
  [Flightradar24 API](https://www.flightradar24.com/blog/b2b/how-to-get-started-with-the-flightradar24-api/),
  [FlightAPI.io comparison](https://www.flightapi.io/blog/flight-status-apis/),
  [AeroDataBox's own comparison](https://aerodatabox.com/flight-api-2024)
