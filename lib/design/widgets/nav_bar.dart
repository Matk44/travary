import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../art/art_catalog.dart';
import '../art/art_slots.dart';
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';

class NavItem {
  const NavItem(this.label, this.icon);

  final String label;
  final IconSlot icon;
}

/// The home tabs: two fabric tabs, the coral add tab, two more, standing on
/// the leather strip at the bottom of the screen (in the safe area).
///
/// The chosen tab pops up [NavLayout.rise] points with an ease-out-back
/// spring, its shadow deepening, and takes the trip palette's primary
/// colour; the others settle back without anything moving sideways. With
/// reduced motion the change is instant. Tabs and their pictures come from
/// raster surfaces; while those are missing, plain flat tabs stand in
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
    final slots = TravaryChrome.of(context).slots;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final leather = slots.surface(SurfaceSlot.leather);

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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            left: NavLayout.inset,
            right: NavLayout.inset,
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
          if (leather != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: bottom + 2,
              child: IgnorePointer(
                child: Image(
                  key: const ValueKey('nav-leather'),
                  image: artImageProvider(leather),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A tab's surface: its raster fabric, or a plain flat tab while the art is
/// missing. [tint] recolours a neutral selected-tab fabric.
class _TabSurface extends StatelessWidget {
  const _TabSurface({required this.image, required this.color, required this.elevation, this.tint});

  final ArtImageRef? image;
  final Color color;
  final double elevation;
  final Color? tint;

  static const _shape = BorderRadius.vertical(top: Radius.circular(NavLayout.radius));

  @override
  Widget build(BuildContext context) {
    final shadow = [
      BoxShadow(color: const Color(0x33000000), blurRadius: 3 + elevation * 6, offset: Offset(0, 1 + elevation * 2)),
    ];
    if (image != null) {
      return DecoratedBox(
        decoration: BoxDecoration(borderRadius: _shape, boxShadow: shadow),
        // Never stretched: the tab's top edge shows, its foot runs on under
        // the leather strip.
        child: Image(
          image: artImageProvider(image!),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          color: tint,
          colorBlendMode: tint == null ? null : BlendMode.multiply,
        ),
      );
    }
    return DecoratedBox(
      key: const ValueKey('tab-fallback'),
      decoration: BoxDecoration(color: color, borderRadius: _shape, boxShadow: shadow),
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
                    image: c > 0.5 ? (selectedImage ?? tabImage) : tabImage,
                    tint: c > 0.5 && selectedImage != null ? colors.primary : null,
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(item.label, style: label, maxLines: 1),
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
              child: _TabSurface(image: image, color: TravaryColors.coral, elevation: 0.6),
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
