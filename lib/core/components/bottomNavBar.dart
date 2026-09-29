import 'package:flutter/material.dart';

/// Ítem de la barra de navegación inferior: solo ícono, sin etiqueta
/// visible. [label] se usa como tooltip/accesibilidad.
class AppBottomNavItem {
  final IconData icon;
  final String label;

  const AppBottomNavItem({required this.icon, required this.label});
}

/// Fila de ítems para usar como `child` de un [BottomAppBar] con muesca
/// central acoplado a [AppFloatingNavButton] (ver su uso en `RootShell`,
/// vía `Scaffold.floatingActionButton` +
/// `FloatingActionButtonLocation.centerDocked`). El primer ítem (según
/// [centerAfterIndex]) ocupa, centrado, la mitad izquierda de la barra; el
/// resto se agrupa y centra en la mitad derecha. Ninguno de los dos grupos
/// se acerca al centro geométrico de la barra, que es justo donde el
/// framework talla la muesca para el botón flotante — así se evita
/// cualquier solape sin necesidad de calcular a mano un hueco fijo.
class AppBottomNavBar extends StatelessWidget {
  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int centerAfterIndex;

  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.centerAfterIndex = 0,
  });

  /// Alto de la bandeja; lo usa `RootShell` para dimensionar el
  /// [BottomAppBar] que envuelve esta fila.
  static const trayHeight = 56.0;

  static const _duration = Duration(milliseconds: 250);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final izquierda = items.sublist(0, centerAfterIndex + 1);
    final derecha = items.sublist(centerAfterIndex + 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < izquierda.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    _NavBarItem(
                      item: izquierda[i],
                      active: i == currentIndex,
                      onTap: () => onTap(i),
                      colorScheme: colorScheme,
                      duration: _duration,
                      curve: _curve,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < derecha.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    _NavBarItem(
                      item: derecha[i],
                      active: (centerAfterIndex + 1 + i) == currentIndex,
                      onTap: () => onTap(centerAfterIndex + 1 + i),
                      colorScheme: colorScheme,
                      duration: _duration,
                      curve: _curve,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón circular flotante para usar como `Scaffold.floatingActionButton`
/// junto con `FloatingActionButtonLocation.centerDocked`: el framework lo
/// centra y alinea su mitad exactamente sobre el borde superior de la
/// barra (la otra mitad queda dentro de la muesca). Un aro del color de
/// fondo del tema rodea el botón relleno con el color primario, para que
/// el corte se vea limpio sin importar qué haya detrás.
class AppFloatingNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const AppFloatingNavButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  static const _buttonSize = 48.0;
  static const _ringPadding = 4.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final boton = Material(
      color: colorScheme.primary,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: _buttonSize,
          height: _buttonSize,
          child: Icon(icon, color: colorScheme.onPrimary),
        ),
      ),
    );

    final anillo = Container(
      width: _buttonSize + _ringPadding * 2,
      height: _buttonSize + _ringPadding * 2,
      padding: const EdgeInsets.all(_ringPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        shape: BoxShape.circle,
      ),
      child: boton,
    );

    return tooltip == null ? anillo : Tooltip(message: tooltip!, child: anillo);
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

    return Tooltip(
      message: item.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: duration,
          curve: curve,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: active ? colorScheme.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}
