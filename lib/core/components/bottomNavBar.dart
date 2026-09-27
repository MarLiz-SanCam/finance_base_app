import 'package:flutter/material.dart';

/// Ítem de la barra de navegación inferior: ícono siempre visible y
/// etiqueta que solo se muestra cuando el ítem está activo.
class AppBottomNavItem {
  final IconData icon;
  final String label;

  const AppBottomNavItem({required this.icon, required this.label});
}

/// Barra de navegación inferior flotante: los ítems inactivos se muestran
/// como solo ícono sobre una barra oscura, y el ítem activo se expande en
/// su propia posición a una píldora con ícono + etiqueta.
class AppBottomNavBar extends StatelessWidget {
  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  static const _duration = Duration(milliseconds: 250);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _NavBarItem(
              item: items[i],
              active: i == currentIndex,
              onTap: () => onTap(i),
              colorScheme: colorScheme,
              duration: _duration,
              curve: _curve,
            ),
          ],
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final AppBottomNavItem item;
  final bool active;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final Duration duration;
  final Curve curve;

  const _NavBarItem({
    required this.item,
    required this.active,
    required this.onTap,
    required this.colorScheme,
    required this.duration,
    required this.curve,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = active
        ? colorScheme.onPrimary
        : colorScheme.onInverseSurface.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        padding: active
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 22, color: iconColor),
            AnimatedSize(
              duration: duration,
              curve: curve,
              child: active
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox(width: 0, height: 0),
            ),
          ],
        ),
      ),
    );
  }
}
