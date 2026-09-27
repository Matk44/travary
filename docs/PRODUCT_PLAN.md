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

| | Free | Trip Pass $7.99 (per trip) | Plus $34.99/yr (14-day trial) |
|---|---|---|---|
| Unlimited trips + manual bookings, Today, Wallet, offline tickets | ✓ | ✓ | ✓ |
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

1. Onboarding, after the aha moment (their first booking rendered on their Day 1).
2. Contextual: 4th import, inviting a co-planner, enabling alerts, backup.
3. Trip Readiness meter steps that are Plus.
4. T-10 days before a trip: Trip Pass offer.
5. Renewal: value recap two weeks before.

**Never:** a paywall on open during a trip, blocking tickets, fake urgency.
Transparent trial timeline and a reminder 2 days before charging (Blinkist
reported +23% trial starts and −55% complaints with this approach).

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

## Decisions

- Prices confirmed: Plus $34.99/yr (14-day trial), Trip Pass $7.99.
- AI: Gemini via Google AI Studio, server-side (accuracy first: a wrong AM/PM
  destroys trust, so imports are always a draft to confirm).
- Firebase project on the Blaze plan.

## Open decisions

- Founding lifetime offer: yes/no.
- Release bundle ID (currently `com.travary.travaryTemp`).
