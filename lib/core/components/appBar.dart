import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'buttons.dart';

/// AppBar compartido por los dashboards principales (Resumen, Balance,
/// Organización): título alineado a la izquierda y, a la derecha, la acción
/// contextual de la pantalla ([trailing], ej. transferir entre cuentas en
/// Organización) y el botón de ayuda que abre el showcase ([onHelp]). Cuando la
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

  static const _toolbarHeight = 64.0;

  @override
  Size get preferredSize =>
      Size.fromHeight(_toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      toolbarHeight: _toolbarHeight,
      titleSpacing: 20,
      title: Text(
        title,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        if (trailing != null) trailing!,
        if (onHelp != null)
          AppCircularIconButton(
            icon: Symbols.help,
            tooltip: 'Ayuda',
            onPressed: onHelp,
          ),
        const SizedBox(width: 4),
      ],
      bottom: bottom,
    );
  }
}
