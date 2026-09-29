import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../logic/art_pack_selection.dart';
import 'art_catalog.dart';
import 'card_shells.dart' show FractionRect;

/// Every raster icon the interface places, with its catalog name
/// (`icons/<name>.png`, overridable by an installed pack) and the Material
/// glyph shown only while that file doesn't exist yet. Missing files are
/// listed in docs/ART_ASSET_GAPS.md.
enum IconSlot {
  flight('flight', Icons.flight_takeoff_rounded),
  stay('stay', Icons.hotel_rounded),
  attraction('attraction', Icons.confirmation_number_rounded),
  dining('dining', Icons.restaurant_rounded),
  transport('transport', Icons.directions_car_rounded),
  activity('activity', Icons.explore_rounded),
  event('event', Icons.theater_comedy_rounded),
  note('note', Icons.sticky_note_2_rounded),
  navToday('nav_today', Icons.home_rounded),
  navTrips('nav_trips', Icons.luggage_rounded),
  navDocuments('nav_wallet', Icons.description_outlined),
  navProfile('nav_profile', Icons.person_outline_rounded),
  navAdd('nav_add', Icons.add_rounded),
  weatherSunny('weather_sunny', Icons.wb_sunny_rounded),
  weatherCloudy('weather_cloudy', Icons.cloud_rounded),
  weatherRain('weather_rain', Icons.umbrella_rounded),
  weatherSnow('weather_snow', Icons.ac_unit_rounded),
  calendar('calendar', Icons.calendar_today_rounded),

  /// A stop on the day timeline, and the stop happening now. While these
  /// are missing the timeline draws plain dots.
  timelineStop('timeline_stop', Icons.circle),
  timelineNow('timeline_now', Icons.radio_button_checked);

  const IconSlot(this.key, this.fallback);

  final String key;
  final IconData fallback;

  static IconSlot forKind(BookingKind kind) => switch (kind) {
    BookingKind.flight => flight,
    BookingKind.stay => stay,
    BookingKind.attraction => attraction,
    BookingKind.dining => dining,
    BookingKind.transport => transport,
    BookingKind.activity => activity,
    BookingKind.event => event,
    BookingKind.note => note,
  };
}

/// Raster surfaces of the interface chrome (`common/<name>.png`). Until a
/// file exists the interface draws the plainest usable stand-in (a flat
/// colour, or nothing where the element is optional), never an imitation
/// of the material.
enum SurfaceSlot {
  /// Oatmeal linen behind every screen, tiled.
  linen('linen'),

  /// Navy leather strip under the home tabs, in the bottom safe area.
  leather('leather'),

  /// Cream canvas home tab. The tab itself spans [body] of the image (the
  /// rest is margin and shadow); its foot runs off the bottom edge.
  tab('tab', body: FractionRect(0.080, 0.290, 0.920, 1.0)),

  /// The selected home tab: a finished petrol-teal canvas, drawn as it is
  /// (never tinted). A destination pack may override it with its own.
  tabSelected('tab_selected', body: FractionRect(0.062, 0.277, 0.938, 1.0)),

  /// The coral add tab.
  tabAdd('tab_add', body: FractionRect(0.076, 0.292, 0.924, 1.0)),

  /// The raised pill behind the weather or countdown.
  pill('pill'),

  /// Inked stamp frame for "Show tickets" on tickets that don't print one.
  stamp('stamp'),

  /// The blank luggage tag hung on the countdown postcard (1024 × 1536):
  /// warm-ivory card, brass eyelet, cord running up and off to the right.
  /// Every word on it is live text.
  countdownTag('countdown_luggage_tag', body: FractionRect(0.170, 0.261, 0.788, 0.982)),

  /// A small tag under the countdown postcard holding one fact ("4 days").
  countdownFact('countdown_fact_tag'),

  /// The ticket-shaped "View trip" button under the countdown.
  countdownButton('countdown_button');

  const SurfaceSlot(this.key, {this.body});

  final String key;

  /// For objects drawn with margin round them: where the object itself is,
  /// as fractions of the image (measured from the supplied files; pack
  /// versions are made to the same template).
  final FractionRect? body;
}

/// The destination postcard behind the countdown to the next trip
/// (`common/countdown_postcard.png`, 1122 × 1402). Nothing is bundled:
/// only a pack that suits the trip supplies one (see
/// `TravelStore.countdownPostcardFor`), so a trip never shows another
/// place's postcard.
const countdownPostcardArt = 'countdown_postcard';

/// A coming trip's landscape postcard on the Trips tab
/// (`common/trip_postcard.png`, 1536 × 1024), with the countdown tag hung
/// on it. Like [countdownPostcardArt], only a pack that suits the trip
/// supplies one (`TravelStore.tripPostcardFor`); without it the trip keeps
/// its plain row.
const tripPostcardArt = 'trip_postcard';

/// A resolved icon: the raster file, or the stand-in glyph.
class IconArt {
  const IconArt({required this.slot, this.art});

  final IconSlot slot;
  final SharedArtRef? art;

  ArtImageRef? get image => art?.image;

  /// True while the raster file is missing.
  bool get isFallback => art == null;
}

/// Resolves icons and surfaces for one trip context, in the same ranked
/// order as card art (installed packs first where they suit the trip).
class ArtSlots {
  const ArtSlots(this.catalog, this.context);

  /// Bundled art only, no trip.
  ArtSlots.bundled(this.catalog) : context = null;

  final ArtCatalog catalog;
  final TripArtContext? context;

  IconArt icon(IconSlot slot) => IconArt(
    slot: slot,
    art: catalog.iconArt(slot.key, context: context),
  );

  ArtImageRef? surface(SurfaceSlot slot) => catalog.common(slot.key, context: context);
}
