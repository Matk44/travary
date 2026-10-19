import 'package:flutter/material.dart';

import '../../domain/pricing.dart';
import '../tokens.dart';

/// A purchased pass as a physical foil ticket. The accessible name stays
/// live even though the ticket's lettering is part of its artwork.
class PassBadge extends StatelessWidget {
  const PassBadge({super.key, required this.kind});

  final OfferKind kind;

  String get label => kind == OfferKind.tripPass ? 'Holiday Pass' : 'Annual Pass';

  @override
  Widget build(BuildContext context) {
    final holiday = kind == OfferKind.tripPass;
    return Semantics(
      label: '$label active',
      image: true,
      child: Tooltip(
        message: '$label active',
        excludeFromSemantics: true,
        child: Image.asset(
          'assets/art/common/${holiday ? 'holiday' : 'annual'}_pass_badge_v1.webp',
          width: PassBadgeLayout.width,
          height: PassBadgeLayout.height,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
