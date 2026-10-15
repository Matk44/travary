import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art/art_catalog.dart';
import '../art/art_slots.dart';
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'ledger.dart';

class ProfileHeading extends StatelessWidget {
  const ProfileHeading({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final postmark =
          TravaryChrome.of(context).slots.surface(SurfaceSlot.profilePostmark) ??
          const BundledArtImage('assets/art/common/profile_postmark.webp');
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Profile', style: TravaryText.display),
              const SizedBox(height: TravarySpace.sm),
              Text('A little home for your travels.', style: TravaryText.profileSubtitle),
            ],
          ),
          if (box.maxWidth >= 350 && MediaQuery.textScalerOf(context).scale(14) <= 17)
            Positioned(
              right: 0,
              top: -4,
              width: 100,
              height: 60,
              child: ExcludeSemantics(child: TrimmedArt(image: postmark)),
            ),
        ],
      );
    },
  );
}

/// One continuous paper plate. Slicing this textured artwork produced visible
/// horizontal and vertical seams on device; it must be painted in one pass.
/// Shadows use the same image alpha, so every cut corner and notch agrees.
class ProfileStationery extends StatelessWidget {
  const ProfileStationery.folio({super.key, required this.child}) : folio = true;
  const ProfileStationery.pass({super.key, required this.child}) : folio = false;

  final Widget child;
  final bool folio;

  @override
  Widget build(BuildContext context) {
    final slot = folio ? SurfaceSlot.profileAccountFolio : SurfaceSlot.profileAnnualPass;
    final image = TravaryChrome.of(context).slots.surface(slot);
    // These are bundled global stationery, also available outside a trip's
    // chrome (the account card and standalone previews).
    final art = image ?? BundledArtImage('assets/art/common/${slot.key}.webp');
    Widget plate() => Image(
      image: artImageProvider(art),
      fit: BoxFit.fill,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => const PaperPanel(child: SizedBox.expand()),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Transform.translate(
              offset: const Offset(0, 4),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(TravaryColors.profileCastShadow, BlendMode.srcIn),
                  child: plate(),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: plate()),
        child,
      ],
    );
  }
}

enum ProfilePaperKind { pocket, memo, archive, workshop, correspondence, legal, bookplate }

/// The lower profile is a collection of useful travel stationery. The frame
/// owns the visual treatment; every switch, link and debug action stays live.
class ProfilePaperCard extends StatelessWidget {
  const ProfilePaperCard({super.key, required this.kind, required this.child});
  final ProfilePaperKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = kind == ProfilePaperKind.bookplate;
    final accent = switch (kind) {
      ProfilePaperKind.memo || ProfilePaperKind.correspondence => TravaryColors.coral,
      ProfilePaperKind.archive => TravaryColors.sage,
      ProfilePaperKind.workshop => TravaryColors.teal,
      ProfilePaperKind.bookplate => TravaryColors.mustard,
      _ => TravaryColors.kraft,
    };
    final shape = BorderRadius.circular(14);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? TravaryColors.ink : TravaryColors.paper,
          borderRadius: shape,
          border: Border.all(color: dark ? TravaryColors.kraft : TravaryColors.paperEdge),
          boxShadow: const [
            BoxShadow(color: TravaryColors.profileCastShadow, blurRadius: 12, offset: Offset(0, 4)),
            BoxShadow(color: TravaryColors.profileContactShadow, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: ClipRRect(
          borderRadius: shape,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                if (!dark) const Positioned.fill(child: IgnorePointer(child: _ProfilePaperTexture())),
                ListTileTheme(
                  data: ListTileThemeData(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    minLeadingWidth: 28,
                    horizontalTitleGap: 12,
                    iconColor: dark ? TravaryColors.mustard : accent,
                    textColor: dark ? TravaryColors.paper : TravaryColors.ink,
                    titleTextStyle: TravaryText.profileSettingTitle.copyWith(color: dark ? TravaryColors.paper : null),
                    subtitleTextStyle: TravaryText.profileSettingCopy.copyWith(
                      color: dark ? TravaryColors.paper.withValues(alpha: 0.8) : null,
                    ),
                  ),
                  child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: child),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single crop of the approved folio's blank paper; no grid, rule, pattern
/// or stitched-together image regions are drawn over settings content.
class _ProfilePaperTexture extends StatelessWidget {
  const _ProfilePaperTexture();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final sx = box.maxWidth / 1140;
      final sy = box.maxHeight / 600;
      return Opacity(
        opacity: 0.6,
        child: ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: -240 * sx,
                top: -180 * sy,
                width: 1612 * sx,
                height: 976 * sy,
                child: Image.asset(
                  'assets/art/common/profile_account_folio.webp',
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// The existing passport illustration, shared by Profile and the invitation
/// inside Travel documents. Its alpha is trimmed rather than tinted.
class PassportIllustration extends StatelessWidget {
  const PassportIllustration({super.key, this.size = 76});
  final double size;

  @override
  Widget build(BuildContext context) {
    final image =
        TravaryChrome.of(context).slots.surface(SurfaceSlot.addPassport) ??
        const BundledArtImage('assets/art/common/add_passport.webp');
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: TrimmedArt(image: image),
      ),
    );
  }
}

/// The approved navy pass button, with a live label, arrow and busy state.
/// Its transparent atlas margin is cropped at paint time, never baked onto
/// the cream ticket underneath it.
class ProfilePassAction extends StatelessWidget {
  const ProfilePassAction({super.key, required this.onPressed, this.busy = false});
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final image =
        TravaryChrome.of(context).slots.surface(SurfaceSlot.profilePassButton) ??
        const BundledArtImage('assets/art/common/profile_pass_button.webp');
    return Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, box) {
                // The generated 2172 × 724 master has transparent margins.
                final sx = box.maxWidth / 2116;
                final sy = box.maxHeight / 412;
                return ClipRect(
                  child: Stack(
                    children: [
                      Positioned(
                        left: -28 * sx,
                        top: -160 * sy,
                        width: 2172 * sx,
                        height: 724 * sy,
                        child: Image(
                          image: artImageProvider(image),
                          fit: BoxFit.fill,
                          errorBuilder: (_, _, _) => const ColoredBox(color: TravaryColors.ink),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: busy ? null : onPressed,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              foregroundColor: TravaryColors.paper,
              textStyle: TravaryText.ticketButton,
              shape: const NotchedTicketBorder(),
            ),
            child: busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: TravaryColors.paper),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: Text('See the Annual Pass', textAlign: TextAlign.center)),
                      const SizedBox(width: TravarySpace.sm),
                      const Icon(Icons.chevron_right_rounded, size: 22),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// A paper pocket with the passport peeking out, rather than a settings glyph.
class ProfileDocumentsPocket extends StatelessWidget {
  const ProfileDocumentsPocket({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ProfilePaperCard(
    kind: ProfilePaperKind.pocket,
    child: InkWell(
      key: const ValueKey('profile-travel-documents'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        child: Row(
          children: [
            const PassportIllustration(),
            const SizedBox(width: TravarySpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Travel documents', style: TravaryText.title),
                  const SizedBox(height: 3),
                  Text('Passports, visas & insurance', style: TravaryText.bodySoft),
                  const SizedBox(height: 3),
                  Text('Kept on this phone only', style: TravaryText.small),
                ],
              ),
            ),
            const SizedBox(width: TravarySpace.sm),
            const Icon(Icons.chevron_right_rounded, color: TravaryColors.ink),
          ],
        ),
      ),
    ),
  );
}
