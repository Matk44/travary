import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../logic/travel_documents.dart';
import '../tokens.dart';
import '../trip_chrome.dart';

/// The icon for each kind of travel document.
IconData documentTypeIcon(TravelDocumentType type) => switch (type) {
  TravelDocumentType.passport => Icons.menu_book_rounded,
  TravelDocumentType.visa => Icons.approval_rounded,
  TravelDocumentType.insurance => Icons.health_and_safety_outlined,
  TravelDocumentType.drivingLicence => Icons.directions_car_outlined,
  TravelDocumentType.idCard => Icons.badge_outlined,
  TravelDocumentType.health => Icons.medical_services_outlined,
  TravelDocumentType.other => Icons.description_outlined,
};

/// One travel document in a list: its kind's medallion, its name, whose it
/// is with the masked number, and when it runs out (in coral when that's a
/// problem). Drawn from [text], never worded here.
///
/// A plain paper row for now; a passport-cover shell can replace it later
/// (`docs/ART_ASSET_GAPS.md`).
class TravelDocumentCard extends StatelessWidget {
  const TravelDocumentCard({super.key, required this.text, required this.type, this.onTap});

  final DocumentCardText text;
  final TravelDocumentType type;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final warn = text.alert == DocumentAlert.trip || text.alert == DocumentAlert.expired;
    final statusColor = switch (text.alert) {
      DocumentAlert.none => TravaryColors.inkSoft,
      DocumentAlert.soon => TravaryColors.ink,
      DocumentAlert.trip || DocumentAlert.expired => TravaryColors.coral,
    };
    final shape = BorderRadius.circular(TravaryRadius.card);
    return Semantics(
      button: onTap != null,
      label: text.semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: TravaryColors.paper,
        borderRadius: shape,
        elevation: 1,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Padding(
            padding: const EdgeInsets.all(TravarySpace.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                  child: Icon(documentTypeIcon(type), color: colors.onPrimary, size: 22),
                ),
                const SizedBox(width: TravarySpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text.title, style: TravaryText.label.copyWith(fontSize: 15.5)),
                      const SizedBox(height: 2),
                      Text(
                        [text.holder, ?text.detail].join(' · '),
                        style: TravaryText.small,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (text.status case final status?) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (warn) ...[
                              const Icon(Icons.error_outline_rounded, size: 14, color: TravaryColors.coral),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                status,
                                style: TravaryText.small.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: TravaryColors.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
