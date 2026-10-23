import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../art/art_catalog.dart';
import '../art/art_slots.dart';
import '../art/card_shells.dart' show FractionRect;
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'readable_width.dart';

class NavItem {
  const NavItem(this.label, this.icon);

  final String label;
  final IconSlot icon;
}

/// The home tabs: two fabric tabs, the coral add tab, two more, running off
/// the bottom of the screen (through the safe area). Nothing is drawn under
/// them: the owner had the navy leather strip taken out (14 Oct 2026).
///
/// The chosen tab pops up [NavLayout.rise] points with an ease-out-back
/// spring, its shadow deepening, as its cream fabric crossfades into the
/// teal selected tab; the others settle back without anything moving
/// sideways. With reduced motion the change is instant. Each tab is a
/// raster shell, a raster icon (tinted navy, or the palette's onPrimary
/// when selected), a real label and one hit target; nothing is baked into
/// the shells. While a file is missing, plain flat tabs stand in
/// (docs/ART_ASSET_GAPS.md).
class TravaryNavBar extends StatelessWidget {
  const TravaryNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onAdd,
  }) : assert(items.length == 4);

  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    Widget tab(int index) => Expanded(
      flex: NavLayout.tabFlex,
      child: _NavTab(
        item: items[index],
        selected: index == selectedIndex,
        onTap: () => onSelected(index),
        bottomInset: bottom,
      ),
    );

    const gap = SizedBox(width: NavLayout.gap);
    return SizedBox(
      height: NavLayout.height + NavLayout.rise + bottom,
      child: Padding(
        // On a tablet the tabs keep a phone's proportions, centred.
        padding: EdgeInsets.symmetric(
          horizontal: NavLayout.inset + readableInset(context, maxWidth: ScreenLayout.navWidth),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tab(0),
            gap,
            tab(1),
            gap,
            Expanded(
              flex: NavLayout.addFlex,
              child: _AddTab(onTap: onAdd, bottomInset: bottom),
            ),
            gap,
            tab(2),
            gap,
            tab(3),
          ],
        ),
      ),
    );
  }
}

/// A tab's surface. The raster tabs are finished materials (`tab.webp`
/// cream, `tab_selected.webp` petrol teal, `tab_add.webp` coral), never tinted:
/// a destination pack that wants another selected tab supplies its own
/// `common/tab_selected.webp`. Each is placed by the tab's own measured
/// edges ([SurfaceSlot.body]), never stretched: its top edge sits at the top
/// of the slot and its foot runs off the bottom of the screen (where the
/// file ends first, over a home indicator, its last stretch of fabric
/// carries on), while the file's transparent margin spills harmlessly round
/// it. Resting crossfades into selected by [selection], and a soft shadow
/// behind the tab deepens as it rises ([elevation]).
///
/// While a file is missing, a plain flat tab in [color] stands in (the only
/// place the palette colours a tab).
class _TabSurface extends StatelessWidget {
  const _TabSurface({
    required this.resting,
    required this.restingSlot,
    required this.color,
    required this.elevation,
    this.selected,
    this.selection = 0,
  });

  final ArtImageRef? resting;
  final SurfaceSlot restingSlot;
  final ArtImageRef? selected;

  /// 0 resting, 1 selected.
  final double selection;

  /// The flat stand-in's colour.
  final Color color;

  /// 0 resting, 1 raised (may overshoot with the spring).
  final double elevation;

  static const _shape = BorderRadius.vertical(top: Radius.circular(NavLayout.radius));

  List<BoxShadow> get _shadow => [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.14 + 0.10 * elevation.clamp(0.0, 1.0)),
      blurRadius: 3 + elevation * 6,
      offset: Offset(0, 1 + elevation * 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (resting == null) {
      return DecoratedBox(
        key: const ValueKey('tab-fallback'),
        decoration: BoxDecoration(color: color, borderRadius: _shape, boxShadow: _shadow),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        List<Widget> place(ArtImageRef image, SurfaceSlot slot, {Key? key}) {
          final body = slot.body ?? const FractionRect(0, 0, 1, 1);
          final width = box.maxWidth / body.width;
          // Tab files are made at 720 × 1024: this box is exactly their shape.
          final height = width * 1024 / 720;
          final left = -body.left * width;
          final top = -body.top * height;
          Widget picture({Key? key}) =>
              Image(key: key, image: artImageProvider(image), fit: BoxFit.fill, gaplessPlayback: true);
          // Room left under the file's foot: its last stretch of fabric,
          // straight sides and all, runs on into it (from just above the
          // foot, whose very edge darkens a little).
          final rest = box.maxHeight - top - height;
          final edge = height * .03;
          return [
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: picture(key: key),
            ),
            if (rest > 0)
              Positioned(
                left: left,
                top: top + height - edge,
                width: width,
                height: rest + edge,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.bottomCenter,
                    minHeight: height,
                    maxHeight: height,
                    child: Transform.translate(offset: Offset(0, edge), child: picture()),
                  ),
                ),
              ),
          ];
        }

        Widget layer(double opacity, List<Widget> children) => Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: Stack(clipBehavior: Clip.none, children: children),
          ),
        );

        final showSelected = selected != null && selection > 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // The elevation response: a shadow under the tab's own outline.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: _shape, boxShadow: _shadow),
              ),
            ),
            if (!showSelected || selection < 1)
              layer(showSelected ? 1 - selection : 1, place(resting!, restingSlot, key: const ValueKey('tab-raster'))),
            if (showSelected)
              layer(selection, place(selected!, SurfaceSlot.tabSelected, key: const ValueKey('tab-selected-raster'))),
          ],
        );
      },
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.item, required this.selected, required this.onTap, required this.bottomInset});

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final chrome = TravaryChrome.of(context);
    final colors = chrome.colors;
    final slots = chrome.slots;
    final still = MediaQuery.disableAnimationsOf(context);
    final icon = slots.icon(item.icon);
    final tabImage = slots.surface(SurfaceSlot.tab);
    final selectedImage = slots.surface(SurfaceSlot.tabSelected);

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: selected ? 1 : 0),
        duration: still ? Duration.zero : NavLayout.popDuration,
        curve: Curves.easeOutBack,
        builder: (context, t, _) {
          // easeOutBack overshoots past 1: the spring. Colours don't.
          final c = t.clamp(0.0, 1.0);
          final surface = Color.lerp(TravaryColors.paper, colors.primary, c)!;
          final ink = Color.lerp(colors.ink, colors.onPrimary, c)!;
          final label = TextStyle.lerp(
            TravaryText.tabLabel.copyWith(color: ink),
            TravaryText.tabLabelSelected.copyWith(color: ink),
            c,
          )!;
          return Transform.translate(
            // Unselected tabs sit lower; the chosen one pops up.
            offset: Offset(0, NavLayout.rise * (1 - t)),
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  // Reaches past the screen bottom so the rise never shows a gap.
                  bottom: -NavLayout.rise,
                  child: _TabSurface(
                    resting: tabImage,
                    restingSlot: SurfaceSlot.tab,
                    selected: selectedImage,
                    selection: c,
                    color: surface,
                    elevation: t,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: NavLayout.height + NavLayout.rise,
                  child: Padding(
                    // The words stay near their resting place while the
                    // fabric rises, as on the reference.
                    padding: EdgeInsets.only(top: lerpDouble(4, 6, t)!),
                    child: Column(
                      children: [
                        // Raster icons keep a transparent margin; the box
                        // may overlap the label's space without touching it.
                        SizedBox(
                          height: lerpDouble(NavLayout.iconSize - 8, NavLayout.selectedIconSize - 8, c),
                          child: OverflowBox(
                            maxHeight: NavLayout.selectedIconSize,
                            child: SlotIcon(
                              icon: icon,
                              color: ink,
                              size: lerpDouble(NavLayout.iconSize, NavLayout.selectedIconSize, c),
                            ),
                          ),
                        ),
                        // Shrinks to the room left under the icon too, so
                        // large text never spills out of the tab.
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(item.label, style: label, maxLines: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(NavLayout.radius)),
                      focusColor: colors.highlight.withValues(alpha: 0.25),
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The central coral tab: add a booking. Always a little raised.
class _AddTab extends StatelessWidget {
  const _AddTab({required this.onTap, required this.bottomInset});

  final VoidCallback onTap;
  final double bottomInset;

  static const _lift = 5.0;

  @override
  Widget build(BuildContext context) {
    final chrome = TravaryChrome.of(context);
    final colors = chrome.colors;
    final image = chrome.slots.surface(SurfaceSlot.tabAdd);
    final icon = chrome.slots.icon(IconSlot.navAdd);

    return Semantics(
      button: true,
      label: 'Add a booking',
      excludeSemantics: true,
      child: Transform.translate(
        offset: const Offset(0, NavLayout.rise - _lift),
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              bottom: -NavLayout.rise,
              child: _TabSurface(
                resting: image,
                restingSlot: SurfaceSlot.tabAdd,
                color: TravaryColors.coral,
                elevation: 0.6,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: NavLayout.height + _lift,
              child: Center(
                child: SlotIcon(icon: icon, color: colors.ink, size: 40),
              ),
            ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(NavLayout.radius)),
                  focusColor: colors.highlight.withValues(alpha: 0.25),
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
