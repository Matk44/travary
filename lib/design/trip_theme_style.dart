import 'package:flutter/material.dart';

import '../domain/domain.dart';
import 'tokens.dart';

/// Colour and icon for a trip's theme, used on trip tiles until each theme
/// has its own cover artwork.
({Color color, IconData icon}) tripThemeStyle(TripTheme theme) => switch (theme) {
  TripTheme.classic => (color: TravaryColors.ink, icon: Icons.luggage_rounded),
  TripTheme.tropical => (color: TravaryColors.coral, icon: Icons.beach_access_rounded),
  TripTheme.city => (color: TravaryColors.teal, icon: Icons.location_city_rounded),
  TripTheme.snow => (color: const Color(0xFF6F8FAF), icon: Icons.ac_unit_rounded),
  TripTheme.countryside => (color: const Color(0xFF6E8B5E), icon: Icons.forest_rounded),
  TripTheme.themepark => (color: TravaryColors.plum, icon: Icons.attractions_rounded),
};
