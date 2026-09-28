import 'package:flutter/material.dart';

import '../domain/domain.dart';
import 'tokens.dart';

/// Colour and icon for a trip's look, used on trip tiles and theme chips
/// until each theme has its own cover artwork.
({Color color, IconData icon}) tripThemeStyle(ExperienceTheme theme) => switch (theme) {
  ExperienceTheme.classicTravel => (color: TravaryColors.ink, icon: Icons.luggage_rounded),
  ExperienceTheme.coastalResort => (color: TravaryColors.coral, icon: Icons.beach_access_rounded),
  ExperienceTheme.urbanModern => (color: TravaryColors.teal, icon: Icons.location_city_rounded),
  ExperienceTheme.urbanHeritage => (color: TravaryColors.tealDeep, icon: Icons.account_balance_rounded),
  ExperienceTheme.alpine => (color: TravaryColors.alpine, icon: Icons.ac_unit_rounded),
  ExperienceTheme.countryside => (color: TravaryColors.moss, icon: Icons.forest_rounded),
  ExperienceTheme.outdoorAdventure => (color: TravaryColors.pine, icon: Icons.hiking_rounded),
  ExperienceTheme.themepark => (color: TravaryColors.plum, icon: Icons.attractions_rounded),
  ExperienceTheme.cruise => (color: TravaryColors.harbour, icon: Icons.directions_boat_rounded),
  ExperienceTheme.roadtrip => (color: TravaryColors.mustard, icon: Icons.directions_car_rounded),
  ExperienceTheme.wellnessRetreat => (color: TravaryColors.lilac, icon: Icons.spa_rounded),
};
