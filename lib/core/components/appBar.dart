import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'buttons.dart';

/// AppBar compartido por los dashboards principales (Resumen, Balance,
/// Organización): a la izquierda el botón de ayuda que abre el showcase de
/// la pantalla ([onHelp]; sin él queda un círculo reservado), título
/// centrado y un círculo a la derecha para la acción contextual de la
/// pantalla (ej. transferir entre cuentas en Organización). Cuando la
/// pantalla tiene tabs, [bottom] agrega la barra de pestañas debajo del
/// título.
class AppMainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onHelp;
  final Widget? trailing;
  final PreferredSizeWidget? bottom;

  const AppMainAppBar({
    super.key,
    required this.title,
    this.onHelp,
    this.trailing,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: onHelp == null
          ? const _EmptyCircleSlot()
          : AppCircularIconButton(
              icon: MdiIcons.helpCircleOutline,
              tooltip: 'Ayuda',
              onPressed: onHelp,
            ),
      title: Text(
        title,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [trailing ?? const _EmptyCircleSlot(), const SizedBox(width: 8)],
      bottom: bottom,
    );
  }
}

/// Reserva el mismo espacio que [AppCircularIconButton] sin dibujar nada,
/// para que el título quede centrado aunque ese lado no tenga acción.
class _EmptyCircleSlot extends StatelessWidget {
  const _EmptyCircleSlot();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Opacity(
        opacity: 0,
        child: AppCircularIconButton(icon: Icons.circle, onPressed: null),
      ),
    );
  }
}
