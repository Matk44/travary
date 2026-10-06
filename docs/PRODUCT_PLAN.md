# Travary product plan (Sept 2026)

## Positioning

"You planned it. Travary keeps everyone on it." The calm, beautiful day-of
companion for holidays. Initial focus: family theme-park and resort trips
(complex, high-spend, mixed iPhone/Android families, active planning communities).

Gaps versus competitors: nobody is built around *today* (TripIt organises,
Wanderlog plans, Tripsy is Apple-only at $59.99/yr); sharing is paywalled or
view-only; parsing errors erode trust; the category looks dated.

## Who pays

- **Organiser** (buyer): one per group; wants less admin, everyone self-serving,
  peace of mind.
- **Travellers** (free, the growth channel): "tell me where to be, show my ticket".
- **Frequent traveller**: annual / lifetime.

## Tiers (starting point, A/B test via RevenueCat)

| | Free | Trip Pass $7.99 (per trip) | Plus $34.99/yr |
|---|---|---|---|
| Unlimited trips + manual bookings, Today, Wallet, offline tickets | ✓ | ✓ | ✓ |
| Travel documents (passports, visas, insurance) on this phone, behind Face ID, with expiry checks | ✓ | ✓ | ✓ |
| Countdown widget, read-only share link | ✓ | ✓ | ✓ |
| Smart Import (screenshot / PDF / email) | 3 total | ✓ that trip | ✓ unlimited |
| Family co-planning, tickets on everyone's phone (up to 6) | – | ✓ that trip | ✓ |
| Cloud backup and sync of tickets | – | ✓ that trip | ✓ |
| Flight alerts, Live Activity, "leave by" reminders | – | ✓ that trip | ✓ |

- "Plus travels with the trip": members invited by a Plus organiser get Plus on that trip.
- No monthly plan (the Trip Pass replaces it). Trip Pass holders get annual at
  $26.99 for the first year ("your pass counts toward Plus").
- Optional founding lifetime at $79.99, launch only, capped.

## Paywall moments

No free trial and no trial reminders: premium sells itself at the moment
it's needed ("share it with the family", "don't miss anything").

1. Contextual: 4th import, inviting a co-planner, enabling alerts, backup.
2. Trip Readiness meter steps that are Plus.
3. T-10 days before a trip: Trip Pass offer.
4. Renewal: value recap two weeks before.

**Never:** a paywall on open during a trip, blocking tickets, fake urgency,
a free trial or a "your trial is ending" reminder.

## Onboarding (day 0 decides most conversions)

Destination and dates → who's coming → first booking via import (free) →
"Here's your Day 1 morning" → dismissible paywall → notifications prompt →
account only when inviting, backing up or buying (anonymous auth first).

## Growth loops

Invite loop (web preview → install) · "Share today's plan" image for family
chats · post-trip ticket-stub recap · give-a-pass referral · design-led short
videos (stub tear-off, ticket "printing" on import).

## Build phases

- **Foundation (done):** domain, day/trip logic, demo + Firestore data,
  Today / Trips / Wallet / detail / form, art system, tests.
- **Design phase:** travel-ephemera interface on top (cards, artwork, nav, header).
- **v1.0:** premium plumbing (done), Smart Import (done, Gemini via Google AI
  Studio), family sharing + ticket backup (done), RevenueCat paywalls,
  onboarding, analytics funnel events.
- **v1.1:** flight alerts, Live Activity, "leave by", email-forward import.
- **v1.2:** memories and recap, referrals, year-in-travel.
- **Later (documents):** end-to-end encrypted family sharing of travel
  documents (Plus); trip "readiness" shared as statuses only ("3 of 4
  passports ready"), never contents; passport scan reading the
  machine-readable zone on the phone; blurring the app switcher snapshot.

## Decisions

- Prices confirmed: Plus $34.99/yr, Trip Pass $7.99. No free trial (decided
  2026-10-04): premium features sell themselves where they're needed.
- Trip Pass (decided 2026-10-04, refined 2026-10-06): one trip of at most
  30 days, bought for the dates it had then, until 7 days after it ends. It
  grows with the same holiday (adding the flight home later stays covered,
  up to 30 days) but never moves to another one: changing the trip to other
  dates or another place doesn't carry the pass. Longer trips are offered
  Plus instead.
- Family permissions (decided 2026-10-04): everyone on a trip sees all
  bookings and tickets and can add bookings. You edit and delete your own;
  the organiser can edit and delete anything. Deletes can be undone.
  Passports and visas never leave each person's phone.
- AI: Gemini via Google AI Studio, server-side (accuracy first: a wrong AM/PM
  destroys trust, so imports are always a draft to confirm).
- Firebase project on the Blaze plan.
- Bundle ID and Android application ID: `com.travary.app`.

## Open decisions

- Founding lifetime offer: yes/no.
