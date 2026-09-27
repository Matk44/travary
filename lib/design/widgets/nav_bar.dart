import 'package:flutter/material.dart';

import '../tokens.dart';

class NavItem {
  const NavItem(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Bottom bar: two tabs, the big add button, two tabs.
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
    Widget tab(int index) {
      final item = items[index];
      final selected = index == selectedIndex;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          label: item.label,
          excludeSemantics: true,
          child: InkResponse(
            onTap: () => onSelected(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: selected ? TravaryColors.ink : TravaryColors.inkFaint,
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  style: TravaryText.small.copyWith(
                    color: selected ? TravaryColors.ink : TravaryColors.inkFaint,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? 22 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: TravaryColors.coral,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: TravaryColors.paper,
        border: Border(top: BorderSide(color: TravaryColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              tab(0),
              tab(1),
              Expanded(
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Add a booking',
                    excludeSemantics: true,
                    child: Material(
                      color: TravaryColors.ink,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: InkWell(
                        onTap: onAdd,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 58,
                          height: 58,
                          child: Icon(Icons.add_rounded, color: TravaryColors.paper, size: 30),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              tab(2),
              tab(3),
            ],
          ),
        ),
      ),
    );
  }
}
