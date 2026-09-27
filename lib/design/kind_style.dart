import 'package:flutter/material.dart';

import '../domain/domain.dart';
import 'tokens.dart';

/// The physical object each kind of card imitates.
enum CardShape {
  /// Flights: boarding pass.
  boardingPass,

  /// Stays: hotel key card with a magnetic stripe.
  keyCard,

  /// Parks, activities, shows: admission ticket with a tear-off stub.
  ticket,

  /// Restaurants: reservation card with a luggage tag.
  reservation,

  /// Transfers, trains, car hire: travel ticket.
  travelTicket,

  /// Reminders: paper note.
  note,
}

/// Colours for a card drawn without artwork.
class CardPalette {
  const CardPalette(this.background, this.foreground, this.accent);

  final Color background;
  final Color foreground;
  final Color accent;
}

/// How a kind of booking looks: icon, shape and placeholder palettes.
///
/// Placeholder palettes stand in until real artwork is added to
/// `assets/art/<kind>/`. Each booking gets one of them by its stable
/// variant number, so a page of cards has some variety.
class KindStyle {
  const KindStyle({required this.icon, required this.shape, required this.palettes});

  final IconData icon;
  final CardShape shape;
  final List<CardPalette> palettes;

  CardPalette palette(int variant) => palettes[variant % palettes.length];

  static KindStyle of(BookingKind kind) => switch (kind) {
    BookingKind.flight => _flight,
    BookingKind.stay => _stay,
    BookingKind.attraction => _attraction,
    BookingKind.dining => _dining,
    BookingKind.transport => _transport,
    BookingKind.activity => _activity,
    BookingKind.event => _event,
    BookingKind.note => _note,
  };
}

const _paperInk = CardPalette(TravaryColors.paper, TravaryColors.ink, TravaryColors.coral);

const _flight = KindStyle(
  icon: Icons.flight_takeoff_rounded,
  shape: CardShape.boardingPass,
  palettes: [
    CardPalette(TravaryColors.tealDeep, TravaryColors.paper, TravaryColors.coral),
    CardPalette(TravaryColors.ink, TravaryColors.paper, TravaryColors.mustard),
    CardPalette(Color(0xFF2F6F7E), TravaryColors.paper, TravaryColors.paper),
  ],
);

const _stay = KindStyle(
  icon: Icons.hotel_rounded,
  shape: CardShape.keyCard,
  palettes: [
    _paperInk,
    CardPalette(Color(0xFFF1E9DA), TravaryColors.ink, TravaryColors.teal),
    CardPalette(Color(0xFFEAF0EA), TravaryColors.ink, TravaryColors.sage),
  ],
);

const _attraction = KindStyle(
  icon: Icons.confirmation_number_rounded,
  shape: CardShape.ticket,
  palettes: [
    CardPalette(TravaryColors.teal, TravaryColors.paper, TravaryColors.coral),
    CardPalette(TravaryColors.plum, TravaryColors.paper, TravaryColors.mustard),
    CardPalette(TravaryColors.tealDeep, TravaryColors.paper, TravaryColors.sage),
  ],
);

const _dining = KindStyle(
  icon: Icons.restaurant_rounded,
  shape: CardShape.reservation,
  palettes: [
    _paperInk,
    CardPalette(Color(0xFFF4ECDF), TravaryColors.ink, TravaryColors.teal),
    CardPalette(Color(0xFFF6EEE6), TravaryColors.ink, TravaryColors.plum),
  ],
);

const _transport = KindStyle(
  icon: Icons.directions_car_rounded,
  shape: CardShape.travelTicket,
  palettes: [
    CardPalette(Color(0xFFE6EDE5), TravaryColors.ink, TravaryColors.teal),
    CardPalette(Color(0xFFF1E9DA), TravaryColors.ink, TravaryColors.coral),
    CardPalette(Color(0xFFE8ECF2), TravaryColors.ink, TravaryColors.ink),
  ],
);

const _activity = KindStyle(
  icon: Icons.explore_rounded,
  shape: CardShape.ticket,
  palettes: [
    CardPalette(Color(0xFF7A8F5C), TravaryColors.paper, TravaryColors.mustard),
    CardPalette(TravaryColors.teal, TravaryColors.paper, TravaryColors.coral),
    CardPalette(Color(0xFFB0643F), TravaryColors.paper, TravaryColors.paper),
  ],
);

const _event = KindStyle(
  icon: Icons.theater_comedy_rounded,
  shape: CardShape.ticket,
  palettes: [
    CardPalette(TravaryColors.plum, TravaryColors.paper, TravaryColors.mustard),
    CardPalette(Color(0xFF8E3B46), TravaryColors.paper, TravaryColors.paper),
    CardPalette(TravaryColors.ink, TravaryColors.paper, TravaryColors.coral),
  ],
);

const _note = KindStyle(
  icon: Icons.sticky_note_2_rounded,
  shape: CardShape.note,
  palettes: [
    CardPalette(Color(0xFFF3E4C4), TravaryColors.ink, TravaryColors.coral),
    CardPalette(Color(0xFFEFE3D0), TravaryColors.ink, TravaryColors.teal),
  ],
);
