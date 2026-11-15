import 'package:material_ui/material_ui.dart';

/// Ítem de la barra de navegación inferior: ícono con etiqueta pequeña.
class AppBottomNavItem {
  final IconData icon;
  final String label;

  const AppBottomNavItem({required this.icon, required this.label});
}

/// Barra de navegación inferior plana: línea fina arriba, ítems con ícono y
/// etiqueta, y un botón "+" central (el [centerButton]) entre los ítems
/// [0..centerAfterIndex] y el resto. Sin muesca ni bandeja: el botón es un
/// ítem más de la fila, así que nada se solapa con el contenido.
class AppBottomNavBar extends StatelessWidget {
  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int centerAfterIndex;

  /// Widget del centro (normalmente [AppAddButton]); null deja el hueco
  /// vacío para que los ítems no cambien de posición.
  final Widget? centerButton;

  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.centerAfterIndex = 0,
    this.centerButton,
  });

  static const height = 60.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget item(int i) => Expanded(
      child: _NavBarItem(
        item: items[i],
        active: i == currentIndex,
        onTap: () => onTap(i),
        colorScheme: colorScheme,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (var i = 0; i <= centerAfterIndex; i++) item(i),
              SizedBox(
                width: 72,
                child: Center(child: centerButton ?? const SizedBox.shrink()),
              ),
              for (var i = centerAfterIndex + 1; i < items.length; i++) item(i),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón "+" central: círculo relleno con el color primario.
class AppAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? tooltip;

  const AppAddButton({super.key, required this.onTap, this.tooltip});

  static const _size = 44.0;

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
          width: _size,
          height: _size,
          child: Icon(Icons.add, color: colorScheme.onPrimary),
        ),
      ),
    );
    return tooltip == null ? boton : Tooltip(message: tooltip!, child: boton);
  }
}

class _NavBarItem extends StatelessWidget {
  final AppBottomNavItem item;
  final bool active;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _NavBarItem({
    required this.item,
    required this.active,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? colorScheme.onSurface : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
