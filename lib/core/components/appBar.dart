import 'package:flutter/material.dart';

import '../../pages/categorias/dash_categorias.dart';
import '../../pages/cuentas/dash_cuentas.dart';
import '../../pages/obligaciones/dash_obligaciones.dart';
import 'buttons.dart';

/// AppBar compartido por los dashboards principales (Egresos, Inicio,
/// Ingresos): título alineado a la izquierda y, a la derecha, 3 accesos
/// directos fijos a Cuentas, Categorías y Obligaciones (antes agrupados en
/// la pestaña "Más", ahora eliminada).
class AppMainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AppMainAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: Text(
        title,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        AppCircularIconButton(
          icon: Icons.account_balance_wallet_outlined,
          tooltip: 'Cuentas',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DashCuentasPage()),
          ),
        ),
        AppCircularIconButton(
          icon: Icons.category_outlined,
          tooltip: 'Categorías',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DashCategoriasPage()),
          ),
        ),
        AppCircularIconButton(
          icon: Icons.repeat,
          tooltip: 'Obligaciones',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DashObligacionesPage()),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
